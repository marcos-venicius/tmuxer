import std/[options, strformat, strutils, terminal, os]

import types

proc parsePanels(parseProlog: bool): Panel

var sessions: seq[Session] = @[]

var configFileNamePath: string = ""
var content: string = ""
var size: Natural = 0
var bot: Natural = 0
var cursor: Natural = 0
var line: Natural = 1
var col: Natural = 1
var hintsEnabled = false
var infosEnabled = true

proc cacheLocation(): tuple[line: Natural, col: Natural] =
  (line, col)

proc incCursor() =
  if content[cursor] == '\n':
    line.inc()
    col = 1
  else:
    col.inc()

  cursor.inc()

proc padReplacer(location: string, label: string, message: string): string =
  let pad = repeat(' ', len(location) + len(label))
  message.replace("@{pad}", pad)

proc logError(msg: string) =
  # Using the 'terminal' module is cleaner than raw ANSI escape codes
  # It automatically handles cases where the user's terminal doesn't support color
  let errorHeader = &"{configFileNamePath}:{line}:{col}: "
  let label = "error: "
  
  stderr.write(errorHeader)
  styledWriteLine(stderr, fgRed, styleBright, label, resetStyle, padReplacer(errorHeader, label, msg))
  
  quit(1)

proc logInfo(msg: string) =
  if not infosEnabled:
    return

  # Using the 'terminal' module is cleaner than raw ANSI escape codes
  # It automatically handles cases where the user's terminal doesn't support color
  let errorHeader = &"{configFileNamePath}:{line}:{col}: "
  let label = "info: "
  
  stderr.write(errorHeader)
  styledWriteLine(stderr, fgBlue, styleBright, label, resetStyle, padReplacer(errorHeader, label, msg))

proc logHint(msg: string) =
  if not hintsEnabled:
    return
  # Using the 'terminal' module is cleaner than raw ANSI escape codes
  # It automatically handles cases where the user's terminal doesn't support color
  let errorHeader = &"{configFileNamePath}:{line}:{col}: "
  let label = "hint: "
  
  stderr.write(errorHeader)
  styledWriteLine(stderr, fgGreen, styleBright, label, resetStyle, padReplacer(errorHeader, label, msg))

proc expectChar(c: char, b: char) =
  if c != b:
    logError(&"expected '{b}' but got '{c}'")

proc isEmpty(): bool =
  cursor >= size

proc isWhitespace(c: char): bool =
  c in " \n\t"

proc isComment(c: char): bool =
  c == '#'

proc isSymbol(c: char):  bool =
  c >= 'a' and c <= 'z'

proc parseSymbol(): Option[string] =
  if isEmpty() or not isSymbol(content[cursor]):
    return none(string)
  
  while isSymbol(content[cursor]):
    incCursor()

  some(content[bot..<cursor])

proc parseWhitespaces() =
  while not isEmpty() and isWhitespace(content[cursor]):
    incCursor()

proc parseComments() =
  if not isEmpty() and isComment(content[cursor]):
    while not isEmpty() and content[cursor] != '\n':
      incCursor()

proc parseString(): string =
  if isEmpty():
    logError("unexpected end of file while parsing string")

  expectChar(content[cursor], '"')

  incCursor()

  bot = cursor

  while not isEmpty() and content[cursor] != '"':
    incCursor()

  if isEmpty():
    logError("unexpected end of file while parsing string")

  let str = content[bot..<cursor]

  incCursor()

  str

proc cleanUp() =
  while not isEmpty():
    if isWhitespace(content[cursor]):
      parseWhitespaces()
    elif isComment(content[cursor]):
      parseComments()
    else:
      break

proc parseStringProperty(): string =
  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing session name")

  expectChar(content[cursor], '=')

  incCursor()

  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing session name")

  bot = cursor
  
  parseString()

