-- The editor: one small function per command, from a state to a state, and update, which turns the events of the window into commands.
-- Commands are found by name in names, and keys.Kp says which key runs which name. Errors from the file system never panic: they become a message.
use rope
use sdl
use files
use keys
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
rows(state) = view.Layout(state.Width, state.Height, state.Cell, not IsMissing(state.Run)).Rows

-- Moves, by name of a command. The select_ ones keep the mark of a selection.

-- One character on.
forwardChar(state) = move(b -> text.MoveChar(1, b), state)
-- One character back.
backwardChar(state) = move(b -> text.MoveChar(-1, b), state)
-- One line down.
nextLine(state) = move(b -> text.MoveLine(1, b), state)
-- One line up.
previousLine(state) = move(b -> text.MoveLine(-1, b), state)
-- One word on.
forwardWord(state) = move(b -> text.MoveWord(1, b), state)
-- One word back.
backwardWord(state) = move(b -> text.MoveWord(-1, b), state)
-- To the start of the line.
lineStart(state) = move(text.ToLineStart, state)
-- To the end of the line.
lineEnd(state) = move(text.ToLineEnd, state)
-- One page down.
pageDown(state) = move(b -> text.MovePage(1, rows(state), b), state)
-- One page up.
pageUp(state) = move(b -> text.MovePage(-1, rows(state), b), state)
-- To the start of the file.
fileStart(state) = move(text.ToFileStart, state)
-- To the end of the file.
fileEnd(state) = move(text.ToFileEnd, state)
-- Selecting one character on.
selectForwardChar(state) = select(b -> text.MoveChar(1, b), state)
-- Selecting one character back.
selectBackwardChar(state) = select(b -> text.MoveChar(-1, b), state)
-- Selecting one line down.
selectNextLine(state) = select(b -> text.MoveLine(1, b), state)
-- Selecting one line up.
selectPreviousLine(state) = select(b -> text.MoveLine(-1, b), state)
-- Selecting to the start of the line.
selectLineStart(state) = select(text.ToLineStart, state)
-- Selecting to the end of the line.
selectLineEnd(state) = select(text.ToLineEnd, state)
-- Selecting one page down.
selectPageDown(state) = select(b -> text.MovePage(1, rows(state), b), state)
-- Selecting one page up.
selectPageUp(state) = select(b -> text.MovePage(-1, rows(state), b), state)

-- The mark put at the cursor, and kept through moves until C-g, an edit or a cut.
defn setMark(state)
  b = text.SetMark(current(state))
  b.Origin = "key"
  put(b, state)
end

-- The mark taken away, and the message to show it.
defn cancel(state)
  say("Quit", put(unmarked(current(state)), state))
end

-- ---- Edits

-- The current buffer after f. The selection, if any, is removed first, and the mark ends.
defn replacing(f, state)
  b = current(state)
  gone = if hasSelection(b) text.CutRegion(b) else b end
  put(unmarked(f(gone)), state)
end

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
deleteBefore(state) = deleting(text.DeleteBefore, state)
-- The character after the cursor deleted, or the selection.
deleteAfter(state) = deleting(text.DeleteAfter, state)
-- A line end with the indent of the line, in place of the selection.
newLine(state) = replacing(text.NewLine, state)
-- Two spaces, in place of the selection.
tab(state) = typed("  ", state)

-- The undone step back.
undo(state) = put(text.Undo(current(state)), state)
-- The undone step done again.
redo(state) = put(text.Redo(current(state)), state)

-- The selection removed and put in the clipboard. Without a selection, nothing changes but the message.
defn cut(state)
  b = current(state)
  if hasSelection(b)
    put(unmarked(text.CutRegion(b)), clip(text.Region(b), state))
  else
    say("Nothing is selected.", state)
  end
end

-- The selection put in the clipboard, and the mark ended. Without a selection, nothing changes but the message.
defn copy(state)
  b = current(state)
  if hasSelection(b)
    put(unmarked(b), clip(text.Region(b), state))
  else
    say("Nothing is selected.", state)
  end
end

-- The clipboard inserted at the cursor, in place of the selection.
defn paste(state)
  words = clipped(state)
  if words == ""
    say("The clipboard is empty.", state)
  else
    typed(words, state)
  end
end

-- The rest of the line cut into the clipboard, or the line end if the cursor is already there. Cuts one after the other add up, as in Emacs.
defn cutLine(state)
  r = text.CutLine(current(state))
  if r.Cut == ""
    say("Nothing to cut.", state)
  else
    before = if state.Chain clipped(state) else "" end
    s = clip("$before$(r.Cut)", put(unmarked(r.Buffer), state))
    s.Chain = true
    s
  end
