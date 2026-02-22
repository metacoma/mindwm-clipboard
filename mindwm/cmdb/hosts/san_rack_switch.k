import mindwm.cmdb.host as host
import kando.utils as utils
import kando.schema as kando
import mindwm.cmdb.datacenter as datacenter
import mindwm.cmdb.user as user
import mindwm.cmdb.team as team
import mindwm.cmdb.hosts.physical as physical
import kando.images as images
import mindwm.ipv4 as ipv4

schema SanRackSwitch(physical.PhysicalHost):
  icon = lambda -> str {
    utils.makeIcon(images.SAN_RACK_SWITCH)
  }


make = lambda obj: any, all_objects : any -> SanRackSwitch {
  SanRackSwitch {
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
