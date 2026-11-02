-- Tests of commands.Kp that need no file: run with kepler test .
-- What opens or saves a file is in tests/commands-check.k.
use commands
use keys
use press
use text
use view
use rope
use ui

cell = {Width: 8, Height: 19}
look = ui.Look(ui.Dark, (words, font) -> Len(words) * 8, 19)

-- A state of one buffer holding words, with no window.
stateOf(words) = view.Start([text.Of(words, missing)], look, cell, 800, 600)
here(state) = state.Buffers[state.Current]
regionOf(state) = text.Region(here(state))
wordsOf(state) = rope.Text(here(state).Rope)
-- A state whose current buffer is modified.
modified(words) = press.Press(["x"], stateOf(words))
-- The key event of a mouse event.
mouse(action, x, y) = {Kind: "mouse", Action: action, X: x, Y: y, Button: 1, Amount: 0.0}
-- The pixel under a character of the first line: the code starts at x = view.Gutter and the first line at y = 36 + 4.
atChar(column) = view.Gutter + column * 8 + 1

isEveryCommandExists() = Len(Filter(name -> not Has(name, commands.Names), Values(keys.Table))) == 0
isShiftKeysInTable() = keys.Table["S-backspace"] == "delete_before" and keys.Table["S-enter"] == "new_line" and keys.Table["S-delete"] == "delete_after" and keys.Table["S-tab"] == "tab"
isTypeAndMove() = wordsOf(press.Press(["a", "b", "C-b", "x"], stateOf(""))) == "axb"
isTypeCursor() = here(press.Press(["a", "b", "C-b", "x"], stateOf(""))).Cursor.Column == 2
isTab() = wordsOf(press.Press(["tab"], stateOf(""))) == "  "
isShiftTab() = wordsOf(press.Press(["S-tab"], stateOf(""))) == "  "
isShiftSelects() = regionOf(press.Press(["a", "b", "S-left"], stateOf(""))) == "b"
isPlainMoveClearsShiftMark() = IsMissing(here(press.Press(["a", "b", "S-left", "left"], stateOf(""))).Mark)
isShiftExtends() = regionOf(press.Press(["a", "b", "c", "S-left", "S-left"], stateOf(""))) == "bc"
isCancelPair() = wordsOf(press.Press(["C-x", "C-g", "C-s"], stateOf("a"))) == "a" and IsMissing(press.Press(["C-x", "C-g", "C-s"], stateOf("a")).Prompt)
isCancelPairClearsPending() = press.Press(["C-x", "C-g"], stateOf("")).Pending == ""
isPairPending() = press.Press(["C-x"], stateOf("")).Pending == "C-x"
isPromptGetsKeys() = press.Press(["C-x", "C-f", "a.k"], stateOf("hi")).Prompt.Answer == "a.k" and wordsOf(press.Press(["C-x", "C-f", "a.k"], stateOf("hi"))) == "hi"
isPromptLabel() = press.Press(["C-x", "C-f"], stateOf("")).Prompt.Label == "Find file: "
isPromptBackspace() = press.Press(["C-x", "C-f", "a.k", "backspace"], stateOf("")).Prompt.Answer == "a."
isPromptIgnoresChords() = press.Press(["C-x", "C-f", "C-f", "C-a", "left", "tab"], stateOf("hi")).Prompt.Answer == "" and wordsOf(press.Press(["C-x", "C-f", "C-a", "tab"], stateOf("hi"))) == "hi"
isPromptCancel() = IsMissing(press.Press(["C-x", "C-f", "a", "C-g"], stateOf("hi")).Prompt) and wordsOf(press.Press(["C-x", "C-f", "a", "C-g"], stateOf("hi"))) == "hi"
isPromptShiftEnterAndBackspace() = press.Press(["C-x", "C-f", "ab", "S-backspace"], stateOf("")).Prompt.Answer == "a"
isSaveAsAsks() = press.Press(["C-x", "C-s"], stateOf("a")).Prompt.Label == "Save as: "
isNextBuffer() = press.Press(["C-x", "b"], view.Start([text.Of("a", "x.k"), text.Of("b", "y.k")], look, cell, 800, 600)).Current == 2
isNextBufferGoesRound() = press.Press(["C-x", "b", "C-x", "b"], view.Start([text.Of("a", "x.k"), text.Of("b", "y.k")], look, cell, 800, 600)).Current == 1
isCloseUnsavedAsks() = closeAsks()
defn closeAsks()
  s = press.Press(["C-x", "k"], modified(""))
  s.Prompt.Label == "Text not saved. Close anyway? (y or n)" and Len(s.Buffers) == 1
