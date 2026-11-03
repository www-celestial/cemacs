-- Tests of lists: run with kepler test .
use lists
use text

isMatchInOrder() = lists.Matches("cmk", "commands.k") and not lists.Matches("kmc", "commands.k")
isMatchSideBySideToo() = lists.Matches("comm", "commands.k")
isMatchIgnoresCase() = lists.Matches("CMK", "commands.k") and lists.Matches("cmk", "COMMANDS.K")
isEmptyFilterMatchesAll() = lists.Matches("", "anything") and lists.Matches("", "")
isNoMatchPastTheEnd() = not lists.Matches("commands.kk", "commands.k")
isFilteredKeepsOrder() = Equal(Map(r -> r.Item, lists.Filtered("a", [{Words: "b", Item: 1}, {Words: "a2", Item: 2}, {Words: "xa", Item: 3}])), [2, 3])
isWordsOnePerLine() = lists.Words([{Words: "a", Item: 1}, {Words: "b", Item: 2}]) == "a\nb" and lists.Words([]) == ""
isLineOfItem() = lists.LineOf(30, [10, 30, 40], 3) == 2
isLineOfGoneItem() = lists.LineOf(20, [10, 30, 40], 3) == 3 and lists.LineOf(20, [10], 3) == 1 and lists.LineOf(20, [], 3) == 1
isTextIsNoList() = not lists.IsList(text.Of("a", missing)) and IsMissing(lists.Of(text.Of("a", missing)))
