import .schema as kando
import config as config
import file
import base64
import kando.images as images
import regex

schema SubMenuArgs:
  name: str
  icon?: str = "🕸️"
  children: [kando.Child]

makeSubmenu = lambda args : SubMenuArgs -> kando.Child {
  {
    type = "submenu"
    name = args.name
    icon = args.icon
    "children" = args.children
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
    cmd = "echo ${text} | /home/bebebeka/spaces/mindwm/clipboard/bin/copy_action.sh"
    icon = "📋"
  })
}

makeIcon = lambda icon : str -> str {
  "data:image/png;base64," + icon
}

makeInsertAction = lambda args : any -> kando.Command {
  makeCommand({
    if args.name:
      name = args.name
    else:
      name = "Insert"
    if args.icon:
      icon = args.icon
    else:
      icon = "⤵️"
    cmd = "xdotool type \"${args.text}\""
  })
}

showEmoji = lambda title : str, emoji  : str -> kando.Command {
  makeCommand({
    name = title
    cmd = ""
    icon = emoji
  })
}

showText = lambda args : any -> kando.Child {
  makeSubmenu({
    name = args.text
    icon = args.icon
    children = [
      makeCopyAction(args.text)
      makeInsertAction({ text = args.text })
    ]
  })
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
  run_cmd = "xterm -u8 -fa 'JetBrains Mono' -fs 11      -bg '#1e1e1e' -fg '#d4d4d4'   -xrm 'XTerm*termName: xterm-256color' -e sh -c '${cmd}'"
  if (config.terminal == "gnome-terminal"):
    run_cmd = "gnome-terminal -- sh -c '${cmd}'"
  run_cmd
}


makeTelegramContact = lambda args : any -> kando.Uri {
  kando.Uri {
    name = args.name
    icon = makeIcon(images.TELEGRAM)
    data.uri = "https://t.me/{args.telegram}"
  }
}

makeJiraUrl = lambda args : any -> kando.Uri {
  kando.Uri {
    name = args.name
    icon = makeIcon(images.JIRA)
    data.uri = args.url
  }
}

operatingSystemIcon = lambda os : str -> str {
    icon = None
    if os == "Windows":
      icon = makeIcon(images.windows)
    if os == "Linux":
      icon = makeIcon(images.linux)
    if os == "FortiOS":
      icon = makeIcon(images.fortios)
    str(icon)

}


showOperatingSystem = lambda name : str -> kando.Text {
  kando.Text {
    name = name
    icon = operatingSystemIcon(name)
    data.text = name
  }
}

makeServiceIcon = lambda service : str -> str {
  icon = "⚙️"
  #if regex.match(service, "PostgreSQL"):
  if (service == "PostgreSQL"):
    icon = makeIcon(images.POSTGRESQL)
  icon
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
