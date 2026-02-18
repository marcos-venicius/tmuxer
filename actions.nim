import os
import std/strformat, std/options
from parser import Session

proc viewAction(sessions: seq[Session]) =
  for session in sessions:
    echo &"""Session: {session.name.get("<unamed>")}"""
    for window in session.windows:
      echo &"""  Window: {window.name.get("<unamed>")}"""
      echo &"""    Path: {window.path.get("N/A")}"""
      echo &"""    Cmd: {window.cmd.get("N/A")}"""

proc upAction(sessions: seq[Session]) =
  for i, session in sessions.pairs:
    let sessionName = session.name.get(&"unamed-{i}")

    echo &"""Creating session: {sessionName}"""

    var result = execShellCmd(&"tmux new-session -d -s {sessionName}")

    if result != 0:
      echo &"""Failed to create session {sessionName} with exit code {result}"""
      continue
  
    for j, window in session.windows.pairs:
      let windowName = window.name.get(&"unamed-{j}")

      echo &"""  Creating window: {windowName}"""

      if j == 0:
        # the first window is created by default with the session, so we just need to rename it
        result = execShellCmd(&"tmux rename-window -t {sessionName}:0 {windowName}")

        if result != 0:
          echo &"""Failed to rename default window to {windowName} in session {sessionName} with exit code {result}"""
          continue
      else:
        result = execShellCmd(&"tmux new-window -t {sessionName} -n {windowName}")

        if result != 0:
          echo &"""Failed to create window {windowName} in session {sessionName} with exit code {result}"""
          continue
      
      if window.path.isSome:
        result = execShellCmd(&"""tmux send-keys -t {sessionName}:{windowName}.0 'cd {window.path.get()}' C-m""")

        if result != 0:
          echo &"""Failed to set path for window {windowName} in session {sessionName} with exit code {result}"""
          continue
      
      if window.cmd.isSome:
        result = execShellCmd(&"""tmux send-keys -t {sessionName}:{windowName}.0 '{window.cmd.get()}' C-m""")

        if result != 0:
          echo &"""Failed to set cmd for window {windowName} in session {sessionName} with exit code {result}"""
          continue

      result = execShellCmd(&"""tmux send-keys -t {sessionName}:{windowName}.0 'clear' C-m""")

      if result != 0:
        echo &"""Failed to clear terminal for window {windowName} in session {sessionName} with exit code {result}"""
        continue

      result = execShellCmd(&"""tmux clear-history -t {sessionName}:{windowName}.0""")

      if result != 0:
        echo &"""Failed to clear history for window {windowName} in session {sessionName} with exit code {result}"""
        continue

export viewAction, upAction