end
isCloseUnsavedYes() = Len(press.Press(["C-x", "k", "y"], modified("")).Buffers) == 1 and wordsOf(press.Press(["C-x", "k", "y"], modified(""))) == "" and press.Press(["C-x", "k", "y"], modified("")).Prompt == missing
isCloseUnsavedNo() = wordsOf(press.Press(["C-x", "k", "n"], modified(""))) == "x"
isCloseSavedDirectly() = IsMissing(press.Press(["C-x", "k"], stateOf("")).Prompt)
defn isLastBufferClosed()
  s = press.Press(["C-x", "k"], stateOf("abc"))
  Len(s.Buffers) == 1 and wordsOf(s) == ""
end
defn isCloseGoesToNeighbour()
  s = press.Press(["C-x", "k"], view.Start([text.Of("a", "x.k"), text.Of("b", "y.k")], look, cell, 800, 600))
  Len(s.Buffers) == 1 and wordsOf(s) == "b"
end
defn isQuitAsks()
  s = press.Press(["C-x", "C-c"], modified(""))
  s.Prompt.Label == "Text not saved. Quit anyway? (y or n)" and not s.Ending
end
isQuitNoKeeps() = not press.Press(["C-x", "C-c", "n"], modified("")).Ending and IsMissing(press.Press(["C-x", "C-c", "n"], modified("")).Prompt)
isQuitYesEnds() = press.Press(["C-x", "C-c", "y"], modified("")).Ending
isQuitSavedEnds() = press.Press(["C-x", "C-c"], stateOf("")).Ending
isQuitPromptIgnoresOtherText() = press.Press(["C-x", "C-c", "q"], modified("")).Prompt.Label == "Text not saved. Quit anyway? (y or n)"
isQuitPromptIgnoresEnter() = not IsMissing(press.Press(["C-x", "C-c", "enter"], modified("")).Prompt)
isWindowCloseAsks() = not IsMissing(commands.Update({Kind: "quit"}, modified(""))) and commands.Update({Kind: "quit"}, modified("")).Prompt.Label == "Text not saved. Quit anyway? (y or n)"
isWindowCloseClean() = IsMissing(commands.Update({Kind: "quit"}, stateOf("")))
isWindowCloseAnswerY() = press.Press(["y"], commands.Update({Kind: "quit"}, modified(""))).Ending
isClick() = clickPlaces()
defn clickPlaces()
  s = commands.Update(mouse("down", atChar(2), 40), stateOf("abcd\nefgh"))
  here(s).Cursor == {Line: 1, Column: 2}
end
defn isClickSecondLine()
  s = commands.Update(mouse("down", atChar(1), 40 + 19), stateOf("abcd\nefgh"))
  here(s).Cursor == {Line: 2, Column: 1}
end
isClickBelowText() = here(commands.Update(mouse("down", atChar(30), 300), stateOf("abcd\nefgh"))).Cursor == {Line: 2, Column: 4}
defn isDragSelects()
  s = commands.Update(mouse("down", atChar(1), 40), stateOf("abcd\nefgh"))
  s = commands.Update(mouse("move", atChar(3), 40), s)
  s = commands.Update(mouse("up", atChar(3), 40), s)
  regionOf(s) == "bc" and not s.Dragging
