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

makeCopyAction = lambda text : str -> kando.Command {
  makeCommand({
    name = "Copy"
    cmd = "echo ${text} | copy_action.sh"
    icon = "📋"
  })
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

country_icon = lambda country -> str {
  icon = "📍"
  if (country):
      icon = country_flag[country]
  icon
}


country_flag = {
    "AD": "🇦🇩", "AE": "🇦🇪", "AF": "🇦🇫", "AG": "🇦🇬", "AI": "🇦🇮",
    "AL": "🇦🇱", "AM": "🇦🇲", "AO": "🇦🇴", "AQ": "🇦🇶", "AR": "🇦🇷",
    "AS": "🇦🇸", "AT": "🇦🇹", "AU": "🇦🇺", "AW": "🇦🇼", "AX": "🇦🇽",
    "AZ": "🇦🇿",

    "BA": "🇧🇦", "BB": "🇧🇧", "BD": "🇧🇩", "BE": "🇧🇪", "BF": "🇧🇫",
    "BG": "🇧🇬", "BH": "🇧🇭", "BI": "🇧🇮", "BJ": "🇧🇯", "BL": "🇧🇱",
    "BM": "🇧🇲", "BN": "🇧🇳", "BO": "🇧🇴", "BQ": "🇧🇶", "BR": "🇧🇷",
    "BS": "🇧🇸", "BT": "🇧🇹", "BV": "🇧🇻", "BW": "🇧🇼", "BY": "🇧🇾",
    "BZ": "🇧🇿",

    "CA": "🇨🇦", "CC": "🇨🇨", "CD": "🇨🇩", "CF": "🇨🇫", "CG": "🇨🇬",
    "CH": "🇨🇭", "CI": "🇨🇮", "CK": "🇨🇰", "CL": "🇨🇱", "CM": "🇨🇲",
    "CN": "🇨🇳", "CO": "🇨🇴", "CR": "🇨🇷", "CU": "🇨🇺", "CV": "🇨🇻",
    "CW": "🇨🇼", "CX": "🇨🇽", "CY": "🇨🇾", "CZ": "🇨🇿",

    "DE": "🇩🇪", "DJ": "🇩🇯", "DK": "🇩🇰", "DM": "🇩🇲", "DO": "🇩🇴",
    "DZ": "🇩🇿",

    "EC": "🇪🇨", "EE": "🇪🇪", "EG": "🇪🇬", "EH": "🇪🇭", "ER": "🇪🇷",
    "ES": "🇪🇸", "ET": "🇪🇹",

    "FI": "🇫🇮", "FJ": "🇫🇯", "FK": "🇫🇰", "FM": "🇫🇲", "FO": "🇫🇴",
    "FR": "🇫🇷",

    "GA": "🇬🇦", "GB": "🇬🇧", "GD": "🇬🇩", "GE": "🇬🇪", "GF": "🇬🇫",
    "GG": "🇬🇬", "GH": "🇬🇭", "GI": "🇬🇮", "GL": "🇬🇱", "GM": "🇬🇲",
    "GN": "🇬🇳", "GP": "🇬🇵", "GQ": "🇬🇶", "GR": "🇬🇷", "GS": "🇬🇸",
    "GT": "🇬🇹", "GU": "🇬🇺", "GW": "🇬🇼", "GY": "🇬🇾",

    "HK": "🇭🇰", "HM": "🇭🇲", "HN": "🇭🇳", "HR": "🇭🇷", "HT": "🇭🇹",
    "HU": "🇭🇺",

    "ID": "🇮🇩", "IE": "🇮🇪", "IL": "🇮🇱", "IM": "🇮🇲", "IN": "🇮🇳",
    "IO": "🇮🇴", "IQ": "🇮🇶", "IR": "🇮🇷", "IS": "🇮🇸", "IT": "🇮🇹",

    "JE": "🇯🇪", "JM": "🇯🇲", "JO": "🇯🇴", "JP": "🇯🇵",

    "KE": "🇰🇪", "KG": "🇰🇬", "KH": "🇰🇭", "KI": "🇰🇮", "KM": "🇰🇲",
    "KN": "🇰🇳", "KP": "🇰🇵", "KR": "🇰🇷", "KW": "🇰🇼", "KY": "🇰🇾",
    "KZ": "🇰🇿",

    "LA": "🇱🇦", "LB": "🇱🇧", "LC": "🇱🇨", "LI": "🇱🇮", "LK": "🇱🇰",
    "LR": "🇱🇷", "LS": "🇱🇸", "LT": "🇱🇹", "LU": "🇱🇺", "LV": "🇱🇻",
    "LY": "🇱🇾",

    "MA": "🇲🇦", "MC": "🇲🇨", "MD": "🇲🇩", "ME": "🇲🇪", "MF": "🇲🇫",
    "MG": "🇲🇬", "MH": "🇲🇭", "MK": "🇲🇰", "ML": "🇲🇱", "MM": "🇲🇲",
    "MN": "🇲🇳", "MO": "🇲🇴", "MP": "🇲🇵", "MQ": "🇲🇶", "MR": "🇲🇷",
    "MS": "🇲🇸", "MT": "🇲🇹", "MU": "🇲🇺", "MV": "🇲🇻", "MW": "🇲🇼",
    "MX": "🇲🇽", "MY": "🇲🇾", "MZ": "🇲🇿",

    "NA": "🇳🇦", "NC": "🇳🇨", "NE": "🇳🇪", "NF": "🇳🇫", "NG": "🇳🇬",
    "NI": "🇳🇮", "NL": "🇳🇱", "NO": "🇳🇴", "NP": "🇳🇵", "NR": "🇳🇷",
    "NU": "🇳🇺", "NZ": "🇳🇿",

    "OM": "🇴🇲",

    "PA": "🇵🇦", "PE": "🇵🇪", "PF": "🇵🇫", "PG": "🇵🇬", "PH": "🇵🇭",
    "PK": "🇵🇰", "PL": "🇵🇱", "PM": "🇵🇲", "PN": "🇵🇳", "PR": "🇵🇷",
    "PS": "🇵🇸", "PT": "🇵🇹", "PW": "🇵🇼", "PY": "🇵🇾",

    "QA": "🇶🇦",

    "RE": "🇷🇪", "RO": "🇷🇴", "RS": "🇷🇸", "RU": "🇷🇺", "RW": "🇷🇼",

    "SA": "🇸🇦", "SB": "🇸🇧", "SC": "🇸🇨", "SD": "🇸🇩", "SE": "🇸🇪",
    "SG": "🇸🇬", "SH": "🇸🇭", "SI": "🇸🇮", "SJ": "🇸🇯", "SK": "🇸🇰",
    "SL": "🇸🇱", "SM": "🇸🇲", "SN": "🇸🇳", "SO": "🇸🇴", "SR": "🇸🇷",
    "SS": "🇸🇸", "ST": "🇸🇹", "SV": "🇸🇻", "SX": "🇸🇽", "SY": "🇸🇾",
    "SZ": "🇸🇿",

    "TC": "🇹🇨", "TD": "🇹🇩", "TF": "🇹🇫", "TG": "🇹🇬", "TH": "🇹🇭",
    "TJ": "🇹🇯", "TK": "🇹🇰", "TL": "🇹🇱", "TM": "🇹🇲", "TN": "🇹🇳",
    "TO": "🇹🇴", "TR": "🇹🇷", "TT": "🇹🇹", "TV": "🇹🇻", "TW": "🇹🇼",
    "TZ": "🇹🇿",

    "UA": "🇺🇦", "UG": "🇺🇬", "UM": "🇺🇲", "US": "🇺🇸", "UY": "🇺🇾",
    "UZ": "🇺🇿",

    "VA": "🇻🇦", "VC": "🇻🇨", "VE": "🇻🇪", "VG": "🇻🇬", "VI": "🇻🇮",
    "VN": "🇻🇳", "VU": "🇻🇺",

    "WF": "🇼🇫", "WS": "🇼🇸",

    "YE": "🇾🇪", "YT": "🇾🇹",

    "ZA": "🇿🇦", "ZM": "🇿🇲", "ZW": "🇿🇼",
}
