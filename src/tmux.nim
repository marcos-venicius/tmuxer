import std/[os, options, strformat]

type
  Tmux* = object
    session: Option[string] = none(string)
    window: Option[string] = none(string)

proc getSessionName(tmux: Tmux): string =
  if tmux.session.isSome:
    tmux.session.get()
  else:
    raise newException(ValueError, "no session selected")

proc getWindowName(tmux: Tmux): string =
  if tmux.window.isSome:
    tmux.window.get()
  else:
    raise newException(ValueError, "no window selected")

proc setSessionName*(tmux: var Tmux, name: string) =
  tmux.session = some(name)

proc setWindowName*(tmux: var Tmux, name: string) =
  tmux.window = some(name)

proc newSession*(tmux: var Tmux): int =
  execShellCmd(&""" tmux new-session -d -s "{tmux.getSessionName()}" """)

proc newWindow*(tmux: var Tmux): int =
  execShellCmd(&""" tmux new-window -t "{tmux.getSessionName()}" -n "{tmux.getWindowName()}" """)

proc renameWindow*(tmux: var Tmux, newWindowName: string): int =
  execShellCmd(&""" tmux rename-window -t "{tmux.getSessionName()}:{tmux.getWindowName()}" "{newWindowName}" """)

proc sendKeys*(tmux: var Tmux, keys: string, useCurrentSelectedSessionAndWindow: bool = false): int =
  if useCurrentSelectedSessionAndWindow:
    execShellCmd(&""" tmux send-keys -t "{tmux.getSessionName()}:{tmux.getWindowName()}.0" '{keys}' C-m """)
  else:
    execShellCmd(&""" tmux send-keys '{keys}' C-m """)

proc clearHistory*(tmux: var Tmux): int =
  execShellCmd(&""" tmux clear-history -t "{tmux.getSessionName()}:{tmux.getWindowName()}.0" """)

proc killSession*(tmux: var Tmux): int =
  execShellCmd(&""" tmux kill-session -t "{tmux.getSessionName()}" """)

proc splitHorizontally*(): int =
  execShellCmd("tmux split-window -h")

proc splitVertically*(): int =
  execShellCmd("tmux split-window -v")

proc selectsNewlyCreatedRightPanel*(): int =
  execShellCmd("tmux select-pane -R")

proc selectsNewlyCreatedBottomPanel*(): int =
  execShellCmd("tmux select-pane -D")

proc selectsWindow*(tmux: var Tmux): int =
  execShellCmd(&""" tmux select-window -t "{tmux.getSessionName()}:{tmux.getWindowName()}" """)