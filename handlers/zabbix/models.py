# models.py  (Pydantic v2)
from __future__ import annotations

import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Type, Sequence, ClassVar

import pyzabbix
from pydantic import BaseModel, Field, computed_field, model_serializer

import re
import humanize

import logging
from kando_icon import generate_kando_icon

logger = logging.getLogger(__name__)

def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _availability_state(v: Optional[str]) -> Optional[str]:
    # Zabbix: 0 unknown, 1 available, 2 unavailable
    if v is None:
        return None
    m = {"0": "unknown", "1": "available", "2": "unavailable"}
    return m.get(str(v), str(v))


class ZbxInterface(BaseModel):
    interfaceid: Optional[str] = None
    type: Optional[str] = None
    main: Optional[str] = None
    useip: Optional[str] = None
    ip: Optional[str] = None
    dns: Optional[str] = None
    port: Optional[str] = None


class ZbxGroup(BaseModel):
    groupid: Optional[str] = None
    name: Optional[str] = None


class ZbxTemplate(BaseModel):
    templateid: Optional[str] = None
    name: Optional[str] = None


class ZbxTag(BaseModel):
    tag: Optional[str] = None
    value: Optional[str] = None


class ZbxAvailability(BaseModel):
    agent: Optional[str] = None
    snmp: Optional[str] = None
    ipmi: Optional[str] = None
    jmx: Optional[str] = None
    error_agent: Optional[str] = None
    error_snmp: Optional[str] = None
    error_ipmi: Optional[str] = None
    error_jmx: Optional[str] = None


class ZbxItem(BaseModel):
    itemid: str
    hostid: Optional[str] = None
    name: Optional[str] = None
    key_: Optional[str] = None
    type: Optional[str] = None
    value_type: Optional[str] = None
    status: Optional[str] = None
    state: Optional[str] = None
    lastvalue: Optional[str] = None
    lastclock: Optional[str] = None
    delay: Optional[str] = None
    units: Optional[str] = None
    description: Optional[str] = None
    error: Optional[str] = None

    @computed_field
    @property
    def serialize(self) -> Dict:
        return {
            "name": self.name,
            "itemid": self.itemid,
            "state": self.state,
            "status": self.status,
            "lastvalue": self.lastvalue,
            "key": self.key_,
            "description": self.description
        }

