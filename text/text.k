-- The buffer of a file: a rope, a cursor, a mark and the history. Lines count from 1, columns from 0.
use rope
use history
use color

-- A buffer holding words, for the file at path (or missing for a text with no file). The cursor is at the start, nothing is selected,
-- nothing is colored yet, and the text counts as saved. The editor owns two more fields: free, true while the wheel has moved the screen away
-- from the cursor, and origin, where the mark came from: "" for no mark, "key" for C-space, "shift" for a selection with Shift, "mouse" for a drag.
-- Besides the fields of the state, a buffer has three private ones: wanted, the column that
-- MoveLine and MovePage try to keep through shorter lines (a column, or missing, and every other move and every edit clears it); clock, the
-- highest version given so far, so that a new edit never gets the number of a state that was undone; and typing, which is true while the last
-- command was a letter typed that a following letter continues (the step of undo).
--
--   Of("a", "a.k").Cursor.Line --> 1
defn Of(words, path)
  r = rope.Of(words)
  cursor = {Line: 1, Column: 0}
  {Rope: r, Cursor: cursor, Mark: missing, History: history.Of({Rope: r, Cursor: cursor, Version: 0, Before: cursor, Line: 1}), Version: 0, Top: 1, Left: 0, Path: path, Saved: 0, Disk: missing,
    Colors: color.BlankColors(), Wanted: missing, Clock: 0, Typing: false, Free: false, Origin: ""}
end

-- Does line n end with a CRLF? Then its \r belongs to the line end. A \r anywhere else, or at the end of the last line, is an ordinary character.
hasCr(n, b) = n < rope.LineCount(b.Rope) and EndsWith("\r", rope.Line(n, b.Rope))

-- The text of line n, without its line end: a \r before the line end is not part of it.
defn line(n, b)
  s = rope.Line(n, b.Rope)
  if hasCr(n, b) withoutLast(s) else s end
end

-- A text without its last character.
withoutLast(s) = Join("", Take(Len(s) - 1, Chars(s)))

-- The line end of line n: \r\n or \n. The last line has none, so it takes the one of the line above, or \n if it is alone.
defn eol(n, b)
  if n < rope.LineCount(b.Rope)
    if hasCr(n, b) "\r\n" else "\n" end
  else if n > 1 and hasCr(n - 1, b)
    "\r\n"
  else
    "\n"
  end
end
-- The number of characters of line n.
width(n, b) = Len(line(n, b))

-- A position {Line, Column} brought inside the text.
defn clamp(pos, b)
  line = Min(Max(1, pos.Line), rope.LineCount(b.Rope))
  {Line: line, Column: Min(Max(0, pos.Column), width(line, b))}
end

-- The byte of the rope at a position: the start of its line, plus the bytes of the characters before it.
defn byte(pos, b)
  start = rope.LineStart(pos.Line, b.Rope)
  if pos.Column == 0
    start
  else
    start + ByteLength(Slice(1, pos.Column, line(pos.Line, b)))
  end
end

-- The position after another one, or missing at the end of the file. A line end counts as one step.
defn forwardFrom(pos, b)
  if pos.Column < width(pos.Line, b)
    {Line: pos.Line, Column: pos.Column + 1}
  else if pos.Line < rope.LineCount(b.Rope)
    {Line: pos.Line + 1, Column: 0}
  else
    missing
  end
end

-- The position before another one, or missing at the start of the file.
defn back(pos, b)
  if pos.Column > 0
    {Line: pos.Line, Column: pos.Column - 1}
  else if pos.Line > 1
    {Line: pos.Line - 1, Column: width(pos.Line - 1, b)}
  else
    missing
  end
end

-- Does the first position come before the second?
before(p, q) = p.Line < q.Line or (p.Line == q.Line and p.Column < q.Column)

-- The buffer with a cursor, after a command that is not a move by lines: no wanted column, and the step of typing ends.
defn moved(cursor, b)
  b.Cursor = cursor
  b.Wanted = missing
  b.Typing = false
  b
end

