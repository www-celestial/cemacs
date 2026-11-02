-- Checks of files.Kp against real files, in a new folder under /tmp. It is a script, not a test file: it needs permissions.
-- Run it with kepler run --allow read,write tests/files-check.k. It prints ok at the end and stops at the first failure.
use sys
use files

-- Stops the script with the words if the condition is false.
defn check(condition, words)
  if not condition
    Panic("FAILED: $words")
  end
end

-- The kind of the error of a result, or "ok" for an Ok.
kindOf(r) = if IsErr(r) r.Error.Kind else "ok" end

-- The names in the folder, in one text: lists compare element by element in Kepler, so a text is the way to compare them.
names(folder) = Join(",", Unwrap(sys.List(folder)))

-- Is there a folder at this path?
folderAt(path) = sys.Exists(path) and Unwrap(sys.Stat(path)).IsDir

-- The bytes of a text, in one text.
byteText(words) = Join(",", [Text(b) for b in Bytes(words)])

folder = "/tmp/kemacs-files-check-$(Text(sys.Now()))"
check(IsOk(sys.Mkdir(folder)), "the folder is made")
target = "$folder/a.k"

-- A file that doesn't exist reads as "" with disk missing.
gone = files.ReadFile("$folder/none.k")
check(IsOk(gone), "missing file is Ok")
check(Unwrap(gone).Words == "" and IsMissing(Unwrap(gone).Disk), "missing file reads as empty with disk missing")

-- Save a new file, then read it back.
saved = files.SaveFile(target, "héllo\nworld\n", missing)
check(IsOk(saved), "saving a new file")
back = Unwrap(files.ReadFile(target))
check(back.Words == "héllo\nworld\n", "save then read gives the same words")
check(back.Disk == Unwrap(saved), "the disk after saving is the disk of a read")
check(names(folder) == "a.k", "saving leaves no other file in the folder")

-- Saving a new file where a file has appeared in the meantime.
check(kindOf(files.SaveFile(target, "mine", missing)) == "changed", "a new file over a file that appeared is refused")
check(Unwrap(sys.Read(target)) == "héllo\nworld\n", "the file that appeared stays as it was")

-- A file changed after reading. A different size is a different disk even within one tick of the clock.
other = "$folder/b.k"
Unwrap(files.ForceSave(other, "one"))
readB = Unwrap(files.ReadFile(other))
Unwrap(sys.Write(other, "two2"))
refused = files.SaveFile(other, "mine", readB.Disk)
check(kindOf(refused) == "changed", "a file changed after reading gives Err of kind changed")
check(Unwrap(sys.Read(other)) == "two2", "the changed file stays as it was")
check(names(folder) == "a.k,b.k", "a refused save leaves no other file")

-- Saving with the right disk works, and gives the next disk.
okSave = files.SaveFile(other, "fresh", Unwrap(files.ReadFile(other)).Disk)
check(IsOk(okSave), "saving with the right disk")
check(Unwrap(sys.Read(other)) == "fresh", "the new words are in the file")
check(Unwrap(okSave) == Unwrap(files.ReadFile(other)).Disk, "the new disk is the one of the file")

-- A file removed after reading: saving is refused, force_save writes it again.
Unwrap(sys.Remove(other))
check(kindOf(files.SaveFile(other, "x", Unwrap(okSave))) == "changed", "a file that vanished is refused")
check(IsOk(files.ForceSave(other, "again")), "force_save writes over anything")
check(Unwrap(sys.Read(other)) == "again", "force_save wrote the words")

-- A failed write leaves the old file whole: here the target is in a folder that doesn't exist.
bad = "$folder/nodir/c.k"
check(IsErr(files.SaveFile(bad, "x", missing)), "saving in a folder that doesn't exist fails")
check(IsErr(files.ForceSave(bad, "x")), "force_save in a folder that doesn't exist fails")
noFolder = files.ForceSave(bad, "x").Error.Message
check(Contains(bad, noFolder) and not Contains(".kemacs-", noFolder), "a failed write names the file, not the new one: $noFolder")
check(names(folder) == "a.k,b.k", "a failed save leaves nothing behind")

-- A failed rename leaves the old file whole: the target is a folder.
Unwrap(sys.Mkdir("$folder/sub"))
check(IsErr(files.ForceSave("$folder/sub", "x")), "saving over a folder fails")
overFolder = files.ForceSave("$folder/sub", "x").Error.Message
check(Contains("$folder/sub", overFolder) and not Contains(".kemacs-", overFolder), "a failed rename names the file, not the new one: $overFolder")
check(names(folder) == "a.k,b.k,sub", "a failed rename removes the new file")
check(IsErr(files.ReadFile("$folder/sub")), "reading a folder fails")
check(IsErr(files.SaveFile("$folder/sub", "x", missing)), "saving over a folder with disk missing fails")
Unwrap(sys.Remove("$folder/sub"))

