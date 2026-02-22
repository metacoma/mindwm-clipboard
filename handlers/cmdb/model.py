from __future__ import annotations
from enum import IntEnum,StrEnum
import ipaddress

from typing import Any, List, Optional, Dict, ClassVar
from pydantic import BaseModel, Field, ConfigDict,  model_serializer,  computed_field
from datetime import datetime
import pprint
import json
import os
import utils
import logging
import hashlib
import time

logger = logging.getLogger(__name__)

jira_url = os.getenv('jira_url')
cmdb_id = os.getenv('CMDB_ID')

CACHE_DIR = "/tmp/cmdb_cache"
CACHE_TTL = 60 * 60 * 24  # 1 day

os.makedirs(CACHE_DIR, exist_ok=True)

class JiraTypes(StrEnum):
    SAN_RACK_SWITCH = "SAN Rack Switch"
    FIREWALL = "Firewall"
    NAS = "NAS"

class JiraAttributeID(IntEnum):
    #dc
    DC_LOCATION = 16877
    COUNTRY = 16878
    STATUS = 73044
    NUMBER = 16880
    DC_DOC = 16886

    #host
    HOST_LOCATION = 19284
    NETWORK_INTERFACE = 54993
    HOST_OWNER = 75572
    HOST_OS = 78843
    HOST_SERVICE = 19394
    HOST_VIP_IP = 56556
    HOST_TEAM = 55217
    HOST_MODEL = 56309

    HW_SERIAL = 19094
    HW_LOCATION = 19284
    HW_RACK = 19299
    HW_START_UNIT = 55345
    HW_UNIT_SIZE = 55344

    # user
    USER_ATTR_ID = 78466
    USER_DETAILS = 80128
    USER_HEAD_OF = 78467

    #team
    TEAM_USERS = 78505

class ObjectAttributeValue(BaseModel):
    model_config = ConfigDict(extra="allow")

    value: Optional[Any] = None
    displayValue: Optional[str] = None
    referencedObject: Optional[Dict[str, Any]] = None


class ObjectAttribute(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: int
    objectId: Optional[int] = None

    objectTypeAttributeId: Optional[int] = None
    objectTypeAttribute: Optional[Dict[str, Any]] = None

    objectAttributeValues: List[ObjectAttributeValue] = Field(default_factory=list)

    def attr_name(self) -> Optional[str]:
        if isinstance(self.objectTypeAttribute, dict):
            return self.objectTypeAttribute.get("name")
        return None


class ObjectType(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: int
    name: Optional[str] = None


class ObjectEntry(BaseModel):
    model_config = ConfigDict(extra="allow")
    #ID = Optional[Dict[str, int]]

    id: int
    label: Optional[str] = None
    objectKey: Optional[str] = None

    objectType: Optional[ObjectType] = None
    created: Optional[datetime] = None
    updated: Optional[datetime] = None
    links: Optional[Dict[str, str]] = Field(default=None, alias="_links")

    # Jira может вернуть attributes или objectAttributes — поддержим оба
    attributes: Optional[List[ObjectAttribute]] = None
    objectAttributes: Optional[List[ObjectAttribute]] = None


    assetId: ClassVar[Dict[str, int]] = {}

    def _attrs(self) -> List["ObjectAttribute"]:
        return self.attributes or self.objectAttributes or []

    def getAttributeById(self, attr_id: int) -> Optional[Any]:
        for attr in self._attrs():
            if attr.objectTypeAttributeId == attr_id:
                return attr
        return None


    def getAttributeValueById(self, attr_id: int) -> Optional[Any]:
        attr = self.getAttributeById(attr_id)
        if (attr):
            values = []
            for v in attr.objectAttributeValues:
                if v.value is not None:
                    values.append(v.value)
                elif v.displayValue is not None:
                    values.append(v.displayValue)
            if not values:
                return None
            return values[0] if len(values) == 1 else values
        return None

    def _attrs(self) -> List[ObjectAttribute]:
        return self.attributes or self.objectAttributes or []

    def get_type(self) -> Optional[str]:
        return self.objectType.name

    def get_name(self) -> Optional[str]:
        for a in self._attrs():
            if a.attr_name() == "Name":
                if a.objectAttributeValues:
                    v = a.objectAttributeValues[0]
                    return v.value if v.value is not None else v.displayValue
        return self.label

    def get_attr_value(self, attr_name: str) -> Optional[Any]:
        for attr in self._attrs():
            if attr.attr_name() == attr_name:
                values = []
                for v in attr.objectAttributeValues:
                    if v.value is not None:
                        values.append(v.value)
                    elif v.displayValue is not None:
                        values.append(v.displayValue)

                if not values:
                    return None
                if len(values) == 1:
                    return values[0]
                return values
        return None

    @computed_field
    @property
    def selfUrl(self) -> Optional[str]:
        if self.links:
            return self.links.get("self")
        return None

class DataCenter(ObjectEntry):

    def getLocation(self):
        return self.getAttributeValueById(JiraAttributeID.DC_LOCATION)

    def getCountry(self):
        return self.getAttributeValueById(JiraAttributeID.COUNTRY)

    def getStatus(self):
        return self.getAttributeValueById(JiraAttributeID.STATUS)

    def getNumber(self):
        return self.getAttributeValueById(JiraAttributeID.NUMBER)

    def getDocumentation(self):
        attr_obj = self.getAttributeById(JiraAttributeID.DC_DOC)
        if not attr_obj:
            return None

        attr = attr_obj.model_dump()

        values = attr.get("objectAttributeValues") or []
        first = values[0] if values else {}

        url = first.get("confluencePage", {}).get("url")

        if url:
            return url

        return None
    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)

        return {
            "name": self.get_attr_value("Name") or self.label,
            "selfUrl": self.selfUrl,
            "documentation": self.getDocumentation(),
            "created": self.created,
            "updated": self.updated,
            "country": self.getCountry(),
            "location": self.getLocation(),
            "number": int(self.getNumber()) if self.getNumber() is not None else None,
            "status": self.getStatus()
        }

class Team(ObjectEntry):

    @computed_field
    @property
    def memberNames(self) -> List[str]:
        users = self.getAttributeById(JiraAttributeID.TEAM_USERS)
        if not users:
            return []
        usernames = [
            u.displayValue
            for u in users.objectAttributeValues
            if (
                u.displayValue
                and u.displayValue != self.name
                and u.displayValue.lower() != "уволился"
            )
        ]
        unique_usernames = list(dict.fromkeys(usernames))

        return unique_usernames

    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
            "name": self.get_attr_value("Name") or self.label,
            "selfUrl": self.selfUrl,
            "created": self.created,
            "updated": self.updated,
            "memberNames": self.memberNames,
            "members": [
                get_user(member_name)
                for member_name in (self.memberNames or [])
                if member_name
            ]
        }

