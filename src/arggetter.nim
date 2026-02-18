import os, std/options

let argc = paramCount()
var argi = 0

proc shift*(): Option[string] =
  if argi > argc:
    return none(string)
  
  let arg = paramStr(argi)

  argi.inc()

  return some(arg)