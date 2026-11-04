-- The buffer list: every open buffer, one per line, with a star for a text that isn't saved. Typing filters it, and enter goes to the buffer under the cursor.
use commands
use lists
use text
use view

-- The keys that work everywhere.
Keys() = {"C-x C-b": Open}

-- The keys of the list. Letters filter it, and the ListKeys of the config take the filter back.
Here() = {"enter": Visit}

-- Opens the list.
Open(state) = commands.ShowList("Buffers", Rows, Here, state)

-- Goes to the buffer under the cursor, and the list closes.
Visit(item, state) = commands.ToBuffer(item, state)

-- One row for each buffer that isn't a list, standing for its index: a star if its text isn't saved, its name, and its path.
defn Rows(state)
  shown = Filter(k -> not lists.IsList(state.Buffers[k]), Range(1, Len(state.Buffers)))
  width = Reduce((w, k) -> Max(w, Len(view.BufferName(state.Buffers[k]))), 0, shown)
  Map(k -> {Words: row(state.Buffers[k], width), Item: k}, shown)
end

-- The words of the row of a buffer, with its name padded to width when a path follows it.
defn row(b, width)
  name = view.BufferName(b)
  star = if text.IsModified(b) "*" else " " end
  if IsMissing(b.Path)
    "$star $name"
  else
    "$star $name$(Repeat(width - Len(name), " "))  $(b.Path)"
  end
end
