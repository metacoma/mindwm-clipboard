__kando_version = "2.2.0-beta.1"

__defaults = {
  iconTheme = "material-symbols-rounded"
  icon = "award_star"
  "type" = "submenu"
}

schema Config:
  version: str = __kando_version
  menus: [Menu]
  collections: any

schema Menu:
  shortcut?: str = "Control+Space"
  shortcutID?: str = "IP"
  centered?: bool = False
  anchored?: bool = False
  hoverMode?: bool = False
  conditions?: {str:str}
  tags?: [str]
  root: Child

schema Child:
  "type": str = __defaults.type
  name: str
  icon?: str = __defaults.icon
  iconTheme?: str = __defaults.iconTheme
  children?: [Child]

schema Submenu(Child):
  "type": str = "submenu"

schema CommandData:
  command: str
  detached?: bool = False
  isolated?: bool = False
  delayed?: bool = True


schema Command(Child):
  "type": str = "command"
  data: CommandData

schema TextData:
  text: str

schema Text(Child):
  "type": str = "text"
  data: TextData
