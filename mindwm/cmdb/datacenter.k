import mindwm.cmdb.schema as schema
import kando.utils as utils
import kando.schema as kando
import kando.images as images
import regex

schema Location(schema.Object):
  status?: str
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
    if country == "Armenia":
      i = utils.country_icon("AM")
    if country == "Cyprus":
      i = utils.country_icon("CY")
    if country == "Kazakhstan":
      i = utils.country_icon("KZ")
    if country == "Belarus":
      i = utils.country_icon("BY")
    if country == "Greece":
      i = utils.country_icon("GR")
    if location and location == "Cloud":
      i = utils.makeIcon(images.COMPUTE_CLOUD)
    i
  }

make = lambda obj: any, all_objects : any -> DC {
  DC {
    selfUrl = obj.selfUrl
    name = obj.name
    if obj.status:
      status = obj.status
    if obj.location:
      location = obj.location
    if obj.country:
      country = obj.country
    if obj.location:
      if regex.match(obj.location, "(Ереван|Yerevan|Armenia).*") or name == "SAD":
        country = "Armenia"
      if regex.match(obj.location, ".*(Moskva|Москва|Sankt-Peterburg).*"):
        country = "Russia"
      if regex.match(obj.location, ".*(NICOSIA).*"):
        country = "Cyprus"
      if regex.match(obj.location, ".*(Minsk|Belarus).*"):
        country = "Belarus"
      if regex.match(obj.location, ".*(Grieķija).*"):
        country = "Greece"
    if obj.locType and obj.locType == "Cloud":
      location = "Cloud"
    if name == "KZS":
      country = "Kazakhstan"
    if obj.number:
      number = obj.number
    if obj.documentation:
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
      if dc.location:
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
