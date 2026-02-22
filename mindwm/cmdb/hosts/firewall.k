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

schema Firewall(physical.PhysicalHost):
  icon = lambda -> str {
    icon = utils.makeIcon(images.FIREWALL)
    if model and regex.match(model, "Forti.*"):
      icon = utils.makeIcon(images.FORTIGATE)
    icon
  }


make = lambda obj: any, all_objects : any -> Firewall {
  Firewall {
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
