# References

The works, standards and programs that Cemacs follows, each with what it took from them. Every entry was checked against its
source; a work that Cemacs doesn't follow is not here, except under the last heading, where the tools it is compared with
are.

## Editors

- Richard M. Stallman. *EMACS: The Extensible, Customizable Self-Documenting Display Editor.* Proceedings of the ACM
  SIGPLAN SIGOA Symposium on Text Manipulation, 1981; also MIT AI Lab Memo 519a, March 1981.
  [doi:10.1145/800209.806466](https://doi.org/10.1145/800209.806466),
  [the memo at MIT](https://dspace.mit.edu/handle/1721.1/5736).
  What Cemacs took: an editor written and changed in its own language, whose commands are functions that any key can name,
  and that documents itself: the band of hints and the `?` lists come from the comments of the code.
- Free Software Foundation. *GNU Emacs Manual.* https://www.gnu.org/software/emacs/manual/.
  What Cemacs took: the keys, from `C-f` to `C-x C-s` and `M-g n`, and the words: buffer, mark, region, mode line, prefix
  key, kill, yank.
- Free Software Foundation. *GNU Emacs Lisp Reference Manual*, section *The Buffer Gap*.
  https://www.gnu.org/software/emacs/manual/html_node/elisp/Buffer-Gap.html.
  What Cemacs took: nothing; it is the source of what [Inside Cemacs](internals.md#why-a-rope) says of the gap buffer of
  Emacs, to which Cemacs prefers a rope.
- Henrik Lissner and contributors. *Doom Emacs*, a configuration framework for GNU Emacs.
  https://github.com/doomemacs/doomemacs.
  What Cemacs took: the keys gathered in groups under one leader key, each group named by its first letter, `C-c f` for the
  files, with the band of hints after a pause.
- Justin Burkett. *which-key*, part of GNU Emacs since version 30.1.
  What Cemacs took: the band that shows, after a pause on a prefix key, the keys that can follow it.

## Data structures

- Hans-J. Boehm, Russ Atkinson and Michael Plass. *Ropes: an Alternative to Strings.* Software: Practice and Experience
  25(12):1315–1330, December 1995. [doi:10.1002/spe.4380251203](https://doi.org/10.1002/spe.4380251203).
  What Cemacs took: the rope, a text held as a tree of flat pieces that edits share and never change; two short pieces
  joined make one; an edit copies only the nodes along its path. See [Inside Cemacs](internals.md#the-rope).
- G. M. Adelson-Velsky and E. M. Landis. *An algorithm for the organization of information.* Doklady Akademii Nauk SSSR
  146(2):263–266, 1962; in English, Soviet Mathematics Doklady 3:1259–1263, 1962.
  [The paper at Math-Net.Ru](https://www.mathnet.ru/eng/dan26964).
  What Cemacs took: the balance of its rope, where the heights of the two sides of a node differ by at most one, kept by
  rotations.
- The Elm Architecture, in *An Introduction to Elm*. https://guide.elm-lang.org/architecture/.
  What Cemacs took: the name of its shape, a state, an update from an event and a view. See
  [Inside Cemacs](internals.md#the-state-the-update-and-the-view).

## Standards

- F. Yergeau. *UTF-8, a transformation format of ISO 10646.* RFC 3629, STD 63, IETF, November 2003.
  https://www.rfc-editor.org/rfc/rfc3629.
  What Cemacs took: what valid UTF-8 is, which [files.IsText] checks: no overlong form, no surrogate, nothing above
  U+10FFFF.
- The Open Group. *The Open Group Base Specifications Issue 8*, IEEE Std 1003.1-2024 (POSIX), `rename`.
  https://pubs.opengroup.org/onlinepubs/9799919799/functions/rename.html.
  What Cemacs took: the guarantee that a rename over an existing name keeps the name leading to the old file or the new one
  at every instant, on which its safe save rests. See [Files and buffers](files.md#never-losing-the-text).
- Mikhail Ramendik, David Faure, Alexander Larsson and Ryan Lortie. *Trash Specification*, version 1.0, freedesktop.org,
  2014-01-02. https://specifications.freedesktop.org/trash/latest/.
  What Cemacs took: the trash in the home, its `files/` and `info/` folders, the `.trashinfo` file written first, and the
  percent-encoded path. Where Cemacs differs is in [Files and buffers](files.md#making-renaming-and-trashing).
- *XDG Base Directory Specification*, version 0.8, freedesktop.org, 2021-05-08.
  https://specifications.freedesktop.org/basedir/latest/.
  What Cemacs took: `$XDG_DATA_HOME`, and `$HOME/.local/share` when it isn't set, for the place of the trash.

## Libraries and fonts

- *SDL3*, Simple DirectMedia Layer, version 3.2 or later. https://www.libsdl.org/. The window, the keyboard, the mouse and
  the drawing.
- *SDL3_ttf*. https://github.com/libsdl-org/SDL_ttf. The text, from TrueType fonts.
- SIL International. *SIL Open Font License*, version 1.1. https://openfontlicense.org/. The license of the three fonts in
  `fonts/`: JetBrains Mono, Adwaita Sans and Noto Sans.
- *The Cesia book.* https://www-celestial.github.io/cesia-lang/. The language Cemacs is written in, and the `cesia check`,
  `cesia run --debugger`, `cesia do` and `--watch` that Cemacs uses.

## Compared, not followed

These are the tools that [Cemacs and other editors](comparison.md) puts Cemacs beside; Cemacs follows neither protocol.

- Microsoft. *Language Server Protocol.* https://microsoft.github.io/language-server-protocol/. Cemacs runs `cesia check`
  instead of a language server.
- Microsoft. *Debug Adapter Protocol.* https://microsoft.github.io/debug-adapter-protocol/. Cemacs speaks a protocol of its
  own with its debugger.
- Visual Studio Code, *Debugger Extension*. https://code.visualstudio.com/api/extension-guides/debugger-extension. How VS
  Code debugs through debug adapters, and how its extensions, written in TypeScript, plug one in.
- GNU Emacs 31.1, https://www.gnu.org/software/emacs/; Neovim 0.12.6, https://neovim.io/; Vim 9.2, https://www.vim.org/.
