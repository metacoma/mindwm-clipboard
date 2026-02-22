import os
import requests
import hashlib
import os
import base64
import re
import logging
from pathlib import Path
from urllib.parse import urlparse
from html import unescape

jira_url = os.getenv('jira_url')
jira_pat = os.getenv('jira_pat')
cmdb_id = os.getenv('CMDB_ID')
from typing import Any, List, Optional, Dict

logger = logging.getLogger(__name__)

def file_to_base64(path: str) -> str:
    p = Path(path)

    if not p.exists():
        raise FileNotFoundError(f"File not found: {path}")

    if not p.is_file():
        raise ValueError(f"Not a regular file: {path}")

    with p.open("rb") as f:
        encoded = base64.b64encode(f.read())

    return encoded.decode("utf-8")

def download_image(url: str, cache_dir: str = "/tmp/jira", timeout: int = 30) -> str:
    """
    Download image by URL with Jira PAT bearer auth, using a file cache in /tmp/jira.

    Returns: path to cached/downloaded file as string.
    Raises: requests.HTTPError on non-2xx, ValueError on bad url.
    """
    if not url or not isinstance(url, str):
        raise ValueError("url must be a non-empty string")

    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise ValueError(f"invalid url: {url!r}")

    cache_path = Path(cache_dir)
    cache_path.mkdir(parents=True, exist_ok=True)

    # Stable cache key: URL -> sha256
    key = hashlib.sha256(url.encode("utf-8")).hexdigest()

    # Try to preserve extension (if any); fall back to .bin
    ext = Path(parsed.path).suffix
    if not ext or len(ext) > 10:
        ext = ".bin"

    dst = cache_path / f"{key}{ext}"

    # Cache hit
    if dst.exists() and dst.stat().st_size > 0:
        return str(dst)

    headers = {
        "Authorization": f"Bearer {jira_pat}",
        "Accept": "*/*",
    }

    # Download to temp file, then atomic rename (avoid partial cache files)
    tmp = cache_path / f"{key}.part"

    with requests.get(url, headers=headers, stream=True, timeout=timeout) as r:
        r.raise_for_status()
        with open(tmp, "wb") as f:
            for chunk in r.iter_content(chunk_size=1024 * 128):
                if chunk:
                    f.write(chunk)

    os.replace(tmp, dst)
    return str(dst)

def execute_aql_query(q):
    logger.info(q)
    api_endpoint = f"{jira_url}/rest/assets/1.0/aql/objects"
    headers = {
        "Authorization": f"Bearer {jira_pat}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    query = {
        "qlQuery": q,
        "resultPerPage": "10",
        "includeAttributes": "true",
        "includeAttributesDeep": "1",
        "includeTypeAttributes": "false"
    }
    try:
        response = requests.get(
            api_endpoint,
            params=query,
            headers=headers
        )
        response.raise_for_status()
        return response.json()

    except requests.exceptions.RequestException as e:
        return {"error": str(e)}

def parse_details(html: str) -> dict[str, str]:
    text = re.sub(r"<br\s*/?>", "\n", html, flags=re.IGNORECASE)
    text = re.sub(r"<[^>]+>", "", text)
    text = unescape(text)
    result = {}

    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue

        if ":" in line:
            key, value = line.split(":", 1)
            result[key.strip()] = value.strip()

    return result