end
defn isClickWithoutDragClearsMark()
  s = commands.Update(mouse("down", atChar(1), 40), stateOf("abcd"))
  s = commands.Update(mouse("up", atChar(1), 40), s)
  IsMissing(here(s).Mark)
end
defn isMoveWithoutButtonIgnored()
  s = commands.Update(mouse("move", atChar(3), 40), stateOf("abcd"))
  here(s).Cursor == {Line: 1, Column: 0} and IsMissing(here(s).Mark)
end
defn isMouseMarkClearedByMove()
  s = commands.Update(mouse("down", atChar(1), 40), stateOf("abcd"))
  s = commands.Update(mouse("move", atChar(3), 40), s)
  s = commands.Update(mouse("up", atChar(3), 40), s)
  IsMissing(here(press.Press(["right"], s)).Mark)
end
defn isClickTab()
  s = view.Start([text.Of("a", "x.k"), text.Of("b", "y.k")], look, cell, 800, 600)
  commands.Update(mouse("down", 70, 10), s).Current == 2 and view.TabAt(10, 10, s) == 1 and view.TabAt(70, 10, s) == 2 and view.TabAt(300, 10, s) == 0 and view.TabAt(10, 100, s) == 0
end
defn isWheel()
  s = stateOf(Join("\n", Map(n -> "word", Range(1, 100))))
  s = commands.Update({Kind: "mouse", Action: "wheel", X: 100, Y: 100, Button: 0, Amount: -1.0}, s)
  here(s).Top == 4 and here(s).Cursor == {Line: 1, Column: 0} and here(s).Free
end
defn isWheelUpStaysInFile()
  s = stateOf("a\nb")
  s = commands.Update({Kind: "mouse", Action: "wheel", X: 100, Y: 100, Button: 0, Amount: 5.0}, s)
  here(s).Top == 1
end
defn isWheelDownStaysInFile()
  s = stateOf("a\nb")
  s = commands.Update({Kind: "mouse", Action: "wheel", X: 100, Y: 100, Button: 0, Amount: -50.0}, s)
  here(s).Top == 2
end
defn isWheelNotPulledBack()
  s = stateOf(Join("\n", Map(n -> "word", Range(1, 100))))
  s = commands.Update({Kind: "mouse", Action: "wheel", X: 100, Y: 100, Button: 0, Amount: -10.0}, s)
  here(s).Top == 31
end
defn isKeyAfterWheelFollows()
  s = stateOf(Join("\n", Map(n -> "word", Range(1, 100))))
  s = commands.Update({Kind: "mouse", Action: "wheel", X: 100, Y: 100, Button: 0, Amount: -10.0}, s)
  s = press.Press(["a"], s)
  here(s).Top == 1 and not here(s).Free
end
defn isResize()
  s = commands.Update({Kind: "resize", Width: 500, Height: 300}, stateOf(""))
  s.Width == 500 and s.Height == 300
end
isUnknownKey() = Contains("C-q", press.Press(["C-q"], stateOf("")).Message)
isUnknownPairClearsPending() = press.Press(["C-x", "C-q"], stateOf("")).Pending == "" and Contains("C-x C-q", press.Press(["C-x", "C-q"], stateOf("")).Message)
defn isTextEventWithCtrl()
  key = {Kind: "key", Key: "f", Ctrl: true, Alt: false, Shift: false, Super: false}
  s = commands.Update({Kind: "text", Text: "f"}, commands.Update(key, stateOf("")))
  wordsOf(s) == "" and not s.Chorded
end
defn isTextAfterCtrlThenRealText()
  key = {Kind: "key", Key: "f", Ctrl: true, Alt: false, Shift: false, Super: false}
  s = commands.Update({Kind: "text", Text: "f"}, commands.Update(key, stateOf("")))
  wordsOf(commands.Update({Kind: "text", Text: "g"}, s)) == "g"
