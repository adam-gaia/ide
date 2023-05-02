# TODO

- Add an input arg 'ls' to list active sessions.

  - This should filter 'tmux ls' output for only sessions started by ide

- Should we start a whole new tmux daemon that is only for ide sessions?
  - This way, interacting with the "normal" tmux wont conflict with ide sessions
