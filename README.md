# `focus.sh`

This is a very simple command line that I developed for my own itch. I usually get distracted when I'm working on some
task and then suddenly (have) to jump into a different topic. After switching back to the last task, I completely forgot
what I've been working on or even forgot which task it is.

The CLI `focus.sh` is a very simple tracking I develop for myself (because I use the Terminal **a lot**).

## Concept

`focus.sh` uses a Git repository to keep track of all the data. It actually does not add any file into the Git
repository so the `.git` directory is the source of truth.

- *Focus*: A focus is a Git branch.
- *Update/Note*: A simple Git commit (with `--allow-empty`).

> @since 0.5.0

Over the time of using `focus.sh`, I developed a practice of using an accompanying directory for each _focus_.This directory contains files, repositories and everything occured during the focus (kinda like _focus jot_ but into real files).


## Workflow

This section describes the typical workflow that I use `focus.sh` as well as some common commands.

```bash

# Show the current focus. In case this is the first time, or
# the last focus has been done, it will show nothing (or master).
$ focus now
nothing

# Switch my focus into work/some-thing
$ focus to work/some-thing

# I update with some steps that got finished.
$ focus jot 'Some findings that I find'

# Or if I need a long text, I can use the default Git EDITOR (vim ftw).
$ focus jot
## open EDITOR to input more text.

# Then I got distracted by some other thing.
$ focus to work/something-completely-different
## now I got distracted

# A note to the new focus
$ focus jot "Nothing to see here"

# Check what was the last focus
$ focus before
work/some-thing

# Set the current focus as DONE.
$ focus done

# Switch back
$ focus work/some-thing

```
## Install


The following steps can be used to install

```bash
$ git clone git@github.com:Genzer/focus.sh.git ~/.local/bin/focus.sh

# Replace ~/.bashrc to ~/.zshrc if you are using Zsh.
$ echo alias focus='$HOME/.local/bin/focus.sh/focus.sh' >>~/.bashrc 

# Reopen your shell.

# Create an empty Git at $FOCUS_TRACKING_REPO. If it is not set, it uses `$XDG_DATA_HOME/focus.sh`. Default to $HOME/.local/share/focus.sh.
$ focus init
```

## Support for XDG Base Directory Specification

_@since: 0.4.0_

- The Git repository used internally is default to `$XDG_DATA_HOME/focus.sh`.
- Hooks' default location are moved to `$XDG_CONFIG_HOME/focus.sh`.

## Commands

Invoking `focus` without any command will show you the full usage of all available commands. Or `focus help`.

For example:

```bash
$ focus
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
```

## Hooks 

_@since 0.2.0_

A hook is an executable (a script file or a binary file) which, this is important, that the current user is granted execute permission (e.g `chmod u+x`).
The hook will be called with exactly the parameters passed in from the original `focus.sh` command.

`focus.sh` supports hooks (like Git hooks) which will be called upon some commands get done. The commands at the moment support hooks are:

| Command      | Environment Variable | Default                                      |
| ------------ | -------------------- | -------------------------------------------- |
| `focus to`   | `FOCUS_TO__HOOK`     | `$HOME/.config/focus.sh/hooks/focus_to.sh`   |
| `focus done` | `FOCUS_DONE__HOOK`   | `$HOME/.config/focus.sh/hooks/focus_done.sh` |
| `focus stop` | `FOCUS_STOP__HOOK`   | `$HOME/.config/focus.sh/hooks/focus_stop.sh` |

