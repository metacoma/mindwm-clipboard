import kando.schema as kando
import kando.utils as utils

schema TwitchStreamer:
  name: str = broadcaster
  broadcaster: str

schema TwitchClip(TwitchStreamer):
  name: str = slug
  slug: str
  title: str
  createdAt: str
  viewCount: int
  durationSeconds: int
  url: str
  category: str
  broadcaster: str

makeMenuTwitchStreamer = lambda streamer : any -> kando.Child {
      utils.makeSubmenu({
        name = streamer.broadcaster
        icon = "🟣📺"
        children = [
          utils.makeURI({
            name = "profile"
            icon = "🧑‍💻"
            uri = "https://twitch.tv/${streamer.broadcaster}"
          })
          utils.makeSubmenu({
            name = "clips"
            icon = "✂️"
            children = [
              utils.makeURI({
                name = "24h"
                icon = "🕒"
                uri = "https://www.twitch.tv/${streamer.broadcaster}/clips?filter=clips&range=24h"
              })
              utils.makeURI({
                name = "7d"
                icon = "📅"
                uri = "https://www.twitch.tv/${streamer.broadcaster}/clips?filter=clips&range=7d"
              })
              utils.makeURI({
                name = "🗓"
                uri = "https://www.twitch.tv/${streamer.broadcaster}/clips?filter=clips&range=30d"
              })
              utils.makeURI({
                name = "All"
                icon = "📚"
                uri = "https://www.twitch.tv/${streamer.broadcaster}/clips?filter=clips&range=all"
              })
            ]
          })
        ]
      })
}

makeMenuTwitchClip = lambda clip : any -> kando.Child {
  r = utils.makeSubmenu({
    name = clip.slug[0:24],
    icon = "🎬"
    children = [
      utils.makeCommand({
        name = "Download"
        icon = "💾"
        cmd = utils.runTerminal("~/bin/twitch-dl download -q source ${clip.slug}")
      })
      utils.makeSubmenu({
        name = clip.broadcaster
        icon = "🟣📺"
        children = [makeMenuTwitchStreamer(clip)]
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
