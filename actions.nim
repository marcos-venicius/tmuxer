import std/strformat, std/options
from parser import Session

proc viewAction(sessions: seq[Session]) =
  for session in sessions:
    echo &"""Session: {session.name.get("<unamed>")}"""
    for window in session.windows:
      echo &"""  Window: {window.name.get("<unamed>")}"""
      echo &"""    Path: {window.path.get("N/A")}"""
      echo &"""    Cmd: {window.cmd.get("N/A")}"""

export viewAction