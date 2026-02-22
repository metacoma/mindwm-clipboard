import kando.schema as kando
import kando.utils as utils
import mindwm.ssh as ssh


schema Ip4:
  ip: str
  name: str = ip
  state?: str
  country?: str
  org?: str
  city?: str
  ssh?: ssh.SshHost
  icon = lambda -> str {
    utils.country_icon(country)
  }

make = lambda obj: any -> Ip4 {
  Ip4 {
    ip = obj.ip
    state = obj.state
    country = obj.country
    org = obj.org
    city = obj.city
    ssh = obj.ssh
  }
}

makeRefIp = lambda ip : str, all_objects : any -> Ip4 {
  r = None
  if "Ip {ip}" in all_objects:
    r = make(all_objects["Ip ${ip.ip}"]["ip4"][0])
  else:
    r = make({
      ip = ip
    })
  r
}

makeMenu = lambda ip -> kando.Child {
  {
    name = ip.ip + ""
    icon = ip.icon()
    children = [
      utils.makeInsertAction({
        name = "ping"
        icon = "🏓"
        text = "ping ${ip.ip}"
      })
      utils.makeInsertAction({
        name = "traceroute"
        icon = "🧭"
        text = "traceroute -n -q1 ${ip.ip}"
      })
      utils.makeCommand({
        name = "MTR"
        icon = "📶"
        cmd = utils.runTerminal("mtr -n ${ip.ip}")
      })
      utils.makeCopyAction(ip.ip)
      if ip.org:
        utils.showEmoji(
          title = ip.org
          emoji = "📡"
        )
      if ip.city:
        utils.showEmoji(
          title = ip.city
          emoji = "🏙️"
        )
      if (ip.ssh):
        ssh.sshMenu(ip.ssh)
    ]
  }
}
