import os, std/options

const configFileName = ".tmuxer.txr"

proc getConfigFilePath*(): Option[string] =
  var dir = getCurrentDir()

  let path = joinPath(dir, configFileName)

  if fileExists(path):
    return some(path)

  while true:
    let (head, _) = splitPath(dir)

    if head == dir:
      break

    dir = head

    let path = joinPath(dir, configFileName)

    if fileExists(path):
      return some(path)

  return none(string)