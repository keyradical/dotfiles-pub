# Zsh Configuration

<!-- TODO: GIF -->

## Ansible

To install this Zsh configuration:

```console
$ ansible-playbook main.yaml --ask-become-pass
```

## Prompt

A custom prompt theme called "fresh" is used by default, its defined in
[prompt\_fresh\_setup](prompt_fresh_setup) and symbolic linked to
`~/.local/share/zsh/site-functions` which is on the `fpath`. The prompt enabled
using `prompt fresh` when the prompt subsystem is enabled. The prompt is
multi-line and does not redraw during command editing. The first line of the
prompt is drawn using a `precmd` hook and displays variable length information
such as the time, current directory, [Git][git] repository branch and status,
and the last commands exit code if its non-zero.

<!-- ### Options
TODO: Implement options:
  * disable git-prompt
  * disable almost on top
  * disable RPS1
  * add widget support?
-->

### Git Status

The "fresh" theme supports displaying Git repository status information, the
majority of this information is gathered using a C program which is compiled on
the fly when the theme is enabled, it resides in `~/.cache/zsh/git-prompt` and
is removed when the theme is disabled. Since the C program uses the standard
library, development headers must be present in addition to the compiler.

[zsh-git-prompt][git-prompt] was originally used but proved to be agonisingly
slow on large repositories containing many unstaged changes. Instead the
`git-prompt` C program calls `git status --porcelain`, which is extremely fast,
and parses the output in a loop. Output from `git-prompt` is a space separated
list of interesting numbers which is captured in a Zsh array and interpreted for
display. This results in no noticeable lag when redrawing the prompt.

## Plugins

Plugins are sourced manually and their git repositories tracked by
[conduit][conduit], no plugin manager is used.

* [zsh-autosuggestions][zsh-autosuggestions] Fish-like autosuggestions for zsh.
* [zsh-syntax-highlighting][syntax] Fish shell like syntax highlighting for Zsh.
* [zsh-history-substring-search][search] Zsh port of the Fish shell's history
  search.

In addition to third party plugins the following are custom plugins residing in
this repository.

* [autoenv](autoenv/autoenv.zsh) is a inspired by [zsh-autoenv][zsh-autoenv] but
  simplified by removing customization points and using a less intrusive UI.
* [build](build/build.plugin.zsh) is a collection of commands to make it easier
  to build projects focuses on C/C++ development.
* [sandbox](sandbox/sandbox.plugin.zsh) is a command which sets up a throw away
  directory for quickly testing ideas.
* [layout](layout/layout.plugin.zsh) is a command which setups up `tmux` panes
  in a window with scripts.
* [notes](notes/notes.plugin.zsh) is a command to quickly edit markdown note
  files.

## Environment & Settings

The bulk of, if not all, configuration occurs in [`zshenv`](zshenv) and
[`zshrc`](zshrc) these files.

### ~/.local

In addition to `/usr/local` add `~/.local` to useful environment variables. This
is especially useful with `pip install --user <package>`.

* Add `~/.local/share/zsh/site-functions` to `fpath`
* Add `~/.local/bin` to `PATH`
* Add `~/.local/share/man` to `MANPATH`
* Add `~/.local/share/info` to `INFOPATH`

### History

Command history is stored in `~/.cache/zsh/histfile`, duplicates are removed,
and multi-terminal history support is enabled.

### Line Editor

The vi mode line editor is enabled. [zsh-vim-mode][vim-mode] was a reasonable
starting point but was replaced as it uses some strange defaults.

#### Cursor Shape

In order to easily ascertain which vi mode the line editor is currently using
escape sequences are sent to the terminal emulator on certain events to change
the current shape of the cursor. Two cursor shapes are used; block for `vicmd`
mode; a vertical line for `viins` mode. Additional escape sequences are used
when [tmux][tmux] is detected to ensure the terminal emulator receives the
appropriate sequence. [iTerm2][iterm2] and VTE compatible terminal emulators are
supported.

Three hooks are registered with the line editor; `zle-keymap-select` changes the
cursor shape then the mode is changed; `zle-line-init` changes the shape
starting editing a new command; and `zle-line-finish` resets the cursor shape
when the line edit is complete.

#### `vicmd` Mode

Undo and repo and enabled using `u` and `U`. Showing help for the command under
the cursor with `<Esc>h` is replaced with `K`. The [Vim][vim] "Ex" mode binding
`:` is disabled mode since is barely of use and easy to enter accidentally.
Bindings for `k` and `j` integrate with [zsh-history-substring-search][search]
performing up and down searches respectively.

#### Edit Command Line

When editing a command using Zsh's line editor becomes cumbersome due to length
the `<Ctrl>+V` binding opens the default editor (Vim) to edit the current
command.

### Miscellaneous

Interactive comments are enabled, useful when creating demo GIF's of terminal
program usage. Ignore end of file, bound to `<Ctrl>+D`, is disabled to avoid
accidentally exiting the terminal.

Audio beeps are disable. Terminal flow control is disabled, this allows
[Vim][vim] and other terminal programs to use `<Ctrl>+S` mapping/binding, this
proves useful as the `S` key is in the middle of the home row on QWERTY
keyboards.

### Completion

The completion subsystem is enable, any custom completions should be symbolic
linked to `~/.local/share/zsh/site-functions`.

<!-- TODO: Enable compiling completions -->

### Aliases

Various aliases are defined at the end of [zshrc](zshrc) for convenience.

[conduit]: https://github.com/kbenzie/conduit
[zsh]: https://www.zsh.org/
[git]: https://git-scm.com/
[git-prompt]: https://github.com/olivierverdier/zsh-git-prompt
[zsh-autosuggestions]: https://github.com/zdharma/fast-syntax-highlighting
[zsh-autoenv]: https://github.com/Tarrasch/zsh-autoenv
[syntax]: https://github.com/zsh-users/zsh-syntax-highlighting
[search]: https://github.com/zsh-users/zsh-history-substring-search
[vim-mode]: https://github.com/sharat87/zsh-vim-mode
[tmux]: https://tmux.github.io
[iterm2]: https://www.iterm2.com
[vim]: http://www.vim.org/
