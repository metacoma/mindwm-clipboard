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

schema ZabbixContainer:
  name: str
  cpu: str
  mem: str
  status: str

schema ZabbixPostgresDb:
  name: str
  size: str

schema ZabbixPostgres:
  replication?: str
  database?: [ZabbixPostgresDb]

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
  container: [ZabbixContainer]
  postgres: ZabbixPostgres

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
    container = [
      ZabbixContainer {
        name = c.name
        cpu = c.cpu
        mem = c.mem
        status = c.status
      }
      for c in obj.container
    ]
    postgres = {
      if obj.postgres.database:
        database = [
          ZabbixPostgresDb {
            name = db.name
            size = db.size
          }
          for db in obj.postgres.database
        ]
      if obj.postgres.replication:
        replication = obj.postgres.replication

    }
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
  hostIp = None
  if host.networkInterface and host.networkInterface[0]:
    hostIp = host.networkInterface[0].ip
  zabbixHost = host.zabbixHost
  [
    utils.makeURI({
      name = "Zabbix"
      icon = utils.makeIcon(images.ZABBIX)
      uri = zabbixHost.url
    })
    utils.showText({
      text = zabbixHost.uptime.lastvalue
      icon = utils.makeIcon(images.UPTIME)
    })
    zabbixItemGraphShow(zabbixHost, zabbixHost.cpu_util, "CPU utilization", utils.makeIcon(images.CPU))
    zabbixItemGraphShow(zabbixHost, zabbixHost.memory_util, "Memory utilization", utils.makeIcon(images.MEMORY))
  ] + [
    if zabbixHost.disk:
      utils.makeSubmenu({
        name = "Disks"
        icon = utils.makeIcon(images.HDD)
        children = [
          zabbixGraphShow(zabbixHost.name, disk.name, "${disk.name}: Disk read/write rates", utils.makeIcon(images.HDD))
          for disk in zabbixHost.disk
        ]
      })
    if zabbixHost.networkInterface:
      utils.makeSubmenu({
        name = "Network"
        icon = utils.makeIcon(images.NETWORK_CARD)
        children = [
          zabbixGraphShow(zabbixHost.name, netIf.name, netIf.graphName, utils.makeIcon(images.NETWORK_CARD))
          for netIf in zabbixHost.networkInterface
        ]
      })
    if zabbixHost.filesystem:
      utils.makeSubmenu({
        name = "Filesystem"
        icon = utils.makeIcon(images.FS)
        children = [
          zabbixGraphShow(zabbixHost.name, fs.name, fs.graphName, fs.icon)
          for fs in zabbixHost.filesystem
        ]
      })

    if zabbixHost.container:
      utils.makeSubmenu({
        name = "Container"
        icon = utils.makeIcon(images.DOCKER)
        children = [
          utils.makeSubmenu({
            name = container.name
            icon = utils.makeIcon(images.CONTAINER)
            children = [
              utils.makeCommand({
                name = "Restart"
                cmd = "restart"
                icon = utils.makeIcon(images.RESTART)
              })
              utils.makeCommand({
                name = "Exec"
                cmd = "restart"
                icon = utils.makeIcon(images.TERMINAL)
              })
              utils.makeCommand({
                name = "Kill"
                cmd = "restart"
                icon = utils.makeIcon(images.KILL)
              })
              zabbixGraphShow(zabbixHost.name, container.mem, "Container /${container.name}: Memory usage", utils.makeIcon(images.MEMORY))
              zabbixGraphShow(zabbixHost.name, container.cpu, "Container /${container.name}: CPU usage", utils.makeIcon(images.CPU))
            ]
          })
          for container in zabbixHost.container
        ]
      })

    if zabbixHost.postgres.database:
      utils.makeSubmenu({
        name = "Postgres"
        icon = utils.makeIcon(images.POSTGRESQL)
        children = [
          if (zabbixHost.postgres.replication):
            utils.makeCommand({
              name = zabbixHost.postgres.replication
              cmd = "echo ${zabbixHost.postgres.replication} | xclip -i -selection primary"
              icon = utils.makeIcon(images.DATABASE_MASTER)
            })
        ] + [
          utils.makeSubmenu({
            name = db.name
            icon = utils.makeIcon(images.DATABASE)
            children = [
              if hostIp:
                utils.makeCommand({
                  name = "Exec"
                  cmd = utils.runTerminal("ssh -t jumphost ssh -t ${hostIp} \"sudo -u postgres psql ${db.name}\"")
                  icon = utils.makeIcon(images.TERMINAL)
                })
              zabbixGraphShow(zabbixHost.name, db.size, "DB ${db.name}: Size", utils.makeIcon(images.SIZE))
            ]
          })
          for db in zabbixHost.postgres.database
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
