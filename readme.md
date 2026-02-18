# Tmuxer

This is a tool that setups your tmux configuration to your daily work.

```
Usage: ./tmuxer [options] <action>
Actions:
  up          - Start tmux sessions as defined in the config file
  down        - Stop tmux sessions as defined in the config file
  view        - Print the parsed configuration to the console
Options:
  -h, --help  - Show this help message
```

The configuration file works almost like git.

If you have a `.tmuxer.txr` file on your current directory and run the tool, it'll get the informations from this file.

If you don't have, it'll search on the parents directory until your home.
If the file is not found, an error will be displayed.
If the file is found, than it's used to construct or destruct your tmux setup.

The syntax is pretty simple:

```conf
# defines a session
session {}

# a session can have a name
session {
  name = "work-folders"
}

session {
  name = "work-folders"

  # defines a window
  window {}

  # a window can have "name", "path" and "cmd"
  window {
    name = ""
    path = "~/path/to/my/folder"
    cmd = "arbitrary command to run in that window after being inside the path above"
  }
}
```

You can define empty windows and empty sessions.

You can define multiple sessions just by placing one bellow another and the same applies to windows.

```conf
session {}
session {}
session {}

session {
  window {}
  window {}
  window {}
}
session {
  window {}
  window {}
  window {}
}
session {
  window {}
  window {}
  window {}
}
```

This config above creates three empty sessions and three sessions with three empty windows inside everyone.

The syntax also supports comments with `#`

## Warning

If you change the file with the setup running or run another file while there are already a previous one up, it will have a lot of unexpected behaviors.

Later, I'm gonna store some data about the current state and other stuff so I can handle this kind of behavior. But for now,
- **before run a new config file, shutdown the current one**
- **before updateing the config file, guarantee there is no previous up**

**Also important to note that this tool doesn't watch the tmux, so if you delete/create/update sessions/windows/panels this tool will not be able to handle this**

## Building

```bash
nimble build
```
