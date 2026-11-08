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
- Robert S. Boyer and J Strother Moore. *A Fast String Searching Algorithm.* Communications of the ACM 20(10):762–772,
  October 1977. [doi:10.1145/359842.359859](https://doi.org/10.1145/359842.359859).
  What Cemacs took: nothing; it is the source of what [Speed](performance.md#search) says of Emacs's search, which compares
  the word from its end and skips ahead by tables, with the case folded in them.
- James Gosling. *A Redisplay Algorithm.* Proceedings of the ACM SIGPLAN SIGOA Symposium on Text Manipulation, SIGPLAN Notices
  16(6):123–129, June 1981. [doi:10.1145/800209.806463](https://doi.org/10.1145/800209.806463).
  What Cemacs took: nothing yet; it is the source of what [Speed](performance.md#typing-and-scrolling) says of how Emacs
  redraws a terminal, the screen wanted compared with the screen shown and the cheapest edit of lines found by dynamic
  programming, where Cemacs draws its whole frame at each event.
- GNU Emacs 31.1, `lisp/jit-lock.el`, the documentation of `jit-lock-mode` and of `jit-lock-stealth-time`, and
  `lisp/emacs-lisp/syntax.el`, the documentation of `syntax-ppss-max-span`, read in the installed Emacs.
  What Cemacs took: colouring what the screen shows on demand, then from the true context of the lines above after a pause,
  for a far place; and a cache of parser states kept sparse, its entries at least 20,000 characters apart, which Cemacs
  follows with its states in chunks of 1,024 lines. See [Inside Cemacs](internals.md#the-colours).
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
- Charles Crowley. *Data Structures for Text Sequences.* University of New Mexico, Computer Science Department, June 10,
  1998. https://www.cs.unm.edu/~crowley/papers/sds.pdf.
  What Cemacs took: the piece table, a text held as pieces that view the file read, which is never copied nor changed, and
  the texts of the edits; Crowley compares six structures in one model and an editing simulator, and finds it the best. The
  leaves of Cemacs's rope are such views: see [Inside Cemacs](internals.md#the-rope).
- Peng Lyu. *Text Buffer Reimplementation.* Visual Studio Code blog, March 23, 2018.
  https://code.visualstudio.com/blogs/2018/03/23/text-buffer-reimplementation.
  What Cemacs took: pieces in a balanced tree whose nodes count the bytes and the line breaks under them, and a file kept as
  the texts it was read in, without joining them; VS Code's array of line objects had taken about 600 MB for a file of
  35 MB.
- *Html.lazy*, in *An Introduction to Elm*, the chapter on optimization. https://guide.elm-lang.org/optimization/lazy.html.
  What Cemacs took: skipping the making of a part of the view whose arguments are the same as at the frame before; Elm
  compares them by reference, Cemacs the text, the width and the state of a line by value. See
  [Inside Cemacs](internals.md#the-frame).
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
  What Cemacs took: the trash in the home, its `files/` and `info/` folders, the `.trashinfo` file written first, the
  percent-encoded path, and the date on the local clock. Where Cemacs differs is in [Files and buffers](files.md#making-renaming-and-trashing).
- *XDG Base Directory Specification*, version 0.8, freedesktop.org, 2021-05-08.
  https://specifications.freedesktop.org/basedir/latest/.
  What Cemacs took: `$XDG_DATA_HOME`, and `$HOME/.local/share` when it isn't set, for the place of the trash.

## The case of finding a file

The works that [A case: finding a file from a few letters](finding.md) rests on, in the order of its steps.

- George Pólya. *How to Solve It: A New Aspect of Mathematical Method.* Princeton University Press, 1945.
  What Cemacs took: the first step of the chapter, understanding the problem by its unknown, its data and its condition.
- George H. Heilmeier. *The Heilmeier Catechism.* DARPA. https://www.darpa.mil/about/heilmeier-catechism.
  What Cemacs took: the questions that frame the problem: what you are trying to do, how it is done today and its limits,
  what is new, and the "exams" that check success.
- Robert B. Miller. *Response time in man-computer conversational transactions.* Proceedings of the AFIPS Fall Joint
  Computer Conference, part I, 1968, pages 267–277. [doi:10.1145/1476589.1476628](https://doi.org/10.1145/1476589.1476628).
  What Cemacs took: the budget of a letter: a key shows its effect within 0.1 second, and its echo within 0.1 to 0.2
  second (page 271).
- Stuart K. Card, George G. Robertson and Jock D. Mackinlay. *The Information Visualizer, an information workspace.*
  Proceedings of CHI '91, ACM, 1991, pages 181–186. [doi:10.1145/108844.108874](https://doi.org/10.1145/108844.108874).
  What Cemacs took: 0.1 second, the time constant of perceptual processing, within which the screen must be repainted to
  keep the illusion of animation (table 3, page 185).
- Raj Jain. *The Art of Computer Systems Performance Analysis.* Wiley, 1991. ISBN 978-0-471-50336-1.
  What Cemacs took: a baseline before any change, and the method of a measure.
- Andy Georges, Dries Buytaert and Lieven Eeckhout. *Statistically rigorous Java performance evaluation.* Proceedings of
  OOPSLA 2007, ACM, pages 57–76. [doi:10.1145/1297027.1297033](https://doi.org/10.1145/1297027.1297033).
  What Cemacs took: many runs and an interval, never one timing.
- Tomas Kalibera and Richard Jones. *Rigorous benchmarking in reasonable time.* Proceedings of ISMM 2013, ACM, pages 63–74.
  [doi:10.1145/2464157.2464160](https://doi.org/10.1145/2464157.2464160).
  What Cemacs took: the same, with the versions measured taking turns.
- Andreas Zeller and Ralf Hildebrandt. *Simplifying and isolating failure-inducing input.* IEEE Transactions on Software
  Engineering 28(2):183–200, 2002. [doi:10.1109/32.988498](https://doi.org/10.1109/32.988498).
  What Cemacs took: delta debugging, `ddmin`, which shrank each query that found nothing to a single space.
- T. F. Smith and M. S. Waterman. *Identification of common molecular subsequences.* Journal of Molecular Biology
  147(1):195–197, 1981. [doi:10.1016/0022-2836(81)90087-5](https://doi.org/10.1016/0022-2836(81)90087-5).
  What Cemacs took: the idea of the score: an alignment that rewards matches and charges for gaps, found best by filling a
  table.
- Osamu Gotoh. *An improved algorithm for matching biological sequences.* Journal of Molecular Biology 162(3):705–708,
  1982. [doi:10.1016/0022-2836(82)90398-9](https://doi.org/10.1016/0022-2836(82)90398-9).
  What Cemacs took: a gap weight w(k) = uk + v in about one step per cell, through a second table: fzy's table D.
- John Hawthorn. *fzy*, its `ALGORITHM.md`, `src/config.def.h`, `src/bonus.h` and `src/match.c`. https://github.com/jhawthorn/fzy.
  What Cemacs took: the score of [lists.Score], its bonuses and its gaps, in thousandths.
- The Vim project. Patch 9.1.1627, *fuzzy matching can be improved*, by Girish Palya, August 2025, and `:help
  fuzzy-matching` in Vim 9.2 and Neovim 0.12.6. https://github.com/vim/vim.
  What Cemacs took: the words of a filter matched apart, in any order; and Vim's `matchfuzzy()` as the check of its ranks.
- Junegunn Choi. *fzf*, its `src/algo/algo.go` and its manual. https://github.com/junegunn/fzf.
  What Cemacs took: nothing of its points; it is the source of what the chapter says of fzf, and of its `--scheme=path`.
- Free Software Foundation. *GNU Emacs Manual*, section *Completion Styles*, and `project.el` and `minibuffer.el` of Emacs
  31.1. https://www.gnu.org/software/emacs/manual/html_node/emacs/Completion-Styles.html.
  What Cemacs took: the key `C-x p f`, and `git ls-files -z -c -o --exclude-standard` for the files of a project.
- Ellen M. Voorhees. *The TREC-8 Question Answering Track Report.* The Eighth Text REtrieval Conference (TREC-8), NIST
  Special Publication 500-246, 1999, pages 77–82. https://trec.nist.gov/pubs/trec8/papers/qa_report.pdf.
  What Cemacs took: the mean reciprocal rank, the measure of the ranking.
- Koen Claessen and John Hughes. *QuickCheck: a lightweight tool for random testing of Haskell programs.* Proceedings of
  ICFP 2000, ACM, pages 268–279. [doi:10.1145/351240.351266](https://doi.org/10.1145/351240.351266).
  What Cemacs took: property-based tests, through Cesia's `test.ForAll`.
- Todd Mytkowicz, Amer Diwan, Matthias Hauswirth and Peter F. Sweeney. *Producing wrong data without doing anything
  obviously wrong!* Proceedings of ASPLOS 2009, ACM, pages 265–276.
  [doi:10.1145/1508244.1508275](https://doi.org/10.1145/1508244.1508275).
  What Cemacs took: the threats to validity of a timing, and why the versions run in the same way, taking turns.

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