-- A person's file named like the old temporary file is never touched, by a save, by a failed save or by the cleanup.
oldName = "$folder/a.k.kemacs-new"
Unwrap(sys.Write(oldName, "precious"))
Unwrap(files.ForceSave(target, "after"))
check(Unwrap(sys.Read(oldName)) == "precious", "a file named a.k.kemacs-new keeps its content after a save")
check(names(folder) == "a.k,a.k.kemacs-new,b.k", "a save leaves no new file")
Unwrap(sys.Mkdir("$folder/sub"))
Unwrap(sys.Write("$folder/sub.kemacs-new", "mine"))
check(IsErr(files.ForceSave("$folder/sub", "x")), "saving over a folder fails again")
check(Unwrap(sys.Read("$folder/sub.kemacs-new")) == "mine", "a failed save removes nothing it didn't create")
check(names(folder) == "a.k,a.k.kemacs-new,b.k,sub,sub.kemacs-new", "a failed save leaves nothing of its own")
Unwrap(sys.Remove("$folder/sub.kemacs-new"))
Unwrap(sys.Remove("$folder/sub"))
Unwrap(sys.Remove(oldName))
Unwrap(sys.Mkdir(oldName))
check(IsOk(files.ForceSave(target, "again2")), "an empty folder named like the old temporary file is no obstacle")
check(folderAt(oldName), "the empty folder is still there")
Unwrap(sys.Remove(oldName))

-- CRLF: read then save gives the same bytes.
crlf = "a\r\nb\r\n"
Unwrap(sys.Write(target, crlf))
r = Unwrap(files.ReadFile(target))
check(r.Words == crlf, "CRLF is read as it is")
Unwrap(files.SaveFile(target, r.Words, r.Disk))
check(byteText(Unwrap(sys.Read(target))) == byteText(crlf), "CRLF: the same bytes after a save")

-- A file with a zero byte, and one that is not UTF-8, give an Err and are not touched.
zero = "$folder/zero"
Unwrap(sys.Write(zero, FromBytes([97, 0, 98])))
check(IsErr(files.ReadFile(zero)), "a zero byte gives an Err")
latin = "$folder/latin"
Unwrap(sys.Write(latin, FromBytes([99, 97, 102, 233])))
check(IsErr(files.ReadFile(latin)), "Latin-1 gives an Err")
check(byteText(Unwrap(sys.Read(latin))) == "99,97,102,233", "the refused file stays as it was")

-- A file over 16 MiB is refused from its size alone, as an Err: reading one too large for memory would panic and lose the text of the other buffers.
large = "$folder/large"
Unwrap(sys.Write(large, Repeat(16 * 1024 * 1024 + 1, "x")))
tooLarge = files.ReadFile(large)
check(kindOf(tooLarge) == "large", "a file over the limit gives an Err of kind large")
check(Contains(large, tooLarge.Error.Message) and Contains("too large", tooLarge.Error.Message), "the message names the file and says why")
Unwrap(sys.Remove(large))

-- What isn't a regular file is refused from sys.Stat, before any read: reading a FIFO waits for a writer that never comes, and /dev/zero never ends and fills the memory.
fifo = "$folder/pipe"
check(Unwrap(sys.Run("mkfifo", [fifo])).Code == 0, "the FIFO is made")
pipe = files.ReadFile(fifo)
check(kindOf(pipe) == "special", "a FIFO gives an Err of kind special")
check(Contains(fifo, pipe.Error.Message) and Contains("not a regular file", pipe.Error.Message), "the message names the FIFO and says why")
device = files.ReadFile("/dev/zero")
check(kindOf(device) == "special", "a device gives an Err of kind special")
check(Contains("/dev/zero", device.Error.Message) and Contains("not a regular file", device.Error.Message), "the message names the device and says why")
check(kindOf(files.ReadFile(folder)) == "folder", "a folder keeps its own message")
Unwrap(sys.Remove(fifo))

-- IsText.
check(files.IsText(""), "empty is text")
check(files.IsText("plain ascii\r\n"), "ascii is text")
check(files.IsText("é€😀"), "valid UTF-8 is text")
check(not files.IsText(FromBytes([97, 0])), "zero byte")
check(not files.IsText(FromBytes([255])), "0xff")
check(not files.IsText(FromBytes([0xc3])), "cut sequence at the end")
check(not files.IsText(FromBytes([0xc3, 0x41])), "lead followed by a letter")
check(not files.IsText(FromBytes([0x80])), "lone continuation")
check(not files.IsText(FromBytes([0xc0, 0x80])), "overlong two bytes")
check(not files.IsText(FromBytes([0xe0, 0x80, 0x80])), "overlong three bytes")
check(not files.IsText(FromBytes([0xed, 0xa0, 0x80])), "surrogate")
check(not files.IsText(FromBytes([0xf4, 0x90, 0x80, 0x80])), "above U+10FFFF")
check(not files.IsText(FromBytes([0xf8, 0x88, 0x80, 0x80, 0x80])), "five bytes")
check(files.IsText(FromBytes([0xf4, 0x8f, 0xbf, 0xbf])), "U+10FFFF")

-- normal.
check(files.Normal("./a/../b.k") == "b.k", "normal of ./a/../b.k")
check(files.Normal("a//b/./c/") == "a/b/c", "normal of doubled and trailing slashes")
check(files.Normal("/a/b/../../c") == "/c", "normal of an absolute path")
check(files.Normal("../a/../../b") == "../../b", "normal keeps leading ..")
check(files.Normal("/../a") == "/a", "normal drops .. above the root")
check(files.Normal("a/..") == ".", "normal of nothing is a dot")
check(files.Normal("/") == "/", "normal of the root")
check(files.Normal("x.k") == "x.k", "normal of a plain name")

-- Clean up.
for name in Unwrap(sys.List(folder))
  Unwrap(sys.Remove("$folder/$name"))
end
Unwrap(sys.Remove(folder))
check(not sys.Exists(folder), "the folder is gone")
Print("ok")
