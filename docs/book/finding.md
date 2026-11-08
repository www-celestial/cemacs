# A case: finding a file from a few letters

This chapter follows one real problem from start to end, the way a researcher would: the problem said precisely, a
measure before anything changes, a hypothesis that an experiment could prove wrong, the research that already solved this
kind of problem, the smallest change to Cemacs, and the proof that the problem is solved, with what could make the proof
wrong. It ends with what is left. Every block of Cesia code below ran when this page was built, against the code of
Cemacs, and the lines with `-->` were checked. The works cited are in [References](references.md#the-case-of-finding-a-file).

The problem is an ordinary one. You work in a project of a few thousand files, you know part of a file's name, and you want
it open in a few keys.

## 1. The problem, stated precisely

George Pólya's *How to Solve It* (1945) starts every problem with the same questions: what is the unknown, what are the
data, what is the condition? George Heilmeier, who ran DARPA from 1975 to 1977, asked the same of any project in plain words,
in what is now called the Heilmeier catechism: what are you trying to do, how is it done today and what are its limits,
what is new, and what are the exams that will tell you it worked? Answered for this problem:

- **What you want.** You are in a project, Cesia's own repository for the measures of this chapter: 1,933 files, 1,574 of
  them tests. You remember part of a name, such as "the messages file", or "something with reload and test". You type a few
  letters, maybe with gaps, maybe in another order than the name has them, and you want the file you mean on the first
  row, where Enter opens it.
- **How it is done today.** Cemacs has no list of a project's files. `C-x C-f` asks for a path, which you must know;
  `C-x d` lists one folder at a time, and you must know which. Both lists filter by [subsequence matching](search.md#how-a-filter-matches),
  and keep their rows in their own order: the rows aren't ranked, so the row you mean is first only when every row before it
  is filtered out.
- **What "solved" means**, as three properties that a measure can check:
  1. *Exact.* The list shows every file whose path holds the letters, and no other: each word of what you typed, the words
     being split at the spaces, must come in the path in order, letters side by side or not, whatever their case.
  2. *The file you mean comes first, or near.* On a fixed set of queries written down before any change, the file meant is
     on the first row for at least three queries in four, and in the first five rows for nine in ten.
  3. *Each letter answers at once.* Robert Miller's study of response times (1968) asks that a key show its effect within
     0.1 second, and from a key to its echo on the screen within 0.1 to 0.2 second; Card, Robertson and Mackinlay (1991)
     give 0.1 second as the time constant of perceptual processing: to keep the illusion of animation, the screen must be
     repainted at least every 0.1 second. So the list must be filtered, ranked and drawn within 0.1 second of each letter,
     on the slowest letter. Cemacs's own goal is stricter: a key to its frame within 16 ms, one frame at 60 frames a second
     ([Speed](performance.md)).
- **Out of scope.** A letter typed wrong, which subsequence matching can't forgive; what the files hold, which is a search
  through files; files outside the project; and a ranking that learns from the files you opened before.

## 2. Measure before changing anything

A measure taken before the change is the baseline: without it, nothing after can be called better. Raj Jain's *The Art of
Computer Systems Performance Analysis* (1991) teaches the order of a sound study: the goal and its metrics first, then the
workload, then the measures, each given with its variation and not as one number. Georges, Buytaert and Eeckhout (2007) and
Kalibera and Jones (2013) show how easily a single timing misleads: a time here is the median of many runs, with its
interval, as [Speed](performance.md#how-it-was-measured) does.

### The files and the queries

The files are those of Cesia's repository at its commit fa1701d, as Git lists them, in Git's order, which sorts the paths
byte by byte: `git ls-tree -r --name-only fa1701d`. A list given these rows shows them in that order.

The queries were written before any line of the change, each with the file it means, in six kinds: the start of a name;
letters with gaps, as one abbreviates; a folder and a name; words in any order, apart; initials; and a test. They are in
`bench/find.ce`, and in the tables of [the proof](#quality-the-file-you-mean-comes-first).

### How ranking is measured

The measure is the mean reciprocal rank, from the question answering track of TREC-8, the Text REtrieval Conference of
1999, as Ellen Voorhees defined it. Each query scores the reciprocal of the rank of its file: 1 when the file is first, 1/2
when it is second, 1/5 fifth, and 0 when the list doesn't hold it. The mean over the queries is between 0 and 1, and 1 means
that every file came first. TREC-8 counted only the first five answers; a list shows all its rows, so here every rank
counts. Two simpler counts go with it: how many queries put their file first, and how many in the first five rows.

The filter as it was, before this chapter, is the function below, copied from the Cemacs of then. A space was one more
character to find:

```cesia
use core/lists
use core/press
use core/commands
use core/text
use core/view
use src/emacs
use src/rope
use src/ui
use std/list
use std/math
use std/text as str
use std/value

defn before(filter, words)
  (** The filter of a list before this chapter: every character of the filter, a space too, in the words in order, whatever the case. *)
  wanted = str.Chars(str.Lower(filter))
  k = 1
  for c in str.Chars(str.Lower(words))
    if k <= value.Len(wanted) and c == wanted[k]
      k += 1
    end
  end
  k > value.Len(wanted)
end

(* Eleven files of Cesia's repository, in Git's order. *)
files = ["bench/RESULTS.md", "docs/book/fibers.md", "src/lib/messages.ml", "src/lib/messages.mli", "src/std/result.ce", "tests/check/results.ce",
  "tests/project/checks/missing_need/cesia.toml", "tools/editors/cesia-mode.el", "tools/editors/nvim/syntax/cesia.vim", "tools/http-gate.sh",
  "tools/reload-test.sh"]
rows = [{Words: f, Item: f} for f in files]
kept(filter) = [f for f in files if before(filter, f)]

kept("cmel") --> ["src/lib/messages.ml", "src/lib/messages.mli", "tests/project/checks/missing_need/cesia.toml", "tools/editors/cesia-mode.el"]
kept("ml messages") --> []
```

### The baseline

On the 1,933 files and the 41 queries, the filter as it was gives:

| Measure | Before |
|---|---|
| mean reciprocal rank | 0.597 |
| the file first | 21 of 41 |
| the file in the first five rows | 30 of 41 |
| no row at all | 7 of 41: every query of words in any order |
| the worst rank | 207th, for `rlt`, meaning `tools/reload-test.sh` |

It does well when the query is long and the file sorts early: `src/` comes before `tests/` and `tools/`. It does badly on
initials, mean reciprocal rank 0.318: `cmel` puts `tools/editors/cesia-mode.el` 48th, behind 47 files that hold the same
letters in order and sort before it.

The time of each letter, typed in a list of these 1,933 rows through the editor's update, the way the window sends it, is in
[the proof](#speed-each-letter-answers-at-once), beside the time after the change.

## 3. A hypothesis that could be proved wrong

A hypothesis is only useful if an experiment can show it false. Here there are two causes to tell apart, so two hypotheses:

- **H1: the file is found, but buried.** The filter keeps the file in its list, and the order of the rows puts others
  before it. If H1 were false, the file would be missing from the list, and its rank would be 0. The experiment: in the
  baseline, every query of one word lists its file, 34 of 34; only the order differs. `rlt` holds `tools/reload-test.sh`
  among 207 rows, and every one of the 206 others sorts before it. H1 holds for those 34.
- **H2: the space is the cause of the 7 empty lists.** If H2 were false, a query of words in any order would fail for
  another reason, a letter of a word, say. The experiment shrinks a failing query to its smallest part that still fails,
  by Zeller and Hildebrandt's *delta debugging* (2002): take pieces out of the input, keep a smaller input as long as it
  still fails, and go on with smaller pieces until nothing more can go. What is left is the cause.

```cesia
defn shrunk(fails, input)
  (** Zeller and Hildebrandt's ddmin on the characters of a text: the input, with pieces taken out as long as it still fails, from halves down to single
      characters. *)
  chars = str.Chars(input)
  n = 2
  while value.Len(chars) >= 2
    size = math.Div(value.Len(chars) + n - 1, n)
    smaller = missing
    for i in 1..n
      first = (i - 1) * size + 1
      last = list.Min(i * size, value.Len(chars))
      if first <= last
        rest = list.Concat(list.Take(first - 1, chars), list.Skip(last, chars))
        if fails(str.Join("", rest))
          smaller = rest
          break
        end
      end
    end
    if not value.IsMissing(smaller)
      chars = smaller
      n = list.Max(n - 1, 2)
    else if n >= value.Len(chars)
      break
    else
      n = list.Min(n * 2, value.Len(chars))
    end
  end
  str.Join("", chars)
end

shrunk(q -> not before(q, "src/lib/messages.ml"), "ml messages") --> " "
shrunk(q -> not before(q, "bench/maps.go"), "go maps") --> " "
```

Each of the seven shrinks to one space: a path holds no space, so a filter that holds one can never match. H2 holds.

The cause of the bad ranks is the absence of a ranking, and the cause of the empty lists is the space. What's left to find
is how to rank.

## 4. Research: how this kind of problem is solved

### Matching is solved; ranking is the question

Every editor below finds the rows by subsequence matching. They differ in how they order the rows found, by a *score*: a
number given to each row that says how well the query fits it, the best first.

### Alignment and its table

The idea of the score comes from biology. To find the most alike pieces of two molecular sequences, of DNA or of proteins,
Smith and Waterman (1981) align them: they set the letters of one under the letters of the other, allowing *gaps*, places
where one sequence has letters that the other skips. Each pair of matching letters earns points, each gap costs points, and
the best alignment is the one with the most points. Trying every alignment would take far too long; they fill a table
instead, one cell for each letter of one sequence and each letter of the other, each cell holding the best score of two
pieces that end there, computed from the cells before it. This way of solving a problem from the answers of its smaller parts, kept in a table, is called *dynamic
programming*. Two years later, Gotoh (1982) showed how to make a gap cost one price to open and a smaller price per letter
after, a gap weight of the form *w(k) = uk + v* for a gap of *k* letters, still in about one step per cell, by keeping a
second table beside the first.

### fzy's score

A file name and a query are two sequences, and the query's letters must all match, in order: an alignment that may skip
letters of the path but none of the query. fzy, by John Hawthorn, scores file names this way, and says so in its
`ALGORITHM.md`: a dynamic programming algorithm "similar to Wagner–Fischer and Needleman–Wunsch", with an affine gap
penalty, "Inspired by the Gotoh algorithm", through a second table, named D, which holds the best score that ends in a match
at that cell. Its points, from its `config.def.h`:

| Where a letter of the query matches | Points |
|---|---|
| right after the letter matched before it | 1.0, and no other bonus |
| at the start of the path, or after a `/` | 0.9 |
| after a `-`, a `_` or a space: the start of a word | 0.8 |
| a capital after a small letter, the start of a word in CamelCase | 0.7 |
| after a `.`, often an extension | 0.6 |
| a letter skipped between two matched letters | −0.01 each |
| a letter skipped before the first, or after the last | −0.005 each |

So letters at the starts of words and side by side win, and of two paths that match alike, the shorter wins: it skips fewer
letters. A bonus goes only to a letter or a digit that matches, never to a sign.

### What the giants do

- **Vim 9.2 and Neovim 0.12.6** use fzy's algorithm for their fuzzy matching, by their documentation, `:help
  fuzzy-matching`: "Vim's implementation is based on the algorithm from the fzy project". It came with Vim's patch
  9.1.1627 of August 2025, which Neovim took. Their documentation also says that a query of several words separated by
  white space matches each word separately, in any order. Their function `matchfuzzy()` ranks any list this way. Neither has
  a fuzzy finder of a project's files built in: `:find` looks in the folders of the `'path'` option, by wildcards, and the
  fuzzy completion of `'wildoptions'` "is not supported for file and directory names", by their documentation; the option
  `'findfunc'` lets a few lines of script give `:find` the files of `git ls-files` instead.
- **GNU Emacs 31.1** finds a file of a project with `C-x p f`, `project-find-file`, which reads the files of a Git repository
  with `git ls-files -z -c --exclude-standard -o`, in `project.el`. Its `flex` completion style, new in Emacs 27.1, matches
  by subsequence; Emacs 31.1 rewrote it, by its `NEWS`, "to be faster and more accurate". Its function
  `completion--flex-cost-gotoh`, written in C, computes "the cost of PAT matching STR using modified Gotoh algorithm", by
  its documentation, and `minibuffer.el` sorts by one more than that cost times the number of letters of the name that the
  query doesn't use, so that short names come first. A space is a letter to match, as it was in Cemacs: the words
  don't come in any order. `flex` is not what `C-x p f` uses unless you choose it: Emacs 31.1 gives the files of a project
  the `substring` style, the query found whole, and sorts them alphabetically. This chapter compares with `flex`, the
  style of Emacs that ranks.
- **fzf**, by Junegunn Choi, not installed here, by its source, `src/algo/algo.go`: "a modified version of Smith-Waterman
  algorithm to find the optimal solution (highest score)", with points of its own (16 for a match, a gap costing 3 to open
  and 1 per letter after, a bonus of 8 at a word's start), and words separated by spaces that must all match, in any order.

### What applies

fzy's score, as it is: it is the one that Vim and Neovim chose, its points are published, and an editor that ranks the same
way can be checked against theirs, row by row. Words split at the spaces, each scored alone and their scores added, as Vim,
Neovim and fzf take several words. Two rules of fzy's `match.c` are left out: a path exactly as long as the query, so the
same text whatever its case, scores the highest, which fzy's points already give it, as nothing beats a letter right after
the one before it; and a path longer than 1,024 bytes scores the lowest, a bound on fzy's table that the places visited
don't need. Not taken either: fzf's own syntax of `^`, `$`, `'` and `!`, nor its points, which no measure here favours over
fzy's; and no ranking by the files you opened, which is out of scope.

## 5. The smallest solution

Four changes, each in the code of Cemacs, each with its tests.

**Words in any order.** [lists.Matches] splits the filter at its spaces; each word must match, in any order. Each letter is
now found by [text.ByteFind], natively, after the one before it, where the old filter read each character of each row in
Cesia:

```cesia
lists.Matches("ml messages", "src/lib/messages.ml") --> true
lists.Matches("messages ml", "src/lib/messages.ml") --> true
lists.Matches("ml zz", "src/lib/messages.ml") --> false
```

**The score.** [lists.Score] is fzy's score, with fzy's points in thousandths, so that its sums are exact integers: 900 for
a letter after a slash, 1000 for a letter right after the one before it, −10 for a letter skipped between two. fzy fills its
whole table, every letter of the query by every byte of the path. But a cell can hold a match only where that letter is, so
[lists.Score] visits only those places: for each letter of the query, the places where it is, found with [text.ByteFind],
each taking the best of the places of the letter before it, less its gap, as it goes. It gives the same score in about one
step per place in place of one per cell; [the proof](#correct-tests-that-fail-before-and-pass-after) checks that it equals
fzy's full table.

```cesia
lists.Score("ml", "a/ml") --> 1890
lists.Score("ml", "a/m-l") --> 1680
lists.Score("lexer", "src/lib/lexer.ml") > lists.Score("lexer", "src/lib/lexer.mli") --> true
lists.Score("zz", "a/ml") --> missing
```

In `a/ml`, `m` comes after a slash, 900, less 10 for the two letters before it at 5 each; `l` comes right after it, 1000;
1890. In `a/m-l`, `l` comes after a dash, 800, less 10 for the dash skipped between the two letters, and so does without the
1000 of a neighbour: 1680.

**The ranking.** [lists.Ranked] gives the rows the filter keeps, the best first; rows of the same score keep their order, so
that the result never depends on chance. A list says whether it ranks: [commands.ShowList] takes `ranked = true`. The list
of the output of a program keeps its order, as a log must; the other lists keep theirs too for now, which is a
[choice left](#7-what-is-left).

```cesia
[r.Item for r in lists.Ranked("cmel", rows)] --> ["tools/editors/cesia-mode.el", "src/lib/messages.ml", "src/lib/messages.mli", "tests/project/checks/missing_need/cesia.toml"]
[r.Item for r in lists.Ranked("vim syntax", rows)] --> ["tools/editors/nvim/syntax/cesia.vim"]
```

A list filters a letter added from the rows that its filter kept before, not from all of them, since a longer filter can
only keep fewer. A ranked list keeps those rows in their own order and ranks them for the screen only, so that typing a
query letter by letter shows what typing it at once shows. Here is a list of the eleven files, ranked, in a window, typed
into as the window sends the letters:

```cesia
start = view.Start([text.Of("", missing)], ui.Look(ui.Dark, (w, f) -> 8, 19), {Width: 8, Height: 19}, 800, 600)
start.Config = () -> emacs.Config(emacs.Keys)
opened = commands.ShowList("cesia", rows, () -> {}, start, ranked = true)
shown(state) = str.Lines(rope.Text(state.Buffers[state.Current].Rope))
shown(press.Press(["cmel"], opened))[1] --> "tools/editors/cesia-mode.el"
shown(press.Press(["msgs"], opened)) --> ["src/lib/messages.ml", "src/lib/messages.mli", "tests/project/checks/missing_need/cesia.toml"]
```

**The files of a project.** A new app, `src/project`, opens the list of the files of the project with `C-x p f`, as Emacs,
or `C-c f p` in the group of the files. The project is the Git repository that holds the current file, or the folder Cemacs
started in; its files are those Git lists, with the same command as Emacs's `project.el`: `git ls-files -z -c -o
--exclude-standard`, the files Git tracks and the new ones it doesn't ignore. The prompt line says `Find file in NAME: `
before what you type, and Enter opens the file under the cursor. Cemacs now asks for one more permission, `exec=git`: see
[Install](install.md#starting-it). [Files and buffers](files.md#the-files-of-a-project) tells the rest.

The change is about 250 lines, its comments included: 180 in `core/lists`, 10 in `core/commands`, 55 in `src/project`.

## 6. The proof

### Correct: tests that fail before and pass after

A test that passes after a change proves little unless it failed before it: it might pass whatever the code. These failed
on the code before the change, where `Ranked` and `Score` didn't exist and a space was a letter, and pass now, in
`core/lists/lists.test.ce`:

| Test | What it checks |
|---|---|
| `isWordsMatchInAnyOrder` | `ml messages` and `messages ml` match `src/lib/messages.ml` |
| `isSpacesAloneMatchAll` | a filter of spaces alone keeps every row |
| `isRankedBestFirst` | `rlt` puts `tools/reload-test.sh` before `tests/check/release-test.ce`, `msgml` puts `src/lib/messages.ml` first |
| `isRankedOnlyMatches`, `isRankedTiesKeepOrder`, `isRankedEmptyKeepsAll` | only the rows that match, ties in their order, all of them for an empty filter |
| `isScoreStartOfWordBest`, `isScoreShorterBest`, `isScoreWordsAddUp` | the bonuses, the shorter of two paths, the sum of the words |

A few examples prove little more than the cases they hold. A *property-based test* states a rule that must hold for every
input, and a program makes hundreds of inputs at random to try it, smallest first; when one fails, it shrinks it to the
smallest that still fails. Claessen and Hughes introduced this with QuickCheck (2000); Cesia has it as `test.ForAll`. Five
rules, each tried on 300 or 500 inputs made of a few letters, slashes, dots, dashes, capitals, spaces and `é`, so that the
inputs often match:

| Rule | Inputs | Why it matters |
|---|---|---|
| [lists.Score] equals fzy's full table, computed cell by cell as fzy's `match.c` does | 500 | the places visited give the same score as the table |
| [lists.Matches] equals the old filter, character by character, for one word | 500 | nothing lost or added, `é` too: a letter of two bytes is found whole |
| [lists.Score] is missing exactly when [lists.Matches] is false | 500 | a row is ranked if and only if it is shown |
| [lists.Ranked] holds the same rows as [lists.Filtered], in an order of scores that never rises | 300 | the ranking only reorders |
| ranking a letter more from the rows kept before equals ranking it from all of them | 300 | typing letter by letter shows what typing at once shows |

The first rule found a mistake on its 17th input, in the reference written for the test, not in Cemacs: for the query `a`
in `aa`, the reference gave 890 and the score 895, because Cesia read `if i == n -5` as `if i == n - 5`. Shrunk to those
two letters, it took a minute to see. Here is the reference, which fills fzy's tables as `match.c` does, and agrees with
[lists.Score]:

```cesia
lowest = -1000000000
trailing = -5
inner = -10
lowerByte(b) = if b >= 65 and b <= 90 b + 32 else b end
defn bonus(prev, b)
  (** fzy's bonus of a match on byte b after byte prev, in thousandths: only a letter or a digit earns one. *)
  small = (b >= 97 and b <= 122) or (b >= 48 and b <= 57)
  capital = b >= 65 and b <= 90
  if not (small or capital)
    0
  else if prev == 47
    900
  else if prev == 45 or prev == 95 or prev == 32
    800
  else if prev == 46
    600
  else if capital and prev >= 97 and prev <= 122
    700
  else
    0
  end
end
defn table(query, path)
  (** fzy's score of a query of one word in a path, from its two tables, cell by cell: D, the best score that ends with a match at this byte, and M, the
      best score up to this byte. *)
  if not lists.Matches(query, path)
    return missing
  end
  n = str.ByteLength(query)
  m = str.ByteLength(path)
  wanted = [lowerByte(b) for b in str.Bytes(query)]
  bytes = str.Bytes(path)
  lastD = list.Fill(lowest, m)
  lastM = list.Fill(lowest, m)
  for i in 1..n
    d = list.Fill(lowest, m)
    best = list.Fill(lowest, m)
    gap = if i == n trailing else inner end
    prev = lowest
    for j in 1..m
      if wanted[i] == lowerByte(bytes[j])
        here = bonus(if j == 1 47 else bytes[j - 1] end, bytes[j])
        d[j] = if i == 1 (j - 1) * trailing + here else if j > 1 list.Max(lastM[j - 1] + here, lastD[j - 1] + 1000) else lowest end
        prev = list.Max(d[j], prev + gap)
      else
        prev = prev + gap
      end
      best[j] = prev
    end
    lastD = d
    lastM = best
  end
  lastM[m]
end

pairs = list.Flatten([[[q, p] for p in files if lists.Matches(q, p)] for q in ["msgml", "rlt", "a", "cmel", "ml", "lib"]])
value.Len(pairs) --> 24
value.Equal([table(x[1], x[2]) for x in pairs], [lists.Score(x[1], x[2]) for x in pairs]) --> true
```

`tests/project-check.ce` checks the app against a real Git repository, made for it: `C-x p f` from a file two folders down
lists the files of the whole repository, the tracked ones and a new one, never the one that `.gitignore` names; `msgml` puts
`src/lib/messages.ml` first; `ml lib` keeps the three files of `src/lib` whose names hold `ml`; Enter opens the file and closes
the list; and out of any repository, the prompt line says so and nothing opens.

### A bound

For a query of *n* letters and a path of *m* bytes, fzy's table has *n × m* cells: 5 × 27 = 135 for a query of five letters
in a path of the median length of Cesia's files, 27 bytes. [lists.Score] visits, for each letter of the query, only the
places of that letter in the path, each once, and the places of the letter before it once in all: at most *2 × n × m*
steps in Cesia and *n × m* bytes read natively by [text.ByteFind], and in practice a few places per letter. A letter typed
costs, for each row that the filter kept before, one [text.ByteFind] per letter of the query to filter it, then the score of
each row still shown.

### Quality: the file you mean comes first

The 41 queries, with the rank of their file before the change, after it, in Vim 9.2's `matchfuzzy()` and in Emacs 31.1's
`flex` style sorted by its cost; and how many letters of the query were typed when the file came first for the first time,
before and after. `–` means never:

| Query | The file meant | Before | After | Vim, Neovim | Emacs | Letters before | Letters after |
|---|---|---|---|---|---|---|---|
| `messag` | `src/lib/messages.ml` | 2 | 1 | 1 | 1 | – | 5 |
| `parser.ml` | `src/lib/parser.ml` | 1 | 1 | 1 | 1 | 6 | 4 |
| `lexer` | `src/lib/lexer.ml` | 1 | 1 | 1 | 1 | 4 | 2 |
| `natives` | `src/std/natives.ce` | 4 | 1 | 1 | 1 | – | 7 |
| `infer.ml` | `src/lib/infer.ml` | 1 | 1 | 1 | 1 | 3 | 3 |
| `fibers.md` | `docs/book/fibers.md` | 1 | 1 | 1 | 1 | 8 | 8 |
| `bench.sh` | `tools/bench.sh` | 2 | 1 | 1 | 1 | – | 6 |
| `release.yml` | `.github/workflows/release.yml` | 1 | 1 | 1 | 1 | 4 | 9 |
| `CHANGE` | `CHANGELOG.md` | 1 | 1 | 1 | 1 | 2 | 2 |
| `site.ce` | `src/tools/site.ce` | 1 | 1 | 1 | 1 | 7 | 2 |
| `msgml` | `src/lib/messages.ml` | 1 | 1 | 1 | 1 | 5 | 5 |
| `prsml` | `src/lib/parser.ml` | 1 | 5 | 5 | 1 | 5 | – |
| `cmpml` | `src/lib/compile.ml` | 3 | 1 | 1 | 1 | – | 3 |
| `rntm` | `src/lib/runtime.ml` | 5 | 1 | 1 | 1 | – | 3 |
| `typmli` | `src/lib/types.mli` | 1 | 1 | 1 | 1 | 5 | 4 |
| `jitml` | `src/jit/jit.ml` | 5 | 3 | 3 | 1 | – | – |
| `fbrsmd` | `docs/book/fibers.md` | 1 | 1 | 1 | 1 | 5 | 6 |
| `prmsmd` | `docs/book/permissions.md` | 1 | 4 | 4 | 3 | 3 | – |
| `mirgenx86` | `src/sys/mir/mir-gen-x86_64.c` | 1 | 1 | 1 | 1 | 8 | 7 |
| `wrkrs` | `src/sys/workers.ml` | 2 | 2 | 2 | 1 | – | 3 |
| `liblists` | `src/lib/lists.ml` | 1 | 1 | 1 | 1 | 6 | 5 |
| `stdlist` | `src/std/list.ce` | 1 | 1 | 1 | 1 | 5 | 4 |
| `bookindex` | `docs/book/index.md` | 1 | 1 | 1 | 1 | 8 | 5 |
| `jitengine` | `src/jit/engine.ml` | 1 | 1 | 1 | 1 | 5 | 4 |
| `sysnet` | `src/sys/net.ml` | 1 | 1 | 1 | 1 | 6 | 4 |
| `toolstest` | `tools/test.sh` | 4 | 1 | 1 | 1 | – | 2 |
| `nvimlsp` | `tools/editors/nvim/lsp/cesia.lua` | 1 | 1 | 1 | 1 | 6 | 2 |
| `benchfibgo` | `bench/fib.go` | 1 | 1 | 1 | 1 | 9 | 9 |
| `ml messages` | `src/lib/messages.ml` | – | 1 | 1 | – | – | 5 |
| `toml lib` | `src/lib/toml.ml` | – | 1 | 1 | – | – | 3 |
| `go maps` | `bench/maps.go` | – | 1 | 1 | – | – | 4 |
| `py fib` | `bench/fib.py` | – | 1 | 1 | – | – | 4 |
| `md speed` | `docs/book/speed.md` | – | 1 | 1 | – | – | 5 |
| `ce http` | `src/std/http.ce` | – | 2 | 2 | – | – | – |
| `vim syntax` | `tools/editors/nvim/syntax/cesia.vim` | – | 1 | 1 | – | – | 5 |
| `mgx` | `src/sys/mir/mir-gen-x86_64.c` | 2 | 1 | 1 | 4 | – | 3 |
| `rlt` | `tools/reload-test.sh` | 207 | 24 | 24 | 38 | – | – |
| `htgt` | `tools/http-gate.sh` | 15 | 1 | 1 | 1 | – | 3 |
| `cmel` | `tools/editors/cesia-mode.el` | 48 | 1 | 1 | 18 | – | 4 |
| `ffic` | `src/sys/ffi.c` | 1 | 1 | 1 | 1 | 2 | 2 |
| `private-field.ce` | `tests/errors/private-field.ce` | 7 | 1 | 1 | 1 | – | 5 |

By kind: the mean reciprocal rank, then in brackets how many first and how many in the first five. The column "Words
apart" is the change without its ranking: words in any order, rows kept in their order.

| Kind | Queries | Before | Words apart | After | Vim 9.2, Neovim 0.12.6 | Emacs 31.1, `flex` |
|---|---|---|---|---|---|---|
| the start of a name | 10 | 0.825 (7, 10) | 0.825 (7, 10) | 1.000 (10, 10) | 1.000 (10, 10) | 1.000 (10, 10) |
| letters with gaps | 10 | 0.723 (6, 10) | 0.723 (6, 10) | 0.728 (6, 10) | 0.728 (6, 10) | 0.933 (9, 10) |
| a folder and a name | 8 | 0.906 (7, 8) | 0.906 (7, 8) | 1.000 (8, 8) | 1.000 (8, 8) | 1.000 (8, 8) |
| words in any order | 7 | 0.000 (0, 0) | 0.905 (6, 7) | 0.929 (6, 7) | 0.929 (6, 7) | 0.000 (0, 0) |
| initials | 5 | 0.318 (1, 2) | 0.318 (1, 2) | 0.808 (4, 4) | 0.808 (4, 4) | 0.466 (2, 3) |
| a test | 1 | 0.143 (0, 0) | 0.143 (0, 0) | 1.000 (1, 1) | 1.000 (1, 1) | 1.000 (1, 1) |
| **all** | **41** | **0.597 (21, 30)** | **0.751 (27, 37)** | **0.898 (35, 40)** | **0.898 (35, 40)** | **0.748 (30, 32)** |

So property 2 holds on these queries: the file is first for 35 of 41, more than three in four, and in the first five rows
for 40 of 41, more than nine in ten. The mean reciprocal rank goes from 0.597 to 0.898: words apart bring it to 0.751, and
the ranking the rest. The file came first within the letters of its query for 36 queries, against 21 before; of the 19
queries that put it first both ways, it took 87 letters in all after the change against 104 before, a median of 4 letters
against 5.

**Beside the giants.** Vim 9.2 and Neovim 0.12.6 put every file at the same rank as Cemacs, on all 41 queries: the same
score, written three times, gives the same order. That is a *differential test*, one program checked against another that
solves the same problem, and it catches what neither test would alone. Emacs's `flex` wins on letters with gaps, 0.933
against 0.728: its cost grows with the letters of the name the query doesn't use, so a short name such as
`src/lib/parser.ml` beats a long one under `tests/project/` whose folders hold the letters. It loses on initials, 0.466,
since a letter at the start of a word earns it nothing more; and it finds nothing for words in any order, since its space is
a letter. Over all 41 it scores 0.748; on the 34 queries of one word it scores 0.902, and Cemacs 0.892.

### Speed: each letter answers at once

**How it was measured.** The 41 queries typed one letter at a time, 288 letters, each from an empty filter, in a list of the
1,933 files: each letter is the key event and the text event that the window sends, through [commands.Update], up to the new
state, the list filtered, ranked, and the cursor followed. Three versions took turns, each in a process of its own, four
turns of five rounds, 20 rounds each: the code before the change, at 3d6d8dc; the code after with the rows kept in their
order, `ranked = false`, words apart; and the code after, ranked. Then the same with the frame: after each letter,
[view.View] and [sdl.Frame] draw the list in a window of 1920 by 1080, through SDL's dummy driver, as in
[Speed](performance.md#how-it-was-measured). All alone on the machine, under the lock that its heavy jobs share. Each time is
the median of 20, with its 95 % interval, from the 6th to the 15th time sorted.

| Letters typed in a list of 1,933 files | Before | After, rows kept | After, ranked |
|---|---|---|---|
| all 288 letters, one round | 402 ms [393, 421] | 210 ms [208, 213] | 645 ms [637, 668] |
| the median letter | 0.64 ms | 0.31 ms | 0.94 ms |
| the slowest letter | 8.43 ms [7.41, 8.73], `cm` | 3.62 ms [1.96, 3.81], `c` | 15.3 ms [13.6, 15.8], `st` |
| `s`, the first letter of `sysnet`, which keeps 1,897 rows | 1.44 ms [1.37, 1.54] | 2.06 ms [1.97, 2.31] | 9.30 ms [8.97, 9.48] |
| `st`, its second, which keeps 1,725 | 6.90 ms [6.80, 7.09] | 2.31 ms [2.22, 2.42] | 15.3 ms [13.6, 15.8] |
| with the frame: all 288 letters | 2,900 ms [2,887, 2,926] | 2,897 ms [2,883, 2,916] | 3,121 ms [3,116, 3,167] |
| with the frame: the median letter | 10.1 ms | 10.9 ms | 8.2 ms |
| with the frame: the slowest letter | 18.0 ms [17.1, 18.5], `cm` | 13.9 ms [13.7, 14.1], `pr` | 26.2 ms [25.9, 26.7], `st` |
| with the frame: letters over 16 ms | 16 of 288 | 0 of 288 | 66 of 288 |

Finding each letter natively made the filter twice as fast: 210 ms against 402 for the 288 letters. Ranking costs three
times that, 645 ms, and all of it on the first letters, where nearly every file matches and each must be scored: `s` keeps
1,897 rows, `st` 1,725. By the fourth letter, a few dozen rows are left, and a letter costs less than a millisecond. With its frame, a letter
costs about 10 ms at the median whichever the version: drawing the frame is most of it, and its cost depends on the rows
on the screen, which differ once they are ranked.

So property 3 holds: the slowest letter, drawn, answers in 26 ms, under the 100 ms of Miller and of Card, Robertson and
Mackinlay. Cemacs's own goal of one frame, 16 ms, does not hold for a ranked list: 66 of the 288 letters miss it, all among
the first two or three letters of a query, when most of the files are still kept and must be scored. Before the change, 16
letters missed it too, for the filter alone, slow on the second letters; with the rows kept and found natively, none does.

**Beside the giants.** The same 288 prefixes, each one ranked from all 1,933 files, as a function that each editor has; one
process each, 20 rounds. Cemacs is timed here the same way, with [lists.Ranked] from all the rows, not through its editor:

| Each prefix ranked from the 1,933 files | All 288 | The median | The slowest |
|---|---|---|---|
| Cemacs, [lists.Ranked] | 1,544 ms [1,537, 1,554] | 4.84 ms | 13.5 ms [13.3, 13.8], `std` |
| Vim 9.2, `matchfuzzy()` | 180 ms [179, 181] | 0.50 ms | 1.65 ms [1.64, 1.67], `ce h` |
| Neovim 0.12.6, `matchfuzzy()` | 136 ms [135, 137] | 0.35 ms | 1.30 ms [1.30, 1.34], `ce h` |
| Emacs 31.1, `flex`, then sorted by its cost | 617 ms [604, 622] | 0.47 ms | 17.0 ms [16.9, 17.1], `st` |

Vim and Neovim rank with the same score, in C, 8.6 and 11 times faster than Cemacs in Cesia, and their slowest letter
takes under 2 ms. Emacs's `flex`, its cost in C and its sort in Lisp, is 2.5 times faster than Cemacs in all, but its
slowest letter, 17.0 ms, is slower. Cemacs's editor took 645 ms for the same letters, not 1,544, because it ranks only the
rows that the letters before kept, where these rank all 1,933 files for each prefix. That is where the giants win, and
plainly: the score is the same, and C runs it faster than Cesia does.

**Opening the list.** `C-x p f` on Cesia's repository, Git's two runs and the list of 1,933 rows, 20 times: 7.30 ms [6.85,
8.10]. Emacs's `project-files`, the same `git ls-files` with its own reading of the output, 20 times in one process:
5.80 ms [5.62, 6.10].

**Typing in a buffer** doesn't change: `bench/gate.ce`, three runs of each version taking turns, gives one typed character at
line 19,000 in 11.4, 11.4 and 11.4 ms before, and 11.4, 11.4 and 11.4 ms after; one scrolled line in 18.0, 17.9 and 18.0 ms
before, and 18.1, 17.7 and 17.7 ms after.

### Threats to validity

A threat to validity is a reason why the proof could be wrong even though every number above is true. Mytkowicz, Diwan,
Hauswirth and Sweeney (2009) showed how a change as innocent as the size of the environment of a program moves its times by
more than the effects measured. Each threat here, and what was done:

- **The queries were written by the author of the change.** One could choose queries that the new ranking favours. They
  were written and saved before any line of the ranking existed, and they are all here, the misses with the rest. The
  ranking's points are fzy's, taken as published, and none was tuned on these queries; Vim and Neovim, which nobody here
  wrote, rank them the same.
- **One project.** Cesia's paths are short, in English, in ASCII, with many tests. A project of deep Java folders, or of
  names in another script, could rank otherwise. The tests take names with `é`, but the quality was measured on one tree.
- **The file meant is a judgement.** For `ce http`, `bench/http.ce` and `src/std/http.ce` are both honest answers; the
  table counts only the second.
- **The order before.** The baseline is Git's order, which sorts the paths. Any other order, by date or at random, would
  give another baseline; the ranking after doesn't depend on the order, except for ties.
- **The times.** The heavy jobs of the machine waited on the lock while these ran, but lighter work could run beside them:
  the load was 2.9 on 8 threads when they began. The versions took turns, in the same conditions, so such noise falls on
  all of them, and the intervals stay narrow. Each version ran in a process of its own, started the same way, so that a
  difference of environment, of the kind Mytkowicz and his colleagues measured, falls on all alike; and Cesia's JIT, which
  compiles a function once it runs often, is inside the 20 rounds, not before them. SDL's dummy driver draws in memory: a
  real screen adds the work of its driver and of the compositor, the same for every version. One machine: an Intel Core
  i7-4720HQ, as in [Speed](performance.md#how-it-was-measured).

## 7. What is left

- **Letters in folders count as much as letters in the name.** `rlt` puts `tools/reload-test.sh` 24th, behind
  `bench/RESULTS.md` and `src/std/result.ce`: in `result`, the `l` and the `t` are side by side, which earns 1000, more
  than the 800 of the `t` at the start of `test`. `prsml` and `prmsmd` lose to files under `tests/project/` and `tests/programs/`, whose folder names
  hold the letters. fzf's `--scheme=path` ranks a match in the file's own name above one in its folders, by its manual, and
  Emacs's cost favours short names, which wins it the letters with gaps. Either could help here; it would need queries
  that were not used to choose it, or it would only fit these.
- **The first letters miss a frame.** Ranking 1,900 rows in Cesia takes up to 15 ms, and with the frame 26 ms: under the
  0.1 second of a response that feels immediate, over the 16 ms of one frame. Vim's score in C ranks the same rows in under
  2 ms. A score written natively in Cesia's standard library, as [text.ByteFind] is, would close most of that gap; it is a
  change of Cesia, not of Cemacs.
- **Only Git.** A folder in no Git repository has no project list: the prompt line says so. Emacs, by `project.el`, asks
  then for the project to use, through its `project-prompter`.
- **The list is read once.** A file made after `C-x p f` is not in the list until it opens again.
- **The other lists keep their order.** The buffers, the folder manager and the keys could rank too. The output of a program
  must not: its order is its meaning.
- **A letter typed wrong** finds nothing, as in every editor here.