class InfrastructureNode(ObjectEntry):
    assetId: ClassVar[dict[str, int]] = {
        "networkInterface": JiraAttributeID.NETWORK_INTERFACE,
        "location": JiraAttributeID.HW_LOCATION,
        "serial": JiraAttributeID.HW_SERIAL,
        "team": JiraAttributeID.HOST_TEAM,
        "owner": JiraAttributeID.HOST_OWNER,
        "model": JiraAttributeID.HOST_MODEL,
    }
    @computed_field
    @property
    def name(self) -> str:
        return self.get_attr_value("Name") or self.label

    @computed_field
    @property
    def location(self) -> str|DataCenter|None:
        r = self.getAttributeValueById(self.assetId["location"])
        if (r):
            dc = get_dc(r)
            if dc:
                return dc
            else:
                return r
        return None

    @computed_field
    @property
    def networkInterface(self) -> List[str]|None:
        r = self.getAttributeValueById(self.assetId["networkInterface"])

        if r is None:
            return None

        if isinstance(r, list):
            return r

        return [ r ]

    @computed_field
    @property
    def owner(self) -> User|None:
        attr_obj = self.getAttributeById(self.assetId["owner"])
        if not attr_obj:
            return None

        attr = attr_obj.model_dump()

        values = attr.get("objectAttributeValues") or []
        first = values[0] if values else {}

        #avatarUrl = first.get("user", {}).get("avatarUrl")
        #name = first.get("user", {}).get("name")
        displayName = first.get("user", {}).get("displayName")

        return get_user(displayName)

    @computed_field
    @property
    def team(self) -> Team|None:
        r = self.getAttributeValueById(self.assetId["team"])
        if r:
            return get_team(r)
        return None

class PhysicalInfrastructureNode(InfrastructureNode):
    assetId: ClassVar[dict[str, int]] = {
        **InfrastructureNode.assetId,
        "serial": JiraAttributeID.HW_SERIAL,
        "startUnit": JiraAttributeID.HW_START_UNIT,
        "size": JiraAttributeID.HW_UNIT_SIZE,
        "rackId" : JiraAttributeID.HW_RACK
    }
    @computed_field
    @property
    def serial(self) -> str|None:
        return self.getAttributeValueById(self.assetId["serial"])

    @computed_field
    @property
    def model(self) -> str|None:
        return self.getAttributeValueById(self.assetId["model"])

    @computed_field
    @property
    def startUnit(self) -> str|None:
        return self.getAttributeValueById(self.assetId["startUnit"])

    @computed_field
    @property
    def size(self) -> str|None:
        return self.getAttributeValueById(self.assetId["size"])

    @computed_field
    @property
    def rackId(self) -> str | None:
        return self.getAttributeValueById(self.assetId["rackId"])

