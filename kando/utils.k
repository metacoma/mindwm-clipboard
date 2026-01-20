import .schema as kando

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
    data.text = args.text
  }
}
