import std/options
import std/strformat
# locals
import parser
import arggetter
import configgetter
import actions

# Comes directly from the build
const NimblePkgVersion {.strdefine.} = "0.0.0"

let programName = shift().get()
var action: Option[string] = none(string)

proc showHelp(withError: bool) =
  stderr.writeLine(&"Usage: {programName} [options] <action>")
  stderr.writeLine("Actions:")
  stderr.writeLine("  up              - Start tmux sessions as defined in the config file")
  stderr.writeLine("  down            - Stop tmux sessions as defined in the config file")
  stderr.writeLine("  view            - Print the parsed configuration to the console")
  stderr.writeLine("Options:")
  stderr.writeLine("  -h, --help      - Show this help message")
  stderr.writeLine("  -v, --version   - Show current app version")
  quit(if withError: 1 else: 0)

while true:
  let arg = shift()

  if arg.isNone:
    break

  let value = arg.get()

  case value:
    of "--help", "-h":
      showHelp(false)
    of "--version", "-v":
      echo NimblePkgVersion
      quit(0)
    of "up", "down", "view":
      if action.isSome:
        stderr.writeLine("multiple actions specified. only one action can be performed at a time")
        quit(1)
      action = some(value)
    else:
      stderr.writeLine(&"""unexpected argument "{value}". expected 'up', "down', or 'view'""")
      quit(1)

if action.isNone:
  showHelp(true)

let configFilePath = getConfigFilePath()

if configFilePath.isNone:
  stderr.writeLine("no config file found. expected a .tmuxer.txr file in the current directory or any parent directory")
  quit(1)

let sessions = parseConfigFile(configFilePath.get())

case action.get():
  of "up":
    upAction(sessions)
  of "view":
    viewAction(sessions)
  of "down":
    downAction(sessions)
  else:
    stderr.writeLine(&"""unexpected action "{action.get()}". expected 'up', "down', or 'view'""")
    quit(1)
