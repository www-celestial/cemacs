-- The editor: one small public function per command, from a state to a state, and update, which turns the events of the window into commands.
-- No key is bound here: the Config of the state says which key runs which function, as apps/emacs/emacs.k does, and kepler doc commands lists every command.
-- Errors from the file system never panic: they become a message.
use rope
use sdl
use files
use keys
use lists
use panes
use text
use view

-- The buffer being edited.
current(state) = state.Buffers[state.Current]

-- The state with a buffer in place of the current one.
defn put(b, state)
  s = state
  s.Buffers[state.Current] = b
  s
end

-- The state with a message for the person.
defn say(words, state)
  s = state
  s.Message = words
  s
end

-- The state with a message for the person, as an app shows one.
Say(words, state) = say(words, state)

-- The folder of Kemacs, where fonts/ and apps/ are: what the program gave, or "." for a state with none, as one from a session before this field.
defn Home(state)
  match state
    {Home: home} -> home
    else -> "."
  end
end

-- The buffer without its mark.
defn unmarked(b)
  out = b
  out.Mark = missing
  out.Origin = ""
  out
end

-- Is something selected? A mark with nothing between it and the cursor selects nothing.
defn hasSelection(b)
  e = text.Selection(b)
  not IsMissing(e) and e.First != e.Last
end

-- ---- The clipboard: the one of the system when there is a window, else the state's own.

-- The state with words in the clipboard.
defn clip(words, state)
  if not IsMissing(state.Window)
    sdl.Copy(words, state.Window)
    state
  else
    s = state
    s.Clip = words
    s
  end
end

-- The words in the clipboard.
clipped(state) = if IsMissing(state.Window) state.Clip else sdl.Paste(state.Window) end

-- ---- Moves

-- The current buffer moved by f. A mark stays only if C-space set it: the others end with the next move.
defn move(f, state)
  b = f(current(state))
  if b.Origin != "key"
    b = unmarked(b)
  end
  put(b, state)
end

-- The current buffer moved by f, selecting: a mark is put where the cursor was, if there is none.
defn select(f, state)
  before = current(state)
  b = f(before)
  if IsMissing(before.Mark)
    b.Mark = before.Cursor
    b.Origin = "shift"
  end
  put(b, state)
end

-- The number of lines of a page.
rows(state) = view.LayoutOf(state).Rows

-- Moves. The Select ones keep the mark of a selection.

-- One character on.
ForwardChar(state) = move(b -> text.MoveChar(1, b), state)
-- One character back.
BackwardChar(state) = move(b -> text.MoveChar(-1, b), state)
-- One line down.
NextLine(state) = move(b -> text.MoveLine(1, b), state)
-- One line up.
PreviousLine(state) = move(b -> text.MoveLine(-1, b), state)
-- One word on.
ForwardWord(state) = move(b -> text.MoveWord(1, b), state)
-- One word back.
BackwardWord(state) = move(b -> text.MoveWord(-1, b), state)
-- To the start of the line.
LineStart(state) = move(text.ToLineStart, state)
-- To the end of the line.
LineEnd(state) = move(text.ToLineEnd, state)
-- One page down.
PageDown(state) = move(b -> text.MovePage(1, rows(state), b), state)
-- One page up.
PageUp(state) = move(b -> text.MovePage(-1, rows(state), b), state)
-- To the start of the file.
FileStart(state) = move(text.ToFileStart, state)
-- To the end of the file.
FileEnd(state) = move(text.ToFileEnd, state)
-- Selecting one character on.
SelectForwardChar(state) = select(b -> text.MoveChar(1, b), state)
-- Selecting one character back.
SelectBackwardChar(state) = select(b -> text.MoveChar(-1, b), state)
-- Selecting one line down.
SelectNextLine(state) = select(b -> text.MoveLine(1, b), state)
-- Selecting one line up.
SelectPreviousLine(state) = select(b -> text.MoveLine(-1, b), state)
-- Selecting to the start of the line.
SelectLineStart(state) = select(text.ToLineStart, state)
-- Selecting to the end of the line.
SelectLineEnd(state) = select(text.ToLineEnd, state)
-- Selecting one page down.
SelectPageDown(state) = select(b -> text.MovePage(1, rows(state), b), state)
-- Selecting one page up.
SelectPageUp(state) = select(b -> text.MovePage(-1, rows(state), b), state)