proc parseVpanelProperty(): Panel =
  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing vpanel")

  expectChar(content[cursor], '{')

  incCursor()

  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing vpanel")

  var left: Option[Panel] = none(Panel)
  var right: Option[Panel] = none(Panel)

  while not isEmpty():
    cleanUp()

    if isEmpty():
      logError("unexpected end of file while parsing vpanel")

    bot = cursor

    if content[cursor] == '}':
      break

    let symbol = parseSymbol()

    if symbol.isNone:
      logError(&"was expecting symbol 'left' or 'right' but got unexpected character '{content[cursor]}'")
    
    case symbol.get():
      of "left":
        left = some(parsePanels(true))
      of "right":
        right = some(parsePanels(true))
      else:
        logError(&"was expecting symbol 'left' or 'right' but got unexpected '{symbol.get()}'")

    incCursor()
  
  if left.isNone:
    logHint("you can specify a left panel for your vpanel by adding a 'left' property to it")
    left = some(Panel(kind: PanelKind.single))
  
  if right.isNone:
    logHint("you can specify a right panel for your vpanel by adding a 'right' property to it")
    right = some(Panel(kind: PanelKind.single))

  Panel(
    kind: PanelKind.vertical,
    left: left.get(),
    right: right.get()
  )

proc parseHpanelProperty(): Panel =
  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing hpanel")

  expectChar(content[cursor], '{')

  incCursor()

  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing hpanel")

  var top: Option[Panel] = none(Panel)
  var bottom: Option[Panel] = none(Panel)

  while not isEmpty():
    cleanUp()

    if isEmpty():
      logError("unexpected end of file while parsing hpanel")

    bot = cursor

    if content[cursor] == '}':
      break

    let symbol = parseSymbol()

    if symbol.isNone:
      logError(&"was expecting symbol 'top' or 'bottom' but got unexpected character '{content[cursor]}'")
    
    case symbol.get():
      of "top":
        top = some(parsePanels(true))
      of "bottom":
        bottom = some(parsePanels(true))
      else:
        logError(&"was expecting symbol 'top' or 'bottom' but got unexpected '{symbol.get()}'")

    incCursor()

  if top.isNone:
    logHint("you can specify a top panel for your hpanel by adding a 'top' property to it")
    top = some(Panel(kind: PanelKind.single))
  
  if bottom.isNone:
    logHint("you can specify a bottom panel for your hpanel by adding a 'bottom' property to it")
    bottom = some(Panel(kind: PanelKind.single))

  Panel(
    kind: PanelKind.horizontal,
    top: top.get(),
    bottom: bottom.get()
  )

proc parsePanelProperty(): Panel =
  cleanUp()

  expectChar(content[cursor], '{')

  incCursor()

  var path: Option[string] = none(string)
  var cmd: Option[string] = none(string)

  while not isEmpty():
    cleanUp()

    if isEmpty():
      logError("unexpected end of file while parsing panel")
    
    bot = cursor

    if content[cursor] == '}':
      break

    let (pastLineCache, pastColCache) = cacheLocation()

    let symbol = parseSymbol()

    if symbol.isNone:
      logError(&"was expecting symbol 'path' or 'cmd' but got unexpected character '{content[cursor]}'")

    case symbol.get():
      of "path":
        path = some(parseStringProperty())

        let (postLineCache, postColCache) = cacheLocation()

        line = pastLineCache
        col = pastColCache

        let expandedPath = absolutePath(expandTilde(path.get()))

        if not dirExists(expandedPath):
          if expandedPath.startsWith(" ") or expandedPath.endsWith(" "):
            logError("this path does not exists or is not a valid folder. this path has leading or trailing whitespace check if ins't that the problem")
          else:
            logError("this path does not exists or is not a valid folder")

        line = postLineCache
        col = postColCache
      of "cmd":
        cmd = some(parseStringProperty())
      else:
        logError(&"was expecting symbol 'path' or 'cmd' but got unexpected character '{symbol.get()}'")

  if path.isNone:
    logHint("you can specify where your panel will start by adding a 'path' property to it")
  
  if cmd.isNone:
    logHint("you can specify a command to run in your panel by adding a 'cmd' property to it")

  Panel(kind: PanelKind.single, path: path, cmd: cmd)


