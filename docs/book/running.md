# Running and debugging

Cemacs runs the Cesia file you edit, shows what it prints as it comes, and stops it. It also runs it under a debugger, a
program that runs yours and can stop it at a line to show its variables. This chapter tells both. The commands are in
[core/commands], and what they ask of the program is in [core/run].

## Running a file

| Keys | Command | What it does |
|---|---|---|
| `C-c c r`, `C-c C-c` | [commands.Run] | runs the file of the current buffer |
| `C-c c k`, `C-c C-k` | [commands.Stop] | asks the program that runs to end |
| `C-c c h` | [commands.ToggleOutput] | hides the output, or shows it again |
| `C-c c o`, `C-c C-o` | [output.ShowOutput] | opens the whole output as a list, on its last error |

`C-c c r` runs the file as it is on disk: Cemacs doesn't save it first. A buffer whose text isn't saved runs its last save, and
the prompt line says `Running PATH as saved, without the changes here.`; else it says `Running PATH.` A buffer with no file
says `This buffer has no file to run: save it first.`

The program is a process of its own, started from the folder where Cemacs started, in one of two ways:

- `cesia run PATH`, as fast as from a terminal, and with no permission: it computes and prints, and stops at the first file it
  reads, with the permission it lacks in its output. The first line of the output is the command, `> cesia run PATH`.
- `cesia do TASK`, when the `cesia.toml` of that folder has a task whose `file` is this file: see below.

`C-c c r` while a program runs ends it first: it sends it the TERM signal, the usual request to end, and waits up to 2
seconds, reading what it writes meanwhile, so that a server gives back its port before the new one starts. A program that
hasn't ended by then is left running, nothing new starts, and the prompt line says
`The program that runs doesn't end: C-c c k asks it again.` A program that can't start at all, because `cesia` isn't on the
`PATH` for instance, says `PATH doesn't run: REASON`.

### The task that runs a file

A task of `cesia.toml` is a program to run with its permissions, as Cesia's book tells in its chapter on packages. When the
`cesia.toml` of the folder where Cemacs started has a task whose `file` is the file of the buffer, `C-c c r` runs that task,
through `cesia do`, and the prompt line says `Running PATH as the task NAME.`:

```toml
[tasks.serve]
file = "src/server.ce"
allow = ["read=data", "net=:8080"]
watch = true
```

The task brings its `allow`, its `limit`, its `watch` and the tasks it `needs`, which `cesia do` runs first. `cesia do` writes
its own command as the first line of the output, with the permissions: `> cesia run --allow read=data,net=:8080 ...`. With
`watch = true` the program runs under `--watch`: each save of one of its files loads the new code into the program that runs,
a hot reload, and a program that has ended starts again.

[run.TaskFor] finds the task. Both paths are read from the folder where Cemacs started, so `src/server.ce` and
`/home/me/app/src/server.ce` name the same file there; the first task that names it wins, and a task whose `file` is `.`,
the whole project, runs no single file:

```cesia
use core/run
run.TaskFor("[tasks.serve]\nfile = \"src/a.ce\"\n", "/p/src/a.ce", "/p") --> "serve"
run.TaskFor("[tasks.all]\nfile = \".\"\n", "a.ce", "/p") --> missing
```

Only the `cesia.toml` of the folder where Cemacs started is read, since `cesia do` reads the one of the folder it runs in. A
file of another project runs with `cesia run`, with no permission.

### The output

What the program writes, on its standard output and its errors alike, comes to Cemacs as one stream, read by a fiber, a task
of Cesia that waits for the program while the editor goes on; Cesia's book tells fibers in their chapter. At each pass of its
loop, Cemacs takes what came, cuts it into lines, and shows the last ones that fit in the output, the line not yet ended
too. It keeps the last 1,000 lines. [run.Read] does the cutting:

```cesia
run.Lines(run.Read("one\ntwo\nthr", run.Empty())) --> ["one", "two", "thr"]
```

The title of the output is followed by the state of the program: `running`, then `ended, code N` with its exit code, the
number a program gives back when it ends, 0 when all went well. A program ended by `C-c c k` shows `ended, code -1`, as Cesia
gives -1 for a program ended by a signal.

Cemacs writes nothing to the program's input: a program that reads its standard input waits until you stop it. A new run
replaces the output of the last one.

