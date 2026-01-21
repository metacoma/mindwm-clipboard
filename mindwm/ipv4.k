import kando.schema as kando
import kando.utils as utils
import mindwm.ssh as ssh


schema Ip4:
  name: str = ip
  ip: str
  state?: str
  country?: str
  org?: str
  city?: str
  ssh?: ssh.SshHost
  icon = lambda -> str {
    utils.country_icon(country)
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
