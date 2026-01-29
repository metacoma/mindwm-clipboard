import kando.schema as kando
import kando.utils as utils
import file

schema Node:
  id: str
  tags?: [str] = []
  text: str
  name: str = text
  attributes?: {str:str} = {}
  detail?: str
  children: [Node] = []
  note?: str
  link?: str
  iconTheme = lambda -> str {
    r = "material-symbols-rounded"
    if icon().startswith("data:image/"):
      r = "base64"
    r
  }
  icon = lambda -> str {
    mindmap_icon
  }
  mindmap_icon?: str = "🧠"

getIconTheme = lambda icon : str -> str {
  r = "material-symbols-rounded"
  if icon.startswith("data:image/"):
    r = "base64"
  r
}

make = lambda obj: any, all_objects: any -> Node {
  Node {
    id = obj.id
    text = obj.text
    name = obj.text
    if (obj.icon):
      mindmap_icon = obj.icon
    if obj.note:
      note = obj.note
    if obj.attributes:
      attributes = obj.attributes
    if obj.detail:
      detail = obj.detail
    if obj.link:
      link = obj.link
    children = [
      make(child, all_objects)
      for child in obj.children
    ]
  }
}

nodeIcon = lambda node : Node -> any {
  iconTheme = "base64"
}

makeMenu = lambda node -> kando.Child {
  {
    name = node.name
    icon = node.icon()
    iconTheme = getIconTheme(node.icon())
    children = [
      makeMenu(child)
      for child in node.children
    ] + [
      utils.makeCommand({
        name = "open"
        icon = "🗺️"
        cmd = "/home/bebebeka/git/freeplane_plugin_grpc/grpc/shell/centerNode.sh ${node.id}"
      })
      if node.link:
        utils.makeCommand({
          name = "url"
          icon = "🌍"
          cmd = "xdg-open ${node.link}"
        })
    ]
  }
}