`C-c c o` opens the whole output as a list, with the cursor on the last error, a line that starts with a place as
`src/a.ce:4:11: `. The list grows as the program writes; typing filters it, and Enter on a line that names a place of a file
goes there: see [Search](search.md#places-in-the-output). The output stays below the panes while the list is open.

`C-c c k` says `Stopping the program.` and sends TERM, which ends a Cesia program; one that takes that signal for itself may
need a second `C-c c k`. With no program running it says `No program is running.`, and `C-c c h` with no run yet says
`There is no output yet: C-c c r runs the file.`

## Tests

Cesia's tests are the examples in the documentation of a function, a line with `-->` and the value it should give, and the
test functions of the `.test.ce` files, whose names start with `is` and a capital: Cesia's book tells them in its chapter
on [tests](https://www-celestial.github.io/cesia-lang/tests.html). The keys are a group of `C-c`, `t` for test, of
[src/ide], which asks [src/testing] what to run:

| Keys | Command | What it does |
|---|---|---|
| `C-c t t` | [ide.TestHere] | in a `.test.ce` file, runs the test function the cursor is in; elsewhere, or outside one, the tests of the folder of the file |
| `C-c t a` | [ide.TestAll] | runs every test of the project |
| `C-c t r` | [ide.TestAgain] | runs the last tests again, from any buffer |

Each runs `cesia test` as `C-c c r` runs a program, in the folder where Cemacs started: `C-c t t` inside `isTotal` of
`src/shop/shop.test.ce` runs `cesia test src/shop/shop.test.ce:isTotal`, which runs that test alone; in `src/shop/shop.ce`,
`cesia test src/shop`, the package with the examples of its documentation and its tests; `C-c t a` runs `cesia test`. A test
function is found as the nearest definition at the top of the file above the cursor, `isTotal() = ...` or `defn isTotal()`,
when its name is one of a test. The command is the first line of the output, below the panes, and a program that runs is
stopped first, as for `C-c c r`. In a test, `--> 5` says what an example must give:

```cesia norun
(** Twice.

      Twice(2) --> 5 *)
Twice(x) = x * 2
```

Once the tests end, the prompt line says what `cesia test` said last, as `1 passed, 2 failed`, and each failure, a line of
the output that starts with the path of a file of Cesia and a line, as `src/a/a.ce:5: Twice(2) --> 5, got 4`, becomes a red
mark on that line, in the buffer of that file if one is open, with the words of the failure and the two lines under it that
tell more, as `isOne failed  Twice(1) == 3  | Twice(1) = 2`. The marks are those of [Errors in the lines](check.md): the
mode line counts them, `M-g n` and `M-g p` go to them, the prompt line tells the one under the cursor. A check of the file
keeps them, a line you change loses its mark, as the check's do, and the next run of tests takes them all away. `C-c c o`
lists the output on the last failure, and Enter goes to the place a line names, `(path:line)` under a failure included.

`cesia test` gives each test the permissions it has by Cesia's rules, a test reading the files of its project and writing
only in its own folder, and those that `allow` of `[test]` in the `cesia.toml` of the project adds; Cemacs adds none.

## Debugging

| Keys | Command | What it does |
|---|---|---|
| `C-c d r` | [commands.DebugRun] | runs the file under the debugger of Cemacs |
| `C-c d b` | [commands.ToggleBreak] | puts a breakpoint on the line of the cursor, or takes it away |
| `C-c d e` | [commands.Eval] | evaluates the selection, or else the line of the cursor, in the program |
| `C-c d c` | [commands.Continue] | goes on to the next stop |
| `C-c d n` | [commands.StepOver] | runs one line, a call in it as a whole, and stops |
| `C-c d s` | [commands.StepInto] | runs one line, going into a call in it, and stops |
| `C-c d u` | [commands.StepOut] | runs on until the function returns, and stops |

`C-c d r` runs `cesia run --debugger HOME/tools/debugger.ce PATH`, `HOME` being the folder of Cemacs: Cesia's own debugger
runs beside the program and calls `tools/debugger.ce` at each stop. Cesia's debugger stops every program before its first
line; there, `tools/debugger.ce` takes the breakpoints you have set, which Cemacs sent with the start, and lets the program go
on without telling Cemacs, so the state stays `running`. Only a breakpoint on that first line makes it a stop that you see.
It runs nearly as fast as without the debugger until it reaches a breakpoint: Cesia's
book tells why in its chapter on the prompt and the debugger. It runs with no permission, even when a task runs the file:
`cesia do` can't start a debugger.

### Breakpoints

A breakpoint is a line where the program stops each time it reaches it. `C-c d b` puts one on the line of the cursor,
`Breakpoint on line N.`, or takes it away, `Breakpoint removed.`; it shows as a dot of colour before the number of the line.
A program that runs takes it at once. The breakpoints stay in the editor from one run to the next, each a file and a line
number: lines added above one don't move it. A buffer with no file says `A breakpoint needs a file: save the buffer first.`

### A stop

The program stops at a breakpoint, after a step, and on an error, a bug that would end it, with every variable still there.
Then:

- the state after the title of the output says `stopped at PATH:LINE`, or `stopped on an error at PATH:LINE`;
- the line of the stop has a band of colour, in a buffer of that file if one is open: Cemacs doesn't open the file for you;
- the output is titled `Variables` and lists each variable of the function where the program stopped, the innermost frame of
  its calls, as `name = value`, after the message of the error for a stop on an error.

`C-c d c`, `C-c d n`, `C-c d s` and `C-c d u` go on from a stop; with the program running, they say
`The program isn't stopped.` After an error, `C-c d c` lets the error go on, as it would without the debugger.

### Evaluating code

`C-c d e` sends the selection, or else the line of the cursor, to the program, which runs it and sends back its value. The
value shows at the end of the line it came from, the last line of the selection, two characters after it, in grey and after
`= `; an error shows as `= error: MESSAGE`. It is not part of the text: it is drawn, not typed, and a save doesn't write it.

At a stop, the code runs in the innermost frame, and sees its variables. While the program runs, it runs at the file level of
its main file, as the prompt of `cesia run --repl` would. An expression only reads: it never changes the program. Without a
program under the debugger, `C-c d e` says `No program runs under the debugger: C-c d r runs the file under it.`

### Fix and continue

While the program is stopped, you can change its code and save it. When it goes on, by any of the four keys, the debugger
reloads the files that changed: the function that was running finishes with its old code, and its next call runs the new one.
A file that doesn't load, with an error in it, isn't loaded: the state says `the fix doesn't load`, the program stays stopped
where it was, with its line still marked, and the errors of the file show in the output after the variables, the last lines
of the pane, so that they are seen; they are added to the whole output too, which `C-c c o` lists. From there:

- fix the file, save it, and go on with any of the four keys: the fix loads then;
- or go on without fixing it: Cesia counts the file as read, so the program goes on with the code it had, and the next
  fix you save loads at the next stop.

```cesia
atLine3 = "$(run.Mark){\"Kind\": \"stop\", \"File\": \"a.ce\", \"Line\": 3, \"Reason\": \"break\", \"Error\": \"\", \"Fiber\": 0, \"Vars\": []}\n"
refused = "$(run.Mark){\"Kind\": \"reload\", \"Ok\": false, \"Text\": \"a.ce:3:7: Expected an expression, found *.\"}\n"
after = run.Read(refused, run.Resume("continue", run.Read(atLine3, run.Empty())))
after.Status --> "the fix doesn't load"
run.StoppedAt("a.ce", after) --> 3
run.FixOf(after) --> ["a.ce:3:7: Expected an expression, found *."]
```

[run.Resume] keeps the stop it leaves until the debugger has loaded the fixes, and a fix that doesn't load brings it back.

### How Cemacs speaks with the debugger

The debugger of Cemacs, `tools/debugger.ce`, is a small Cesia program that speaks with the editor over the program's own input
and output. Each of its messages is one line that starts with the byte 1, a control character that no ordinary output holds,
and goes on with a map in JSON:

| `Kind` | Its fields | When |
|---|---|---|
| `"stop"` | `File`, `Line`, `Reason`, `Error`, `Fiber`, and `Vars`, each a `Name` and a `Value` | the program stopped, but not before its first line, unless a breakpoint is there |
| `"value"` | `Id`, `Ok`, `Text` | the answer to an eval |
| `"reload"` | `Ok`, `Text` | a fix didn't load, after a word to go on: the program still waits at its stop |

Cemacs writes one command per line, a map in JSON whose `Do` is `"eval"` with an `Id` and the `Code`, `"break"` or `"clear"`
with a `File` and a `Line`, or `"continue"`, `"step"`, `"next"` or `"out"`. Every other line the program writes is its
output. [run.Read] reads both:

```cesia
stop = "$(run.Mark){\"Kind\": \"stop\", \"File\": \"a.ce\", \"Line\": 3, \"Reason\": \"break\", \"Error\": \"\", \"Fiber\": 0, \"Vars\": []}"
r = run.Read("hello\n$stop\n", run.Empty())
r.Output --> ["hello"]
r.Status --> "stopped at a.ce:3"
```

This is a protocol of Cemacs's own, not the Debug Adapter Protocol that VS Code and other editors speak: the debugger's side
is one program of 137 lines, and Cesia's [std/debug] gives the rest.

Since the program's input carries the commands of the editor, a program that reads its standard input doesn't run right under
`C-c d r`. And the debugger shows the innermost frame only: to go up the calls, to watch an expression at each stop, or to
put a condition on a breakpoint, use Cesia's debugger in a terminal, `cesia run --debugger debugger FILE`, which has them.
