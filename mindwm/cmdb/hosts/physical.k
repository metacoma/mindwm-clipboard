import mindwm.cmdb.schema as schema
import mindwm.cmdb.host as host
import kando.schema as kando
import kando.images as images
import kando.utils as utils

schema PhysicalHost(schema.Object):
  host: host.Host
  serial?: str
  rack_id?: str
  model?: str

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
