#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timedelta
from http.cookiejar import MozillaCookieJar
from pathlib import Path
from typing import Any, Dict
from urllib.parse import quote, urljoin
from zoneinfo import ZoneInfo

import requests


MOSCOW_TZ = ZoneInfo("Europe/Moscow")


def api_base(zabbix_url: str) -> str:
    return zabbix_url.rsplit("/api_jsonrpc.php", 1)[0]


def q(s: str) -> str:
    return quote(
        s,
        safe="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_.",
    )


def eprint(*args: object) -> None:
    print(*args, file=sys.stderr)


def jsonrpc(
    session: requests.Session,
    zabbix_url: str,
    token: str,
    method: str,
    params: Dict[str, Any],
    req_id: str = "1",
) -> Dict[str, Any]:
    payload = {"jsonrpc": "2.0", "method": method, "params": params, "id": req_id}
    r = session.post(
        zabbix_url,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}",
        },
        data=json.dumps(payload),
        timeout=60,
    )
    r.raise_for_status()
    data = r.json()
    if data.get("error"):
        raise RuntimeError(data["error"].get("message", "Zabbix API error"))
    return data


def ensure_login_cookie(
    session: requests.Session,
    zabbix_url: str,
    user: str,
    password: str,
    cookie_file: Path,
) -> None:
    cookie_file.parent.mkdir(parents=True, exist_ok=True)
    session.cookies = MozillaCookieJar(str(cookie_file))

    if cookie_file.exists():
        session.cookies.load(ignore_discard=True, ignore_expires=True)
        return

    login_url = urljoin(api_base(zabbix_url) + "/", "index.php")

    r = session.post(
        login_url,
        data={
            "name": user,
            "password": password,
            "autologin": "1",
            "enter": "Sign in",
        },
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        timeout=60,
    )
    r.raise_for_status()

    if not any(c.name == "zbx_session" for c in session.cookies):
        raise RuntimeError("Login failed: no zbx_session cookie")

    session.cookies.save(ignore_discard=True, ignore_expires=True)


def find_host_id(session, zabbix_url, token, hostname):
    data = jsonrpc(
        session,
        zabbix_url,
        token,
        "host.get",
        {"filter": {"host": hostname}, "output": ["hostid"]},
        "2",
    )
    result = data.get("result") or []
    if not result:
        raise RuntimeError("Host not found")
    return result[0]["hostid"]


def find_graph_id(session, zabbix_url, token, host_id, graph_name):
    data = jsonrpc(
        session,
        zabbix_url,
        token,
        "graph.get",
        {"hostids": [host_id], "output": ["graphid", "name"]},
        "3",
    )
    eprint(data.get("result"))
    for g in data.get("result", []):
        if g.get("name") == graph_name:
            return g.get("graphid")
    raise RuntimeError("Graph not found")


def download_graph_bytes(
    session,
    zabbix_url,
    user,
    password,
    cookie_file,
    graph_id,
    date_from,
    date_to,
    width,
    height,
):
    ensure_login_cookie(session, zabbix_url, user, password, cookie_file)

    chart_url = f"{api_base(zabbix_url)}/chart2.php"
    query = "&".join(
        [
            f"graphid={graph_id}",
            f"from={q(date_from)}",
            f"to={q(date_to)}",
            f"width={width}",
            f"height={height}",
            "profileIdx=web.graphs.filter",
        ]
    )

    r = session.get(f"{chart_url}?{query}", timeout=60)

    if "index.php" in str(r.url):
        cookie_file.unlink(missing_ok=True)
        ensure_login_cookie(session, zabbix_url, user, password, cookie_file)
        r = session.get(f"{chart_url}?{query}", timeout=60)

    r.raise_for_status()
    return r.content


def write_output(data: bytes, output_file: str):
    if output_file == "-":
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()
        return

    path = Path(output_file).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def get_env(name: str) -> str:
    v = os.getenv(name)
    if not v:
        raise RuntimeError(f"Missing env var {name}")
    return v.strip()


def fmt_dt(dt_obj: datetime) -> str:
    return dt_obj.strftime("%Y-%m-%d %H:%M:%S")


def build_parser():
    p = argparse.ArgumentParser(description="Download one Zabbix graph by name")
    p.add_argument("hostname")
    p.add_argument("graph_name")
    p.add_argument(
        "--from-date",
        dest="from_date",
        default=None,
        help='From date: "YYYY-MM-DD HH:MM:SS" (default: now-4h, Moscow TZ)',
    )
    p.add_argument(
        "--to-date",
        dest="to_date",
        default=None,
        help='To date: "YYYY-MM-DD HH:MM:SS" (default: now, Moscow TZ)',
    )
    p.add_argument(
        "--graphid",
        dest="graphid",
        default=None,
        help='graphid',
    )
    p.add_argument("-o", "--output-file", default="-")
    p.add_argument("--cookie-file", default="~/.cache/zabbix_cookies.txt")
    p.add_argument("--width", type=int, default=1200)
    p.add_argument("--height", type=int, default=600)
    return p


def main(argv):
    args = build_parser().parse_args(argv)

    now_moscow = datetime.now(MOSCOW_TZ)
    from_date = args.from_date or fmt_dt(now_moscow - timedelta(hours=4))
    to_date = args.to_date or fmt_dt(now_moscow)

    zabbix_url = get_env("ZABBIX_URL")
    token = get_env("ZABBIX_TOKEN")
    user = get_env("ZABBIX_USER")
    password = get_env("ZABBIX_PASSWORD")

    if "api_jsonrpc.php" not in zabbix_url:
        raise RuntimeError("ZABBIX_URL must contain api_jsonrpc.php")

    cookie_file = Path(args.cookie_file).expanduser()
    session = requests.Session()

    eprint("Resolving host...")
    host_id = find_host_id(session, zabbix_url, token, args.hostname)

    eprint("Resolving graph...")
    if not args.graphid:
        graph_id = find_graph_id(session, zabbix_url, token, host_id, args.graph_name)
    else:
        graph_id = args.graphid

    eprint("Downloading...")
    data = download_graph_bytes(
        session,
        zabbix_url,
        user,
        password,
        cookie_file,
        graph_id,
        from_date,
        to_date,
        args.width,
        args.height,
    )

    write_output(data, args.output_file)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except Exception as e:
        eprint("ERROR:", e)
        raise SystemExit(2)
