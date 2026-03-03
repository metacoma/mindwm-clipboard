#!/usr/bin/env python3
import os
import sys

import pprint

import requests

OUTFILE = os.environ.get("OUTFILE", "names.txt")

jira_url = os.getenv('JIRA_URL')
jira_pat = os.getenv('JIRA_TOKEN')
cmdb_id = os.getenv('CMDB_ID')

ASSETS_AQL_URL = jira_url

AQL = f'objectSchemaId IN "{cmdb_id}"'

def extract_name(obj: dict) -> str | None:
    for a in obj.get("attributes") or obj.get("objectAttributes") or []:
        ota = a.get("objectTypeAttribute") or {}
        if ota.get("name") == "Name":
            vals = a.get("objectAttributeValues") or []
            if vals:
                v = vals[0].get("value")
                if v is not None:
                    return str(v)
    return obj.get("label")

page = 1

api_endpoint = f"{jira_url}/rest/assets/1.0/aql/objects"
headers = {
    "Authorization": f"Bearer {jira_pat}",
    "Content-Type": "application/json",
    "Accept": "application/json"
}

with open(OUTFILE, "w", encoding="utf-8") as f:
    while True:

        query = {
            "qlQuery": AQL,
            "resultPerPage": "200",
            "includeAttributes": "true",
            "includeAttributesDeep": "1",
            "includeTypeAttributes": "false"
        }
        query["page"] = str(page)

        r = requests.get(
            api_endpoint,
            params=query,
            headers=headers
        )
        r.raise_for_status()
        pprint.pprint(r)
        data = r.json()

        entries = data.get("objectEntries") or data.get("values") or data.get("objects") or []
        if not entries:
            break

        for obj in entries:
            name = extract_name(obj)
            if name:
                f.write(name + "\n")

        is_last = data.get("isLast")
        if is_last is True:
            break

        page += 1

print(f"Saved to {OUTFILE}")
