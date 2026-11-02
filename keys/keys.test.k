-- Tests of keys.Kp: run with kepler test .
use keys

press(key, ctrl, alt, shift) = {Kind: "key", Key: key, Ctrl: ctrl, Alt: alt, Shift: shift, Super: false}
plain(key) = press(key, false, false, false)
withCtrl(key) = press(key, true, false, false)
withAlt(key) = press(key, false, true, false)
withShift(key) = press(key, false, false, true)

isCtrl() = keys.Chord(withCtrl("f")) == "C-f"
isAlt() = keys.Chord(withAlt("w")) == "M-w"
isPlainLetterTypes() = IsMissing(keys.Chord(plain("a")))
isShiftLetterTypes() = IsMissing(keys.Chord(withShift("a")))
isPlainSpaceTypes() = IsMissing(keys.Chord(plain("space")))
isCtrlSpace() = keys.Chord(withCtrl("space")) == "C-space"
isEnter() = keys.Chord(plain("enter")) == "enter"
isTab() = keys.Chord(plain("tab")) == "tab"
isBackspace() = keys.Chord(plain("backspace")) == "backspace"
isShiftMove() = keys.Chord(withShift("right")) == "S-right"
isCtrlShiftMove() = keys.Chord(press("right", true, false, true)) == "C-S-right"
isCtrlShiftLetter() = keys.Chord(press("x", true, false, true)) == "C-S-x"
isCtrlAlt() = keys.Chord(press("f", true, true, false)) == "C-M-f"
isSuperMissing() = IsMissing(keys.Chord({Kind: "key", Key: "f", Ctrl: true, Alt: false, Shift: false, Super: true}))
isFunctionKey() = keys.Chord(plain("f5")) == "f5"
isAltLessThan() = keys.Chord(press("<", false, true, true)) == "M-<"
isAltLessThanPlain() = keys.Chord(withAlt("<")) == "M-<"
isAltGreaterThan() = keys.Chord(press(">", false, true, true)) == "M->"
isAltCommaAlias() = keys.Chord(press(",", false, true, true)) == "M-S-,"
isAltPeriodAlias() = keys.Chord(press(".", false, true, true)) == "M-S-."
isCtrlQuestion() = keys.Chord(press("?", true, false, true)) == "C-?"
isCtrlSlash() = keys.Chord(withCtrl("/")) == "C-/"
isCtrlSlashAlias() = keys.Chord(press("/", true, false, true)) == "C-S-/"
isNoShiftForUnderscore() = keys.Chord(press("_", true, false, true)) == "C-_"
isUpperLetterLowered() = keys.Chord(press("X", true, false, true)) == "C-S-x"

isPair() = keys.Resolved("", "C-x") == {Pending: "C-x"}
isPairC() = keys.Resolved("", "C-c") == {Pending: "C-c"}
isPairEnd() = keys.Resolved("C-x", "C-s") == {Command: "save"}
isUnknown() = keys.Resolved("", "C-q") == {Unknown: "C-q"}
isUnknownPair() = keys.Resolved("C-x", "C-q") == {Unknown: "C-x C-q"}
isCancelInPair() = keys.Resolved("C-x", "C-g") == {Command: "cancel"}
isCancel() = keys.Resolved("", "C-g") == {Command: "cancel"}
isSingle() = keys.Resolved("", "C-f") == {Command: "forward_char"}
isArrow() = keys.Resolved("", "S-right") == {Command: "select_forward_char"}
isChordThenResolved() = keys.Resolved("", keys.Chord(press("<", false, true, true))) == {Command: "file_start"}
isAliasResolved() = keys.Resolved("", "M-S-,") == {Command: "file_start"} and keys.Resolved("", "C-S-/") == {Command: "redo"}
isNoPairAfterPair() = keys.Resolved("C-x", "C-x") == {Unknown: "C-x C-x"}
isWholeTable() = keys.Table["C-c C-c"] == "run" and keys.Table["C-c C-k"] == "stop" and keys.Table["C-c C-o"] == "toggle_output" and keys.Table["C-x C-f"] == "open_file" and keys.Table["C-x b"] == "next_buffer" and keys.Table["C-x k"] == "close_buffer" and keys.Table["C-x C-c"] == "quit"
