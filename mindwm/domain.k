import kando.schema as kando
import kando.utils as utils
import mindwm.ssh as ssh
import mindwm.ipv4 as ipv4

schema Nameserver:
  name: str
  ip_addresses: [ipv4.Ip4]

schema Mailserver:
  name: str
  ip_addresses: [ipv4.Ip4]

schema Domain:
  name: str
  ip_addresses: [ipv4.Ip4]
  ns: [Nameserver]
  mx: [Mailserver]
  icon = lambda -> str {
    "🌐"
  }

makeNameserver = lambda obj: any, all_objects: any -> Nameserver {
  Nameserver {
    name = obj.nameserver
    ip_addresses = [
      ipv4.make(all_objects["Ip ${ip.ip}"]["ip4"][0])
      for ip in obj.ipv4
    ]
  }
}

makeMailserver = lambda obj: any, all_objects: any -> Mailserver {
  Mailserver {
    name = obj.mailserver
    ip_addresses = [
      ipv4.make(all_objects["Ip ${ip.ip}"]["ip4"][0])
      for ip in obj.ipv4
    ]
  }
}

make = lambda obj: any, all_objects: any -> Domain {
  Domain {
    name = obj.name
    ip_addresses = [
      ipv4.make(all_objects["Ip ${ip.ip}"]["ip4"][0])
      for ip in obj.ipv4
    ]
    ns = [
      makeNameserver(ns, all_objects)
      for ns in obj.ns
    ]
    if obj.mx:
      mx = [
        makeMailserver(mx, all_objects)
        for mx in obj.mx
      ]
    else:
      mx = []
  }
}

makeMenu = lambda d: Domain, objects: any -> kando.Child {
  kando.Child {
    name = d.name
    children = [
      utils.makeSubmenu({
        name = "NS"
        icon = "🖥️"
        children = [
          utils.makeSubmenu({
            name = nameserver.name
            icon = "🗄️"
            children = [
              ipv4.makeMenu(ip)
              for ip in nameserver.ip_addresses
            ]
          })
          for nameserver in d.ns
        ]
      })
      if d.mx:
        utils.makeSubmenu({
          name = "MX"
          icon = "📬"
          children = [
            utils.makeSubmenu({
              name = mailserver.name
              icon = "🗄️"
              children = [
                ipv4.makeMenu(ip)
                for ip in mailserver.ip_addresses
              ]
            })
            for mailserver in d.mx
          ]
        })
    ] + [
      ipv4.makeMenu(ip)
      for ip in d.ip_addresses
    ]
  }
}
