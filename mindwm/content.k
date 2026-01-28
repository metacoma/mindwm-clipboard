import kando.schema as kando
import kando.utils as utils

schema File:
  name: str = path
  path: str
  content: str = None
  icon = lambda -> str {
    "📄"
  }

schema JsonFile(File):
  content: str = "json"
  icon = lambda -> str {
    "📄"
  }

schema YamlFile(File):
  content: str = "yaml"
  icon = lambda -> str {
    "📑"
  }

schema TextFile(File):
  content: str = "text"
  icon = lambda -> str {
    "📜"
  }

makeMenuExplore = lambda f : any -> [kando.Child] {
  [
      utils.makeCommand({
        name = "jless"
        icon = "👀"
        if (typeof(f) == "JsonFile"):
          cmd = utils.runTerminal("cat ${f.path} | jless")
        if (typeof(f) == "YamlFile"):
          cmd = utils.runTerminal("cat ${f.path} | yq | jless")
      })
      utils.makeCommand({
        name = "fx"
        icon = "🧠"
        if (typeof(f) == "JsonFile"):
          cmd = utils.runTerminal("cat ${f.path} | fx")
        if (typeof(f) == "YamlFile"):
          cmd = utils.runTerminal("cat ${f.path} | yq | fx")
      })
      utils.makeCommand({
        name = "visidata"
        icon = "📊"
        if (typeof(f) == "JsonFile"):
          cmd = utils.runTerminal("cat ${f.path} | vd")
        if (typeof(f) == "YamlFile"):
          cmd = utils.runTerminal("cat ${f.path} | yq | vd")
      })
      utils.makeCommand({
        name = "gron"
        icon = "🧩"
        if (typeof(f) == "JsonFile"):
          cmd = utils.runTerminal("cat ${f.path} | gron | less")
        if (typeof(f) == "YamlFile"):
          cmd = utils.runTerminal("cat ${f.path} | yq | gron | less")
      })
  ]
}


makeMenuJsonFile = lambda f : JsonFile -> kando.Child {
  utils.makeSubmenu({
    name = "JSON"
    icon = "📄"
    children = [
      utils.makeCommand({
        name = "as YAML"
        icon = "🧾"
        cmd = utils.runTerminal("sh -c 'cat ${f.path} | yq --yaml-output | less'")
      })
      utils.makeCommand({
        name = "as KCL"
        icon = "🧬"
        cmd = utils.runTerminal("sh -c '(cd /tmp; kcl import -m json --force ${f.path} -o /dev/stdout | less)'")
      })
      utils.makeCommand({
        name = "Prettyfy"
        icon = "🪄"
        cmd = utils.runTerminal("sh -c 'cat ${f.path} | jq | less'")
      })
      utils.makeSubmenu({
        name = "Explore"
        icon = "🔍"
        children = makeMenuExplore(f)
      })
    ]
  })
}

makeMenuYamlFile = lambda f : YamlFile -> kando.Child {
  utils.makeSubmenu({
    name = "YAML"
    icon = "📄"
    children = [
      utils.makeCommand({
        name = "as JSON"
        icon = "🧾"
        cmd = utils.runTerminal("cat ${f.path} | yq | less")
      })
      utils.makeCommand({
        name = "as KCL"
        icon = "🧬"
        cmd = utils.runTerminal("sh -c '(cd /tmp; kcl import -m yaml --force ${f.path} -o /dev/stdout | less)'")
      })
      utils.makeSubmenu({
        name = "Explore"
        icon = "🔍"
        children = makeMenuExplore(f)
      })
    ]
  })
}

makeMenuTextFile = lambda f : any -> kando.Child {
  utils.makeSubmenu({
    name = "Text"
    icon = f.icon()
    children = [
      utils.makeCommand({
        name = "as Mindmap(AI)"
        icon = "🗺️"
        cmd = utils.runTerminal("cat ${f.path} | /home/bebebeka/git/mindmap_llm_clipboard/stdin.sh")
      })
    ]
  })
}
