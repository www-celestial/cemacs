-- Checks of the editor in a window, under SDL_VIDEODRIVER=dummy, with events pushed to SDL as the keyboard and the mouse would send them.
-- Run it from the root of kemacs:
--   SDL_VIDEODRIVER=dummy kepler run --allow read,write,exec=kepler,ffi=SDL3,ffi=SDL3_ttf tests/window-check.k
-- It prints ok at the end and stops at the first failure.
use c
use apps/emacs
use rope
use sdl
use sys
use ui
use commands
use text
use view

-- Stops the script with the words if the condition is false.
defn check(condition, words)
  if not condition
    Panic("FAILED: $words")
  end
end

-- Pushes an event of this type to SDL, with its fields as [type, offset, value].
defn push(type, fields)
  lib = Unwrap(c.Open("SDL3", version = 0))
  send = Unwrap(c.Fn("SDL_PushEvent", ["ptr"], "bool", lib))
  event = c.Alloc(128)
  c.Set("u32", 0, type, event)
  for field in fields
    c.Set(field[1], field[2], field[3], event)
  end
  send(event)
  c.Free(event)
end

-- A key event with a key code and the modifiers of SDL: 0x1 shift, 0x40 control, 0x100 alt.
key(code, mods) = push(0x300, [["u32", 28, code], ["u16", 32, mods]])

-- A text event for the characters of a text. The blocks stay: SDL keeps their addresses until the events are read.
defn typed(words)
  held = c.Alloc(ByteLength(words) + 1)
  for k in 1:Len(Bytes(words))
    c.Set("u8", k - 1, Bytes(words)[k], held)
  end
  push(0x303, [["ptr", 24, held]])
end

-- A letter typed: its key event and then its text event.
defn letter(words)
  key(Bytes(words)[1], 0)
  typed(words)
end

-- A mouse button event on the point.
mouse(type, x, y) = push(type, [["u8", 24, 1], ["f32", 28, x], ["f32", 32, y]])

-- The state after the events waiting in the window went through update. If update ends the editor, its state has ending true.
defn played(state)
  s = state
  for event in sdl.Events(state.Window)
    if s.Ending
      return s
    end
    next = commands.Update(event, s)
    s = if IsMissing(next) ended(s) else next end
  end
  s
end

-- The state, ended.
defn ended(state)
  s = state
  s.Ending = true
  s
end

here(state) = state.Buffers[state.Current]
wordsOf(state) = rope.Text(here(state).Rope)
read(path) = Unwrap(sys.Read(path))

folder = "/tmp/kemacs-window-check-$(Text(sys.Now()))"
check(IsOk(sys.Mkdir(folder)), "the folder is made")
path = "$folder/a.k"
Unwrap(sys.Write(path, "alpha\n"))

defn opened()
  first = sdl.Open("Kemacs check", 800, 600, "fonts/AdwaitaSans-Regular.ttf", size = emacs.FontSize(), light = true)?
  second = sdl.AddFont("strong", "fonts/NotoSans-Medium.ttf", emacs.FontSize(), first, light = true)?
  sdl.AddFont("code", "fonts/JetBrainsMono-Regular.ttf", emacs.FontSize(), second)
end

-- What the editor runs on in this check: the Emacs keys and the settings, as apps/kemacs.k gives them without its apps.
checkConfig() = emacs.Config(emacs.Keys)

window = Unwrap(opened())
measured = sdl.Measure(window)
look = ui.Look(ui.Dark, measured.Width, measured.Height)
cell = {Width: look.Width("M", "code"), Height: sdl.TextSize("Ag", window, font = "code").Height + view.LineGap}
empty = view.Start([text.Of("", missing)], look, cell, 800, 600)
empty.Window = window
empty.Config = checkConfig
state = commands.Settled(commands.OpenAll([path], empty))
check(here(state).Path == path and wordsOf(state) == "alpha\n", "the file is open")

-- Typing, then C-x C-s: the file is written.
letter("a")
typed("é")
key(0x78, 0x40)
key(0x73, 0x40)
state = played(state)
check(wordsOf(state) == "aéalpha\n", "typed text: $(wordsOf(state))")
check(read(path) == "aéalpha\n", "C-x C-s writes the file")
check(not text.IsModified(here(state)), "the star is gone")

-- A file changed on disk: C-x C-s asks, and y writes over it.
Unwrap(sys.Write(path, "theirs\n"))
letter("z")
key(0x78, 0x40)
key(0x73, 0x40)
state = played(state)
check(not IsMissing(state.Prompt) and state.Prompt.Label == "File changed on disk. Overwrite? (y or n)", "a changed file asks")
check(read(path) == "theirs\n", "nothing is written before the answer")
letter("y")
state = played(state)
check(IsMissing(state.Prompt) and read(path) == "aézalpha\n", "y writes over the file")
check(not text.IsModified(here(state)), "the star is gone after y")

-- M-w then C-y goes through the clipboard of the system.
key(0x40000050, 0x1)
key(0x40000050, 0x1)
key(0x77, 0x100)
state = played(state)
check(sdl.Paste(window) == "éz", "M-w puts the selection in the clipboard of the system: $(sdl.Paste(window))")
check(IsMissing(here(state).Mark), "M-w ends the selection")
key(0x65, 0x40)
key(0x79, 0x40)
state = played(state)
check(wordsOf(state) == "aézalphaéz\n", "C-y pastes the clipboard: $(wordsOf(state))")

-- A click in the code places the cursor.
mouse(0x401, 62.0 + 3.0 * cell.Width + 1.0, 4.0 + 2.0)
mouse(0x402, 62.0 + 3.0 * cell.Width + 1.0, 4.0 + 2.0)
state = played(state)
check(here(state).Cursor == {Line: 1, Column: 3} and IsMissing(here(state).Mark), "a click places the cursor")

-- The window takes a few events and quits: sdl.Run returns when the window closes, and the text is saved by then, so it doesn't ask.
key(0x78, 0x40)
key(0x73, 0x40)
state = played(state)
check(read(path) == "aézalphaéz\n", "saved again")
letter("q")
key(0x78, 0x40)
key(0x73, 0x40)
push(0x206, [["i32", 20, 640], ["i32", 24, 480]])
push(0x100, [])
last = sdl.Run(state, commands.Update, view.View, window, moving = commands.Moving)
check(wordsOf(last) == "aézqalphaéz\n", "run took the events: $(wordsOf(last))")
check(last.Width == 640 and last.Height == 480, "run took the resize")
sdl.Close(window)
Print("ok")