class Host(InfrastructureNode):
    assetId = {
        "location": JiraAttributeID.HOST_LOCATION,
        "networkInterface": JiraAttributeID.NETWORK_INTERFACE,
        "owner": JiraAttributeID.HOST_OWNER,
        "team": JiraAttributeID.HOST_TEAM,
        "os": JiraAttributeID.HOST_OS,
        "service": JiraAttributeID.HOST_SERVICE,
        "vip": JiraAttributeID.HOST_VIP_IP,
    }

    @computed_field
    @property
    def os(self) -> str|None:
        return self.getAttributeValueById(self.assetId["os"])

    @computed_field
    @property
    def service(self) -> str|None:
        return self.getAttributeValueById(self.assetId["service"])

    @computed_field
    @property
    def vip(self) -> str|None:
        return self.getAttributeValueById(self.assetId["vip"])

    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
            "name": self.name,
            "selfUrl": self.selfUrl,
            "created": self.created,
            "updated": self.updated,
            "location": self.location,
            "networkInterface": self.networkInterface,
            "owner": self.owner,
            "os": self.os,
            "service": self.service,
            "vipIp": self.vip,
            "team": self.team
        }

class User(ObjectEntry):
    @computed_field
    @property
    def name(self) -> str:
        return self.get_attr_value("Name") or self.label

    @computed_field
    @property
    def jiraUserAvatar(self) -> str:
        attr_obj = self.getAttributeById(JiraAttributeID.USER_ATTR_ID)
        if not attr_obj:
            return ""

        attr = attr_obj.model_dump()

        values = attr.get("objectAttributeValues") or []
        first = values[0] if values else {}

        avatarUrl = first.get("user", {}).get("avatarUrl")

        return avatarUrl

    @computed_field
    @property
    def jiraUserName(self) -> str:
        attr_obj = self.getAttributeById(JiraAttributeID.USER_ATTR_ID)
        if not attr_obj:
            return ""

        attr = attr_obj.model_dump()

        values = attr.get("objectAttributeValues") or []
        first = values[0] if values else {}

        name = first.get("user", {}).get("name")

        return name

    @computed_field
    @property
    def phone(self) -> str:
        r = ""
        if "Phone number" in self.details:
            return self.details["Phone number"]
        return r

    @computed_field
    @property
    def telegram(self) -> str:
        r = ""
        if "Telegram" in self.details:
            return self.details["Telegram"]
        return r

    @computed_field
    @property
    def head(self) -> list[User]:
        head_ref = self.getAttributeById(JiraAttributeID.USER_HEAD_OF)
        if not head_ref:
            return []

        usernames = [
            u.displayValue
            for u in head_ref.objectAttributeValues
            if u.displayValue and u.displayValue != self.name
        ]

        unique_usernames = list(dict.fromkeys(usernames))

        # вызываем get_user
        head_users = [get_user(username) for username in unique_usernames]

        return head_users


    @computed_field
    @property
    def details(self) -> dict[str, str]:
        attr_obj = self.getAttributeById(JiraAttributeID.USER_DETAILS)
        if not attr_obj:
            return {}

        attr = attr_obj.model_dump()

        values = attr.get("objectAttributeValues") or []
        first = values[0] if values else {}

        details = first.get("value", "")

        return utils.parse_details(details)


    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
            "name": self.name,
            "selfUrl": self.selfUrl,
            "created": self.created,
            "updated": self.updated,
            "jiraProfile": f"{jira_url}/secure/ViewProfile.jspa?name={self.jiraUserName}",
            "avatar":  "data:image/png;base64," + utils.file_to_base64(utils.download_image(self.jiraUserAvatar)),
            "phone": self.phone,
            "telegram": self.telegram,
            "head": self.head
        }
    pass