class ZbxHost(BaseModel):
    hostname: str
    fetched_at: str = Field(default_factory=_utc_now_iso)

    hostid: str
    host: Optional[str] = None
    name: Optional[str] = None
    status: Optional[str] = None  # 0 enabled, 1 disabled

    interfaces: List[ZbxInterface] = Field(default_factory=list)
    groups: List[ZbxGroup] = Field(default_factory=list)
    templates: List[ZbxTemplate] = Field(default_factory=list)
    tags: List[ZbxTag] = Field(default_factory=list)
    inventory: Optional[Dict[str, Any]] = None

    availability: Optional[ZbxAvailability] = None
    items: List[ZbxItem] = Field(default_factory=list)


    _registry: ClassVar[list[type["ZbxHost"]]] = []


    @classmethod
    def get_type(cls) -> str:
        return cls.__name__

    @classmethod
    def register(cls, subclass: Type["ZbxHost"]):
        cls._registry.append(subclass)
        return subclass

    @classmethod
    def classify(cls, host: "ZbxHost") -> "ZbxHost":
        for subclass in cls._registry:
            if subclass.matches(host):
                return subclass(**host.model_dump())
        return host  # fallback

    @computed_field
    @property
    def enabled(self) -> Optional[bool]:
        if self.status is None:
            return None
        return str(self.status) == "0"

    @computed_field
    @property
    def has_interfaces(self) -> bool:
        return len(self.interfaces) > 0

    @computed_field
    @property
    def has_ip_or_dns(self) -> bool:
        return any(((i.ip or "").strip() or (i.dns or "").strip()) for i in self.interfaces)

    @computed_field
    @property
    def agent_available(self) -> Optional[bool]:
        if not self.availability or self.availability.agent is None:
            return None
        return self.availability.agent == "available"

    @computed_field
    @property
    def total_items(self) -> int:
        return len(self.items)

    @computed_field
    @property
    def disabled_items(self) -> int:
        return sum(1 for it in self.items if str(it.status) == "1")

    @computed_field
    @property
    def unsupported_items(self) -> int:
        return sum(1 for it in self.items if str(it.state) == "1")

    def getTagValueByName(self, tag_name: str) -> Optional[str]:
        if not tag_name:
            return None

        for tag in self.tags:
            if tag.tag == tag_name:
                return tag.value

        return None

    def getItemValueByName(self, item_name: str) -> Optional[str]:
        if not item_name:
            return None

        for item in self.items:
            if item.name == item_name:
                return item.lastvalue

        return None

    def getItemByName(self, item_name: str) -> Optional[ZbxItem|None]:
        if not item_name:
            return None

        for item in self.items:
            if item.name == item_name:
                return item

        return None

    def getItemByKey(self, key_name: str) -> Optional[ZbxItem|None]:
        if not key_name:
            return None

        for item in self.items:
            if item.key_ == key_name:
                return item

        return None

    def getSerializedItemByKey(self, key_name: str) -> Dict|None:
        r = self.getItemByKey(key_name)
        if not r:
            return None

        return r.serialize | { "graphName": "", "graphId": "" }

    def getSerializedItemByName(self, item_name: str) -> Dict|None:
        r = self.getItemByName(item_name)
        if not r:
            return None

        return r.serialize

    def itemStub(self, lastvalue: str) -> Dict|None:
        return {
            "name": "",
            "itemid": "",
            "state": "0",
            "status": "0",
            "lastvalue": str(lastvalue),
            "key": "",
            "description": "",
            "graphName": "",
            "graphId": ""
        }


    def resourceUtilization(self, resourceName) -> str|None:
        r = self.getItemValueByName(resourceName),

        if (r):
            return f"{float(r[0]):.2f}%"

        return None

@ZbxHost.register
class ZbxHostFirewall(ZbxHost):
    @staticmethod
    def matches(host: ZbxHost) -> bool:
        model = (host.inventory or {}).get("model", "")
        return model.lower().startswith("forti")

    @computed_field
    @property
    def cores(self) -> int:
        cores = 0
        for item in self.items:
            if item.name.startswith("CPU Usage ["):
                cores = cores + 1
        return cores

    def getCores(self) -> Dict:
        return self.itemStub(self.cores)


    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
            "name": self.hostname,
            "url": os.getenv("ZABBIX_URL", "") + f"/zabbix.php?action=charts.view&filter_hostids%5B0%5D={self.hostid}",
            "hostname": self.itemStub(self.hostname),
            "arch": self.itemStub("x86"),
            "uname": self.getSerializedItemByKey("fortinetSystemModel"),
            "uptime": zabbixItemUptime(self.getSerializedItemByKey("fortinetUpTime")),
            "cpu": {
                "utilization": self.getSerializedItemByKey("fortinetCurrentCPUUtil") | {"graphId": get_graph_id_by_itemid(self.getSerializedItemByKey("fortinetCurrentCPUUtil")["itemid"]) },

                "cores": self.getCores()
            },
            "swap": {
                "free": self.itemStub("0"),
                "size": self.itemStub("0"),
            },
            "memory": {
                "total": self.itemStub("0"),
                "used": self.itemStub("0"),
                "util": self.getSerializedItemByKey("fortinetCurrentRAMUtil") | {"graphId": get_graph_id_by_itemid(self.getSerializedItemByKey("fortinetCurrentRAMUtil")["itemid"]) },
            },
            "networkInterface": [],
            "disk": [],
            "fs": [],
            "container": [],
            "postgres": []
        }



