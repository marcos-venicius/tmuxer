import std/options

type
  PanelKind* = enum
    single, vertical, horizontal

  Panel* = ref object
    path*: Option[string] = none(string)
    cmd*: Option[string] = none(string)

    case kind*: PanelKind
      of PanelKind.single:
        discard
      of PanelKind.vertical:
        left*, right*: Panel
      of PanelKind.horizontal:
        top*, bottom*: Panel

  Window* = object
    name*: Option[string] = none(string)
    panel*: Panel

  Session* = object
    name*: Option[string] = none(string)
    windows*: seq[Window] = @[]