-- The mark put at the cursor, and kept through moves until C-g, an edit or a cut.
defn SetMark(state)
  b = text.SetMark(current(state))
  b.Origin = "key"
  put(b, state)
end

-- The mark taken away, and the message to show it.
defn Cancel(state)
  say("Quit", put(unmarked(current(state)), state))
end

-- C-g as the second key of a pair: the pair is already forgotten, and the selection stays. It is bound for each first key.
CancelPair(state) = say("Quit", state)

-- ---- Edits

-- The current buffer after f, in place of the selection if there is one, as one step of undo. The mark ends.
replacing(f, state) = put(unmarked(text.ReplaceRegion(f, current(state))), state)

-- The current buffer after f, or only without its selection if it has one: Backspace and Delete delete what is selected.
defn deleting(f, state)
  b = current(state)
  if hasSelection(b)
    put(unmarked(text.CutRegion(b)), state)
  else
    put(unmarked(f(b)), state)
  end
end

-- Words typed or pasted at the cursor, in place of the selection.
typed(words, state) = replacing(b -> text.InsertWords(words, b), state)

-- The character before the cursor deleted, or the selection.
DeleteBefore(state) = deleting(text.DeleteBefore, state)
-- The character after the cursor deleted, or the selection.
DeleteAfter(state) = deleting(text.DeleteAfter, state)
-- A line end with the indent of the line, in place of the selection.
NewLine(state) = replacing(text.NewLine, state)
-- The text of a tab, in place of the selection.
Tab(state) = typed(config(state).TabText(), state)

-- The undone step back, and the mark ended: left where it was, it would select a text the person never chose.
Undo(state) = put(unmarked(text.Undo(current(state))), state)
-- The undone step done again, and the mark ended.
Redo(state) = put(unmarked(text.Redo(current(state))), state)

-- The selection removed and put in the clipboard. Without a selection, nothing changes but the message.
defn Cut(state)
  b = current(state)
  if hasSelection(b)
    put(unmarked(text.CutRegion(b)), clip(text.Region(b), state))
  else
    say("Nothing is selected.", state)
  end
end

-- The selection put in the clipboard, and the mark ended. Without a selection, nothing changes but the message.
defn Copy(state)
  b = current(state)
  if hasSelection(b)
    put(unmarked(b), clip(text.Region(b), state))
  else
    say("Nothing is selected.", state)
  end
end

-- The clipboard inserted at the cursor, in place of the selection.
defn Paste(state)
  words = clipped(state)
  if words == ""
    say("The clipboard is empty.", state)
  else
    typed(words, state)
  end
end

-- The rest of the line cut into the clipboard, or the line end if the cursor is already there. Cuts one after the other add up, as in Emacs. It sets Chain itself,
-- so that the cuts add up through any function that calls it, and any other command ends them: see ran.
defn CutLine(state)
  r = text.CutLine(current(state))
  if r.Cut == ""
    say("Nothing to cut.", state)
  else
    before = if state.Chain == wasCut() clipped(state) else "" end
    s = clip("$before$(r.Cut)", put(unmarked(r.Buffer), state))
    s.Chain = true
    s
  end
end

-- ---- Prompts

-- The state with a prompt open. The first key of a pair ends here, or the next key would be its second one instead of an answer, and so does a chain of cuts.
defn prompted(prompt, state)
  s = state
  s.Prompt = prompt
  s.Pending = ""
  s.Chain = false
  s
end

-- The state with a prompt that takes an answer: done gets the answer and the state, without the prompt.
ask(label, answer, done, state) = prompted({Label: label, Answer: answer, Done: done, Choice: false}, state)

-- The state with a prompt that takes y or n.
confirm(label, done, state) = prompted({Label: label, Answer: "", Done: done, Choice: true}, state)

-- The state after the answer of the prompt is accepted.
defn accept(state)
  p = state.Prompt
  s = state
  s.Prompt = missing
  p.Done(p.Answer, s)
