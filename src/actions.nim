import std/[strformat, options, terminal]
import tmux
import types

proc getSessionName(session: Session, index: int): string =
  session.name.get(&"unamed-{index}")

proc getWindowName(window: Window, index: int): string =
  window.name.get(&"unamed-{index}")

# Helper to draw the panel tree recursively
proc viewPanel(panel: Panel, prefix: string, isLast: bool, wrapper: string) =
  if panel == nil: return

  # 1. Determine the branch characters
  let connector = if isLast: "└── " else: "├── "
  let childPipe = if isLast: "    " else: "│   "
  
  # 2. Print the kind of panel
  stdout.write(&"{prefix}{connector}")
  case panel.kind:
    of PanelKind.single:
      if wrapper != "":
        styledWriteLine(stdout, fgCyan, &"{wrapper}(Panel)", resetStyle)
      else:
        styledWriteLine(stdout, fgCyan, "Panel", resetStyle)
    of PanelKind.vertical:
      if wrapper != "":
        styledWriteLine(stdout, fgYellow, &"{wrapper}(Vertical Split)", resetStyle)
      else:
        styledWriteLine(stdout, fgYellow, "Vertical Split", resetStyle)
    of PanelKind.horizontal:
      if wrapper != "":
        styledWriteLine(stdout, fgMagenta, &"{wrapper}(Horizontal Split)", resetStyle)
      else:
        styledWriteLine(stdout, fgMagenta, "Horizontal Split", resetStyle)

  # 3. Print Panel details (Path/Cmd)
  let nextPrefix = prefix & childPipe
  if panel.path.isSome:
    echo &"{nextPrefix}  path: {panel.path.get()}"
  if panel.cmd.isSome:
    echo &"{nextPrefix}  cmd:  {panel.cmd.get()}"

  # 4. Recursively visit children
  case panel.kind:
    of PanelKind.vertical:
      viewPanel(panel.left, nextPrefix, false, "left")
      viewPanel(panel.right, nextPrefix, true, "right")
    of PanelKind.horizontal:
      viewPanel(panel.top, nextPrefix, false, "top")
      viewPanel(panel.bottom, nextPrefix, true, "bottom")
    of PanelKind.single:
      discard

proc viewAction*(sessions: seq[Session]) =
  for i, session in sessions.pairs:
    if i > 0: echo ""

    # Print Session
    styledWriteLine(stdout, fgBlue, styleBright, getSessionName(session, i), resetStyle)

    for j, window in session.windows.pairs:
      let isLastWindow = j == session.windows.len - 1
      let connector = if isLastWindow: "└── " else: "├── "
      let pipe = if isLastWindow: "    " else: "│   "

      # Print Window
      stdout.write(&"  {connector}")
      styledWriteLine(stdout, fgGreen, getWindowName(window, j), resetStyle)

      # Print the Panel Tree starting from the window's root panel
      viewPanel(window.panel, "  " & pipe, true, "")

proc setupPanel(panel: Panel, sessionName: string, windowName: string) =
  if panel == nil: return

  var result: int = 0

  case panel.kind:
    of PanelKind.single:
      if panel.path.isSome:
        result = sendKeys(&"cd {panel.path.get()}")

        if result != 0:
          echo &"""Failed to set path for window {windowName} in session {sessionName} with exit code {result}"""
          return

      result = sendKeys("clear")

      if result != 0:
        echo &"""Failed to clear terminal for window {windowName} in session {sessionName} with exit code {result}"""
        return

      result = clearHistory(sessionName, windowName)

      if result != 0:
        echo &"""Failed to clear history for window {windowName} in session {sessionName} with exit code {result}"""
        return

      if panel.cmd.isSome:
        result = sendKeys(panel.cmd.get())

        if result != 0:
          echo &"""Failed to set cmd for window {windowName} in session {sessionName} with exit code {result}"""
          return
    of PanelKind.vertical:
      result = splitHorizontally()

      if result != 0:
        echo &"""Failed to split window {windowName} vertically in session {sessionName} with exit code {result}"""
        return

      setupPanel(panel.right, sessionName, windowName)

      result = selectsNewlyCreatedRightPanel()

      if result != 0:
        echo &"""Failed to select right panel for window {windowName} in session {sessionName} with exit code {result}"""
        return

      setupPanel(panel.left, sessionName, windowName)
    of PanelKind.horizontal:
      result = splitVertically()

      if result != 0:
        echo &"""Failed to split window {windowName} horizontally in session {sessionName} with exit code {result}"""
        return

      setupPanel(panel.bottom, sessionName, windowName)

      result = selectsNewlyCreatedBottomPanel()

      if result != 0:
        echo &"""Failed to select bottom panel for window {windowName} in session {sessionName} with exit code {result}"""
        return

      setupPanel(panel.top, sessionName, windowName)


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
      
      result = selectsWindow(sessionName, windowName)

      if result != 0:
        echo &"""Failed to select window {windowName} in session {sessionName} with exit code {result}"""
        continue

      setupPanel(window.panel, sessionName, windowName)

proc downAction*(sessions: seq[Session]) =
  for i, session in sessions.pairs:
    let sessionName = getSessionName(session, i)

    echo &"""Killing session: {sessionName}"""

    let result = killSession(sessionName)

    if result != 0:
      echo &"""Failed to kill session {sessionName} with exit code {result}"""
