#!/usr/bin/env bash

[ "$DEBUG" == "1" ] && set -x

FOCUS_TRACKING_REPO=${FOCUS_TRACKING_REPO:-$HOME/work/focus.sh-tracking}

function focus__version() {
  echo "0.2.0"
}

function focus__init() {
  mkdir -p ${FOCUS_TRACKING_REPO}
  __git init
  __git switch -c "nothing"
}

function __git() {
  git -C "$FOCUS_TRACKING_REPO" "$@"
}

function focus__now() {
  __git branch --show-current
}

function focus__before() {
  __git rev-parse --abbrev-ref "@{-${1:-1}}"
}

function focus__done() {
  local current_branch="$(focus__now)"
  __git switch "done"
  __git merge --no-ff --no-edit "$current_branch"
  __git branch -D "${current_branch}"
  __git switch "nothing"
  local hook="${FOCUS_DONE__HOOK:-$HOME/.focus/hooks/focus_done.sh}"
  [ -f ${hook} ] && ${hook}
}

function focus__all() {
  __git branch --all
}

# Add an update/message/note into the current focus.
function focus__jot() {
  __git commit --allow-empty "$@"
}

function focus__to() {
  local new_topic="${*}"
  new_topic=${new_topic// /-}
  
  focus__jot -m "Switch to [${new_topic}]"

  $(__git show-ref --quiet --verify -- "refs/heads/${new_topic}")
  if [ "$?" == "0" ]
  then
    __git switch "${new_topic}"
  else
    __git switch -c "${new_topic}" "nothing"
    focus__jot -m "Started on ${new_topic}"
  fi

  local hook="${FOCUS_TO__HOOK:-$HOME/.focus/hooks/focus_to.sh}"
  [ -f ${hook} ] && ${hook} "${new_topic}"

  echo "previous topic $(focus__before)"
}

function focus__ls() {
  __git ls
}

function usage() {
  cat <<__USAGE__
The following commands can be used:

  now
    Show the current topic (as a Git branch)

  before [n]
    Show the previous topic. Use 'n' (1..99) to show the previous topic.

  to SUMMARY_OF_TOPIC
    Switch the current focus to another topic.

  done
    Mark the current topic as done.

  all
    List all (undone) active focuses.

  ls
    List what I did in the current topic

  jot [MESSAGE]
    Jot down a quick summary of what has been done.
    The MESSAGE is optional. If it is missing, the default Git commit EDITOR will be opened.

  fix
    Fix the last messsage jotted down.

  help
    Show this usage.
__USAGE__

}

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
  ls)
    focus__ls
    ;;
  all)
    focus__all
    ;;
  help)
    usage
    ;;
  version)
    focus__version
    ;;
  *)
    usage
    ;;
esac