end

-- The state with the prompt closed.
defn closed(state)
  s = state
  s.Prompt = missing
  s
end

-- The state after f on the prompt that is open. With none, as when a global key is bound to one of these commands, nothing changes.
inPrompt(f, state) = if IsMissing(state.Prompt) state else f(state.Prompt, state) end

-- Accepts the answer of a prompt. A prompt of y or n waits for one of the two.
PromptAccept(state) = inPrompt((p, s) -> if p.Choice s else accept(s) end, state)

-- The last character of the answer of a prompt removed.
PromptDeleteBefore(state) = inPrompt((p, s) -> withAnswer(Join("", Take(Max(0, Len(p.Answer) - 1), Chars(p.Answer))), s), state)

-- The state with this answer in the prompt.
defn withAnswer(answer, state)
  s = state
  s.Prompt.Answer = answer
  s
end

-- The first line of the clipboard added to the answer of a prompt, since an answer has one. A prompt of y or n takes no paste.
PromptPaste(state) = inPrompt((p, s) -> if p.Choice s else promptText(Join("", Take(1, Lines(clipped(s)))), s) end, state)

-- Closes the prompt with no answer.
PromptCancel(state) = inPrompt((p, s) -> say("Quit", closed(s)), state)

-- A chord while a prompt is open: it runs what bindings give it, and any other chord does nothing.
defn promptChord(chord, bindings, state)
  match keys.Lookup("", chord, bindings)
    {Command: f} -> ran(f, state)
    else -> state
  end
end

-- Text while a prompt is open: it goes to the answer. A prompt of y or n takes one of the two and ends.
defn promptText(words, state)
  p = state.Prompt
  if p.Choice
    answer = Lower(words)
    if answer == "y" or answer == "n" p.Done(answer, closed(state)) else state end
  else
    withAnswer("$(p.Answer)$words", state)
  end
end

-- ---- Buffers and files

-- The state with the buffers. At least one is kept, and current stays among them.
defn withBuffers(buffers, current, state)
  s = state
  s.Buffers = if Len(buffers) == 0 [text.Of("", missing)] else buffers end
  s.Current = Min(Max(1, current), Len(s.Buffers))
  s
end

-- An array without its element k.
without(k, items) = Concat(Take(k - 1, items), Skip(k, items))

-- The state without buffer k, and current the current one, as withBuffers keeps it. A pane that showed buffer k shows the buffer that takes its place, at
-- the place that one holds, and a pane on a buffer after it counts one less.
defn dropped(k, current, state)
  s = withBuffers(without(k, state.Buffers), current, state)
  n = Len(s.Buffers)
  s.Panes = panes.MapLeaves(leaf -> renumbered(k, n, leaf), panes.Tree(state))
  s
end

-- A leaf of a pane after buffer k went, of the n buffers left.
renumbered(k, n, leaf) = if leaf.Buffer > k {Buffer: leaf.Buffer - 1, View: leaf.View} else if leaf.Buffer == k panes.One(Min(k, n)) else leaf end

-- The folder of a path with its slash, or an empty text for a path with no folder.
defn folder(path)
  if IsMissing(path) or not Contains("/", path)
    ""
  else
    "$(Join("/", Take(Len(Split("/", path)) - 1, Split("/", path))))/"
  end
end

-- The index of the buffer for this file, or 0.
defn indexOfFile(path, state)
  wanted = files.Normal(path)
  for k in 1:Len(state.Buffers)
    b = state.Buffers[k]
    if not IsMissing(b.Path) and files.Normal(b.Path) == wanted
      return k
    end
  end
  0
end

-- Goes to the file at path, in a new buffer or in the one that has it. A file that can't be read is a message.
defn OpenFile(path, state)
  if path == ""
    return say("No file name.", state)
  end
  known = indexOfFile(path, state)
  if known > 0
    s = state
    s.Current = known
    return s
  end
  match files.ReadFile(path)
    Ok(read) -> opened(path, read, state)
    Err(e) -> say(e.Message, state)
  end
end

