import std/options, std/strformat

type
  Window = object
    name: Option[string] = none(string)
    path: Option[string] = none(string)
    cmd: Option[string] = none(string)

type
  Session = object
    name: Option[string] = none(string)
    windows: seq[Window] = @[]

let content = readFile("./config.txr")

var sessions: seq[Session] = @[]

var cursor: Natural = 0
var bot: Natural = 0
let size = content.len

proc expectChar(c: char, b: char) =
  if c != b:
    stderr.writeLine(&"""expected "{c}" but got "{b}" at position {cursor}""")
    quit(1)

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
    cursor.inc()

  return some(content[bot..<cursor])

proc parseWhitespaces() =
  while not isEmpty() and isWhitespace(content[cursor]):
    cursor.inc()

proc parseComments() =
  if not isEmpty() and isComment(content[cursor]):
    while not isEmpty() and content[cursor] != '\n':
      cursor.inc()

proc parseString(): string =
  if isEmpty():
    stderr.writeLine("unexpected end of file while parsing string")
    quit(1)

  expectChar(content[cursor], '"')

  cursor.inc()

  bot = cursor

  while not isEmpty() and content[cursor] != '"':
    cursor.inc()

  if isEmpty():
    stderr.writeLine("unexpected end of file while parsing string")
    quit(1)

  let str = content[bot..<cursor]

  cursor.inc()

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
    stderr.writeLine("unexpected end of file while parsing session name")
    quit(1)

  expectChar(content[cursor], '=')

  cursor.inc()

  cleanUp()

  if isEmpty():
    stderr.writeLine("unexpected end of file while parsing session name")
    quit(1)

  bot = cursor
  
  return parseString()


proc parseWindow(): Window =
  cleanUp()

  expectChar(content[cursor], '{')

  cursor.inc()

  cleanUp()

  if isEmpty():
    stderr.writeLine("unexpected end of file while parsing window")
    quit(1)
  
  var name: Option[string] = none(string)
  var path: Option[string] = none(string)
  var cmd: Option[string] = none(string)

  while not isEmpty():
    cleanUp()

    if isEmpty():
      stderr.writeLine("unexpected end of file while parsing window")
      quit(1)

    bot = cursor

    if content[cursor] == '}':
      break

    let symbol = parseSymbol()

    if symbol.isNone:
      stderr.writeLine(&"""unexpected token "{content[cursor]}" at position {cursor}. expected 'name', 'path' or 'cmd'""")
      quit(1)
   
    case symbol.get():
      of "name":
        name = some(parseStringProperty())
      of "path":
        path = some(parseStringProperty())
      of "cmd":
        cmd = some(parseStringProperty())
      else:
        stderr.writeLine(&"""unexpected symbol "{symbol.get()}" at position {bot}. expected 'name', 'path' or 'cmd'""")
        quit(1)

  cursor.inc()

  return Window(name: name, path: path, cmd: cmd)

proc parseSession() =
  cleanUp()

  expectChar(content[cursor], '{')

  cursor.inc()

  cleanUp()

  if isEmpty():
    stderr.writeLine("unexpected end of file while parsing session")
    quit(1)
  

  var name: Option[string] = none(string)
  var windows: seq[Window] = @[]

  while not isEmpty():
    cleanUp()

    if isEmpty():
      stderr.writeLine("unexpected end of file while parsing session")
      quit(1)

    bot = cursor

    if content[cursor] == '}':
      break

    let symbol = parseSymbol()

    if symbol.isNone:
      stderr.writeLine(&"""unexpected token "{content[cursor]}" at position {cursor}. expected 'name' or 'window'""")
      quit(1)
   
    case symbol.get():
      of "name":
        name = some(parseStringProperty())
      of "window":
        windows.add parseWindow()
      else:
        stderr.writeLine(&"""unexpected symbol "{symbol.get()}" at position {bot}. expected 'name' or 'window'""")
        quit(1)
  
  let session = Session(name: name, windows: windows)

  sessions.add session

  cursor.inc()


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
        stderr.writeLine(&"""unexpected symbol "{symbol.get()}" at position {bot}. expected 'session'""")
        quit(1)
  else:
    stderr.writeLine(&"""unexpected token "{content[cursor]}" at position {cursor}. expected 'session'""")
    quit(1)

  cursor.inc()