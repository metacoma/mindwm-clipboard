import .schema as kando
import config as config

schema SubMenuArgs:
  name: str
  icon?: str = "🕸️"
  children: [kando.Child]

makeSubmenu = lambda arg : SubMenuArgs -> kando.Child {
  {
    type = "submenu"
    name = arg.name
    icon = arg.icon
    "children" = arg.children
  }
}

makeCommand = lambda args : any -> kando.Command {
  {
    name = args.name
    data = {
      command = args.cmd
      delayed = True
    }
    if (args.icon):
      icon = args.icon
  }
}

insertText = lambda args : any -> kando.Command {
  makeCommand({
    name = args.name
    cmd = "xdotool type \"${args.cmd}\""
    if args.cmd.startswith("ping "):
      icon = "🏓"
      iconTheme = "emoji"
    if args.cmd.startswith("traceroute "):
      icon = "🧭"
      iconTheme = "emoji"
    if args.cmd.startswith("ssh "):
      icon = "🖥️"
      iconTheme = "emoji"
    if args.icon:
      icon = args.icon
      iconTheme = "emoji"

  })
}

showEmoji = lambda title : str, emoji  : str -> kando.Command {
  makeCommand({
    name = title
    cmd = ""
    icon = emoji
    iconTheme = emoji
  })
}

showText = lambda args : any -> kando.Text {
  kando.Text {
    name = args.name
    icon = args.icon
    data.text = args.text
  }
}

makeURI = lambda args : any -> kando.Uri {
  kando.Uri {
    name = args.name
    if args.icon:
      icon = args.icon
    data.uri = args.uri
  }
}

runTerminal = lambda cmd : any -> str {
  run_cmd = "xterm -e sh -c '${cmd}'"
  if (config.terminal == "gnome-terminal"):
    run_cmd = "gnome-terminal -- sh -c '${cmd}'"
  run_cmd
}