-- The state with a buffer for the file just read, and the person in it.
defn opened(path, read, state)
  b = text.Of(read.Words, path)
  b.Disk = read.Disk
  s = state
  s.Buffers = Append(b, state.Buffers)
  s.Current = Len(s.Buffers)
  s
end

-- Opens every file in order, in new buffers, and stays in the first one that was opened. An empty buffer that nothing touched makes room.
defn OpenAll(paths, state)
  s = Reduce((acc, path) -> OpenFile(path, acc), state, paths)
  if Len(s.Buffers) == Len(state.Buffers)
    s
  else if isPlaceholder(state)
    dropped(1, 1, s)
  else
    withBuffers(s.Buffers, Len(state.Buffers) + 1, s)
  end
end

-- Does the state have only an untouched empty buffer with no file, which a first file replaces?
isPlaceholder(state) = Len(state.Buffers) == 1 and IsMissing(state.Buffers[1].Path) and not text.IsModified(state.Buffers[1]) and rope.Text(state.Buffers[1].Rope) == ""

-- Asks for a file to open, with the folder of the current file as the start of the answer.
FindFile(state) = ask("Find file: ", folder(current(state).Path), (answer, s) -> OpenFile(answer, s), state)

-- Goes to the next buffer, from the last to the first.
defn NextBuffer(state)
  s = state
  s.Current = Mod(state.Current, Len(state.Buffers)) + 1
  s
end

-- The state with buffer k closed.
defn close(k, state)
  dropped(k, k, state)
end

-- The answer to the question about closing buffer k.
closeIfYes(k, answer, state) = if answer == "y" close(k, state) else state end

-- Closes the current buffer, asking first if its text isn't saved. The last one is replaced by an empty buffer.
defn CloseBuffer(state)
  k = state.Current
  if text.IsModified(current(state))
    confirm("Text not saved. Close anyway? (y or n)", (answer, s) -> closeIfYes(k, answer, s), state)
  else
    close(k, state)
  end
end

-- The state with buffer k saved at path, with the time of the file given, and a message.
defn saved(k, path, disk, words, state)
  b = text.MarkSaved(disk, state.Buffers[k])
  b.Path = path
  s = state
  s.Buffers[k] = b
  say(words, s)
end

-- The answer to the question about writing over a file that changed.
defn overwrite(k, path, answer, state)
  if answer == "y"
    store(k, path, true, missing, state)
  else
    say("Not saved.", state)
  end
end

-- Writes buffer k to path, if the file is still the one of disk, or whatever is there when force is true. An Err of kind changed asks first,
-- one of kind saved counts as a save whose time is unknown, and any other Err is a message with the text still modified.
defn store(k, path, force, disk, state)
  words = rope.Text(state.Buffers[k].Rope)
  r = if force files.ForceSave(path, words) else files.SaveFile(path, words, disk) end
  match r
    Ok(now) -> saved(k, path, now, "Saved $path", state)
    Err(e) -> failed(k, path, disk, e, state)
  end
end

-- The state after a save that gave an error.
defn failed(k, path, disk, e, state)
  if e.Kind == "changed"
    confirm("File changed on disk. Overwrite? (y or n)", (answer, s) -> overwrite(k, path, answer, s), state)
  else if e.Kind == "saved"
    saved(k, path, missing, e.Message, state)
  else
    say(e.Message, state)
  end
end

-- The answer of the prompt Save as: the buffer gets a path only if the save works. A file there already is asked about, as one that changed,
-- and a file open in another buffer is refused: one file would get two buffers, with two texts.
defn saveAs(k, answer, state)
  if answer == ""
    say("No file name.", state)
  else if indexOfFile(answer, state) > 0
    say("$answer is open in another buffer.", state)
  else
    store(k, answer, false, missing, state)
  end
end

-- Saves the current buffer, asking for a file name first if it has none. A list has no file to save.
defn Save(state)
  b = current(state)
  k = state.Current
  if lists.IsList(b)
    say("A list has no file.", state)
  else if IsMissing(b.Path)
    ask("Save as: ", "", (answer, s) -> saveAs(k, answer, s), state)
  else
    store(k, b.Path, false, b.Disk, state)
  end