proc parsePanels(parseProlog: bool): Panel =
  if parseProlog:
    cleanUp()

    expectChar(content[cursor], '{')

    incCursor()

    cleanUp()

    if isEmpty():
      logError("unexpected end of file while parsing panels")

  var panel: Option[Panel] = none(Panel)

  while not isEmpty():
    cleanUp()

    if isEmpty():
      logError("unexpected end of file while parsing panel")

    if content[cursor] == '}':
      break
  
    bot = cursor

    let symbol = parseSymbol()

    if symbol.isNone:
      logError(&"was expecting symbol 'panel', 'vpanel' or 'hpanel' but got unexpected character '{content[cursor]}'")
    
    case symbol.get():
      of "panel":
        panel = some(parsePanelProperty())
      of "vpanel":
        panel = some(parseVpanelProperty())
      of "hpanel":
        panel = some(parseHpanelProperty())
      else:
        logError(&"was expecting symbol 'panel', 'vpanel' or 'hpanel' but got unexpected '{content[cursor]}'")

    incCursor()

  if panel.isNone:
    if parseProlog:
      logHint("you can specify a panel for your split pane by adding a 'panel', 'vpanel' or an 'hpanel' block to it")
    else:
      logHint("you can specify a panel for your window by adding a 'panel', 'vpanel' or an 'hpanel' block to it")

    return Panel(kind: PanelKind.single)

  panel.get()


proc parseWindow(): Window =
  cleanUp()

  expectChar(content[cursor], '{')

  incCursor()

  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing window")
  
  var name: Option[string] = none(string)

  while not isEmpty():
    cleanUp()

    if isEmpty():
      logError("unexpected end of file while parsing window")

    bot = cursor

    if content[cursor] == '}':
      break

    let symbol = parseSymbol()

    if symbol.isNone:
      logError(&"was expecting symbol 'name', 'path' or 'cmd' but got unexpected character '{content[cursor]}'")
   
    case symbol.get():
      of "name":
        let value = parseStringProperty()

        if value.contains(".") or value.contains(":"):
          logError(&"window name '{value}' cannot contain '.' or ':' characters")

        name = some(value)

        break
      else:
        break

  if name.isNone:
    cursor = bot

    logHint("you can name your window by adding a 'name' property to it")

  let panel = parsePanels(false)

  incCursor()

  Window(name: name, panel: panel)

proc parseSession() =
  cleanUp()

  expectChar(content[cursor], '{')

  incCursor()

  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing session")

  var name: Option[string] = none(string)
  var windows: seq[Window] = @[]

  while not isEmpty():
    cleanUp()

    if isEmpty():
      logError("unexpected end of file while parsing session")

    bot = cursor

    if content[cursor] == '}':
      break

    let symbol = parseSymbol()

    if symbol.isNone:
      logError(&"was expecting symbol 'name' or 'window' but got unexpected character '{content[cursor]}'")
   
    case symbol.get():
      of "name":
        let value = parseStringProperty()
        name = some(value)

        if value.contains(".") or value.contains(":"):
          logError(&"session name '{value}' cannot contain '.' or ':' characters")
      of "window":
        windows.add parseWindow()
      else:
        logError(&"was expecting symbol 'name' or 'window' but got unexpected symbol '{symbol.get()}'")
  
  if name.isNone:
    logHint("you can name your session by adding a 'name' property to it")
  
  if windows.len == 0:
    logHint("you can add windows to your session by adding 'window' blocks to it")

  let session = Session(name: name, windows: windows)

  sessions.add session

  incCursor()

proc parseConfigFile*(filepath: string, enableHints: bool, enableInfos: bool): seq[Session] =
  hintsEnabled = enableHints
  infosEnabled = enableInfos

  configFileNamePath = relativePath(filepath, ".")

  content = readFile(filepath)
  size = content.len

  while not isEmpty():
    cleanUp()
    
    if isEmpty():
      break

    bot = cursor

    let symbol = parseSymbol()

    if symbol.isSome:
      case symbol.get():
        of "session":
          parseSession()
        else:
          logError(&"was expecting symbol 'session' but got unexpected symbol '{symbol.get()}'")
    else:
      logError(&"was expecting symbol 'session' but got unexpected character '{content[cursor]}'")

    incCursor()

  if sessions.len == 0:
    logInfo("your configuration file is empty")
    logHint("here is an example of a simple config:\n@{pad}session {\n  @{pad}name = \"my-session\"\n  @{pad}window {\n    @{pad}name = \"my-window\"\n    @{pad}panel {\n      @{pad}path = \"~/\"\n      @{pad}cmd = \"htop\"\n    @{pad}}\n  @{pad}}\n@{pad}}")

  sessions
