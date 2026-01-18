import kando.schema as kando
import kando.utils as utils

schema Tmuxp:
  name: str
  host?: str
  sessions: any


makeWindowMenu = lambda host: str, session_name: str, windows: [any] -> [kando.Child] {
  if windows:
    r = [
      utils.makeCommand({
        name = window
        cmd = "gnome-terminal -- ssh -t ${host} 'tmux attach -t ${session_name} \; select-window -t ${window}'"
      })
      for window in windows
    ]
  else:
    r = []
  r

}

makeMenu = lambda tmuxp : any -> kando.Child {
  windows = []
  r = utils.makeSubmenu(
    name = tmuxp.name,
    children = [
      utils.makeSubmenu(
        name = session.name
        #children = [ makeSessionMenu(tmuxp.host, session) ]
        children = [
          utils.makeCommand({
            name = "open"
            cmd = "gnome-terminal -- ssh -t ${tmuxp.host} tmux attach -t ${session.name}"
          })
          utils.makeCommand({
            name = "restart"
            cmd = "gnome-terminal -- ssh -t ${tmuxp.host} 'tmux kill-session -t ${session.name}; ./.local/bin/tmuxp load ${session.name}'"
          })
        ] + makeWindowMenu(tmuxp.host, session.name, session.windows)
      )
      for session in tmuxp.sessions
    ]
  )
  r
}
