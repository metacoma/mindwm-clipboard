from __future__ import annotations
import sys
import sys
import pprint
import json
import grpc
import freeplane_pb2_grpc
import freeplane_pb2
import argparse
import yaml
from typing import Iterator


from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from pydantic import ConfigDict, model_validator

from typing import List

import base64
from pathlib import Path

import base64
from pathlib import Path


def icon_to_representation(icon: str, icons_dir: str = "icons") -> str | None:
    # emoji-XXXX or emoji-XXXX-YYYY-...
    if icon.startswith("emoji-"):
        try:
            parts = icon[len("emoji-"):].split("-")
            return "".join(chr(int(p, 16)) for p in parts)
        except ValueError:
            return None

    icon_path = Path(icons_dir) / f"{icon}.png"
    if icon_path.is_file():
        data = icon_path.read_bytes()
        b64 = base64.b64encode(data).decode("ascii")
        return f"data:image/png;base64,{b64}"

    return None



def node_contains_keyword(node: Node, keyword: str) -> bool:
    kw = keyword.lower()

    if kw in node.text.lower():
        return True

    if node.detail and kw in node.detail.lower():
        return True

    if node.note and kw in node.note.lower():
        return True

    if node.tags:
        for tag in node.tags:
            if kw in tag.lower():
                return True

    if node.attributes:
        for k, v in node.attributes.items():
            if kw in str(k).lower() or kw in str(v).lower():
                return True

    return False



class Node(BaseModel):
    text: str
    id: str

    children: List["Node"] = Field(default_factory=list)

    attributes: Optional[Dict[str, Any]] = None
    tags: Optional[List[str]] = None
    detail: Optional[str] = None
    note: Optional[str] = None
    icons: Optional[List[str]] = None
    icon: Optional[str] = None
    link: Optional[str] = None

    model_config = ConfigDict(extra = "ignore")

    @model_validator(mode="after")
    def fill_icon_from_icons(self):
        if self.icon is None and self.icons:
            self.icon = icon_to_representation(self.icons[0], "/home/bebebeka/spaces/mindwm/clipboard/handlers/mindmap/icons")
        return self



def walk(node: Node) -> Iterator[Node]:
    yield node
    for child in node.children:
        yield from walk(child)


def find_nodes(root: Node, keyword: str) -> Iterator[Node]:
    pprint.pprint(root)
    kw = keyword.lower()

    for node in walk(root):
        if node_contains_keyword(node, kw):
            yield node

def search_to_json(root: Node, keyword: str) -> str:
    results = [
        node.model_dump()
        for node in walk(root)
        if node_contains_keyword(node, keyword)
    ]

    return results



#Node.model_rebuild()

channel = grpc.insecure_channel('localhost:50051')
fp = freeplane_pb2_grpc.FreeplaneStub(channel)

mindmap = json.loads(fp.MindMapToJSON(freeplane_pb2.MindMapToJSONRequest()).json)

root = Node.model_validate(mindmap)

data = sys.stdin.read().rstrip("\n")

results = search_to_json(root, data)

if results:
    print(yaml.dump({
        "mindmap": results
    }, allow_unicode = True))
