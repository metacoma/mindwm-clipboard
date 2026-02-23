import mindwm.cmdb.schema as schema
import mindwm.cmdb.host as host
import kando.schema as kando
import kando.images as images
import kando.utils as utils
import regex

schema PhysicalHost(schema.Object):
  host: host.Host
  serial?: str
  rack_id?: str
  model?: str
  icon = lambda -> str {
    r = utils.makeIcon(images.SAN_RACK_SWITCH)
    if model and regex.match(model, "^RB"):
      r = utils.makeIcon(images.MIKROTIK)
    r
  }

makeMenu = lambda device : any -> kando.Child {
  host_menu = host.makeMenu(device.host)
  host_menu.children += [
    if device.serial:
      utils.showText({
        text = device.serial
        icon = utils.makeIcon(images.SERIAL2)
      })
    if device.model:
      utils.showText({
        text = device.model
        icon = utils.makeIcon(images.HW_MODEL)
      })
  ]
  host_menu
}
