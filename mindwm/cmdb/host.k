import mindwm.cmdb.schema as schema
import kando.utils as utils
import kando.schema as kando
import mindwm.ipv4 as ipv4
import mindwm.cmdb.datacenter as datacenter
import mindwm.cmdb.team as team
import mindwm.cmdb.user as user
import mindwm.zabbix.schema as zabbix
import kando.images as images

schema Host(schema.Object):
  dc?: datacenter.DC
  networkInterface?: [ipv4.Ip4] = []
  zabbixHost?: zabbix.ZabbixHost #|zabbix.ZabbixHostLinux|zabbix.ZabbixHostWindows|zabbix.ZabbixHostForti
  team?: [team.Team]
  owner?: user.User
  os?: str
  service?: [str]
  vipIp?: ipv4.Ip4
  icon = lambda -> str {
    utils.operatingSystemIcon(os)
  }

schema PhysicalHost(Host):
  serial?: str
  rack_id?: str
  model?: str

make = lambda obj: any, all_objects : any -> Host {
  Host {
    name = obj.name
    selfUrl = obj.selfUrl
    zabbixHost = zabbix.getHost(all_objects, obj.name)


    if obj.location:
      dc = datacenter.make(obj.location, all_objects)
    if obj.networkInterface:
      networkInterface = [
        ipv4.makeRefIp(ip, all_objects)
        for ip in obj.networkInterface
      ]

    if obj.owner:
      owner = user.make(obj.owner, all_objects)
    os = obj.os
    service = obj.service
    if obj.vipIp:
      vipIp = ipv4.makeRefIp(obj.vipIp, all_objects)
    team = obj.team
  }
}

makeMenu = lambda host : any -> kando.Child {
  kando.Child {
    name = host.name
    icon = utils.operatingSystemIcon(host.os)
    children = [
      utils.makeURI({
        name = "Jira"
        icon = "🧩"
        uri = host.selfUrl
      })
      if host.networkInterface and host.os and host.os != "Windows":
        utils.makeCommand({
          name = "ssh"
          icon = utils.makeIcon(images.TERMINAL)
          cmd = utils.runTerminal("ssh -t fonbet ssh ${host.networkInterface[0].ip}")
        })
      if host.vipIp:
        utils.makeSubmenu({
          name = "VIP: ${host.vipIp.ip}"
          icon = host.vipIp.icon()
          children = ipv4.makeMenu(host.vipIp).children
        })
      if host.dc:
        utils.makeSubmenu({
          name = host.dc.name
          icon = host.dc.icon()
          children = datacenter.makeMenu(host.dc).children
        })
      # if host.owner:
      #   utils.makeSubmenu({
      #     name = host.owner.name
      #     icon = host.owner.avatar
      #     children = user.makeMenu(host.owner).children
      #   })
      if host.service:
        utils.showText({
          text = ",".join(host.service)
          #icon = "⚙️"
          icon = utils.makeServiceIcon(",".join(host.service))
        })
    ] + [
        utils.makeSubmenu({
          name = ip.ip
          icon = ip.icon()
          children = ipv4.makeMenu(ip).children
        })
        for ip in host.networkInterface
    ] + [
        utils.makeSubmenu({
          name = host_team.name
          icon = "👥"
          children = team.makeMenu(host_team).children
        })
        for host_team in host.team
    ] + zabbix.makeMenu(host)

  }
}
