-- The keys: how a key event of sdl becomes a chord such as "C-x", and how chords find a function in bindings. The bindings themselves are code, in commands.k.
-- Nothing here knows of a window or a file.

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

-- Does a binding begin with this chord, as "C-x C-s" begins with "C-x"?
isFirst(chord, bindings) = Len(Filter(k -> StartsWith("$chord ", k), Keys(bindings))) > 0

-- What a chord means in bindings, a dictionary from keys to functions, after the pending first key of a pair, which is "" if there is none: {Command} with the
-- function, {Pending} with the first key of a pair, or {Unknown} with the text of the keys that mean nothing. One chord alone is a key of bindings, and two with a space
-- between are a pair, so a chord begins a pair as soon as a binding says so. A chord bound alone runs, and a pair that begins with it can't be reached.
--
--   Lookup("C-x", "C-s", {"C-x C-s": Lower}) --> {Command: Lower}
defn Lookup(pending, chord, bindings)
  both = if pending == "" chord else "$pending $chord" end
  if Has(both, bindings)
    {Command: bindings[both]}
  else if pending == "" and isFirst(chord, bindings)
    {Pending: chord}
  else
    {Unknown: both}
  end
end
