import os, std/strformat

proc newSession*(sessionName: string): int =
  return execShellCmd(&""" tmux new-session -d -s "{sessionName}" """)

proc newWindow*(sessionName: string, windowName: string): int =
  return execShellCmd(&""" tmux new-window -t "{sessionName}" -n "{windowName}" """)

proc renameWindow*(sessionName: string, oldWindowName: string, newWindowName: string): int =
  return execShellCmd(&""" tmux rename-window -t "{sessionName}:{oldWindowName}" "{newWindowName}" """)

proc sendKeys*(sessionName: string, windowName: string, keys: string, panelIndex: int = 0): int =
  return execShellCmd(&""" tmux send-keys -t "{sessionName}:{windowName}.{panelIndex}" '{keys}' C-m """)

proc clearHistory*(sessionName: string, windowName: string, panelIndex: int = 0): int =
  return execShellCmd(&""" tmux clear-history -t "{sessionName}:{windowName}.{panelIndex}" """)

proc killSession*(sessionName: string): int =
  return execShellCmd(&""" tmux kill-session -t "{sessionName}" """)
