import requests
import json
import re
import argparse
import os
import sys
import utils
from dotenv import load_dotenv
from colorama import Fore, Style
import pprint
from model import ObjectEntry,JiraTypes,DataCenter,Host,User,SanRackSwitch,Firewall,NAS,LanRouter,LanRackSwitch,VHost,Database
import yaml
from collections import defaultdict

import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s:%(funcName)s: %(message)s",
    stream=sys.stderr,
)

load_dotenv()
cmdb_id = os.getenv('asset_zabbix_6')

def is_ip_address(input_string):
    ip_pattern = r'^(\d{1,3}\.){1,3}\d{0,3}$'
    return bool(re.match(ip_pattern, input_string))


if __name__ == "__main__":
    patterns = sys.argv[1:]

    if not patterns:
        print("No search patterns provided")
        sys.exit(1)

    conditions = []

    for arg in sys.argv[1:]:
        if is_ip_address(arg):
            conditions.append(
                f'object having outR(objectType IN ("Network Interface", "VIP IP") AND Name = "{arg}")'
            )
        else:
            conditions.append(
                f'Name = "{arg}"'
            )

        aql_query = (
            f'objectSchemaId IN "{cmdb_id}" AND ('
            + " OR ".join(conditions)
            + ")"
        )
# type -> (PydanticModel, output_key)
    TYPE_MAP = {
        JiraTypes.DATACENTER: (DataCenter, "cmdb.dc"),
        JiraTypes.HOST: (Host, "cmdb.host"),
        JiraTypes.TEAM: (User, "cmdb.team"),
        JiraTypes.USER: (User, "cmdb.user"),
        JiraTypes.SAN_RACK_SWITCH: (SanRackSwitch, "cmdb.san_rack_switch"),
        JiraTypes.FIREWALL: (Firewall, "cmdb.firewall"),
        JiraTypes.NAS: (NAS, "cmdb.nas"),
        JiraTypes.LAN_ROUTER: (LanRouter, "cmdb.lan_router"),
        JiraTypes.LAN_RACK_SWITCH: (LanRackSwitch, "cmdb.lan_rack_switch"),
        JiraTypes.VHOST: (VHost, "cmdb.vhost"),
        JiraTypes.DATABASE: (Database, "cmdb.database"),
    }

    all_results = utils.execute_aql_query(aql_query)
    objects = [ObjectEntry.model_validate(o) for o in all_results["objectEntries"]]

    grouped = defaultdict(list)  # output_key -> list[BaseModel]

    for obj in objects:
        t = obj.get_type()
        spec = TYPE_MAP.get(t)
        if not spec:
            continue

        Model, out_key = spec
        grouped[out_key].append(Model.model_validate(obj.model_dump(by_alias=True)))

    for out_key, items in grouped.items():
        output = {out_key: [m.model_dump(mode="json") for m in items]}
        print(yaml.safe_dump(output, allow_unicode=True, sort_keys=False))
