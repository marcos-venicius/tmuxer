# Tmuxer

This is a tool that setups your tmux configuration to your daily work.

<img width="705" height="415" alt="image" src="https://github.com/user-attachments/assets/77950844-261b-4b5b-86fd-60c3091607a7" />

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
session {
  name = "tmuxer project"

  window {
    name = "tmuxer development"

    vpanel {
      left {
        hpanel {
          top {
            panel {
              path = "~/tools/tmuxer/src"
              cmd = "vi ."
            }
          }
          bottom {
            panel {
              path = "~/tools/tmuxer"
              cmd = "nimble build"
            }
          }
        }
      }

      right {
        panel {
          path = "~/tools/tmuxer/examples"
          cmd = "../bin/tmuxer -h"
        }
      }
    }
  }

  window {
    name = "resources monitoring"

    panel {
      path = "~/tools/tmuxer"
      cmd = "btop"
    }
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
