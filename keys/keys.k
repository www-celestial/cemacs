-- The keys: how a key event of sdl becomes a chord such as "C-x", and how chords become commands. The table is data, so that changing a key
-- costs one line. Nothing here knows of a window or a file.

-- The keys that make no difference with Shift, because the character already holds it: "<" is Shift and ",".
shifted = ["<", ">", "?", "_"]

-- The prefix of the modifiers, always in the order C, M, S: "C-M-S-".
prefix(ctrl, alt, shift) = "$(if ctrl "C-" else "" end)$(if alt "M-" else "" end)$(if shift "S-" else "" end)"

-- Has this key a name, as "enter" or "right", rather than being one character?
isNamed(key) = Len(key) > 1

-- The chord of an event, such as "C-f", "M-w", "enter" or "S-right", or missing if the key only types: the text event types it.
-- A key that types is a character or the space bar with no Ctrl and no Alt, with or without Shift. A key with Super is not ours.
defn Chord(event)
  key = if isNamed(event.Key) event.Key else Lower(event.Key) end
  types = (not isNamed(event.Key) or key == "space") and not event.Ctrl and not event.Alt
  if event.Super or types
    missing
  else
    shift = event.Shift and not (key in shifted)
    "$(prefix(event.Ctrl, event.Alt, shift))$key"
  end
end

-- The commands by chord: a chord, or two chords with a space between, to the name of a command of commands.k.
Table = {
  "C-f": "forward_char", "right": "forward_char",
  "C-b": "backward_char", "left": "backward_char",
  "C-n": "next_line", "down": "next_line",
  "C-p": "previous_line", "up": "previous_line",
  "M-f": "forward_word", "M-b": "backward_word",
  "C-a": "line_start", "home": "line_start",
  "C-e": "line_end", "end": "line_end",
  "C-v": "page_down", "pagedown": "page_down",
  "M-v": "page_up", "pageup": "page_up",
  "M-<": "file_start", "M-S-,": "file_start",
  "M->": "file_end", "M-S-.": "file_end",
  "backspace": "delete_before", "S-backspace": "delete_before",
  "C-d": "delete_after", "delete": "delete_after", "S-delete": "delete_after",
  "C-k": "cut_line",
  "C-space": "set_mark",
  "S-right": "select_forward_char",
  "S-left": "select_backward_char",
  "S-down": "select_next_line",
  "S-up": "select_previous_line",
  "S-home": "select_line_start",
  "S-end": "select_line_end",
  "S-pagedown": "select_page_down",
  "S-pageup": "select_page_up",
  "C-w": "cut", "M-w": "copy", "C-y": "paste",
  "C-/": "undo",
  "C-?": "redo", "C-S-/": "redo",
  "C-g": "cancel",
  "tab": "tab", "S-tab": "tab",
  "enter": "new_line", "S-enter": "new_line",
  "C-x C-s": "save",
  "C-x C-f": "open_file",
  "C-x b": "next_buffer",
  "C-x k": "close_buffer",
  "C-x C-c": "quit",
  "C-c C-c": "run",
  "C-c C-k": "stop",
  "C-c C-o": "toggle_output"
}

-- The chords that begin a pair.
firsts = ["C-x", "C-c"]

-- What a chord means after the pending first key of a pair, which is "" if there is none: {Command} to run, {Pending} for the first key of a
-- pair, or {Unknown} with the text of the keys that mean nothing. C-g cancels, even as the second key.
defn Resolved(pending, chord)
  if pending == ""
    if Has(chord, Table)
      {Command: Table[chord]}
    else if chord in firsts
      {Pending: chord}
    else
      {Unknown: chord}
    end
  else if chord == "C-g"
    {Command: "cancel"}
  else
    both = "$pending $chord"
    if Has(both, Table) {Command: Table[both]} else {Unknown: both} end
  end
end