-- A letter, a digit or an underscore. Kepler knows the case of the ASCII letters only, so any character of more than one byte counts as a letter,
-- as in color.Kp: accents and other alphabets are in words, and so are the rare symbols outside ASCII.
isWord(c) = c == "_" or (c >= "0" and c <= "9") or (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or ByteLength(c) > 1

-- The character after a position, or a line end at the end of a line.
defn charAfter(pos, b)
  if pos.Column >= width(pos.Line, b)
    "\n"
  else
    Slice(pos.Column + 1, pos.Column + 1, line(pos.Line, b))
  end
end

-- Moves one position while a test holds for the character that would be crossed, forward or back.
defn skip(forward, test, pos, b)
  p = pos
  go = true
  while go
    next = if forward forwardFrom(p, b) else back(p, b) end
    if IsMissing(next)
      go = false
    else
      c = if forward charAfter(p, b) else charAfter(next, b) end
      if test(c)
        p = next
      else
        go = false
      end
    end
  end
  p
end

-- The cursor moved by whole characters: forward for a positive number, back for a negative one, stopping at the ends of the file.
--
--   MoveChar(1, Of("ab", missing)).Cursor.Column --> 1
defn MoveChar(by, b)
  p = b.Cursor
  n = Abs(by)
  while n > 0
    next = if by > 0 forwardFrom(p, b) else back(p, b) end
    if IsMissing(next)
      n = 0
    else
      p = next
      n -= 1
    end
  end
  moved(p, b)
end

-- The cursor moved by words: a word is a run of letters, digits and underscores, in any alphabet. Forward it goes to the end of the next
-- word, back to the start of the previous one.
--
--   MoveWord(1, Of("foo bar", missing)).Cursor.Column --> 3
defn MoveWord(by, b)
  p = b.Cursor
  for i in Range(1, Abs(by))
    if by > 0
      p = skip(true, isWord, skip(true, c -> not isWord(c), p, b), b)
    else
      p = skip(false, isWord, skip(false, c -> not isWord(c), p, b), b)
    end
  end
  moved(p, b)
end

-- The cursor moved by lines, keeping the column the person wanted through shorter lines. At the first and last lines it stays there.
--
--   MoveLine(1, Of("ab\ncd", missing)).Cursor.Line --> 2
defn MoveLine(by, b)
  wanted = if IsMissing(b.Wanted) b.Cursor.Column else b.Wanted end
  line = Min(Max(1, b.Cursor.Line + by), rope.LineCount(b.Rope))
  b.Cursor = {Line: line, Column: Min(wanted, width(line, b))}
  b.Wanted = wanted
  b.Typing = false
  b
end

-- The cursor moved by pages of rows lines: forward for a positive number, back for a negative one. It keeps the wanted column as MoveLine does.
--
--   MovePage(1, 2, Of("a\nb\nc", missing)).Cursor.Line --> 3
MovePage(by, rows, b) = MoveLine(by * Max(1, rows), b)

-- The cursor at the start of its line.
--
--   ToLineStart(Place(1, 1, Of("ab", missing))).Cursor.Column --> 0
ToLineStart(b) = moved({Line: b.Cursor.Line, Column: 0}, b)

-- The cursor at the end of its line.
--
--   ToLineEnd(Of("ab", missing)).Cursor.Column --> 2
ToLineEnd(b) = moved({Line: b.Cursor.Line, Column: width(b.Cursor.Line, b)}, b)

-- The cursor at the start of the file.
--
--   ToFileStart(Place(1, 1, Of("ab", missing))).Cursor.Column --> 0
ToFileStart(b) = moved({Line: 1, Column: 0}, b)

-- The cursor at the end of the file.
--
--   ToFileEnd(Of("a\nbc", missing)).Cursor.Line --> 2
ToFileEnd(b) = moved(clamp({Line: rope.LineCount(b.Rope), Column: width(rope.LineCount(b.Rope), b)}, b), b)

-- The cursor at a line and a column, brought inside the text.
--
--   Place(9, 9, Of("ab", missing)).Cursor.Column --> 2
Place(line, column, b) = moved(clamp({Line: line, Column: column}, b), b)

-- The buffer with a new rope, a new cursor and the history that records it. A step that continues typing replaces the last state of the history
-- instead of adding one. line is the first line that changed, where the colors stop being known.
defn edit(r, cursor, line, continues, typing, b)
  version = b.Clock + 1
  merging = continues and b.Typing
  now = b.History.Present
  state = {Rope: r, Cursor: cursor, Version: version, Before: if merging now.Before else b.Cursor end, Line: if merging Min(line, now.Line) else line end}
  h = if merging history.Record(state, history.Undo(b.History)) else history.Record(state, b.History) end
  b.Rope = r
  b.Cursor = cursor
  b.Version = version
  b.Clock = version
  b.History = h
  b.Wanted = missing
  b.Typing = typing
  b.Colors = color.ForgetFrom(line, b.Colors)
  b
end

-- The leading spaces and tabs of line n, up to the column.
defn indent(n, column, b)
  cs = Take(column, Chars(line(n, b)))
  Join("", TakeWhile(c -> c == " " or c == "\t", cs))
end

-- Inserts a text at the cursor. Only one character typed continues the step of undo, and a space or a line end ends it.
defn insert(words, continues, b)
  pieces = Split("\n", words)
  at = b.Cursor
  cursor = if Len(pieces) == 1
    {Line: at.Line, Column: at.Column + Len(words)}
  else
    {Line: at.Line + Len(pieces) - 1, Column: Len(Last(pieces))}
  end
  r = rope.Insert(byte(at, b), words, b.Rope)
  typing = Len(words) == 1 and not (words == " " or words == "\t" or words == "\n")
  edit(r, cursor, at.Line, continues and Len(words) == 1, typing, b)
end

-- The text typed at the cursor. The cursor goes after it. Typing one character at a time makes words of undo: a step ends at a space, at a line end
-- and at any command other than typing.
--
--   InsertWords("a", Of("", missing)).Cursor.Column --> 1
InsertWords(words, b) = if words == "" b else insert(words, true, b) end

-- The buffer without the text from one position up to another, which comes after it. The cursor goes to the first.
defn delete(p, q, b)
  r = rope.Delete(byte(p, b), byte(q, b), b.Rope)
  edit(r, p, p.Line, false, false, b)
end

-- A line end, with the spaces and tabs the line starts with, inserted at the cursor, so that the next line is indented as this one.
--
--   NewLine(Place(1, 3, Of("  x", missing))).Cursor.Column --> 2
NewLine(b) = insert("$(eol(b.Cursor.Line, b))$(indent(b.Cursor.Line, b.Cursor.Column, b))", false, b)

-- The character before the cursor deleted, or the line end before it if it is at the start of a line, which joins the two lines. At the
-- start of the file nothing changes.
--
--   DeleteBefore(Place(1, 1, Of("ab", missing))).Cursor.Column --> 0
defn DeleteBefore(b)
  p = back(b.Cursor, b)
  if IsMissing(p)
    b
  else
    delete(p, b.Cursor, b)
  end
end

-- The character after the cursor deleted, or the line end after it if it is at the end of a line. At the end of the file nothing changes.
--
--   DeleteAfter(Of("ab", missing)).Cursor.Column --> 0
defn DeleteAfter(b)
  q = forwardFrom(b.Cursor, b)
  if IsMissing(q)
    b
  else
    delete(b.Cursor, q, b)
  end
end

-- The mark put at the cursor.
defn SetMark(b)
  b.Mark = b.Cursor
  b.Wanted = missing
  b.Typing = false
  b
end

-- The mark taken away.
defn ClearMark(b)
  b.Mark = missing
  b.Wanted = missing
  b.Typing = false
  b
end

-- The two ends of the selection {First, Last}, the first being the one that comes first in the text, or missing if there is no mark. A mark that
-- an edit left outside the text is brought back inside.
defn ends(b)
  if IsMissing(b.Mark)
    missing
  else
    m = clamp(b.Mark, b)
    if before(m, b.Cursor) {First: m, Last: b.Cursor} else {First: b.Cursor, Last: m} end
  end
end

-- The two ends of the selection {First, Last}, the first being the one that comes first in the text, or missing if there is no mark.
--
--   Selection(MoveChar(1, SetMark(Of("ab", missing)))).Last.Column --> 1
Selection(b) = ends(b)

-- The number of characters of line n, without its line end.
--
--   LineWidth(1, Of("abc", missing)) --> 3
LineWidth(n, b) = width(n, b)

-- The selected text, between the mark and the cursor in whichever order, or an empty text if there is no mark.
--
--   Region(MoveChar(1, SetMark(Of("ab", missing)))) --> "a"
defn Region(b)
  e = ends(b)
  if IsMissing(e)
    ""
  else
    rope.Slice(byte(e.First, b), byte(e.Last, b), b.Rope)
  end
end

-- The selected text removed. The cursor goes to its start and the mark is taken away. Without a mark, nothing is removed.
defn CutRegion(b)
  e = ends(b)
  if IsMissing(e) or not before(e.First, e.Last)
    ClearMark(b)
  else
    ClearMark(delete(e.First, e.Last, b))
  end
end

-- Cuts from the cursor to the end of its line, or the line end itself if the cursor is already there: {Buffer, Cut}, cut being the removed
-- text. At the end of the file there is nothing to cut.
--
--   CutLine(Of("ab", missing)).Cut --> "ab"
defn CutLine(b)
  at = b.Cursor
  q = if at.Column < width(at.Line, b) {Line: at.Line, Column: width(at.Line, b)} else forwardFrom(at, b) end
  if IsMissing(q)
    {Buffer: b, Cut: ""}
  else
    {Buffer: delete(at, q, b), Cut: rope.Slice(byte(at, b), byte(q, b), b.Rope)}
  end
end

-- The buffer with the text and version of a state of the history, the cursor given, and the colors known only up to the line given.
defn travel(h, s, cursor, line, b)
  b.Rope = s.Rope
  b.Cursor = cursor
  b.Version = s.Version
  b.History = h
  b.Wanted = missing
  b.Typing = false
  b.Colors = color.ForgetFrom(line, b.Colors)
  b
end

-- The last step of typing or editing undone, with the cursor where it was before that step. A mark stays where it was, and region and
-- CutRegion bring it inside the text. Without a step before, nothing changes.
defn Undo(b)
  if history.CanUndo(b.History)
    left = b.History.Present
    h = history.Undo(b.History)
    travel(h, history.Current(h), left.Before, left.Line, b)
  else
    b
  end
end

-- The step that was undone, done again, with the cursor where that step left it. An edit after an undo forgets it.
defn Redo(b)
  if history.CanRedo(b.History)
    h = history.Redo(b.History)
    entered = history.Current(h)
    travel(h, entered, entered.Cursor, entered.Line, b)
  else
    b
  end
end

-- Is the text different from the last one saved? Undoing back to the saved text makes it false again.
--
--   IsModified(Of("", missing)) --> false
IsModified(b) = b.Version != b.Saved

-- The buffer after a save: the current version counts as saved, and disk is the time of the file that was written.
defn MarkSaved(disk, b)
  b.Saved = b.Version
  b.Disk = disk
  b.Typing = false
  b
end
