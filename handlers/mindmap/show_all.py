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
from pydantic import ConfigDict

from typing import List


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
    icon: Optional[str] = None


    #model_config = ConfigDict(extra = "ignore")



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
pprint.pprint(mindmap)

#root = Node.model_validate(mindmap)

#results = search_to_json(root, "mcmp1")

#print(yaml.dump({
#    "mindmap": results
#}))