class SanRackSwitch(PhysicalInfrastructureNode):
    # assetId = {
    #     "location": JiraAttributeID.HW_LOCATION,
    #     "networkInterface": JiraAttributeID.NETWORK_INTERFACE,
    #     "owner": JiraAttributeID.HOST_OWNER,
    #     "team": JiraAttributeID.HOST_TEAM,
    #     #"serial": JiraAttributeID.HW_SERIAL,
    #     "model": JiraAttributeID.HOST_MODEL,
    #     #"startUnit": JiraAttributeID.HW_START_UNIT,
    #     #"size": JiraAttributeID.HW_UNIT_SIZE,
    #     "rackId" : JiraAttributeID.HW_RACK
    # }
    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
            "name": self.get_attr_value("Name") or self.label,
            "created": self.created,
            "updated": self.updated,
            "location": self.location,
            "networkInterface": self.networkInterface,
            "team": self.team,
            "owner": self.owner,
            "rackId": self.rackId,
            "model": self.model,
            "serial": self.serial,
            "selfUrl": self.selfUrl,
        }

class Firewall(PhysicalInfrastructureNode):
    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
            "name": self.get_attr_value("Name") or self.label,
            "created": self.created,
            "updated": self.updated,
            "location": self.location,
            "networkInterface": self.networkInterface,
            "team": self.team,
            "owner": self.owner,
            "rackId": self.rackId,
            "model": self.model,
            "serial": self.serial,
            "selfUrl": self.selfUrl,
        }

class NAS(PhysicalInfrastructureNode):
    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
            "name": self.get_attr_value("Name") or self.label,
            "created": self.created,
            "updated": self.updated,
            "location": self.location,
            "networkInterface": self.networkInterface,
            "team": self.team,
            "owner": self.owner,
            "rackId": self.rackId,
            "model": self.model,
            "serial": self.serial,
            "selfUrl": self.selfUrl,
        }


# utils
def _cache_path(key: str) -> str:
    h = hashlib.sha256(key.encode()).hexdigest()
    return os.path.join(CACHE_DIR, f"{h}.json")


def safe_object_query(q):
    logger.info(q)

    cache_file = _cache_path(q)

    if os.path.exists(cache_file):
        age = time.time() - os.path.getmtime(cache_file)
        if age < CACHE_TTL:
            logger.debug("Cache hit")
            with open(cache_file, "r", encoding="utf-8") as f:
                return json.load(f)

    result = utils.execute_aql_query(q)
    if not result:
        return None

    entries = result.get("objectEntries")
    if not entries:
        return None

    first = entries[0]

    try:
        with open(cache_file, "w", encoding="utf-8") as f:
            json.dump(first, f, ensure_ascii=False)
    except Exception as e:
        logger.warning(f"Cache write failed: {e}")

    return first

def get_team(team_name : str) -> DataCenter|None:
    logger.info(f"{team_name}")

    r = safe_object_query(f'objectSchemaId IN "{cmdb_id}" AND objectType = "Team" AND Name = "{team_name}"')

    if r:
        return Team.model_validate(r)
    return None

def get_user(user_name : str) -> DataCenter|None:
    logger.info(f"{user_name}")

    r = safe_object_query(f'objectSchemaId IN "{cmdb_id}" AND objectType = "User" AND Name = "{user_name}"')

    if r:
        return User.model_validate(r)
    return None

def get_dc(dc_name : str) -> DataCenter | None:
    logger.info(f"{dc_name}")
    r = safe_object_query(f'objectSchemaId IN "{cmdb_id}" AND objectType = "DataCenter" AND Name = "{dc_name}"')
    if r:
        return DataCenter.model_validate(r)
    return None

def get_host(host_name : str) -> Host | None:
    logging.info(f"{host_name}")
    r = safe_object_query(f'objectSchemaId IN "{cmdb_id}" AND objectType = "Host" AND Name = "{host_name}"')
    if (r):
        return Host.model_validate(r)
    return None

def get_san_rack_switch(switch_name : str) -> Host | None:
    logging.info(f"{switch_name}")
    r = safe_object_query(f'objectSchemaId IN "{cmdb_id}" AND objectType = "{JiraTypes.SAN_RACK_SWITCH}" AND Name = "{switch_name}"')
    if (r):
        return SanRackSwitch.model_validate(r)
    return None

def get_firewall(firewall_name : str) -> Host | None:
    logging.info(f"{firewall_name}")
    r = safe_object_query(f'objectSchemaId IN "{cmdb_id}" AND objectType = "{JiraTypes.FIREWALL}" AND Name = "{firewall_name}"')
    if (r):
        return Firewall.model_validate(r)
    return None

def get_nas(nas_name : str) -> Host | None:
    logging.info(f"{nas_name}")
    r = safe_object_query(f'objectSchemaId IN "{cmdb_id}" AND objectType = "{JiraTypes.NAS}" AND Name = "{nas_name}"')
    if (r):
        return NAS.model_validate(r)
    return None
