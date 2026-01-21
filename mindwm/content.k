import kando.schema as kando
import kando.utils as utils

schema File:
  path: str
  content: str = None

schema JsonFile(File):
  content: str = "json"

schema YamlFile(File):
  content: str = "yaml"

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
        cmd = "gnome-terminal -- sh -c 'cat ${f.path} | yq --yaml-output | less'"
      })
      utils.makeCommand({
        name = "as KCL"
        icon = "🧬"
        cmd = "gnome-terminal -- sh -c '(cd /tmp; kcl import -m json --force ${f.path} -o /dev/stdout | less)'"
      })
      utils.makeCommand({
        name = "Prettyfy"
        icon = "🪄"
        cmd = "gnome-terminal -- sh -c 'cat ${f.path} | jq | less'"
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
        cmd = "gnome-terminal -- sh -c '(cd /tmp; kcl import -m yaml --force ${f.path} -o /dev/stdout | less)'"
      })
      utils.makeSubmenu({
        name = "Explore"
        icon = "🔍"
        children = makeMenuExplore(f)
      })
    ]
  })
}
