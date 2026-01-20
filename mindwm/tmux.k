import kando.utils as utils
import kando.schema as kando

schema Tmux:
  session: str

makeSshPaneMenu = lambda hostname : str, session_name : str, windows: [str] -> [kando.Child] {
  menu = [
    utils.makeCommand({
      name = window
      cmd = "gnome-terminal -- ssh -t ${hostname} tmux attach -t ${session_name}:${window}"
      icon = "🧩"
    })
    for window in windows
  ]
  menu
}

SshWindowMenu = lambda hostname : str, session_name : str, windows: [str] -> kando.Child {
    paneMenu = makeSshPaneMenu(hostname, session_name, windows)
    menu = utils.makeSubmenu(
      session_name,
      paneMenu)
    menu
}

makeSshTmuxMenu = lambda hostname : str, sessions : {str:[str]} -> kando.Child {
  menu = [
    SshWindowMenu(hostname, name, windows)
    for name, windows in sessions
  ]

  subMenu = utils.makeSubmenu("tmux", menu)

  subMenu

}
