# IDE

```
Usage: ide [OPTIONS] [SUBCOMMAND]

Create a new tmux session with a project name or open a file in an existing session.

Options:
  --project NAME Specify the name of the project to work with (default: current directory name)

Subcommands:
  help Show this help message and exit
  start Create a new tmux session with a neovim server
  open FILE Open a file in an existing tmux session with a neovim server
  stop Stop an existing tmux session and close nvim gracefully
```
