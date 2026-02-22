import kando.schema as kando
import kando.utils as utils
import mindwm.tmux as tmux

schema SshHost:
  name: str = hostname
  hostname: str
  tmux_sessions?: {str:[str]} = {}
  icon = lambda -> str {
    "🔑"
  }

sshMenu = lambda sshHost: SshHost  -> kando.Child {
  new_terminal = utils.makeCommand({
    name = "new"
    cmd = utils.runTerminal("ssh ${sshHost.hostname}")
    icon = "🔑"
  })
  current_terminal = utils.makeInsertAction({
    name = "current"
    icon = "🖥️"
    text = "ssh ${sshHost.hostname}"
  })
  menu = utils.makeSubmenu({
      name = "ssh"
      children = [
        new_terminal,
        current_terminal
        if sshHost.tmux_sessions:
          tmux.makeSshTmuxMenu(sshHost.hostname, sshHost.tmux_sessions)
      ]
    })
  menu
}