end

-- ---- Prompts

-- The state with a prompt that takes an answer: done gets the answer and the state, without the prompt.
defn ask(label, answer, done, state)
  s = state
  s.Prompt = {Label: label, Answer: answer, Done: done, Choice: false}
  s
end

-- The state with a prompt that takes y or n.
defn confirm(label, done, state)
  s = state
  s.Prompt = {Label: label, Answer: "", Done: done, Choice: true}
  s
end

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

-- A chord while a prompt is open: Enter accepts, Backspace removes a character, C-g closes. Others do nothing.
defn promptChord(chord, state)
  p = state.Prompt
  if chord == "enter" or chord == "S-enter"
    if p.Choice state else accept(state) end
  else if chord == "backspace" or chord == "S-backspace"
    s = state
    s.Prompt.Answer = Join("", Take(Max(0, Len(p.Answer) - 1), Chars(p.Answer)))
    s
  else if chord == "C-g"
    say("Quit", closed(state))
  else
    state
  end
end

-- Text while a prompt is open: it goes to the answer. A prompt of y or n takes one of the two and ends.
defn promptText(words, state)
  p = state.Prompt
  if p.Choice
    answer = Lower(words)
    if answer == "y" or answer == "n" p.Done(answer, closed(state)) else state end
  else
    s = state
    s.Prompt.Answer = "$(p.Answer)$words"
    s
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
    withBuffers(Skip(1, s.Buffers), 1, s)
  else
    withBuffers(s.Buffers, Len(state.Buffers) + 1, s)
  end
end

-- Does the state have only an untouched empty buffer with no file, which a first file replaces?
isPlaceholder(state) = Len(state.Buffers) == 1 and IsMissing(state.Buffers[1].Path) and not text.IsModified(state.Buffers[1]) and rope.Text(state.Buffers[1].Rope) == ""

-- The prompt for a file to open, with the folder of the current file as the start of the answer.
askFile(state) = ask("Find file: ", folder(current(state).Path), (answer, s) -> OpenFile(answer, s), state)

-- Goes to the next buffer, from the last to the first.
defn nextBuffer(state)
  s = state
  s.Current = Mod(state.Current, Len(state.Buffers)) + 1
  s
end

-- The state with buffer k closed.
defn close(k, state)
  withBuffers(without(k, state.Buffers), k, state)
end

-- The answer to the question about closing buffer k.
closeIfYes(k, answer, state) = if answer == "y" close(k, state) else state end

-- Closes the current buffer, asking first if its text isn't saved. The last one is replaced by an empty buffer.
defn closeBuffer(state)
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

-- The answer of the prompt Save as: the buffer gets a path only if the save works. A file there already is asked about, as one that changed.
defn saveAs(k, answer, state)
  if answer == ""
    say("No file name.", state)
  else
    store(k, answer, false, missing, state)
  end
end

-- Saves the current buffer, asking for a file name first if it has none.
defn save(state)
  b = current(state)
  k = state.Current
  if IsMissing(b.Path)
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
defn quit(state)
  if Len(Filter(text.IsModified, state.Buffers)) > 0
    confirm("Text not saved. Quit anyway? (y or n)", quitIfYes, state)
  else
    ended(state)
  end
end

-- Running a program comes later: these three only say so.
run(state) = say("Running a program is not there yet.", state)
-- Stopping a program: not there yet.
stop(state) = say("No program is running.", state)
-- Showing the output: not there yet.
toggleOutput(state) = say("There is no output yet.", state)

-- ---- Names, keys and events

-- The commands by name, as keys.Table calls them.
Names = {
  "forward_char": forwardChar, "backward_char": backwardChar, "next_line": nextLine, "previous_line": previousLine,
  "forward_word": forwardWord, "backward_word": backwardWord, "line_start": lineStart, "line_end": lineEnd,
  "page_down": pageDown, "page_up": pageUp, "file_start": fileStart, "file_end": fileEnd,
  "delete_before": deleteBefore, "delete_after": deleteAfter, "cut_line": cutLine, "set_mark": setMark,
  "select_forward_char": selectForwardChar, "select_backward_char": selectBackwardChar,
  "select_next_line": selectNextLine, "select_previous_line": selectPreviousLine,
  "select_line_start": selectLineStart, "select_line_end": selectLineEnd,
  "select_page_down": selectPageDown, "select_page_up": selectPageUp,
  "cut": cut, "copy": copy, "paste": paste, "undo": undo, "redo": redo, "cancel": cancel,
  "tab": tab, "new_line": newLine, "save": save, "open_file": askFile, "next_buffer": nextBuffer,
  "close_buffer": closeBuffer, "quit": quit, "run": run, "stop": stop, "toggle_output": toggleOutput
}