end

-- The state that ends the editor.
defn ended(state)
  s = state
  s.Ending = true
  s
end

-- The answer to the question about quitting.
quitIfYes(answer, state) = if answer == "y" ended(state) else state end

-- Ends the editor, asking first if any text isn't saved.
defn Quit(state)
  if Len(Filter(text.IsModified, state.Buffers)) > 0
    confirm("Text not saved. Quit anyway? (y or n)", quitIfYes, state)
  else
    ended(state)
  end
end

-- Running a program: not there yet, like the two after it, which only say so.
Run(state) = say("Running a program is not there yet.", state)
-- Stopping a program: not there yet.
Stop(state) = say("No program is running.", state)
-- Showing the output: not there yet.
ToggleOutput(state) = say("There is no output yet.", state)

-- ---- Panes: the pane being edited holds its place in the current buffer, and each other pane keeps its own in its leaf, see panes.k.

-- The state with its pane being edited on the current buffer, after a command that changed buffer.
defn synced(state)
  tree = panes.Tree(state)
  i = panes.Active(state)
  if panes.At(i, tree).Buffer == state.Current
    state
  else
    s = state
    s.Panes = panes.WithLeaf(i, panes.One(state.Current), tree)
    s
  end
end

-- The state with the panes of tree and pane j being edited: its buffer becomes the current one, at the place its leaf keeps.
defn showing(j, tree, state)
  leaf = panes.At(j, tree)
  k = Min(leaf.Buffer, Len(state.Buffers))
  s = state
  s.Buffers[k] = view.WithView(leaf.View, state.Buffers[k])
  s.Current = k
  s.Panes = tree
  s.Pane = j
  s
end

-- The state with pane j being edited: the place of the current buffer is kept in the leaf of the pane that was, and the buffer of pane j comes at its own.
defn focused(j, state)
  s = synced(state)
  i = panes.Active(s)
  if j == i
    s
  else
    showing(j, panes.WithLeaf(i, {Buffer: s.Current, View: view.ViewOf(current(s))}, panes.Tree(s)), s)
  end
end

-- The pane being edited split in two along "rows" or "columns", if each half has room for two lines of eight characters. It stays the one being edited,
-- and the new half shows the same buffer at the same place.
defn split(along, state)
  s = synced(state)
  i = panes.Active(s)
  cut = panes.Split(i, along, panes.Tree(s))
  s.Panes = panes.WithLeaf(i + 1, {Buffer: s.Current, View: view.ViewOf(current(s))}, cut)
  s.Pane = i
  halves = Skip(i - 1, Take(i + 1, view.PaneLayouts(s)))
  if Len(Filter(one -> one.Rows < 2 or one.Columns < 8, halves)) == 0
    s
  else
    say("This pane is too small to split.", state)
  end
end

-- The pane being edited split in two, one above the other.
SplitBelow(state) = split("rows", state)
-- The pane being edited split in two, side by side.
SplitRight(state) = split("columns", state)

-- The next pane, from the last to the first.
NextPane(state) = focused(Mod(panes.Active(state), panes.Count(panes.Tree(state))) + 1, state)

-- The pane being edited closed: the other side of its split takes its place, and the pane there is edited. The last pane stays.
defn ClosePane(state)
  tree = panes.Tree(state)
  if panes.Count(tree) == 1
    return say("This is the only pane.", state)
  end
  i = panes.Active(state)
  rest = panes.Remove(i, tree)
  showing(Min(i, panes.Count(rest)), rest, state)
end

-- Only the pane being edited is kept.
defn OnlyPane(state)
  s = state
  s.Panes = panes.One(state.Current)
  s.Pane = 1
  s
end

-- ---- Config

-- What the editor runs on: the record that the function in the Config of the state gives, with the keys and the settings, as emacs.Config in apps/ makes it.
-- A state with none, as one from a session before this field, has no key and the settings of unconfigured: see view.Start.
defn config(state)
  match state
    {Config: f} -> if IsMissing(f) unconfigured() else f() end
    else -> unconfigured()
  end
end

