import mindwm.cmdb.host as host
import kando.utils as utils
import kando.schema as kando
import mindwm.cmdb.datacenter as datacenter
import mindwm.cmdb.user as user
import mindwm.cmdb.team as team
import mindwm.cmdb.hosts.physical as physical
import kando.images as images
import mindwm.ipv4 as ipv4
import regex

schema LanRouter(physical.PhysicalHost):
  icon = lambda -> str {
    r = utils.makeIcon(images.LAN_ROUTER)
    if model and regex.match(model, "^RB"):
      r = utils.makeIcon(images.MIKROTIK)
    r
  }


make = lambda obj: any, all_objects : any -> LanRouter {
  LanRouter {
    name = obj.name
    selfUrl = obj.selfUrl
    host = host.make(obj, all_objects)
    if obj.serial:
      serial = obj.serial
    if obj.model:
      model = obj.model
  }
}

makeMenu = lambda switch : any -> kando.Child {
  physical.makeMenu(switch)
}
