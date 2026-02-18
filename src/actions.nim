import std/[strformat, options, terminal]
import tmux
import types

proc getSessionName(session: Session, index: int): string =
  return session.name.get(&"unamed-{index}")

proc getWindowName(window: Window, index: int): string =
  return window.name.get(&"unamed-{index}")

proc viewAction*(sessions: seq[Session]) =
  for i, session in sessions.pairs:
    # Add a newline between sessions for clarity, but not after the last one
    if i > 0:
      echo ""

    # Print Session (Root)
    styledWriteLine(stdout, fgBlue, styleBright, getSessionName(session, i), resetStyle)

    for j, window in session.windows.pairs:
      # Check if this is the last window in the session
      let isLastWindow = j == session.windows.len - 1
      let connector = if isLastWindow: "└── " else: "├── "
      let pipe = if isLastWindow: "    " else: "│   "

      # Print Window
      stdout.write(&"  {connector}")

      styledWrite(stdout, fgGreen, styleBright, getWindowName(window, j), resetStyle)

      case window.panel.kind:
        of PanelKind.single:
          echo ""
          # Print Window Details (Path/Cmd)
          if window.panel.path.isSome:
            echo &"  {pipe}  path: {window.panel.path.get()}"
          if window.panel.cmd.isSome:
            echo &"  {pipe}  cmd:  {window.panel.cmd.get()}"
        of PanelKind.vertical:
          echo " *V"
        of PanelKind.horizontal:
          echo " *H"
      if not isLastWindow:
        echo &"  {pipe}"

proc upAction*(sessions: seq[Session]) =
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
      
      case window.panel.kind:
        of PanelKind.single: # extract this code to a proc
          if window.panel.path.isSome:
            result = sendKeys(sessionName, windowName, &"cd {window.panel.path.get()}")

            if result != 0:
              echo &"""Failed to set path for window {windowName} in session {sessionName} with exit code {result}"""
              continue

          if window.panel.cmd.isSome:
            result = sendKeys(sessionName, windowName, window.panel.cmd.get())

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
        of PanelKind.vertical:
          echo "not implemented creation for vertical panel yet"
          quit(1)
        of PanelKind.horizontal:
          echo "not implemented creation for horizontal panel yet"
          quit(1)

proc downAction*(sessions: seq[Session]) =
  for i, session in sessions.pairs:
    let sessionName = getSessionName(session, i)

    echo &"""Killing session: {sessionName}"""

    let result = killSession(sessionName)

    if result != 0:
      echo &"""Failed to kill session {sessionName} with exit code {result}"""
