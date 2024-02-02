#!/usr/bin/env bash

set -euo pipefail

[ "${DEBUG:-0}" == "1" ] && set -x

# These follows XDG Base Directory Specification
DEFAULT_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share/}"
DEFAULT_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
DEFAULT_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

# Tracking means storing the history of switching focuses.
FOCUS_TRACKING_REPO="${FOCUS_TRACKING_REPO:-$DEFAULT_STATE_DIR}/focus.sh/"

# Store the files generating during focusing.
FOCUS_DATA_DIR="${FOCUS_DATA_DIR:-$DEFAULT_DATA_DIR/focus.sh}"

focus__version() {
  echo "0.5.0-dev"
}

focus__init() {
  mkdir -p ${FOCUS_TRACKING_REPO}
  __git init --initial-branch=nothing
  __git commit --allow-empty -m 'Empty'
  __git branch -c "done"
}

__git() {
  git -C "$FOCUS_TRACKING_REPO" "$@" >&2
}

focus__now() {
  __git branch --show-current 2>&1
}

focus__before() {
  __git rev-parse --abbrev-ref "@{-${1:-1}}" 2>&1
}

focus__done() {
  local current_branch="$(focus__now)"
  
  if [[ "${current_branch}" == 'nothing' ]]
  then
    echo "nothing is done"
    return
  fi

  __git switch "nothing"
  __git merge --no-ff --no-edit "$current_branch" -m "Stop focusing on ${current_branch}"
  __git branch -D "${current_branch}"
  # __git switch "nothing"
  local hook="${FOCUS_DONE__HOOK:-$DEFAULT_CONFIG_DIR/focus.sh/hooks/focus_done.sh}"
  [ -f ${hook} ] && ${hook}
}

focus__all() {
  __git branch --all
}

# Add an update/message/note into the current focus.
focus__jot() {
  __git commit --allow-empty "$@" >&2
}

focus__to_track() {
  local new_topic="${*}"
  new_topic=${new_topic// /-}
 
  # This is important as it won't polute the branch /nothing
  # with too many commits.
  # Previous versions (<= 0.3.0) produced a very long history
  # for any new branch.
  local current_branch="$(focus__now)"
  if [[ "${current_branch}" != 'nothing' ]]
  then
    focus__jot -m "Switch to [${new_topic}]"
  fi
  
  # See https://superuser.com/a/940542/627807.
  # Bash allows to test a command and use the exit code for the `if`
  # statement and bypassing the set -e.
  if __git show-ref --quiet --verify -- "refs/heads/${new_topic}" >/dev/null
  then
    __git switch "${new_topic}" 2>/dev/null 
    focus__jot -m "Switch back to [${new_topic}]"
  else
    __git switch -c "${new_topic}" 'nothing' 2>/dev/null
    focus__jot -m "Started on ${new_topic}" 
  fi

  local hook="${FOCUS_TO__HOOK:-$DEFAULT_CONFIG_DIR/focus.sh/hooks/focus_to.sh}"
  [ -f ${hook} ] && ${hook} "${new_topic}" >&2

  if focus__before >/dev/null
  then
    echo "Previous topic $(focus__before)" >&2
  else
    echo "Previous topic: nothing" >&2
  fi
}

focus__select() {
  if command -v fzf >/dev/null; then
    cd "$FOCUS_DATA_DIR" && ls -t -d -- */ | fzf
    return 
  else
    cd "$FOCUS_DATA_DIR"
    local options=
    readarray -t options < <(ls -t -r -d -- */)
    select dir in "${options[@]}"
    do
      echo "$dir"
      return
    done
  fi
}

focus__to() {
  if [[ "$#" -eq 0 ]]; then
    local select=
    # select="$(cd "$FOCUS_DATA_DIR" && ls -t -d -- */ | fzf)"
    select="$(focus__select)"
    focus__to_track "${select%/}"
    echo "$select"
    return
  fi

  local new_topic="${*}"
  new_topic=${new_topic// /-}
  mkdir -p "$FOCUS_DATA_DIR/$new_topic"
  focus__to_track "$@" && true
  echo "$new_topic"
}

focus__history() {
  __git log --pretty=format:'%C(green)%h %C(yellow)[%ad] %Creset%s' --decorate --date=relative 2>&1
}

focus__la() {
  if command -v exa 2>&1 >/dev/null; then
    exa "$FOCUS_DATA_DIR" --sort=changed  --reverse \
      --group-directories-first \
      --long -t=changed --time-style=long-iso \
      --no-user --no-filesize --no-permissions --color=always
    return
  fi
  ls -ty "$FOCUS_DATA_DIR"
}

focus__ls() {
  focus__la | head -5
}

focus__stop() {
  focus__to_track 'nothing'
  local hook="${FOCUS_STOP__HOOK:-$DEFAULT_CONFIG_DIR/focus.sh/hooks/focus_stop.sh}"
  [ -f ${hook} ] && ${hook}

}

focus__dir() {
  cd "$FOCUS_DATA_DIR"
}

usage() {
  cat <<__USAGE__
The following commands can be used:

  now
    Show the current topic (as a Git branch)

  before [n]
    Show the previous topic. Use 'n' (1..99) to show the previous topic.

  to SUMMARY_OF_TOPIC
    Switch the current focus to another topic.
    Hook is supported.

  stop
    Stop the current focus. Switch back to 'nothing'.
    Hook is supported.

  done
    Mark the current topic as done.
    Hook is supported.

  all
    List all (undone) active focuses.

  ls
    List what I did in the current topic

  jot [MESSAGE]
    Jot down a quick summary of what has been done.
    The MESSAGE is optional. If it is missing, the default Git commit EDITOR will be opened.

  dir
    Go to the FOCUS_DATA_DIR
  fix
    Fix the last messsage jotted down.

  help
    Show this usage.
__USAGE__

}

focus__export() {
  cat <<'__FOCUS_EXPORT__'
function focus {
  local _focus="$XDG_BIN_HOME/focus"
  if [[ "$1" == "dir" ]]; then
    cd "$( $_focus dir )"
  elif [[ "$1" == "to" ]]; then
    cd "$( $_focus dir )/$( $_focus $@)"
  else
    "$_focus" "$@"
  fi
}
__FOCUS_EXPORT__
}

focus__main() {
  if [ "$#" == "0" ]
  then
    usage
    exit 0
  fi

  option="${1}"
  shift

  case "$option" in
    init)
      focus__init
      ;;
    now)
      focus__now
      ;;
    before)
      focus__before "$@"
      ;;
    to)
      focus__to "$@"
      ;;
    done)
      focus__done
      ;;
    jot)
      if [ "$#" == "0" ]
      then
        focus__jot
      else
        focus__jot -m "$*"
      fi
      ;;
    fix)
      focus__jot --edit --amend
      ;;
    log)
      focus__history 2>&1;;
    ls)
      focus__ls;;
    la)
      focus__la;;
    all)
      focus__all;;
    help)
      usage;;
    version)
      focus__version;;
    stop)
      focus__stop;;
    dir)
      echo "$FOCUS_DATA_DIR";;
    export)
      focus__export;;
    *)
      usage
      ;;
  esac
}

focus__main "$@"
