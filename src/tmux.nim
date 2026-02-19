import os, std/strformat

proc newSession*(sessionName: string): int =
  execShellCmd(&""" tmux new-session -d -s "{sessionName}" """)

proc newWindow*(sessionName: string, windowName: string): int =
  execShellCmd(&""" tmux new-window -t "{sessionName}" -n "{windowName}" """)

proc renameWindow*(sessionName: string, oldWindowName: string, newWindowName: string): int =
  execShellCmd(&""" tmux rename-window -t "{sessionName}:{oldWindowName}" "{newWindowName}" """)

proc sendKeys*(sessionName: string, windowName: string, keys: string, panelIndex: int = 0): int =
  execShellCmd(&""" tmux send-keys -t "{sessionName}:{windowName}.{panelIndex}" '{keys}' C-m """)

proc sendKeys*(keys: string): int =
  execShellCmd(&""" tmux send-keys '{keys}' C-m """)

proc clearHistory*(sessionName: string, windowName: string, panelIndex: int = 0): int =
  execShellCmd(&""" tmux clear-history -t "{sessionName}:{windowName}.{panelIndex}" """)

proc killSession*(sessionName: string): int =
  execShellCmd(&""" tmux kill-session -t "{sessionName}" """)

proc splitHorizontally*(): int =
  execShellCmd("tmux split-window -h")

proc splitVertically*(): int =
  execShellCmd("tmux split-window -v")

proc selectsNewlyCreatedRightPanel*(): int =
  execShellCmd("tmux select-pane -R")

proc selectsNewlyCreatedBottomPanel*(): int =
  execShellCmd("tmux select-pane -D")

proc selectsWindow*(sessionName: string, windowName: string): int =
  execShellCmd(&""" tmux select-window -t "{sessionName}:{windowName}" """)