end
defn isTextAfterAlt()
  key = {Kind: "key", Key: "f", Ctrl: false, Alt: true, Shift: false, Super: false}
  wordsOf(commands.Update({Kind: "text", Text: "f"}, commands.Update(key, stateOf("")))) == ""
end
isAccents() = wordsOf(press.Press(["é", "ñ"], stateOf(""))) == "éñ"
isEnterAtStart() = wordsOf(press.Press(["enter"], stateOf("  x"))) == "\n  x"
defn isEnterKeepsIndent()
  s = press.Press(["C-e", "enter", "y"], stateOf("  x"))
  wordsOf(s) == "  x\n  y"
end
defn isEnterUsesEol()
  s = press.Press(["enter"], stateOf("a\r\nb"))
  wordsOf(s) == "\r\na\r\nb"
end
isBackspace() = wordsOf(press.Press(["C-e", "backspace"], stateOf("ab"))) == "a"
isDelete() = wordsOf(press.Press(["delete"], stateOf("ab"))) == "b"
isShiftBackspace() = wordsOf(press.Press(["C-e", "S-backspace"], stateOf("ab"))) == "a"
isShiftDelete() = wordsOf(press.Press(["S-delete"], stateOf("ab"))) == "b"
isShiftEnter() = wordsOf(press.Press(["S-enter"], stateOf("ab"))) == "\nab"
isCtrlD() = wordsOf(press.Press(["C-d"], stateOf("ab"))) == "b"
isTypingReplacesSelection() = wordsOf(press.Press(["C-e", "S-left", "x"], stateOf("ab"))) == "ax"
isPasteReplacesSelection() = wordsOf(press.Press(["C-space", "C-e", "M-w", "C-e", "S-left", "C-y"], stateOf("ab"))) == "aab"
isBackspaceDeletesSelection() = wordsOf(press.Press(["C-e", "S-left", "backspace"], stateOf("ab"))) == "a"
isDeleteDeletesSelection() = wordsOf(press.Press(["S-right", "delete"], stateOf("ab"))) == "b"
isBackspaceWithEmptyKeyMark() = wordsOf(press.Press(["C-e", "C-space", "backspace"], stateOf("ab"))) == "a"
isKeyMarkStaysThroughMoves() = regionOf(press.Press(["C-space", "right", "right"], stateOf("abc"))) == "ab"
isKeyMarkCancelled() = IsMissing(here(press.Press(["C-space", "right", "C-g"], stateOf("abc"))).Mark)
isEditClearsMark() = IsMissing(here(press.Press(["C-space", "right", "x"], stateOf("abc"))).Mark)
isKeyMarkShiftExtend() = regionOf(press.Press(["C-space", "S-right", "S-right"], stateOf("abc"))) == "ab"
isCutAndPaste() = wordsOf(press.Press(["S-right", "S-right", "C-w", "C-e", "C-y"], stateOf("abc"))) == "cab"
isCopyAndPaste() = wordsOf(press.Press(["S-right", "M-w", "C-e", "C-y"], stateOf("abc"))) == "abca"
isCopyClearsMark() = IsMissing(here(press.Press(["S-right", "M-w"], stateOf("abc"))).Mark)
defn isCutNothingSaysSo()
  s = press.Press(["C-w"], stateOf("abc"))
  s.Message != "" and s.Clip == "" and wordsOf(s) == "abc"
end
defn isCopyNothingSaysSo()
  s = press.Press(["M-w"], stateOf("abc"))
  s.Message != "" and s.Clip == ""
end
defn isCopyNothingKeepsClip()
  s = press.Press(["S-right", "M-w", "M-w"], stateOf("abc"))
  s.Clip == "a"
