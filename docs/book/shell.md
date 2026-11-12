# The shell

`C-c o t` opens a buffer named `*shell*`, where you type commands for your shell, the program that `$SHELL` names, or
`/bin/sh` without it: each line typed after the prompt `$ ` runs at Enter, and what the shell writes, its errors too, comes
above the prompt. It is Emacs's `M-x shell`, not a terminal emulator: the shell reads its commands from a pipe, so a program
that draws a whole screen, as `vim` or `top`, or that waits for a password typed on a terminal, has no screen there. The
colours a program writes for a terminal are taken away. The shell is the key `t` of the group `o`, open, of `C-c`, as
`SPC o t` in Doom Emacs. A second `C-c o t` goes back to the buffer.

| Keys | Command | What it does |
|---|---|---|
| `C-c o t` | [ide.Terminal] | opens the shell buffer, the shell started in the folder of the current file, or goes to it |
| Enter, in the shell buffer | [ide.Enter] | runs the command of the last line |

The shell keeps its state from one command to the next: `cd ../shop` once, and the next commands run there. What it writes
shows as it comes, while it writes and three seconds after; what a command writes later, as a server, shows at the next key.
The buffer is a buffer of text: moves, search and copy work in it, and its lines are never saved. Closing it, `C-x k`, ends
the shell; it asks first only when a command is typed and not run.

## Security

- The shell runs only when you press `C-c o t`, and a command only when you press Enter in its buffer: nothing else in
  Cemacs sends it a line.
- Cemacs itself can't start the shell: its permissions name `cesia` and `git` only. `C-c o t` runs
  `cesia run --allow exec=SHELL tools/shell.ce SHELL FOLDER`, a program whose one permission is to start that shell, and
  which passes it the commands and gives back what it writes, as lines of JSON, each a text. Cemacs reads `$SHELL` for it,
  with the permission `env=SHELL`; a value that isn't a path from the root, or that holds a comma, gives `/bin/sh`.
- The shell then has your rights, as in any terminal: what you type runs as you. That is its use, and why it starts only
  by a key of yours.
- Closing the buffer ends the relay, and the shell with it; when Cemacs ends, the shell's input closes, and it ends too.
