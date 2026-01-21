import kando.schema as kando
import kando.utils as utils
import mindwm.ipv4 as ipv4
import mindwm.tmuxp as tmuxp
import mindwm.twitch as twitch
import mindwm.content as content
import mindwm.domain as domain
import file
import yaml


_all_objects = yaml.decode(file.read("./input.yaml"))

object_by_type = lambda t : str, obj: any -> any {
  r = []
  if t == "ip4":
    r = [
      ipv4.make(obj)
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
  if t == "twitch_clips":
    r = [
      twitch.TwitchClip {
        "slug" = _clip.slug
        "title" = _clip.title
        "createdAt" = _clip.createdAt
        "viewCount" = _clip.viewCount
        "durationSeconds" = _clip.durationSeconds
        "url" = _clip.url
        "category" = _clip.category
        "broadcaster" = _clip.broadcaster
      }
      for _clip in obj
    ]

  if t == "twitch_streamer":
    r = [
      twitch.TwitchStreamer {
        "broadcaster" = _streamer.name
      }
      for _streamer in obj
    ]

  if t == "json":
    r = [
      content.JsonFile {
        path = _file.path
      }
      for _file in obj
    ]
  if t == "yaml":
    r = [
      content.YamlFile {
        path = _file.path
      }
      for _file in obj
    ]

  if t == "domain":
    r = [
      domain.make(_domain, _all_objects)
      for _domain in obj
    ]

  r
}

__objects = [
  object_by_type(t,obj)
  for t, obj in _all_objects
]
_objects = [i for sub in __objects for i in sub]

child = lambda obj : any -> kando.Child {
  if typeof(obj) == "Ip4":
    child = ipv4.makeMenu(obj)
  if typeof(obj) == "Tmuxp":
    child = tmuxp.makeMenu(obj)
  if typeof(obj) == "TwitchClip":
    child = twitch.makeMenuTwitchClip(obj)
  if typeof(obj) == "TwitchStreamer":
    child = twitch.makeMenuTwitchStreamer(obj)
  if typeof(obj) == "JsonFile":
    child = content.makeMenuJsonFile(obj)
  if typeof(obj) == "YamlFile":
    child = content.makeMenuYamlFile(obj)
  if typeof(obj) == "Domain":
    child = domain.makeMenu(obj, _all_objects)
  child
}




kando.Config {
    menus = [
      kando.Menu {
        centered = True
        root = {
          name = "root"
          children = [
            kando.Redirect {
              name = "${object.name}"
              icon = object.icon()
              data.menu = "${typeof(object)} ${object.name}"
            }
            for object in _objects
          ]
        }
      }
    ] + [
      kando.Menu {
        centered = True
        root = {
          name = "${typeof(object)} ${object.name}"
          icon = object.icon()
          children = child(object).children + [
            kando.Redirect {
              name = "back"
              icon = "↩️"
              data.menu = "root"
            }
          ]
        }
      }
      for object in _objects
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