-- The config of a state that has none: no key, so that nothing runs that nobody bound, and plain settings.
unconfigured() = {Keys: () -> Dict(), PromptKeys: () -> Dict(), MouseKeys: () -> Dict(), PromptMouseKeys: () -> Dict(), ListKeys: () -> Dict(), TabText: () -> "  ",
  WheelLines: () -> 3.0, DragZone: () -> 4, FontSize: () -> 15}

-- ---- Lists: a buffer of rows that an app gives, which typing filters. See lists.k for what a list holds.

-- Opens a list named name. rows is a function from the state to the rows, each {Words, Item}, and keys a function that gives the keys of the list, whose
-- functions take the item under the cursor and the state. Typing filters the rows, and the ListKeys of the config take the filter back. A list open already
-- gives its place to this one.
defn ShowList(name, rows, keys, state)
  here = current(state)
  back = if lists.IsList(here) lists.Of(here).Back else state.Current end
  s = withoutList(state)
  b = text.Of("", missing)
  b.List = {Name: name, Rows: rows, Keys: keys, Filter: "", Items: [], Back: Min(back, Len(s.Buffers))}
  s.Buffers = Append(b, s.Buffers)
  s.Current = Len(s.Buffers)
  refreshed(s)
end

-- The state without its list, if one is open, and current on the same buffer as before.
defn withoutList(state)
  for k in 1:Len(state.Buffers)
    if lists.IsList(state.Buffers[k])
      return dropped(k, if state.Current > k state.Current - 1 else state.Current end, state)
    end
  end
  state
end

-- Goes to buffer k. From a list, the list closes on the way, and k counts the buffers as they were with it.
defn ToBuffer(k, state)
  if lists.IsList(current(state))
    at = state.Current
    dropped(at, if k > at k - 1 else k end, state)
  else
    withBuffers(state.Buffers, k, state)
  end
end

-- The state with this filter in the list of the current buffer.
defn withFilter(filter, state)
  b = current(state)
  l = lists.Of(b)
  l.Filter = filter
  b.List = l
  put(b, state)
end

-- The last character of the filter of a list taken back. Out of a list, nothing changes.
defn ListBack(state)
  l = lists.Of(current(state))
  if IsMissing(l) state else withFilter(Join("", Take(Max(0, Len(l.Filter) - 1), Chars(l.Filter))), state) end
end

-- The filter of a list cleared, or with none the list closed, back to the buffer it was opened from. Out of a list, nothing changes.
defn ListCancel(state)
  l = lists.Of(current(state))
  if IsMissing(l)
    state
  else if l.Filter != ""
    withFilter("", state)
  else
    ToBuffer(l.Back, state)
  end
end

-- The state with the list in the current buffer, if it is one, made again from its rows and its filter. The cursor stays on the item it was on, if that one is
-- still shown, else on its line. When the words don't change, the buffer stays as it is, with its selection.
defn refreshed(state)
  b = current(state)
  l = lists.Of(b)
  if IsMissing(l)
    return state
  end
  shown = lists.Filtered(l.Filter, l.Rows(state))
  words = lists.Words(shown)
  items = Map(r -> r.Item, shown)
  out = b
  if words != rope.Text(b.Rope)
    was = lists.ItemAt(b)
    out = text.Place(lists.LineOf(was, items, b.Cursor.Line), 0, text.Of(words, missing))
    out.Top = b.Top
  end
  l.Items = items
  out.List = l
  put(out, state)
end

-- The keys of the list in the current buffer, over the keys of the config and its ListKeys: a key of the list gets the item under the cursor.
defn listKeys(state)
  own = MapValues(f -> (s -> withItem(f, s)), lists.Of(current(state)).Keys())
  Merge(Merge(config(state).Keys(), config(state).ListKeys()), own)
end

-- The state after f on the item under the cursor of the list, or a message when no row is left.
defn withItem(f, state)
  item = lists.ItemAt(current(state))
  if IsMissing(item) say("Nothing here.", state) else f(item, state) end
end