end
isPasteEmpty() = wordsOf(press.Press(["C-y"], stateOf("abc"))) == "abc"
isPasteMultiline() = wordsOf(press.Press(["S-down", "C-w", "C-y"], stateOf("a\nb"))) == "a\nb"
isCutLine() = wordsOf(press.Press(["C-k"], stateOf("ab\ncd"))) == "\ncd" and press.Press(["C-k"], stateOf("ab\ncd")).Clip == "ab"
isCutLineAccumulates() = press.Press(["C-k", "C-k"], stateOf("ab\ncd")).Clip == "ab\n" and wordsOf(press.Press(["C-k", "C-k"], stateOf("ab\ncd"))) == "cd"
isCutLineChainBroken() = press.Press(["C-k", "C-k", "C-f", "C-k"], stateOf("ab\ncd\nef")).Clip == "d"
isCutLineEmptyFile() = press.Press(["C-k"], stateOf("")).Clip == ""
isCutLineYank() = wordsOf(press.Press(["C-k", "C-k", "C-y"], stateOf("ab\ncd"))) == "ab\ncd"
isUndo() = wordsOf(press.Press(["a", "b", "C-/"], stateOf(""))) == ""
isRedo() = wordsOf(press.Press(["a", "b", "C-/", "C-?"], stateOf(""))) == "ab"
isPageDown() = here(press.Press(["C-v"], stateOf(Join("\n", Map(n -> "w", Range(1, 100)))))).Cursor.Line > 10
isPageUp() = here(press.Press(["C-v", "M-v"], stateOf(Join("\n", Map(n -> "w", Range(1, 100)))))).Cursor.Line == 1
isSelectPageDown() = regionOf(press.Press(["S-pagedown"], stateOf(Join("\n", Map(n -> "w", Range(1, 100)))))) != ""
isFileEnds() = here(press.Press(["M->"], stateOf("a\nbc"))).Cursor == {Line: 2, Column: 2} and here(press.Press(["M->", "M-<"], stateOf("a\nbc"))).Cursor == {Line: 1, Column: 0}
isWordMoves() = here(press.Press(["M-f"], stateOf("foo bar"))).Cursor.Column == 3 and here(press.Press(["C-e", "M-b"], stateOf("foo bar"))).Cursor.Column == 4
isLineEnds() = here(press.Press(["C-e"], stateOf("abc"))).Cursor.Column == 3 and here(press.Press(["C-e", "C-a"], stateOf("abc"))).Cursor.Column == 0
isWantedColumn() = here(press.Press(["C-e", "C-n", "C-n"], stateOf("abcd\nx\nabcd"))).Cursor == {Line: 3, Column: 4}
isMessageClearedByNextKey() = press.Press(["C-q", "a"], stateOf("")).Message == ""
isPlaceholders() = press.Press(["C-c", "C-c"], stateOf("")).Message != "" and press.Press(["C-c", "C-k"], stateOf("")).Message != "" and press.Press(["C-c", "C-o"], stateOf("")).Message != ""
isMovingFalse() = not commands.Moving(stateOf(""))
isTickIgnored() = wordsOf(commands.Update({Kind: "tick", Seconds: 0.01}, stateOf("a"))) == "a"
isSuperKeyIgnored() = wordsOf(commands.Update({Kind: "key", Key: "a", Ctrl: false, Alt: false, Shift: false, Super: true}, stateOf("a"))) == "a"
isAllKeysOnEmptyFile() = emptyFileSurvives()
defn emptyFileSurvives()
  chords = Filter(k -> not Contains(" ", k) and k != "C-x" and k != "C-c", Keys(keys.Table))
  s = stateOf("")
  for c in chords
    s = press.Press([c], s)
    s = press.Press(["C-g", "y"], s)
  end
  IsArray(view.View(s))
end
isViewWithPrompt() = IsArray(view.View(press.Press(["C-x", "C-f", "a"], stateOf(""))))
isTitleFollowsBuffer() = press.Press(["C-x", "b"], view.Start([text.Of("a", "d/x.k"), text.Of("b", "d/y.k")], look, cell, 800, 600)).Title == "y.k"
isFollowAfterEvent() = here(press.Press(["C-v", "C-v", "C-v"], stateOf(Join("\n", Map(n -> "w", Range(1, 100)))))).Top > 1
