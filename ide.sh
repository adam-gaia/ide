#!/usr/bin/env bash
set -Eeuo pipefail

THIS_SCRIPT_NAME="$(basename "$0")"
WORKING_DIR="${PWD}"
PROJECT_NAME="$(basename "${WORKING_DIR}")"

function show_help() {
  cat <<EOF
  Usage: ${THIS_SCRIPT_NAME} [OPTIONS] [SUBCOMMAND]
  
  Create a new tmux session with a project name or open a file in an existing session.

  Options:
    --project NAME  Specify the name of the project to work with (default: current directory name)
  
  Subcommands:
    help       Show this help message and exit
    start      Create a new tmux session with a neovim server
    open FILE  Open a file in an existing tmux session with a neovim server
    stop       Stop an existing tmux session and close nvim gracefully
EOF
}

function socket_exists() {
  socket="${1}"
  test -S "${socket}"
}

function session_exists() {
  session="${1}"
  tmux has-session -t "${session}" 2>/dev/null
}

function create_session() {
  local session="${1}"
  local socket="${2}"

  if session_exists "${session}"; then
    echo "Error: An existing tmux session was found with the name ${session}"
    exit 1
  fi
  if socket_exists "${socket}"; then
    echo "Error: An existing nvim socket was found at ${socket}"
    exit 1
  fi

  # Create a new tmux session with the specified name
  tmux new-session -d -s "${session}"

  # Split the window (vertically) into two panes
  tmux split-window -v

  # My tmux windows and panes start at 1 (I set it in my config)
  # TODO: figure out a way to parse the first window and pane numbers
  first_window=1
  first_pane=1
  second_pane=2

  first="${session}:${first_window}.${first_pane}"
  second="${session}:${first_window}.${second_pane}"

  # Start a neovim server in the top pane
  tmux send-keys -t "${first}" "nvim --listen ${socket}" Enter

  # Send commands to nvim to set up display in a second pane
  tmux send-keys -t "${second}" "nvr --servername ${socket} --remote-send '<space>e'" Enter # Open the explorer

  # Clear the bottom pane for the user to use as a shell
  tmux send-keys -t "${second}" 'clear' Enter

  # Attach to the created tmux session
  tmux attach -t "${session}"
}

function open_file_in_existing_session() {
  local session="${1}"
  local socket="${2}"
  local file="${3}"
  if ! session_exists "${session}"; then
    echo "Error: A tmux session named ${session} does not exist"
    exit 1
  fi
  if ! socket_exists "${socket}"; then
    echo "Error: The neovim socket at ${socket} does not exist"
    exit 1
  fi
  nvr --servername "${socket}" --remote "${file}"
}

function stop_tmux_session() {
  local session="${1}"
  local socket="${2}"

  if ! session_exists "${session}"; then
    echo "Error: A tmux session named ${session} does not exist"
    exit 1
  fi
  if ! socket_exists "${socket}"; then
    echo "Warning: The neovim socket at ${socket} does not exist"
  else
    # Close nvim gracefully
    nvr --servername "${socket}" --remote-send ':qa!<CR>'
  fi

  # Stop the tmux session
  tmux kill-session -t "${session}"
}

function clean_string() {
  input="${1}"
  local output="${input//[^[:alnum:]]/_}" # Replace non-alphanumerica characters with '_'
  echo "${output,,}"                      # ',,' converts to lowercase
}

# Parse input arguments
ACTION="start"
FILE=""
while [[ $# -gt 0 ]]; do
  arg="$1"
  case "${arg}" in
  '-h' | '--help' | 'help')
    show_help
    exit 0
    ;;
  '--project')
    shift # Move to next arg to get project name
    PROJECT_NAME="$1"
    ;;
  'start')
    ACTION="start"
    ;;
  'open')
    ACTION="open"
    shift # Move to next arg to get the file to open
    FILE="$1"
    ;;
  'stop')
    ACTION="stop"
    ;;
  *)
    echo "Unknown argument: '${arg}'"
    exit 1
    ;;
  esac
  shift
done

SESSION_NAME="$(clean_string "${PROJECT_NAME}")"
NVIM_SOCKET="/tmp/nvim-${PROJECT_NAME}"

case "${ACTION}" in
start)
  create_session "${SESSION_NAME}" "${NVIM_SOCKET}"
  ;;

open)
  open_file_in_existing_session "${SESSION_NAME}" "${NVIM_SOCKET}" "${FILE}"
  ;;

stop)
  stop_tmux_session "${SESSION_NAME}" "${NVIM_SOCKET}"
  echo "Stopped session ${SESSION_NAME}"
  ;;
esac