@ZbxHost.register
class ZbxHostWindows(ZbxHost):
    @staticmethod
    def matches(host: ZbxHost) -> bool:
        return host.getTagValueByName("OS") == "Windows"

    def getNetworkInterface(self) -> List:
        interfaces = []
        for item in self.items:
            if item.key_.startswith("net.if.type["):
                interfaceId = re.search(r'\["({[^"]+})"\]', item.key_)
                if interfaceId:
                    interfaceId = interfaceId.group(1)

                interfaceName = re.search(r"^.*\((.*?)\):", item.name)
                if interfaceName:
                    interfaceName = interfaceName.group(1)

                prefix = re.search(r"(^.*):", item.name)
                if prefix:
                    prefix = prefix.group(1)

                if interfaceName and interfaceId and prefix:
                    interfaces.append({
                        "name": interfaceName,
                        "id": interfaceId,
                        "graphName": f"{prefix}: Network traffic"
                    })

        return interfaces


    def getDisk(self) -> List:
        disk = []
        for item in self.items:
            if item.name.endswith("Disk read rate"):
                diskId = re.search(r'^[0-9]? ?([0-9]+?): Disk read rate', item.name)
                if diskId:
                    diskId = diskId.group(1)
                    disk.append({
                        "name": diskId
                    })


        return disk

    def getFilesystem(self) -> List:
        fs = []
        for item in self.items:
            if item.name.endswith("Space utilization"):
                fsName = re.search(r'^Windows\(([^\)]+)\): Space utilization', item.name)
                if fsName:
                    fsName = fsName.group(1)
                    util = f"{float(item.lastvalue):.2f}%"
                    fs.append({
                        "name": fsName,
                        "util": util,
                        "icon": generate_kando_icon(util),
                        "graphName": f"Windows({fsName}): Disk space usage"
                    })
        return fs

    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
            "name": self.hostname,
            "url": os.getenv("ZABBIX_URL", "") + f"/zabbix.php?action=host.dashboard.view&hostid={self.hostid}",
            "hostname": self.getSerializedItemByKey("system.hostname"),
            "arch": self.getSerializedItemByKey("system.sw.arch"),
            "uname": self.getSerializedItemByKey("system.uname"),
            "uptime": zabbixItemUptime(self.getSerializedItemByKey("system.uptime")),
            "cpu": {
                "utilization": self.getSerializedItemByKey("system.cpu.util"),
                "cores": self.getSerializedItemByName("Number of cores")
            },
            "swap": {
                "free": self.getSerializedItemByKey("system.swap.free"),
                "size": self.getSerializedItemByKey("system.swap.size[,total]")
            },
            "memory": {
                "total": self.getSerializedItemByKey("vm.memory.size[total]"),
                #"used": self.getSerializedItemByKey("vm.memory.size[used]"),
                "util": self.getSerializedItemByKey("vm.memory.util"),
            },
            "networkInterface": self.getNetworkInterface(),
            "disk": self.getDisk(),
            "fs": self.getFilesystem(),
            "container": [],
            "postgres": [],
        }

