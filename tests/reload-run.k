-- The editor in a window, as apps/kemacs.k runs it, for tests/reload-check.sh: a fiber sends the same keys again and again through SDL, and what each one did is
-- printed.
-- The state is one from before the fields Wheel and Pressed, as a session running under --watch keeps it through a reload.
use c
use sdl
use sys
use ui
use apps/emacs
use commands
use text
use view

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

-- A key event with a key code and the modifiers of SDL: 0x40 is control.
key(code, mods) = push(0x300, [["u32", 28, code], ["u16", 32, mods]])
-- C-t, the key the bindings of the test use.
probe() = key(0x74, 0x40)
-- One notch of the wheel, down.
wheel() = push(0x403, [["f32", 28, -1.0], ["f32", 36, 100.0], ["f32", 40, 100.0]])

-- The keys of one pass: C-t alone, tab, the wheel, C-t after C-x, and C-t in the prompt of C-x C-f, which C-g then closes.
defn pass()
  probe()
  key(0x09, 0)
  wheel()
  key(0x78, 0x40)
  probe()
  key(0x78, 0x40)
  key(0x66, 0x40)
  probe()
  key(0x67, 0x40)
end

-- Sends the keys until the window closes, and for 30 seconds at most.
defn sending()
  for n in 1:1500
    pass()
    sys.Sleep(0.02)
  end
end

-- Prints what an event did.
defn note(event, before, after)
  was = before.Buffers[before.Current]
  now = after.Buffers[after.Current]
  if event.Kind == "key" and event.Key == "t"
    place = if not IsMissing(before.Prompt) "in a prompt" else if before.Pending != "" "in a pair" else "alone" end
    Print("C-t $place: $(after.Message)")
  else if event.Kind == "key" and event.Key == "tab"
    Print("tab: $(now.Cursor.Column - was.Cursor.Column)")
  else if event.Kind == "mouse" and event.Action == "wheel"
    Print("wheel: $(now.Top - was.Top) $(after.Message)")
  end
end

-- The new state after an event. A stop ends this at once, whatever the text: nothing here needs saving.
defn update(event, state)
  if event.Kind == "quit"
    return missing
  end
  next = commands.Update(event, state)
  note(event, state, next)
  next
end

defn opened()
  first = sdl.Open("Kemacs reload check", 800, 600, "fonts/AdwaitaSans-Regular.ttf", size = emacs.FontSize(), light = true)?
  second = sdl.AddFont("strong", "fonts/NotoSans-Medium.ttf", emacs.FontSize(), first, light = true)?
  sdl.AddFont("code", "fonts/JetBrainsMono-Regular.ttf", emacs.FontSize(), second)
end

-- What the editor runs on: the Emacs keys and the settings, which tests/reload-check.sh changes in apps/emacs/emacs.k while this runs.
Config() = emacs.Config(emacs.Keys)

-- A state with what view.Start gave before the fields Wheel and Pressed, and the config the program gives.
older(s) = {Buffers: s.Buffers, Current: s.Current, Pending: s.Pending, Prompt: s.Prompt, Message: s.Message, Run: s.Run, Window: s.Window, Width: s.Width,
  Height: s.Height, Cell: s.Cell, Look: s.Look, Clip: s.Clip, Chorded: s.Chorded, Chain: s.Chain, Dragging: s.Dragging, Ending: s.Ending, Title: s.Title,
  Config: Config}

defn main()
  window = opened()?
  measured = sdl.Measure(window)
  look = ui.Look(ui.Dark, measured.Width, measured.Height)
  cell = {Width: look.Width("M", "code"), Height: sdl.TextSize("Ag", window, font = "code").Height + view.LineGap}
  words = Join("\n", Map(n -> "line", Range(1, 1000)))
  state = older(view.Start([text.Of(words, missing)], look, cell, 800, 600))
  state.Window = window
  Spawn(sending)
  sdl.Run(commands.Settled(state), update, view.View, window, moving = commands.Moving)
  sdl.Close(window)
  Ok(missing)
end

Print(main())