-- A list is read only: after a command that changed its text, as a cut or an undo, its buffer is put back as it was, with a message.
defn guarded(after, before)
  if after.Current == before.Current and Len(after.Buffers) == Len(before.Buffers) and lists.IsList(current(after)) and current(after).Version != current(before).Version
    say("This list is read only.", put(current(before), after))
  else
    after
  end
end

-- ---- Keys and events

-- Is a program running? Not for now.
Moving(state) = false

-- What Chain holds while a command runs, if the command before it was a cut of a line: neither true, which only a new cut sets, nor false.
wasCut() = "cut"

-- The state after f, a command. A chain of cuts ends here unless the command cut a line, whatever function it is.
defn ran(f, state)
  s = state
  s.Chain = if state.Chain wasCut() else false end
  after = f(s)
  after.Chain = after.Chain == true
  after
end

-- The chord of a key with no chord of its own that follows the first key of a pair, as the b of C-x b, or missing.
defn secondKey(event, state)
  if state.Pending != "" and not event.Ctrl and not event.Alt and not event.Super
    Lower(event.Key)
  else
    missing
  end
end

-- The state after a chord, found in bindings with the pending key.
defn chorded(chord, bindings, state)
  s = state
  s.Pending = ""
  match keys.Lookup(state.Pending, chord, bindings)
    {Pending: first} -> pending(first, s)
    {Command: f} -> ran(f, s)
    {Unknown: name} -> unbound(name, s)
  end
end

-- The state after keys with no command, which end a chain of cuts as a command does.
defn unbound(name, state)
  s = say("$name is not bound.", state)
  s.Chain = false
  s
end

-- The state waiting for the second key of a pair.
defn pending(first, state)
  s = state
  s.Pending = first
  s.Message = "$first -"
  s
end

-- The state after a key event. A key that types gives its text event the work, unless it is the second key of a pair. Any other key is a command,
-- which ends a step of typing even if it changes nothing.
defn onKey(event, state)
  s = state
  s.Message = ""
  s.Buffers[state.Current].Free = false
  chord = keys.Chord(event)
  second = if IsMissing(chord) secondKey(event, state) else missing end
  held = event.Ctrl or event.Alt or not IsMissing(second)
  s.Chorded = if held and not event.Shift and IsMissing(second) echo(event.Key) else held end
  if IsMissing(chord) and IsMissing(second)
    s
  else if not IsMissing(state.Prompt)
    promptChord(if IsMissing(chord) second else chord end, config(s).PromptKeys(), s)
  else if lists.IsList(current(s))
    guarded(chorded(if IsMissing(chord) second else chord end, listKeys(s), s), s)
  else
    s.Buffers[state.Current].Typing = false
    chorded(if IsMissing(chord) second else chord end, config(s).Keys(), s)
  end
end

-- The text that a key with Ctrl or Alt may also send, which is only the same key again. Most systems send none.
echo(key) = if key == "space" " " else Lower(key) end

-- The state after a text event: typed at the cursor, or into the prompt. Right after a key with Ctrl or Alt it is only the same key again, and so is any
-- text after such a key with Shift, or after the second key of a pair, whose text the key doesn't tell. A key of the numeric keypad comes only as a text.
defn onText(event, state)
  s = state
  same = state.Chorded == true or state.Chorded == Lower(event.Text)
  s.Chorded = false
  if same
    s
  else if not IsMissing(state.Prompt)
    promptText(event.Text, s)
  else if lists.IsList(current(s))
    withFilter("$(lists.Of(current(s)).Filter)$(event.Text)", s)
  else
    s.Chain = false
    s.Buffers[state.Current].Free = false
    typed(event.Text, s)
  end
end

-- What the wheel left for the next event. A state from before this field has none, and reading one it lacks would panic: see view.Start.
defn wheelRest(state)
  match state
    {Wheel: rest} -> rest
    else -> 0.0
  end
end

-- The screen of the pane under the mouse moved by the wheel, the WheelLines of the config for each notch, without moving the cursor, and without making that pane
-- the one being edited. What is less than a line stays for the next event, since a touchpad sends many small ones.
defn Wheel(event, state)
  i = panes.Active(state)
  j = view.PaneAt(event.X, event.Y, state)
  if j > 0 and j != i
    focused(i, wheeled(event, focused(j, state)))
  else
    wheeled(event, state)
  end
