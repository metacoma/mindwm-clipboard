import mindwm.cmdb.schema as schema
import kando.utils as utils
import kando.schema as kando

schema Location(schema.Object):
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

make = lambda obj: any, all_objects : any -> DC {
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

makeMenu = lambda dc : any -> kando.Child {
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
        text = dc.location
        icon = "🗺️"
      })
      if dc.number:
        utils.showText({
          text = str(dc.number)
          icon = "🆔"
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
