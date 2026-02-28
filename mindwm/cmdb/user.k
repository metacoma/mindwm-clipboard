import mindwm.cmdb.schema as schema
import kando.schema as kando
import kando.utils as utils
import kando.images as images

schema User(schema.Object):
  jiraProfile: str
  avatar: str
  phone?: str
  telegram?: str
  head?: [User]

make = lambda obj: any, all_objects : any -> User {
  User {
    name = obj.name
    selfUrl = obj.selfUrl
    avatar = obj.avatar
    phone = obj.phone
    telegram = obj.telegram
    jiraProfile = obj.jiraProfile
    head = [
      make(user_head)
      for user_head in obj.head
    ]
  }
}

makeMenu = lambda user : any -> kando.Child {
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
          text = user.phone
          icon = "☎️"
        })
      utils.makeJiraUrl({
        name = "Profile"
        url = user.jiraProfile
      })
      utils.makeInsertAction({
        name = "Slack"
        icon = utils.makeIcon(images.SLACK)
        text = "@" + user.name
      })
    ] + [
      makeMenu(user_head)
      for user_head in user.head
    ]
  }
}
