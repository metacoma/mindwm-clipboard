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
from model import ObjectEntry,JiraTypes,DataCenter,Host,User,SanRackSwitch,Firewall
import yaml

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
    output = ""
    hosts = []
    datacenters = []
    users = []
    san_rack_switch = []
    firewall = []

    all_results = utils.execute_aql_query(aql_query)
    objects = [ObjectEntry.model_validate(o) for o in all_results["objectEntries"]]

    for obj in objects:
        if obj.get_type() == "DataCenter":
            dc = DataCenter.model_validate(obj.model_dump(by_alias=True))
            datacenters.append(dc)

        if obj.get_type() == "Host":
            host = Host.model_validate(obj.model_dump(by_alias=True))
            hosts.append(host)

        if obj.get_type() == "User":
            user = User.model_validate(obj.model_dump(by_alias=True))
            users.append(user)

        if obj.get_type() == JiraTypes.SAN_RACK_SWITCH:
            switch = SanRackSwitch.model_validate(obj.model_dump(by_alias=True))
            san_rack_switch.append(switch)

        if obj.get_type() == JiraTypes.FIREWALL:
            switch = Firewall.model_validate(obj.model_dump(by_alias=True))
            firewall.append(switch)


    if datacenters:
        output = {"cmdb.dc": [dc.model_dump(mode="json") for dc in datacenters]}
        print(yaml.safe_dump(output, allow_unicode=True, sort_keys=False))

    if hosts:
        output = {"cmdb.host": [host.model_dump(mode="json") for host in hosts]}
        print(yaml.safe_dump(output, allow_unicode=True, sort_keys=False))

    if users:
        output = {"cmdb.user": [user.model_dump(mode="json") for user in users]}
        print(yaml.safe_dump(output, allow_unicode=True, sort_keys=False))

    if san_rack_switch:
        output = {"cmdb.san_rack_switch": [switch.model_dump(mode="json") for switch in san_rack_switch]}
        print(yaml.safe_dump(output, allow_unicode=True, sort_keys=False))

    if firewall:
        output = {"cmdb.firewall": [switch.model_dump(mode="json") for switch in firewall]}
        print(yaml.safe_dump(output, allow_unicode=True, sort_keys=False))



    #print(all_results)
