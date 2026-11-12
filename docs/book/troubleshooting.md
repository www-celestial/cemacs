# Troubleshooting

This chapter lists every message of Cemacs, where it shows, what it means and what to do. Messages at the start go to the
terminal that started Cemacs; messages while it runs go to the prompt line, at the bottom of the window; the state of a
program goes after the title of the output.

## At start

When the window can't open, Cemacs prints the reason in the terminal, as a Cesia value, and ends. When it ends normally, it
prints `Ok(missing)`.

| What the terminal shows | Why | What to do |
|---|---|---|
| `bash: cesia: command not found`, or `cesia: command not found` | Cesia isn't installed, or not on the `PATH` | install Cesia: see [Install](install.md#cesia) |
| `This project needs Cesia 1.1 or later, and this is ...: run cesia upgrade.` | the Cesia on the `PATH` is older than `cesia.toml` asks | `cesia upgrade` |
| `Err({Kind: "c", Message: "Can't load SDL3: libSDL3.so.0: cannot open shared object file: No such file or directory."})` | SDL3 isn't installed, or isn't where the system looks | install it, or set `LD_LIBRARY_PATH` to its folder: see [Install](install.md#sdl3-and-sdl3_ttf) |
| the same with `SDL3_ttf` and `libSDL3_ttf.so.0` | SDL3_ttf is missing | the same |
| `Err({Kind: "sdl", Message: "This program needs SDL 3.2 or later."})` | the SDL3 found is a 3.0 or 3.1 | a newer SDL3, from the system or from `tools/sdl-libs.sh` |
| `Err({Kind: "sdl", Message: "Couldn't open .../fonts/AdwaitaSans-Regular.ttf: No such file or directory"})` | the fonts aren't in the folder Cemacs took as its home | start Cemacs through `bin/cemacs`, which finds its folder, or run `cesia do dev` from the folder of Cemacs |
| `Err({Kind: "sdl", Message: ...})` with another reason, such as `No available video device` | SDL found no display to open a window on | start Cemacs in a graphical session; `SDL_VIDEODRIVER=wayland` or `x11` chooses the display system |
| `Permission "ffi" denied for SDL3.`, or another `Permission ... denied` | Cemacs was started with `cesia run` without its permissions | start it with `bin/cemacs`, or `cesia do dev` |
| `cesia.toml:4:1: The source folder "user" doesn't exist.` | Cesia ran in the folder of Cemacs before `user/` was made, as `cesia test`, `cesia check`, `cesia doc` or `cesia run src/cemacs.ce` in a new clone: `cesia.toml` names `user` among the folders of the code | start Cemacs once through `bin/cemacs` or `cesia do dev`, or run `tools/user.sh`: each makes `user/` from the template. [Install](install.md#your-folder-user) |
| `.../src/cemacs.ce:12:5: Module "user/config" doesn't exist.` | `user/` is there, but not its `config/`: Cemacs makes `user/` only when it is missing | put `user/config/config.ce` back, or move `user/` away and start again: a new one comes from the template |
| `user/config/config.ce:LINE:COLUMN:` and a mistake, as `Name "nothere" doesn't exist.` | your config doesn't load: Cesia shows the line and the place | fix it with another editor; or move `user/` away, and the next start makes a new one from the template. [Changing Cemacs](customising.md#your-folder-user) |
| a mistake followed by `in Config (.../src/cemacs.ce:...)` or `called from Start (core/editor/editor.ce:...)`, as `Changed needs the argument "more".` | your config loads, but `Changed`, or a function it set, fails when the window reads the config at its start: a `Start` that reads a field the state lacks, for instance | the same |

## On the prompt line

These are the messages of the commands, in the order of the chapters. A message stays until the next key or click.

### Editing

| Message | What happened |
|---|---|
| `Quit` | `C-g` stopped what the keys had started: the mark, a question, or a prefix key |
| `KEYS is not bound.`, as `C-t is not bound.` or `C-x C-t is not bound.` | nothing is bound to those keys, and nothing starts with them; nothing changed. [Keys](keys.md) lists every key, and `C-x ?` or `C-c ?` lists those after a prefix |
| `C-x -` | a prefix key waits for the next key; `C-g` forgets it |
| `Nothing is selected.` | `C-w` or `M-w` with no selection: set the mark with `C-space`, or hold Shift while you move |
| `The clipboard is empty.` | `C-y` with nothing in the clipboard |
| `Nothing to cut.` | `C-k` at the end of the file |
| `No completion for WORD.`, as `No completion for Hzq.` | Tab at the end of a word in a file of Cesia found no word that starts with it, in the text around the cursor, the other buffers or the names of Cesia: [Editing](editing.md#completion) |
| `This list is read only.` | a command tried to change the text of a list, and was taken back |
| `Nothing here.` | a key of a list with no row left, as Enter after a filter that matches nothing: Backspace takes the filter back |

### The prompt line

| Message | What happened |
|---|---|
| `No answer before this one.`, `No answer after this one.` | `M-p` or `M-n` at an end of the answers given to the question |
| `{no match}`, after the answer | Tab in `Find file: ` found no entry of the folder that matches the last part of the answer |

### Files and buffers

| Message | What happened, and what to do |
|---|---|
| `Saved PATH` | the save worked |
| `No file name.` | an empty answer to `Find file: ` or `Save as: ` |
| `PATH is a folder.` | `C-x d` shows a folder; `C-x C-f` opens files |
| `PATH is not a regular file: it may be a device, a pipe or a socket.` | Cemacs opens regular files only |
| `PATH is too large to open: SIZE bytes, and the limit is 1073741824.` | Cemacs opens files of 1 GiB at most, which take about twice their size in memory as they open: see [Files and buffers](files.md#which-files-open) |
| `PATH is not valid UTF-8 text, or holds a zero byte.` | the file is in another encoding, or isn't text; convert it to UTF-8 with `iconv`, for instance |
| `PATH is open in another buffer.` | `Save as` to a file already open: save that buffer, or close it first |
| `A list has no file.` | a save in a list |
| `Not saved.` | you answered `n` to `File changed on disk. Overwrite?`: both texts are as they were |
| `No free name next to PATH for a new file.` | 21 names for the new file of a save were taken: remove the files `PATH.cemacs-...` left beside it |
| `PATH was saved, but its time couldn't be read: REASON` | the text is on disk, but the next save of this buffer will ask before writing |
| a reason from the system, such as a permission refused | reading or saving failed; on a failed save, the old file is whole and the buffer keeps its text and its star |

### The folder manager

| Message | What happened |
|---|---|
| `This is the root.` | Backspace at `/` |
| `No folder matches.` | `/` after letters that match no folder |
| `HOME is not set.` | `~/` with no `HOME` in the environment |
| `No file or folder at PATH.` | `C-y` with a path in the clipboard that leads nowhere |
| `No name.` | an empty answer to `New file, or folder/: ` |
| `NAME already exists.` | a new name, or a rename, to a name that is taken |
| `There is no trash: HOME is not set.` | neither `XDG_DATA_HOME` nor `HOME` is set, so there is no trash to move to |
| `Can't move NAME to the trash: REASON` | most often a file on another disk than your home: see [Files and buffers](files.md#making-renaming-and-trashing). The file stays where it was |
| a reason from the system | reading the folder, making, or renaming failed |

### The files of a project

| Message | What happened, and what to do |
|---|---|
| `FOLDER/ is in no Git repository.` | `C-x p f` from a file, or a start folder, outside any Git repository: open a file of the project first, or `git init` it |
| `Can't run git: no such file or directory.` | `git` is not on the `PATH`: install it |
| `git ls-files failed: REASON` | Git found the repository but couldn't list it; REASON is Git's own words |

### Searching a project

| Message | What happened |
|---|---|
| `Searching NAME for WORDS...` | `C-x p g` started git grep in the repository NAME |
| `N lines. C-c r replaces in those shown.` | the list of the search; `, the first 10000 only` when it was cut there |
| `No line of the project holds WORDS.` | git grep found nothing |
| `No words to search.` | Enter on an empty answer |
| `FOLDER/ is in no Git repository.` | the search of a project needs one, as `C-x p f` |
| `git grep failed: REASON`, `git can't run: REASON` | git ended with an error, or couldn't start: is it on the `PATH`? |
| `No place of WORDS is left in those lines.` | `C-c r` after the lines changed, or a filter that kept none |
| `Replaced WORDS with NEW: N files saved.` | the replace is done, told as a rename tells it |
| `Not replaced.` | `n` to the question of a replace |

### Windows and panes

| Message | What happened |
|---|---|
| `This pane is too small to split.` | a half would have less than 2 lines or 8 characters: make the window larger, or `C-x 1` |
| `This is the only pane.` | `C-x 0` on the last pane |

### Errors in the lines and the output

| Message | What happened |
|---|---|
| `No error here.` | `M-g n` or `M-g p` in a buffer with no mark |
| `cesia check can't run: REASON` | the check couldn't start `cesia`: is it on the `PATH`? It is said once; the next change of the buffer tries again |
| `This line names no place of a file.` | Enter in the output on a line without `PATH:LINE:COLUMN: ` or `(PATH:LINE)` |
| `PATH isn't there.` | Enter in the output on a place of a file that doesn't exist from the folder where Cemacs started |
| `There is no output yet: C-c c r runs the file.` | `C-c c h` or `C-c c o` before any run |

### Names

| Message | What happened |
|---|---|
| `Names are those of a file of Cesia.` | `M-.`, `M-?`, `C-c c i` or `C-c c m` in a buffer that isn't a saved `.ce` file, or in a list |
| `No name here.` | the cursor is on no name, nor just after one |
| `No definition of NAME found.` | `M-.` on a name that no file of its package, nor of the packages it uses, defines at its top, as a local or a parameter |
| `No documentation of NAME found.` | `C-c c i` on such a name |
| `No definition of NAME found in the project.` | `M-?` on a name that isn't defined in the project, nor documented by Cesia |
| `No place to go back to.` | `M-,` with no place left on the stack |
| `N places.`, `N places (by name: a method).` | the list of `M-?`; a method is found by name, every `.NAME` of the project: [Names](names.md#the-references) |
| `..., N files don't read.` | some files of the project don't read, so their places aren't listed: open them, the check shows why |
| `Nothing reads NAME.` | the name is defined, and nothing reads it |
| `The lookup failed: WORDS` | `tools/lookup.ce` didn't answer in JSON, or ended with an error: WORDS is the first line it wrote |
| `cesia can't run the lookup: REASON` | `cesia` couldn't start: is it on the `PATH`? |
| `The lookup gave no places.`, `... no documentation.`, `... no edits.` | the answer of the lookup wasn't of the shape Cemacs reads, which it checks before it opens a file |
| `NAME is a method: its calls ... can't be told from those of other methods of the name.` | a method or a field can't be renamed |
| `NEW is not a name: a letter, then letters and digits.` | the new name of a rename has another character, or is a word of Cesia |
| `NEW would be public: ...`, `NEW would be private: ...` | a rename keeps the case of the first letter, which says in Cesia whether a name is public |
| `NEW is defined already, at PATH:LINE.` | the package has that name already |
| `NEW would be another name at PATH:LINE: choose another one.` | at that line, a local or a parameter of the new name would take the place of the renamed one |
| `PATH doesn't read: fix it first, so that its places of NAME are known.` | a file of the project that reads the package doesn't parse: a rename would leave its places |
| `Renamed NAME to NEW: N files saved.` | the rename is done; `, N left unsaved, with changes of their own` and `, N changed since, left as they are` tell the files it didn't save or didn't change |
| `Not renamed.` | `n` to the question of a rename |

### Running and debugging

| Message | What happened |
|---|---|
| `Running PATH.`, `Running PATH as the task NAME.` | the program started; the second runs a task of `cesia.toml`, with its permissions |
| `Running PATH as saved, without the changes here.` | the buffer has changes not saved: the program runs the file on disk. Save, then `C-c c r` again |
| `This buffer has no file to run: save it first.` | `C-c c r` or `C-c d r` in a buffer with no file |
| `PATH doesn't run: REASON` | `cesia` couldn't start: is it on the `PATH`? |
| `The program that runs doesn't end: C-c c k asks it again.` | `C-c c r` asked the program that ran to end, and it didn't within 2 seconds: nothing new started |
| `Stopping the program.` | `C-c c k` sent the TERM signal |
| `No program is running.` | `C-c c k` with nothing running |
| `Breakpoint on line N.`, `Breakpoint removed.` | `C-c d b` |
| `A breakpoint needs a file: save the buffer first.` | `C-c d b` in a buffer with no file |
| `No program runs under the debugger: C-c d r runs the file under it.` | `C-c d e` without a program run by `C-c d r` |
| `The program isn't stopped.` | `C-c d c`, `n`, `s` or `u` while the program runs: they go on from a stop only |
| `Testing: cesia test TARGET` | `C-c t t`, `C-c t a` or `C-c t r` started the tests: [Running and debugging](running.md#tests) |
| `N passed, M failed` | the tests ended; each failure is a mark in the lines of its file |
| `The tests ended: ended, code N.` | the tests ended without the count of `cesia test`, as when `C-c c k` stopped them |
| `Tests are those of a file of Cesia.` | `C-c t t` in a buffer that isn't a `.ce` file |
| `No test ran yet: C-c t t runs those of the file.` | `C-c t r` before any test ran |
| `cesia test doesn't run: REASON` | `cesia` couldn't start: is it on the `PATH`? |

### Questions

| Question | What it asks |
|---|---|
| `Find file: ` | the path of a file to open |
| `Save as: ` | the path to save a buffer with no file |
| `Text not saved. Close anyway? (y or n)` | `C-x k` on a buffer not saved: `y` loses its changes |
| `Text not saved. Quit anyway? (y or n)` | quitting with a buffer not saved: `y` loses every unsaved change |
| `File changed on disk. Overwrite? (y or n)` | the file changed since Cemacs read it, or a file is there already: `y` writes over it |
| `New file, or folder/: ` | in the folder manager, the name to make |
| `Rename NAME to: ` | in the folder manager, the new name or path; in a file of Cesia, after `C-c c m`, the new name of a name of the code |
| `Rename NAME to NEW in N places of M files? (y or n)` | `C-c c m`: `y` makes the edits, as [Names](names.md#a-rename) tells |
| `Search project: ` | `C-x p g`: the words to look for in the project |
| `Replace WORDS with: `, `Replace N places of WORDS in M files with NEW? (y or n)` | `C-c r` in the list of a search |
| `Move NAME to the trash? (y or n)` | in the folder manager |
| `I-search: `, `I-search backward: ` | a search is open: what you type is looked for, Enter stays, `C-g` goes back; see [Search](search.md#searching-a-buffer) |
| `Failing I-search: ` | no place of the words is left that way: `C-s` or `C-r` again goes round the end, `C-g` takes back what matched nothing |
| `Wrapped I-search: `, `Failing wrapped I-search: ` | the search went round the end of the file; failing, the words are nowhere in it |

## After the title of the output

| State | What it means |
|---|---|
| `running` | the program runs, or goes on after a stop |
| `ended, code N` | the program ended with the exit code N: 0 when all went well, -1 when a signal ended it, as `C-c c k` does |
| `stopped at PATH:LINE` | the program waits at a breakpoint, or after a step |
| `stopped on an error at PATH:LINE` | a bug stopped the program under the debugger; the output shows the error and the variables |
| `the fix doesn't load` | a file changed while the program was stopped has an error, and wasn't loaded; the program waits at its stop, and the output shows the error after the variables. Fix and save, then go on: see [Fix and continue](running.md#fix-and-continue) |

## When Cemacs stops by itself

Cemacs can stop with an error, a panic, which ends the program: the text not saved in its buffers is lost, since it has no
autosave. Cesia prints the error in the terminal, with its place in the code. Under `cesia do dev`, the program then waits
for the next save of one of its files, and starts again, with no buffer.

None of these should happen with the code as it is; each comes from a change to Cemacs, or from a limit:

| Error | Why |
|---|---|
| a call with the wrong number of arguments, from a key | a function bound to a key with another number of parameters than a command's one, or a mouse binding's two: see [Changing Cemacs](customising.md#reloading-cemacs-while-it-runs) |
| a field that doesn't exist | code reads a field of the state that a state from before a reload doesn't have: read it through a `match` with a default |
| `This window has no font "NAME".` | a drawing command named a font the window didn't open; Cemacs opens `body`, `strong` and `code` |
| `A frame has no command "KIND".`, `A radius goes from 0 to 24, not R.`, `A curves command holds at most 1024 curves.`, `A window can't hold more than 4096 images.` | a drawing command that `src/sdl` doesn't take: the frame of Cemacs uses none of these |
| a reason from SDL | a drawing call failed on a window that should take it: a bug of SDL or of the graphics driver |

## Slow or busy

- **A large file takes a while to open, and memory.** About 0.27 s and 220 MB for 100 MB, the start, the check of UTF-8
  and the line ends of the rope taking most of it: [Speed](performance.md#opening-a-file) has the numbers.
- **After a jump far down a large file, or a search that goes there, the colours change a few seconds later.** The place
  shows at once, with the colours of its lines guessed; the state of every line above it is then read, 25,000 lines a tick,
  about 4 s for the last line of 100 MB, and the screen is drawn again with its exact colours. Meanwhile a key can wait up to
  about 60 ms more. The states are kept, so the next jumps cost nothing: [Inside Cemacs](internals.md#a-far-place-first-its-exact-colours-after).
- **A large Cesia file shows no errors.** Its mode line says `not checked: over 1 MB`: Cemacs doesn't check a buffer over
  1,000,000 bytes. [Errors in the lines](check.md#when-it-runs) tells why.
- **The processor works while a program runs.** While a program runs, a check runs or a buffer waits for one, Cemacs draws a
  frame at each pass of its loop: see [Inside Cemacs](internals.md#the-loop-of-events). Stop a program you don't need.
- **The output shows only its last lines.** It keeps 1,000 lines; `C-c c o` opens them all as a list.

## The tests

`cesia do test` stops at its first failure, and says which step. `tests/color-std.ce`, one of its steps, and
`bench/gate.ce` read the sources of Cesia's standard library that the binary of Cesia carries, through [cesia.Libraries]: no
clone of Cesia is needed. `tests/files-check.ce` and `tests/commands-check.ce` make a sparse file of 1 GiB and one byte with
`truncate`, a file that takes no room on the disk, to check the limit of size.
