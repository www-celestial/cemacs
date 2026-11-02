-- Every line of every .k file of the Kepler std goes through color.Tokens, keeping the state: no line may lose a character.
-- Run from the root of kemacs with: kepler run --allow read tests/color-std.k
use sys
use color

stdFolder = "../kepler/std"

defn lostIn(path, text)
  state = color.FirstState
  bad = []
  for line in Lines(text)
    r = color.Tokens(line, state)
    state = r.State
    if Join("", Map(t -> t[2], r.Tokens)) != line
      bad = Append("$(path): $(line)", bad)
    end
  end
  bad
end

-- The states at the start of every line given by colored_to must equal the ones given by reading every line with tokens.
defn statesDifferIn(path, text)
  allLines = Lines(text)
  state = color.FirstState
  expected = [state]
  for line in allLines
    state = color.Tokens(line, state).State
    expected = Append(state, expected)
  end
  count = Len(allLines)
  if count == 0
    []
  else
    got = color.ColoredTo(count, n -> allLines[n], color.BlankColors()).Starts
    if Equal(got, Take(count, expected)) [] else ["$(path)"] end
  end
end

-- The paths of the .k files of the folder. No file at all is a bug of the test.
defn kpFiles(folder)
  names = Filter(f -> EndsWith(".k", f), Unwrap(sys.List(folder)))
  if Len(names) == 0
    Panic("no .k file in $(folder)")
  end
  names
end

bad = FlatMap(f -> lostIn(f, Unwrap(sys.Read("$(stdFolder)/$(f)"))), kpFiles(stdFolder))
if Len(bad) > 0
  Panic("lines that lose a character:\n$(Join("\n", Take(5, bad)))")
end
differ = FlatMap(f -> statesDifferIn(f, Unwrap(sys.Read("$(stdFolder)/$(f)"))), kpFiles(stdFolder))
if Len(differ) > 0
  Panic("colored_to differs from tokens in:\n$(Join("\n", differ))")
end
Print("ok")