end

-- The screen of the current buffer moved by the wheel.
defn wheeled(event, state)
  b = current(state)
  wanted = wheelRest(state) - event.Amount * config(state).WheelLines()
  lines = Div(Floor(wanted + 0.5), 1)
  b.Top = Min(Max(1, b.Top + lines), rope.LineCount(b.Rope))
  b.Free = true
  s = put(b, state)
  s.Wheel = wanted - lines
  s
end

-- The state after a mouse press: the pane under it is edited, and in its code the cursor goes under the point and a mark from the mouse starts there.
defn down(event, state)
  j = view.PaneAt(event.X, event.Y, state)
  s = if j > 0 focused(j, state) else state end
  if view.IsInCode(event.X, event.Y, s)
    at = view.ClickAt(event.X, event.Y, s)
    b = text.Place(at.Line, at.Column, current(s))
    b.Mark = b.Cursor
    b.Origin = "mouse"
    b.Free = false
    out = put(b, s)
    out.Dragging = true
    out.Pressed = {X: event.X, Y: event.Y}
    out
  else
    s
  end
end

-- The place of the press, until the mouse has left the zone around it, or missing. A state from before this field has none: see view.Start.
defn pressPoint(state)
  match state
    {Pressed: at} -> at
    else -> missing
  end
end

-- Is this event still in the zone around the press at this point? A hand that moves one pixel during a click means no drag.
inZone(event, at, zone) = not IsMissing(at) and Abs(event.X - at.X) <= zone and Abs(event.Y - at.Y) <= zone

-- The mouse moved: with the button held, the cursor follows it once it has left the zone around the press, even if it comes back.
defn Drag(event, state)
  if not state.Dragging or inZone(event, pressPoint(state), config(state).DragZone())
    state
  else
    at = view.PositionAt(event.X, event.Y, state)
    s = put(text.Place(at.Line, at.Column, current(state)), state)
    s.Pressed = missing
    s
  end
end

-- The end of a drag: a click that selected nothing leaves no mark.
defn Release(event, state)
  b = current(state)
  s = state
  s.Dragging = false
  if state.Dragging and not hasSelection(b) and b.Origin == "mouse"
    put(unmarked(b), s)
  else
    s
  end
end

-- A mouse button pressed, which counts as a command: it ends the first key of a pair, a chain of cuts and a step of typing. Only the first button does more.
defn Press(event, state)
  s = state
  s.Pending = ""
  s.Message = ""
  s.Chain = false
  s.Buffers[state.Current].Typing = false
  if event.Button == 1 down(event, s) else s end
end

-- The state after a mouse event: it runs what bindings give its action, with the event, and any other action does nothing.
defn onMouse(event, bindings, state)
  match keys.Lookup("", event.Action, bindings)
    {Command: f} -> f(event, state)
    else -> state
  end
end

-- The state after the window closed: it asks if some text isn't saved, replacing any question that was open.
defn onQuit(state)
  s = state
  s.Prompt = missing
  Quit(s)
end

-- The state with the size of the window.
defn resized(event, state)
  s = state
  s.Width = event.Width
  s.Height = event.Height
  s
end

-- The state with a list made again from its rows, the pane being edited on the current buffer, the screen of each pane on its cursor, and the title of the
-- window the name of the current buffer.
defn Settled(state)
  s = view.FollowState(synced(refreshed(state)))
  name = view.BufferName(current(s))
  if name != s.Title
    if not IsMissing(s.Window)
      sdl.SetTitle(name, s.Window)
    end
    s.Title = name
  end
  s
end

-- The new state after an event, or missing when the editor ends.
defn Update(event, state)
  next = match event.Kind
    "quit" -> onQuit(state)
    "resize" -> resized(event, state)
    "key" -> onKey(event, state)
    "text" -> onText(event, state)
    "mouse" -> onMouse(event, if IsMissing(state.Prompt) config(state).MouseKeys() else config(state).PromptMouseKeys() end, state)
    else -> state
  end
  if next.Ending missing else Settled(next) end
end
