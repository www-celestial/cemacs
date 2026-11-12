# Cemacs

Cemacs is a text editor for Cesia, written in Cesia. It has the keys of Emacs and the colours of Cesia's code. A band shows
what a key can lead to, so you don't need to learn the keys before you start. Errors show in the lines as you type, and a
program runs, and stops at its breakpoints, inside the window. You change Cemacs in Cesia, and it reloads while it runs.

```cesia
use src/emacs
use std/dict
use std/value
value.Len(dict.Keys(emacs.Keys())) -->
```

That number is how many keys the table of Emacs keys in `src/emacs/emacs.ce` holds today, counted when this page was built:
the keys of Cemacs are a value of its own code, which any Cesia program can read.

## How to read it

- Read [First steps](first-steps.md) first: in ten minutes it takes you from nothing to editing, running and debugging a
  Cesia file. The chapters after it each cover one part in full, and can be read in any order.
- Every word of the field is explained where a chapter first uses it, and again in the [Glossary](glossary.md). Cemacs
  uses the words of Emacs where they are true of it, and says so where its own name differs.
- A name in the text leads to its page in the reference: [commands.Save], for instance, the command that saves.
- Every example of Cesia code on these pages ran when the site was built, and the text under it is what it printed; a line
  with `-->` and a value is checked, and a different result stops the build. So the pages can't drift from the code.

## How keys are written

| Written | Means |
|---|---|
| `C-x` | hold Control and press `x` |
| `M-x` | hold Alt and press `x` (M is for Meta, the old name of the key) |
| `S-right` | hold Shift and press the right arrow |
| `C-x C-s` | `C-x`, then `C-s`: a key sequence of two keys |
| `C-c f f` | `C-c`, then `f`, then `f`, with no Control on the last two |
| `enter`, `tab`, `backspace`, `delete`, `home`, `end`, `pageup`, `pagedown`, `space` | the keys of those names |

## Contents

1. [Install](install.md): Cesia, SDL3 and SDL3_ttf, the code, and the command `bin/cemacs`.
2. [First steps](first-steps.md): a tour, from opening a file to running and debugging it and changing Cemacs.
3. [Editing](editing.md): the cursor, the mark and the selection, moves, typing, the indent of Cesia code, completion,
   cutting and pasting, undo, the mouse.
4. [Files and buffers](files.md): opening, saving safely, what files open, line ends, the buffer list, the folder manager.
5. [Windows and panes](windows.md): the window, its panes, the mode line, the prompt line and the band of hints.
6. [Search](search.md): the incremental search of a buffer, `C-s` and `C-r`, and what else Cemacs finds: rows, keys, errors, places.
7. [Keys](keys.md): every key, generated from the code, and how a key becomes a command.
8. [Running and debugging](running.md): running a file with its permissions, its output, the tests and their failures in
   the lines, breakpoints, stepping, fix and continue.
9. [Errors in the lines](check.md): what the check shows, when it runs, and how to go from one error to the next.
10. [Names](names.md): the definition of a name and back, its documentation, the signature of a call, every place that
    reads it, and its rename across the project.
11. [Git](git.md): the state of a repository, where a letter stages, unstages or commits, the log, a commit, a diff and
    the commit of each line.
12. [The shell](shell.md): a buffer where the commands you type run in your shell, and what that shell may do.
13. [Cells and results](cells.md): a file of Cesia as a notebook, its results under its cells, `*variables*`, `*repl*`
    and the page of a file.
14. [Changing Cemacs](customising.md): your folder `user/`, settings, your own keys and commands, an app of your own, and
    the reload while it runs.
15. [Recipes](recipes.md): small tasks done in `user/`, each with its code, its key and what it shows: your settings, files
    at the start, a new buffer, a group of keys, a question, a list, a hook, an app.
16. [Inside Cemacs](internals.md): the state and its update, the rope, the history, the colours, the indent, the frame, the loop of
    events, saving.
17. [Speed](performance.md): what was measured, how, and the numbers.
18. [Cemacs and other editors](comparison.md): beside GNU Emacs, Neovim, Vim and VS Code, in numbers and in features.
19. [A case: finding a file from a few letters](finding.md): one real problem, from its statement to the proof that it is
    solved, by the methods of research: a baseline, a hypothesis, the papers, the smallest change, tests and measures.
20. [Troubleshooting](troubleshooting.md): every message of Cemacs, what it means and what to do.
21. [Glossary](glossary.md): the words of editors, as Cemacs uses them.
22. [References](references.md): the works and standards that Cemacs follows.

The reference, under [Reference](ref/index.html), lists every package of Cemacs and every public name, from its code.

Cesia has a book of its own, which teaches the language: https://www-celestial.github.io/cesia-lang/.
