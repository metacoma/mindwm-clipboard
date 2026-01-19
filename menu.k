import kando.schema as kando
import kando.utils as utils
import mindwm.ipv4 as ipv4
import mindwm.tmuxp as tmuxp
import file
import yaml


_i = yaml.decode(file.read("./input.yaml"))

object_by_type = lambda t : str, obj: any -> any {
  r = []
  if t == "ip4":
    r = [
      ipv4.Ip4 {
        "ip" = _ip.ip,
        "state" = _ip.state
        "country" = _ip.country
        "org" = _ip.org
        "city" = _ip.city
        "ssh" = _ip.ssh
      }
      for _ip in obj
    ]
  if t == "tmuxp":
    r = [
      tmuxp.Tmuxp {
        "name" = _tmuxp.name,
        "sessions" = _tmuxp.sessions
        "host" = _tmuxp.host
      }
      for _tmuxp in obj
    ]
  r
}

__objects = [
  object_by_type(t,obj)
  for t, obj in _i
]
_objects = [i for sub in __objects for i in sub]

child = lambda obj : any -> kando.Child {
  if typeof(obj) == "Ip4":
    child = ipv4.makeMenu(obj)
  if typeof(obj) == "Tmuxp":
    child = tmuxp.makeMenu(obj)
  child
}




kando.Config {
    menus = [
      kando.Menu {
        root = {
          name = "root"
          children = [
            child(object)
            for object in _objects
          ]
        }
      }
    ]
    collections = [
      {
        name = "Favorites"
        icon = "favorite"
        iconTheme = "material-symbols-rounded"
        tags = [ "favs" ]
      }
    ]
}
