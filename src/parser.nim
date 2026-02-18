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

proc incCursor() =
  if content[cursor] == '\n':
    line.inc()
    col = 1
  else:
    col.inc()

  cursor.inc()

proc logError(msg: string) =
  # Using the 'terminal' module is cleaner than raw ANSI escape codes
  # It automatically handles cases where the user's terminal doesn't support color
  let errorHeader = &"{configFileNamePath}:{line}:{col}: "
  
  stderr.write(errorHeader)
  styledWriteLine(stderr, fgRed, styleBright, "error: ", resetStyle, msg)
  
  quit(1)

proc expectChar(c: char, b: char) =
  if c != b:
    logError(&"expected '{b}' but got '{c}'")

proc isEmpty(): bool =
  return cursor >= size

proc isWhitespace(c: char): bool =
  return c in " \n\t"

proc isComment(c: char): bool =
  return c == '#'

proc isSymbol(c: char):  bool =
  return c >= 'a' and c <= 'z'

proc parseSymbol(): Option[string] =
  if isEmpty() or not isSymbol(content[cursor]):
    return none(string)
  
  while isSymbol(content[cursor]):
    incCursor()

  return some(content[bot..<cursor])

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

  return str

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
  
  return parseString()

proc parseVpanelProperty(): Panel =
  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing vpanel")

  expectChar(content[cursor], '{')

  incCursor()

  cleanUp()

  if isEmpty():
    logError("unexpected end of file while parsing vpanel")

  var left = Panel()
  var right = Panel()

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
        left = parsePanels(true)
      of "right":
        right = parsePanels(true)
      else:
        logError(&"was expecting symbol 'left' or 'right' but got unexpected '{symbol.get()}'")

    incCursor()

  Panel(
    kind: PanelKind.vertical,
    left: left,
    right: right
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

  var top = Panel()
  var bottom = Panel()

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
        top = parsePanels(true)
      of "bottom":
        bottom = parsePanels(true)
      else:
        logError(&"was expecting symbol 'top' or 'bottom' but got unexpected '{symbol.get()}'")

    incCursor()

  Panel(
    kind: PanelKind.horizontal,
    top: top,
    bottom: bottom
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

    let symbol = parseSymbol()

    if symbol.isNone:
      logError(&"was expecting symbol 'path' or 'cmd' but got unexpected character '{content[cursor]}'")

    case symbol.get():
      of "path":
        path = some(parseStringProperty())
      of "cmd":
        cmd = some(parseStringProperty())
      else:
        logError(&"was expecting symbol 'path' or 'cmd' but got unexpected character '{symbol.get()}'")

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
  
  let session = Session(name: name, windows: windows)

  sessions.add session

  incCursor()

proc parseConfigFile*(filepath: string): seq[Session] =
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

  return sessions