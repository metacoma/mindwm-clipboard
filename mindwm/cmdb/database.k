import mindwm.cmdb.schema as schema
import mindwm.cmdb.user as user
import kando.schema as kando
import kando.utils as utils
import kando.images as images
import mindwm.cmdb.host as host

schema Database(schema.Object):
  hostNames?: [str]
  hosts: [host.Host] = []
  head: user.User = None
  size: str
  icon = lambda -> str {
    utils.makeIcon(images.DATABASE)
  }

make = lambda obj: any, all_objects : any -> Database {
  Database {
    name = obj.name
    selfUrl = obj.selfUrl
    hostNames = obj.hostNames
    size = obj.size
    if (obj.head):
      head = user.make(obj.head, all_objects)
    if obj.hosts:
      hosts = [
        host.make(h, all_objects)
        for h in obj.hosts
      ]
  }
}

makeMenu = lambda db : any -> kando.Child {
  kando.Child {
    name = db.name
    icon = db.icon()
    children = [
      utils.showText({
        text = db.size
        icon = utils.makeIcon(images.SIZE)
      })
      if db.head:
        user.makeMenu(db.head)
    ] + [
      host.makeMenu(h)
      for h in db.hosts
    ]
  }
}
