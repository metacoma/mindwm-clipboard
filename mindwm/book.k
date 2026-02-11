import kando.schema as kando
import kando.utils as utils

schema Book:
  name: str
  icon = lambda -> str {
    "📖"
  }

make = lambda obj: any, all_objects: any -> Book {
  Book {
    name = obj.name
  }
}

makeMenu = lambda book : any -> kando.Child {
  kando.Child {
    name = book.name
    icon = book.icon()
    children = [
      utils.makeCommand({
        name = "GoodReads"
        cmd = "xdg-open https://www.goodreads.com/search?q='${book.name}'"
        icon = "📗"
      })
      utils.makeCommand({
        name = "fb2"
        cmd = "xdg-open 'https://google.com/search?q=${book.name} fb2'"
        icon = "📥"
      })
    ]
  }
}
