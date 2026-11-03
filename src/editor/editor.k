-- The window of Kemacs and its loop. A program starts it with a config, as apps/kemacs.k does: the core knows no app, so the keys and the settings come from there.
use sdl
use ui
use commands
use text
use view

-- The window, with the three fonts of Kemacs found in fonts/ under its home, all of this size: body, strong and code.
defn opened(home, size)
  first = sdl.Open("Kemacs", 1280, 720, "$home/fonts/AdwaitaSans-Regular.ttf", size = size, light = true)?
  second = sdl.AddFont("strong", "$home/fonts/NotoSans-Medium.ttf", size, first, light = true)?
  sdl.AddFont("code", "$home/fonts/JetBrainsMono-Regular.ttf", size, second)
end

-- Opens the window with config, the function that gives the keys and the settings, opens the files given after the home or one empty buffer, and runs until
-- the editor ends. bin/kemacs gives the home of Kemacs first, then the files to open; kepler do dev runs from the home and gives nothing.
defn Start(config)
  home = if Len(Args) == 0 "." else Args[1] end
  window = opened(home, config().FontSize())?
  measured = sdl.Measure(window)
  look = ui.Look(ui.Dark, measured.Width, measured.Height)
  cell = {Width: look.Width("M", "code"), Height: sdl.TextSize("Ag", window, font = "code").Height + view.LineGap}
  empty = view.Start([text.Of("", missing)], look, cell, 1280, 720)
  empty.Window = window
  empty.Config = config
  empty.Home = home
  state = commands.Settled(commands.OpenAll(Skip(1, Args), empty))
  sdl.Run(state, commands.Update, view.View, window, moving = commands.Moving)
  sdl.Close(window)
  Ok(missing)
end
