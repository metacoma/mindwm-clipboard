import mindwm.cmdb.schema as schema
import mindwm.cmdb.user as user
import kando.schema as kando

schema Team(schema.Object):
  memberNames?: [str]
  members: [user.User]

make = lambda obj: any, all_objects : any -> Team {
  Team {
    name = obj.name
    selfUrl = obj.selfUrl
    memberNames = obj.memberNames
    members = [
      user.make(member, all_objects)
      for member in obj.members
    ]
  }
}

makeMenu = lambda team : any -> kando.Child {
  kando.Child {
    name = team.name
    icon = "👥"
    children = [
    ] + [
      user.makeMenu(member)
      for member in team.members
    ]
  }
}
