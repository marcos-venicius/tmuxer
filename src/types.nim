import std/options

type
  Window* = object
    name*: Option[string] = none(string)
    path*: Option[string] = none(string)
    cmd*: Option[string] = none(string)

  Session* = object
    name*: Option[string] = none(string)
    windows*: seq[Window] = @[]