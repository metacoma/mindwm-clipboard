import kando.schema as kando
import kando.utils as utils

schema TwitchClip:
  slug: str
  title: str
  createdAt: str
  viewCount: int
  durationSeconds: int
  url: str
  category: str
  broadcaster: str

makeMenuTwitchClip = lambda clip : any -> kando.Child {
  windows = []
  r = utils.makeSubmenu({
    name = clip.slug[0:24],
    icon = "🎬"
    children = [
      utils.makeCommand({
        name = "Download"
        icon = "💾"
        cmd = "gnome-terminal -- ~/bin/twitch-dl download -q source ${clip.slug}"
      })
      utils.makeSubmenu({
        name = clip.broadcaster
        icon = "🟣📺"
        children = [
          utils.makeURI({
            name = "profile"
            icon = "🧑‍💻"
            uri = "https://twitch.tv/${clip.broadcaster}"
          })
          utils.makeURI({
            name = "clips"
            icon = "✂️"
            uri = "https://www.twitch.tv/${clip.broadcaster}/clips?filter=clips&range=7d"
          })
        ]
      })
      utils.showText({
        name = "${clip.viewCount}"
        icon = "🧑‍🤝‍🧑"
        text = "${clip.viewCount}"
      })
      utils.showText({
        name = "${clip.durationSeconds}"
        icon = "⏱️"
        text = "${clip.durationSeconds}"
      })
      utils.showText({
        name = "${clip.category}"
        icon = "🎮"
        text = "${clip.category}"
      })
      utils.showText({
        name = "${clip.title}"
        icon = "🏷️"
        text = "${clip.title}"
      })
    ]
  })
  r
}