-- Is a program running? Not for now.
Moving(state) = false

-- The state after the command called name. Any command but C-k ends a chain of cuts.
defn runCommand(name, state)
  s = Names[name](state)
  if name != "cut_line"
    s.Chain = false
  end
  s
end

-- The chord of a key with no chord of its own that follows the first key of a pair, as the b of C-x b, or missing.
defn secondKey(event, state)
  if state.Pending != "" and not event.Ctrl and not event.Alt and not event.Super
    Lower(event.Key)
  else
    missing
  end
end

-- The state after a chord has been resolved against the pending key.
defn chorded(chord, state)
  s = state
  s.Pending = ""
  match keys.Resolved(state.Pending, chord)
    {Pending: first} -> pending(first, s)
    {Command: name} -> runCommand(name, s)
    {Unknown: name} -> say("$name is not bound.", s)
  end
end

-- The state waiting for the second key of a pair.
defn pending(first, state)
  s = state
  s.Pending = first
  s.Message = "$first -"
  s
end

-- The state after a key event. A key that types gives its text event the work, unless it is the second key of a pair.
defn onKey(event, state)
  s = state
  s.Message = ""
  s.Buffers[state.Current].Free = false
  chord = keys.Chord(event)
  second = if IsMissing(chord) secondKey(event, state) else missing end
  s.Chorded = event.Ctrl or event.Alt or not IsMissing(second)
  if IsMissing(chord) and IsMissing(second)
    s
  else if not IsMissing(state.Prompt)
    promptChord(if IsMissing(chord) second else chord end, s)
  else
    chorded(if IsMissing(chord) second else chord end, s)
  end
end

-- The state after a text event: typed at the cursor, or into the prompt. Right after a key with Ctrl or Alt it is only the same key again.
defn onText(event, state)
  s = state
  was = state.Chorded
  s.Chorded = false
  s.Chain = false
  if was
    s
  else if not IsMissing(state.Prompt)
    promptText(event.Text, s)
  else
    s.Buffers[state.Current].Free = false
    typed(event.Text, s)
  end
end

-- The state with the screen of the current buffer moved by the wheel, three lines for each notch, without moving the cursor.
defn wheel(event, state)
  b = current(state)
  lines = Div(Floor(0.0 - event.Amount * 3.0 + 0.5), 1)
  b.Top = Min(Max(1, b.Top + lines), rope.LineCount(b.Rope))
  b.Free = true
  put(b, state)
end

-- The state after a mouse press in the code: the cursor goes under the point and a mark from the mouse starts there. On a tab, goes to it.
defn down(event, state)
  tab = view.TabAt(event.X, event.Y, state)
  if tab > 0
    s = state
    s.Current = tab
    s
  else if view.IsInCode(event.X, event.Y, state)
    at = view.PositionAt(event.X, event.Y, state)
    b = text.Place(at.Line, at.Column, current(state))
    b.Mark = b.Cursor
    b.Origin = "mouse"
    b.Free = false
    s = put(b, state)
    s.Dragging = true
    s
  else
    state
  end
end

-- The state after the mouse moved with the button held: the cursor follows it.
defn drag(event, state)
  at = view.PositionAt(event.X, event.Y, state)
  put(text.Place(at.Line, at.Column, current(state)), state)
end

-- The state after the button is released: a click that selected nothing leaves no mark.
defn release(state)
  b = current(state)
  s = state
  s.Dragging = false
  if not hasSelection(b) and b.Origin == "mouse"
    put(unmarked(b), s)
  else
    s
  end
end

-- The state after a mouse event. While a prompt is open only the wheel counts, so that the buffer can't change under a question.
defn onMouse(event, state)
  if event.Action == "wheel"
    wheel(event, state)
  else if not IsMissing(state.Prompt)
    state
  else if event.Action == "down" and event.Button == 1
    down(event, state)
  else if event.Action == "move" and state.Dragging
    drag(event, state)
  else if event.Action == "up" and state.Dragging
    release(state)
  else
    state
  end
end

-- The state after the window closed: it asks if some text isn't saved, replacing any question that was open.
defn onQuit(state)
  s = state
  s.Prompt = missing
  quit(s)
end

-- The state with the size of the window.
defn resized(event, state)
  s = state
  s.Width = event.Width
  s.Height = event.Height
  s
end

-- The state with the screen on the cursor and the title of the window the name of the current file.
defn Settled(state)
  s = view.FollowState(state)
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
    "mouse" -> onMouse(event, state)
    else -> state
  end
  if next.Ending missing else Settled(next) end
end