@ZbxHost.register
class ZbxHostLinux(ZbxHost):

    @computed_field
    @property
    def memory_util(self) -> str|None:
        return self.resourceUtilization("Memory utilization")

    @computed_field
    @property
    def cpu_util(self) -> str|None:
        return self.resourceUtilization("CPU utilization")

    @staticmethod
    def matches(host: ZbxHost) -> bool:
        return host.getTagValueByName("OS") == "Linux"

    def getNetworkInterface(self) -> List:
        interfaces = []
        for item in self.items:
            if item.name.endswith("Interface type"):
                interfaceName = re.search(r"Interface ([^ ]+): Interface type", item.name)
                if interfaceName:
                    interfaceName = interfaceName.group(1)
                    interfaceId = interfaceName
                    graphName = f"Interface {interfaceName}: Network traffic"
                    interfaces.append({
                        "name": interfaceName,
                        "id": interfaceId,
                        "graphName": graphName
                    })

        return interfaces

    def getDisk(self) -> List:
        disk = []
        for item in self.items:
            if item.name.endswith("Disk read rate"):
                diskId = re.search(r'^([^:]+): Disk read rate', item.name)
                if diskId:
                    diskId = diskId.group(1)
                    disk.append({
                        "name": diskId
                    })
        return disk

    def getFilesystem(self) -> List:
        fs = []
        for item in self.items:
            if item.name.endswith("Free disk space in %"):
                fsName = re.search(r'^(/[^:]+): Free disk space in %', item.name)
                if fsName:
                    fsName = fsName.group(1)
                    util = f"{100-float(item.lastvalue):.2f}%"
                    fs.append({
                        "name": fsName,
                        "util": util,
                        "icon": generate_kando_icon(util),
                        "graphName": f"{fsName}: Disk space usage",
                    })
        return fs

    def getContainer(self) -> List:
        container = []
        for item in self.items:
            if item.name.startswith("Container /"):
                containerName = re.search(r'Container /(.*): Get info', item.name)
                if containerName:
                    containerName = containerName.group(1)
                else:
                    continue
                memory = self.getItemValueByName(f"Container /{containerName}: Memory usage")
                status = self.getItemValueByName(f"Container /{containerName}: Status")
                cpu = self.getItemValueByName(f"Container /{containerName}: CPU percent usage")

                if containerName:
                    container.append({
                        "name": containerName,
                        "cpu": f"{float(cpu):.2f}%",
                        "mem": str(int(int(memory)/1024/1024)) + "MB",
                        "status": status
                    })
        return container

    def getPostgresDatabase(self) -> Dict:
        postgres = {
            "database": [],
            "replication": None
        }
        for item in self.items:
            if item.name.endswith("Backends connected"):
                dbName = re.search(r'^DB (.*): Backends connected', item.name)
                if dbName:
                    dbName = dbName.group(1)
                else:
                    continue
                dbSize = self.getItemValueByName(f"DB [{dbName}]: Database size")
                postgres["database"].append({
                    "name": dbName,
                    "size": humanize.naturalsize(dbSize, binary=True)
                })
        replication = self.getItemValueByName("Replication: Master IP")
        if replication and replication != "empty":
            postgres["replication"] = replication

        return postgres

    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
             "name": self.hostname,
             "url": os.getenv("ZABBIX_URL", "") + f"/zabbix.php?action=host.dashboard.view&hostid={self.hostid}",
             "hostname": self.getSerializedItemByKey("system.hostname"),
             "arch": self.getSerializedItemByKey("system.sw.arch"),
             "uname": self.getSerializedItemByKey("system.uname"),
             "uptime": zabbixItemUptime(self.getSerializedItemByKey("system.uptime")),
             "cpu": {
                 "utilization": self.getSerializedItemByKey("system.cpu.util"),
                 "cores": self.getSerializedItemByKey("system.cpu.num"),
             },
             "swap": {
                 "free": self.getSerializedItemByKey("system.swap.size[,free]"),
                 "size": self.getSerializedItemByKey("system.swap.size[,total]")
             },
             "memory": {
                 "total": self.getSerializedItemByKey("vm.memory.size[total]"),
                 #"used": self.getSerializedItemByKey("vm.memory.size[used]"), # for linux, used doesn't exist!
                 "util": self.getSerializedItemByKey("vm.memory.utilization"),
             },
             "networkInterface": self.getNetworkInterface(),
             "disk": self.getDisk(),
             "fs": self.getFilesystem(),
             "container": self.getContainer(),
             "postgres": self.getPostgresDatabase()
        }


def _get_zapi() -> pyzabbix.ZabbixAPI:
    url = os.getenv("ZABBIX_URL", "")
    api_token = os.getenv("ZABBIX_TOKEN", "")
    if not url:
        raise RuntimeError("ZABBIX_URL is empty")
    if not api_token:
        raise RuntimeError("ZABBIX_TOKEN is empty")
    zapi = pyzabbix.ZabbixAPI(url)
    zapi.auth = api_token
    return zapi

