import os
import std/strformat, std/options
from parser import Session, Window
import tmux

proc getSessionName(session: Session, index: int): string =
  return session.name.get(&"unamed-{index}")

proc getWindowName(window: Window, index: int): string =
  return window.name.get(&"unamed-{index}")

proc viewAction(sessions: seq[Session]) =
  for i, session in sessions.pairs:
    echo &"""Session: {getSessionName(session, i)}"""
    for j, window in session.windows.pairs:
      echo &"""  Window: {getWindowName(window, j)}"""
      echo &"""    Path: {window.path.get("N/A")}"""
      echo &"""    Cmd: {window.cmd.get("N/A")}"""

proc upAction(sessions: seq[Session]) =
  for i, session in sessions.pairs:
    let sessionName = getSessionName(session, i)

    echo &"""Creating session: {sessionName}"""

    var result = newSession(sessionName)

    if result != 0:
      echo &"""Failed to create session {sessionName} with exit code {result}"""
      continue
  
    for j, window in session.windows.pairs:
      let windowName = getWindowName(window, j)

      echo &"""  Creating window: {windowName}"""

      if j == 0:
        # the first window is created by default with the session, so we just need to rename it
        result = renameWindow(sessionName, "0", windowName)

        if result != 0:
          echo &"""Failed to rename default window to {windowName} in session {sessionName} with exit code {result}"""
          continue
      else:
        result = newWindow(sessionName, windowName)

        if result != 0:
          echo &"""Failed to create window {windowName} in session {sessionName} with exit code {result}"""
          continue
      
      if window.path.isSome:
        result = sendKeys(sessionName, windowName, &"cd {window.path.get()}")

        if result != 0:
          echo &"""Failed to set path for window {windowName} in session {sessionName} with exit code {result}"""
          continue
      
      if window.cmd.isSome:
        result = sendKeys(sessionName, windowName, window.cmd.get())

        if result != 0:
          echo &"""Failed to set cmd for window {windowName} in session {sessionName} with exit code {result}"""
          continue

      result = sendKeys(sessionName, windowName, "clear")

      if result != 0:
        echo &"""Failed to clear terminal for window {windowName} in session {sessionName} with exit code {result}"""
        continue

      result = clearHistory(sessionName, windowName)

      if result != 0:
        echo &"""Failed to clear history for window {windowName} in session {sessionName} with exit code {result}"""
        continue

proc downAction(sessions: seq[Session]) =
  for i, session in sessions.pairs:
    let sessionName = getSessionName(session, i)

    echo &"""Killing session: {sessionName}"""

    let result = killSession(sessionName)

    if result != 0:
      echo &"""Failed to kill session {sessionName} with exit code {result}"""

export viewAction, upAction, downAction
