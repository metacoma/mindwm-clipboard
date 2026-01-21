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

makeMenu = lambda ip -> kando.Child {
  {
    name = ip.ip + ""
    icon = ip.icon()
    children = [
      utils.insertText({
        name = "ping"
        cmd = "ping ${ip.ip}"
      })
      utils.insertText({
        name = "traceroute"
        cmd = "traceroute -n -q1 ${ip.ip}"
      })
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
