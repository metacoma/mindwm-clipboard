import mindwm.cmdb.schema as schema
import mindwm.cmdb.user as user
import kando.schema as kando
import kando.utils as utils
import kando.images as images
import mindwm.cmdb.host as host

schema VHost(schema.Object):
  hostNames?: [str]
  hosts: [host.Host] = []
  port: int
  icon = lambda -> str {
    utils.makeIcon(images.WWW)
  }

make = lambda obj: any, all_objects : any -> VHost {
  VHost {
    name = obj.name
    selfUrl = obj.selfUrl
    hostNames = obj.hostNames
    port = obj.port
    if obj.hosts:
      hosts = [
        host.make(h, all_objects)
        for h in obj.hosts
      ]
  }
}

makeMenu = lambda vhost : any -> kando.Child {
  kando.Child {
    name = vhost.name
    icon = vhost.icon()
    children = [
      utils.showText({
        text = str(vhost.port)
        icon = utils.makeIcon(images.TCP)
      })
    ] + [
      host.makeMenu(h)
      for h in vhost.hosts
    ]
  }
}
