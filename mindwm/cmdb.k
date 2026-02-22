import kando.schema as kando
import kando.utils as utils
import kando.images as images
import mindwm.ipv4 as ipv4

schema Object:
  name: str
  created?: str
  updated?: str
  selfUrl: str
  #links: {str:str}
  icon = lambda -> str {
    "🗃️"
  }

schema Location(Object):
  status: str
  location?: str
  country?: str
  number?: int
  icon = lambda -> str {
    "🗺️"
  }

schema DC(Location):
  documentation?: str
  icon = lambda -> str {
    i = "🗄️"
    if country == "Latvia":
      i = utils.country_icon("LV")
    if country == "Germany":
      i = utils.country_icon("DE")
    if country == "Netherlands":
      i = utils.country_icon("NL")
    if country == "Russia":
      i = utils.country_icon("RU")
    i
  }

makeDC = lambda obj: any, all_objects : any -> DC {
  DC {
    selfUrl = obj.selfUrl
    name = obj.name
    status = obj.status
    location = obj.location
    country = obj.country
    if obj.number:
      number = obj.number
    documentation = obj.documentation
  }
}

makeDCMenu = lambda dc : any -> kando.Child {
  kando.Child {
    name = dc.name
    icon = dc.icon()
    children = [
      utils.makeURI({
        name = "Jira"
        icon = "🧩"
        uri = dc.selfUrl
      })
      utils.showText({
        name = dc.location
        icon = "🗺️"
        text = ""
      })
      if dc.number:
        utils.showText({
          name = str(dc.number)
          icon = "🆔"
          text = ""
        })
      if dc.documentation:
        utils.makeURI({
          name = "Документация"
          icon = "🗂️"
          uri = dc.documentation
        })
    ]
  }
}


schema User(Object):
  jiraProfile: str
  avatar: str
  phone?: str
  telegram?: str
  head?: [User]

makeUser = lambda obj: any, all_objects : any -> User {
  User {
    name = obj.name
    selfUrl = obj.selfUrl
    avatar = obj.avatar
    phone = obj.phone
    telegram = obj.telegram
    jiraProfile = obj.jiraProfile
    #if obj.head:
    head = [
      makeUser(user_head)
      for user_head in obj.head
    ]
  }
}

makeUserMenu = lambda user : any -> kando.Child {
  kando.Child {
    name = user.name
    icon = user.avatar
    children = [
      if user.telegram:
        utils.makeTelegramContact({
          name = user.telegram
          telegram = user.telegram
        })
      if user.phone:
        utils.showText({
          name = user.phone
          icon = "☎️"
          text = ""
        })
      utils.makeJiraUrl({
        name = "Profile"
        url = user.jiraProfile
      })
    ] + [
      makeUserMenu(user_head)
      for user_head in user.head
    ]
  }
}





schema Team(Object):
  memberNames?: [str]
  members: [User]

makeTeam = lambda obj: any, all_objects : any -> Team {
  Team {
    name = obj.name
    selfUrl = obj.selfUrl
    memberNames = obj.memberNames
    members = [
      makeUser(member, all_objects)
      for member in obj.members
    ]
  }
}

makeTeamMenu = lambda team : any -> kando.Child {
  kando.Child {
    name = team.name
    icon = "👥"
    children = [
    ] + [
      makeUserMenu(member)
      for member in team.members
    ]
  }
}


schema Host(Object):
  dc?: DC
  networkInterface?: [ipv4.Ip4] = []
  team?: Team
  owner?: User
  os?: str
  service?: str
  vipIp?: ipv4.Ip4
  icon = lambda -> str {
    utils.operatingSystemIcon(os)
  }

makeHost = lambda obj: any, all_objects : any -> Host {
  Host {
    name = obj.name
    selfUrl = obj.selfUrl
    if obj.location:
      dc = makeDC(obj.location, all_objects)
    if obj.networkInterface:
      if typeof(obj.networkInterface) == "str":
        networkInterface = [
          ipv4.make(all_objects["Ip ${obj.networkInterface}"]["ip4"][0])
        ]
      # if typeof(obj.networkInterface) == list:
      #   networkInterface = [
      #   ipv4.make(all_objects["Ip ${ip.ip}"]["ip4"][0])
      #   for ip in obj.networkInterface
      # ]

    if obj.owner:
      owner = makeUser(obj.owner, all_objects)
    os = obj.os
    service = obj.service
    if obj.vipIp:
      vipIp = ipv4.make(all_objects["Ip ${obj.vipIp}"]["ip4"][0])
    team = obj.team
  }
}

makeHostMenu = lambda host : any -> kando.Child {
  kando.Child {
    name = host.name
    icon = utils.operatingSystemIcon(host.os)
    children = [
      utils.makeURI({
        name = "Jira"
        icon = "🧩"
        uri = host.selfUrl
      })
      if host.vipIp:
        utils.makeSubmenu({
          name = "VIP: ${host.vipIp.ip}"
          icon = host.vipIp.icon()

          children = ipv4.makeMenu(host.vipIp).children
        })
      if host.team:
        utils.makeSubmenu({
          name = host.team.name
          icon = "👥"
          children = makeTeamMenu(host.team).children
        })
      if host.dc:
        utils.makeSubmenu({
          name = host.dc.name
          icon = host.dc.icon()
          children = makeDCMenu(host.dc).children
        })
      if host.owner:
        utils.makeSubmenu({
          name = host.owner.name
          icon = host.owner.avatar
          children = makeUserMenu(host.owner).children
        })
      # if host.os:
      #   utils.showOperatingSystem(host.os)
      if host.service:
        utils.showText({
          name = host.service
          icon = "⚙️"
          text = ""
        })
    ] + [
        # utils.showText({
        #   name = iface
        #   icon = utils.makeIcon(images.IP)
        #   text = ""
        # })
        utils.makeSubmenu({
          name = ip.ip
          icon = ip.icon()
          children = ipv4.makeMenu(ip).children
        })
        for ip in host.networkInterface
    ]
  }
}

schema SanRackSwitch(Object):
  dc?: DC
  networkInterface?: [ipv4.Ip4] = []
  team?: Team
  owner?: User
  serial?: str
  rack_id?: str
  model?: str
  icon = lambda -> str {
    "⚙️"
  }

makeSanRackSwitch = lambda obj: any, all_objects : any -> SanRackSwitch {
  SanRackSwitch {
    name = obj.name
    selfUrl = obj.selfUrl
    if obj.location:
      dc = makeDC(obj.location, all_objects)
    if obj.networkInterface:
      networkInterface = [
        if "Ip {ip}" in all_objects:
          ipv4.make(all_objects["Ip ${ip.ip}"]["ip4"][0])
        else:
          ipv4.make({
            name = ip
          })
        for ip in obj.networkInterface
      ]

    if obj.owner:
      owner = makeUser(obj.owner, all_objects)
    team = obj.team
  }
}
