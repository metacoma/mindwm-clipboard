#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from typing import Any, Dict, List

import yaml


# =========================
# CONFIG (env overridable)
# =========================

EWW_BIN = os.environ.get("EWW_BIN", os.path.expanduser("~/.local/bin/eww"))
EWW_VAR = os.environ.get("EWW_VAR", "items")

#MENUS_FILE = os.environ.get("CHECKSUM_FILE")
MENUS_FILE = os.environ.get("TMP_INPUT")

PATH_VALUE = os.environ.get("EWW_BUTTON_PATH", "/tmp/abc.json")
SKIP_ROOT_NAME = os.environ.get("EWW_SKIP_ROOT", "root")
LIMIT = int(os.environ.get("EWW_LIMIT", "25"))

DRY_RUN = os.environ.get("EWW_DRY_RUN") == "1"
PRESERVE_YAML_ORDER = os.environ.get("EWW_PRESERVE_YAML_ORDER") == "1"


# =========================
# UTILS
# =========================

def run(cmd: List[str]) -> str:
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode != 0:
        raise RuntimeError(f"{' '.join(cmd)}\n{p.stderr.strip()}")
    return p.stdout


def parse_items(raw: str) -> List[Dict[str, Any]]:
    s = raw.strip()
    if not s:
        return []

    try:
        val = json.loads(s)
    except json.JSONDecodeError:
        # sometimes: json string containing json
        val = json.loads(json.loads(s))

    if isinstance(val, str):
        val = json.loads(val)

    if not isinstance(val, list):
        raise TypeError("items must be JSON array")
    for x in val:
        if not isinstance(x, dict):
            raise TypeError("items must contain objects")

    return val


# =========================
# YAML
# =========================

def read_yaml() -> Dict[str, Any]:
    # stdin wins (pipe / redirect)
    if not sys.stdin.isatty():
        data = sys.stdin.read()
        if data.strip():
            return yaml.safe_load(data) or {}

    return {}


def title_from_id(id_value: str) -> str:
    parts = id_value.split()
    return parts[1] if len(parts) > 1 else id_value


def extract_buttons(doc: Dict[str, Any]) -> List[Dict[str, str]]:
    out: List[Dict[str, str]] = []
    for m in doc.get("menus", []):
        root = (m or {}).get("root") or {}
        name = root.get("name")
        icon = root.get("icon")

        if not name or not icon:
            continue

        name = str(name)
        if name == SKIP_ROOT_NAME:
            continue

        out.append(
            {
                "Id": name,
                "Title": title_from_id(name),
                "Icon": str(icon),
                "Command": f"cp {MENUS_FILE} ~/.config/kando/menus.json && kando -m '{name}'",
                "Path": PATH_VALUE,
            }
        )
    return out


# =========================
# DEDUPE
# =========================

def dedupe_by_id(items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Keep first occurrence of each Id, drop later ones.
    Because we prepend new items, new wins and old duplicates are removed.
    """
    seen = set()
    out: List[Dict[str, Any]] = []
    for item in items:
        item_id = item.get("Id")
        if item_id is None:
            # if somehow no Id, keep it (or skip—your call)
            out.append(item)
            continue
        if item_id in seen:
            continue
        seen.add(item_id)
        out.append(item)
    return out


# =========================
# EWW UPDATE
# =========================

def update_items(new_items: List[Dict[str, Any]]) -> str:
    try:
        raw = run([EWW_BIN, "get", EWW_VAR])
    except Exception:
        raw = "[]"

    items = parse_items(raw)

    # prepend new → dedupe by Id → limit
    merged = list(new_items) + items
    merged = dedupe_by_id(merged)
    merged = merged[:LIMIT]

    payload = json.dumps(merged, ensure_ascii=False, separators=(",", ":"))

    if not DRY_RUN:
        run([EWW_BIN, "update", f"{EWW_VAR}={payload}"])

    return payload


# =========================
# MAIN
# =========================

def main() -> None:
    doc = read_yaml()
    buttons = extract_buttons(doc)

    # choose order of inserted block
    if not PRESERVE_YAML_ORDER:
        buttons = buttons[::-1]

    payload = update_items(buttons)

    if DRY_RUN:
        print(payload)
    else:
        print(f"✅ updated EWW: {len(buttons)} buttons (limit={LIMIT})")


if __name__ == "__main__":
    main()
