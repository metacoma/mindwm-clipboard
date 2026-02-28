import kando.images as images
import kando.utils as utils
import kando.schema as kando
import regex


schema ZabbixItem:
  name: str
  itemid: str
  state: str
  status: str
  lastvalue: str
  key: str
  description: str
  graphName?: str
  graphId?: str

schema ZabbixNetworkInterface:
  name: str
  id: str
  graphName: str

schema ZabbixDisk:
  name: str

schema ZabbixFilesystem:
  name: str
  util: str
  icon: str
  graphName: str

schema ZabbixHost:
  name: str
  url: str
  hostname: ZabbixItem
  uname: ZabbixItem
  arch: ZabbixItem
  uname: ZabbixItem

  uptime: ZabbixItem
  cpu_util: ZabbixItem
  cpu_cores: ZabbixItem
  swap_free: ZabbixItem
  swap_size: ZabbixItem
  memory_total: ZabbixItem
  #memory_used: ZabbixItem
  memory_util: ZabbixItem
  networkInterface: [ZabbixNetworkInterface]
  disk: [ZabbixDisk]
  filesystem: [ZabbixFilesystem]

schema ZabbixHostLinux(ZabbixHost):
schema ZabbixHostWindows(ZabbixHost):
schema ZabbixHostForti(ZabbixHost):

makeHost = lambda obj: any, all_objects: any -> ZabbixHost {
  ZabbixHost {
    name = obj.name
    url = obj.url
    hostname = obj.hostname
    arch = obj.arch
    uname = obj.uname
    uptime = obj.uptime
    cpu_util = obj.cpu.utilization
    cpu_cores = obj.cpu.cores
    swap_free = obj.swap.free
    swap_size = obj.swap.size
    memory_total = obj.memory.total
    #memory_used = obj.memory.used
    memory_util = obj.memory.util
    networkInterface = [
      ZabbixNetworkInterface {
        name = netIf.name
        id = netIf.id
        graphName = netIf.graphName
      }
      for netIf in obj.networkInterface
    ]
    disk = [
      ZabbixDisk {
        name = disk.name
      }
      for disk in obj.disk
    ]
    filesystem = [
      ZabbixFilesystem {
        name = fs.name
        util = fs.util
        icon = fs.icon
        graphName = fs.graphName
      }
      for fs in obj.fs
    ]
  }
}

getHost = lambda all_objects: any, host_name : str -> any {
  r = None
  if "monitoring" in all_objects and "hosts" in all_objects["monitoring"]:
    host = filter h in all_objects.monitoring.hosts {
      h.name.lower() == host_name.lower()
    }
    if host:
      host = host[0]
      r = makeHost(host, all_objects)
  r
}

makeMenu = lambda host : any -> [kando.Child] {
  [
    utils.makeURI({
      name = "Zabbix"
      icon = utils.makeIcon(images.ZABBIX)
      uri = host.url
    })
    utils.showText({
      text = host.uptime.lastvalue
      icon = utils.makeIcon(images.UPTIME)
    })
    zabbixItemGraphShow(host, host.cpu_util, "CPU utilization", utils.makeIcon(images.CPU))
    zabbixItemGraphShow(host, host.memory_util, "Memory utilization", utils.makeIcon(images.MEMORY))
  ] + [
    if host.disk:
      utils.makeSubmenu({
        name = "Disks"
        icon = utils.makeIcon(images.HDD)
        children = [
          zabbixGraphShow(host.name, disk.name, "${disk.name}: Disk read/write rates", utils.makeIcon(images.HDD))
          for disk in host.disk
        ]
      })
    if host.networkInterface:
      utils.makeSubmenu({
        name = "Network"
        icon = utils.makeIcon(images.NETWORK_CARD)
        children = [
          zabbixGraphShow(host.name, netIf.name, netIf.graphName, utils.makeIcon(images.NETWORK_CARD))
          for netIf in host.networkInterface
        ]
      })
    if host.filesystem:
      utils.makeSubmenu({
        name = "Filesystem"
        icon = utils.makeIcon(images.FS)
        children = [
          zabbixGraphShow(host.name, fs.name, fs.graphName, fs.icon)
          for fs in host.filesystem
        ]
      })

  ]
}

zabbix_show_image_cmd = "/home/bebebeka/spaces/mindwm/clipboard/bin/zabbix_show_image.sh"

zabbixItemGraphShow = lambda host : ZabbixHost, item : ZabbixItem, graph_name : str, icon : str  -> kando.Child {
  value = item.lastvalue

  if (regex.match(item.name, "utilization|Usage|Util")):
    value = str(round(float(value))) + "%"


  if not item.graphId:
    show_image_args = "${host.name} '${graph_name}'"
  else:
    show_image_args = "${host.name} '${item.graphId}'"
  utils.makeCommand({
    name = value
    "cmd" = zabbix_show_image_cmd + " " + show_image_args
    icon = icon
  })
}

zabbixGraphShow = lambda host_name : str, value : str, graph_name : str, icon : str  -> kando.Child {

  show_image_args = "${host_name} '${graph_name}'"

  utils.makeCommand({
    name = value
    "cmd" = zabbix_show_image_cmd + " " + show_image_args
    icon = icon
  })
}


itemGraphName = lambda i : ZabbixItem, default : str -> str {
  r = default
  if i.graphName:
    r = i.graphName
  r
}