def get_graph_id_by_itemid(item_id: str) -> str:
    zapi = _get_zapi()
    return zapi.graph.get(itemids=[item_id], output=["graphid"])[0]["graphid"]


def get_hosts(hostnames: Sequence[str]) -> List[ZbxHost]:
    names = [h.strip() for h in hostnames if h and h.strip()]
    if not names:
        return []

    seen = set()
    ordered_names: List[str] = []
    for n in names:
        if n not in seen:
            seen.add(n)
            ordered_names.append(n.upper())
            ordered_names.append(n.lower())

    logger.info(ordered_names)

    zapi = _get_zapi()

    hosts_raw = zapi.host.get(
        search={"host": ordered_names},
        #search={"host": ["1FTG-GW04", "4lbdmz-anyfront01"]},
        searchByAny = True,
        #startSearch=True,
        output="extend",
        #searchWildcardsEnabled=False,
        selectInterfaces="extend",
        selectGroups="extend",
        selectParentTemplates="extend",
        selectTags="extend",
        selectInventory="extend",
    ) or []

    if not hosts_raw:
        return []

    # map host -> raw
    by_host: Dict[str, Dict[str, Any]] = {h.get("host"): h for h in hosts_raw if h.get("host")}

    hostids = [h.get("hostid") for h in hosts_raw if h.get("hostid")]
    if not hostids:
        return []

    items_raw = zapi.item.get(hostids=hostids, output="extend") or []

    items_by_hostid: Dict[str, List[ZbxItem]] = {}
    for it in items_raw:
        hid = it.get("hostid")
        iid = it.get("itemid")
        if not hid or not iid:
            continue
        items_by_hostid.setdefault(hid, []).append(ZbxItem(**it))

    result: List[ZbxHost] = []
    for hn in ordered_names:
        raw = by_host.get(hn)
        if not raw:
            continue

        hid = raw.get("hostid")
        if not hid:
            continue

        availability = ZbxAvailability(
            agent=_availability_state(raw.get("available")),
            snmp=_availability_state(raw.get("snmp_available")),
            ipmi=_availability_state(raw.get("ipmi_available")),
            jmx=_availability_state(raw.get("jmx_available")),
            error_agent=raw.get("error") or None,
            error_snmp=raw.get("snmp_error") or None,
            error_ipmi=raw.get("ipmi_error") or None,
            error_jmx=raw.get("jmx_error") or None,
        )

        result.append(
            ZbxHost(
                hostname=hn,
                hostid=hid,
                host=raw.get("host"),
                name=raw.get("name"),
                status=raw.get("status"),
                interfaces=[ZbxInterface(**x) for x in (raw.get("interfaces") or [])],
                groups=[ZbxGroup(**x) for x in (raw.get("groups") or [])],
                templates=[ZbxTemplate(**x) for x in (raw.get("parentTemplates") or [])],
                tags=[ZbxTag(**x) for x in (raw.get("tags") or [])],
                inventory=raw.get("inventory"),
                availability=availability,
                items=items_by_hostid.get(hid, []),
            )
        )

    typed_hosts = [ZbxHost.classify(h) for h in result]
    #pprint.pprint(typed_hosts)

    return typed_hosts


def get_host(hostname: str) -> Optional[ZbxHostLinux]:
    hosts = get_hosts([hostname])
    return hosts[0] if hosts else None

def zabbixItemUptime(d : Dict):
    return d | { "lastvalue" : seconds_to_uptime(d["lastvalue"]) }
    return d

def seconds_to_uptime(seconds: int) -> str:
    seconds = int(seconds)

    days = seconds // 86400
    seconds %= 86400

    hours = seconds // 3600
    seconds %= 3600

    minutes = seconds // 60
    seconds %= 60

    if days > 0:
        return f"{days}d {hours:02}:{minutes:02}:{seconds:02}"
    return f"{hours:02}:{minutes:02}:{seconds:02}"
