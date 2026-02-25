# models.py  (Pydantic v2)
from __future__ import annotations

import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Type, Sequence, ClassVar

import pyzabbix
from pydantic import BaseModel, Field, computed_field, model_serializer


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
    key_: Optional[str] = None  # Zabbix поле называется key_
    type: Optional[str] = None
    value_type: Optional[str] = None
    status: Optional[str] = None  # 0 enabled, 1 disabled
    state: Optional[str] = None   # 0 normal, 1 not supported
    lastvalue: Optional[str] = None
    lastclock: Optional[str] = None
    delay: Optional[str] = None
    units: Optional[str] = None
    description: Optional[str] = None
    error: Optional[str] = None


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

@ZbxHost.register
class ZbxHostFirewall(ZbxHost):
    @staticmethod
    def matches(host: ZbxHost) -> bool:
        model = (host.inventory or {}).get("model", "")
        return model.lower().startswith("forti")

    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)

        return {
            "name": self.hostname,
            "url": os.getenv("ZABBIX_URL", "") + f"/zabbix.php?action=host.dashboard.view&hostid={self.hostid}",
        }


@ZbxHost.register
class ZbxHostWindows(ZbxHost):
    @staticmethod
    def matches(host: ZbxHost) -> bool:
        return host.getTagValueByName("OS") == "Windows"

    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)
        return {
            "name": self.hostname,
            "url": os.getenv("ZABBIX_URL", "") + f"/zabbix.php?action=host.dashboard.view&hostid={self.hostid}",
        }

@ZbxHost.register
class ZbxHostLinux(ZbxHost):

    @staticmethod
    def matches(host: ZbxHost) -> bool:
        return host.getTagValueByName("OS") == "Linux"

    @model_serializer(mode="wrap")
    def _serialize(self, serializer):
        base: Dict[str, Any] = serializer(self)

        return {
            "name": self.hostname,
            "url": os.getenv("ZABBIX_URL", "") + f"/zabbix.php?action=host.dashboard.view&hostid={self.hostid}",
            "os":  {
                "short": self.inventory.get("os_short"),
                "full": self.inventory.get("os")
            },
            "memory": {
                "total": self.getItemValueByName("Total memory"),
                "util": self.getItemValueByName("Memory utilization"),
            },
            "cpu": {
                "number": self.getItemValueByName("Number of CPUs"),
                "util": self.getItemValueByName("CPU utilization"),
            },
            "load": {
                "1m": self.getItemValueByName("Load average (1m avg)"),
                "5m": self.getItemValueByName("Load average (5m avg)"),
                "15m": self.getItemValueByName("Load average (15m avg)")
            },
            "uptime": seconds_to_uptime(self.getItemValueByName("System uptime")),
            "arch": self.getItemValueByName("Operating system architecture"),
        }

def _get_zapi() -> pyzabbix.ZabbixAPI:
    url = os.getenv("ZABBIX_URL", "")
    auth = os.getenv("ZABBIX_AUTH", "")
    if not url:
        raise RuntimeError("ZABBIX_URL is empty")
    if not auth:
        raise RuntimeError("ZABBIX_AUTH is empty")
    zapi = pyzabbix.ZabbixAPI(url)
    zapi.auth = auth
    return zapi


def get_hosts(hostnames: Sequence[str]) -> List[ZbxHost]:
    names = [h.strip() for h in hostnames if h and h.strip()]
    if not names:
        return []

    seen = set()
    ordered_names: List[str] = []
    for n in names:
        if n not in seen:
            seen.add(n)
            ordered_names.append(n)

    zapi = _get_zapi()

    hosts_raw = zapi.host.get(
        filter={"host": ordered_names},
        output="extend",
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
