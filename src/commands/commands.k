-- The editor: one small public function per command, from a state to a state, and update, which turns the events of the window into commands.
-- GlobalKeys, PromptKeys and MouseKeys say which key runs which function: they hold the functions themselves, so that any function can be bound, and kepler doc commands
-- lists them all. Errors from the file system never panic: they become a message.
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
Tab(state) = typed(TabText(), state)

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
  withBuffers(without(k, state.Buffers), k, state)
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

-- Saves the current buffer, asking for a file name first if it has none.
defn Save(state)
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

-- ---- Bindings and settings
-- These are functions and not variables, for --watch: a reload changes functions and reruns no file-level statement. GlobalKeys = {...} would keep its old
-- value until a restart, and a new variable would be read before it has a value, which panics. A function gives what the code says at the next key. It costs a
-- new dictionary for each chord, about 15 microseconds, and nothing for a key that types.

-- What Tab types.
TabText() = "  "

-- The lines that one notch of the wheel moves the screen, as a float: a touchpad sends parts of a notch.
WheelLines() = 3.0

-- How far the mouse can go from the place of a press, in pixels on either axis, for the press to stay a click.
DragZone() = 4

-- The keys, with the function each one runs: one chord, or two with a space between for a pair. Any function from a state to a state will do, also an anonymous
-- one, as in "C-c C-x": s -> say("hi", s). A chord starts a pair as soon as a binding here does. C-g as the second key of a pair is bound for each first key.
GlobalKeys() = {
  "C-f": ForwardChar, "right": ForwardChar,
  "C-b": BackwardChar, "left": BackwardChar,
  "C-n": NextLine, "down": NextLine,
  "C-p": PreviousLine, "up": PreviousLine,
  "M-f": ForwardWord, "M-b": BackwardWord,
  "C-a": LineStart, "home": LineStart,
  "C-e": LineEnd, "end": LineEnd,
  "C-v": PageDown, "pagedown": PageDown,
  "M-v": PageUp, "pageup": PageUp,
  "M-<": FileStart, "M-S-,": FileStart,
  "M->": FileEnd, "M-S-.": FileEnd,
  "backspace": DeleteBefore, "S-backspace": DeleteBefore,
  "C-d": DeleteAfter, "delete": DeleteAfter, "S-delete": DeleteAfter,
  "C-k": CutLine,
  "C-space": SetMark,
  "S-right": SelectForwardChar,
  "S-left": SelectBackwardChar,
  "S-down": SelectNextLine,
  "S-up": SelectPreviousLine,
  "S-home": SelectLineStart,
  "S-end": SelectLineEnd,
  "S-pagedown": SelectPageDown,
  "S-pageup": SelectPageUp,
  "C-w": Cut, "M-w": Copy, "C-y": Paste,
  "C-/": Undo,
  "C-?": Redo, "C-S-/": Redo,
  "C-g": Cancel,
  "tab": Tab, "S-tab": Tab,
  "enter": NewLine, "S-enter": NewLine,
  "C-x C-s": Save,
  "C-x C-f": FindFile,
  "C-x b": NextBuffer,
  "C-x k": CloseBuffer,
  "C-x C-c": Quit,
  "C-x C-g": CancelPair,
  "C-c C-c": Run,
  "C-c C-k": Stop,
  "C-c C-o": ToggleOutput,
  "C-c C-g": CancelPair
}

-- The keys while a prompt is open. Any other key does nothing, and a prompt has no pairs.
PromptKeys() = {
  "enter": PromptAccept, "S-enter": PromptAccept,
  "backspace": PromptDeleteBefore, "S-backspace": PromptDeleteBefore,
  "C-y": PromptPaste,
  "C-g": PromptCancel
}

-- What the mouse does, by the Action of its event. These functions take the event as well as the state.
MouseKeys() = {"down": Press, "move": Drag, "up": Release, "wheel": Wheel}

-- What the mouse does while a prompt is open: only the wheel and the end of a drag count, so that the buffer can't change under a question and a drag doesn't
-- outlive its button.
PromptMouseKeys() = {"up": Release, "wheel": Wheel}

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
    promptChord(if IsMissing(chord) second else chord end, PromptKeys(), s)
  else
    s.Buffers[state.Current].Typing = false
    chorded(if IsMissing(chord) second else chord end, GlobalKeys(), s)
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

-- The screen of the current buffer moved by the wheel, WheelLines for each notch, without moving the cursor. What is less than a line stays for the next
-- event, since a touchpad sends many small ones.
defn Wheel(event, state)
  b = current(state)
  wanted = wheelRest(state) - event.Amount * WheelLines()
  lines = Div(Floor(wanted + 0.5), 1)
  b.Top = Min(Max(1, b.Top + lines), rope.LineCount(b.Rope))
  b.Free = true
  s = put(b, state)
  s.Wheel = wanted - lines
  s
end

-- The state after a mouse press in the code: the cursor goes under the point and a mark from the mouse starts there. On a tab, goes to it.
defn down(event, state)
  tab = view.TabAt(event.X, event.Y, state)
  if tab > 0
    s = state
    s.Current = tab
    s
  else if view.IsInCode(event.X, event.Y, state)
    at = view.ClickAt(event.X, event.Y, state)
    b = text.Place(at.Line, at.Column, current(state))
    b.Mark = b.Cursor
    b.Origin = "mouse"
    b.Free = false
    s = put(b, state)
    s.Dragging = true
    s.Pressed = {X: event.X, Y: event.Y}
    s
  else
    state
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
inZone(event, at) = not IsMissing(at) and Abs(event.X - at.X) <= DragZone() and Abs(event.Y - at.Y) <= DragZone()

-- The mouse moved: with the button held, the cursor follows it once it has left the zone around the press, even if it comes back.
defn Drag(event, state)
  if not state.Dragging or inZone(event, pressPoint(state))
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
    "mouse" -> onMouse(event, if IsMissing(state.Prompt) MouseKeys() else PromptMouseKeys() end, state)
    else -> state
  end
  if next.Ending missing else Settled(next) end
end
