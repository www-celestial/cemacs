-- Kemacs: opens the window and runs the editor of commands.Kp.
-- Run through bin/kemacs, which gives the home of Kemacs first, then the files to open.
use sdl
use sys
use ui
use commands
use text
use view

-- The window, with the three fonts of Kemacs found in fonts/ under its home: body, strong and code.
defn opened(home)
  first = sdl.Open("Kemacs", 1280, 720, "$home/fonts/AdwaitaSans-Regular.ttf", size = 13, light = true)?
  second = sdl.AddFont("strong", "$home/fonts/NotoSans-Medium.ttf", 13, first, light = true)?
  sdl.AddFont("code", "$home/fonts/JetBrainsMono-Regular.ttf", 13, second)
end

-- Opens the window, the files given after the home (or one empty buffer) and runs until the editor ends.
defn main()
  home = Args[1]
  window = opened(home)?
  measured = sdl.Measure(window)
  look = ui.Look(ui.Dark, measured.Width, measured.Height)
  cell = {Width: look.Width("M", "code"), Height: sdl.TextSize("Ag", window, font = "code").Height + view.LineGap}
  empty = view.Start([text.Of("", missing)], look, cell, 1280, 720)
  empty.Window = window
  state = commands.Settled(commands.OpenAll(Skip(1, Args), empty))
  sdl.Run(state, commands.Update, view.View, window, moving = commands.Moving)
  sdl.Close(window)
  Ok(missing)
end

Print(main())
