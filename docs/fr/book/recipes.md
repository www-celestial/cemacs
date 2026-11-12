# Recettes

Chaque recette ici est une petite tâche, faite dans votre propre dossier, `user/` : ce qu'elle fait, le code à y mettre,
comment la lier à une touche ou l'appeler, et ce que vous voyez. Le code de chaque recette a tourné quand cette page a été
construite, sur l'éditeur lui-même sans fenêtre, et les lignes avec `-->` ont vérifié ce qu'il fait ; les liens sous chaque
recette mènent à la référence de chaque package et de chaque fonction qu'elle emploie. [Modifier Cemacs](customising.md)
donne les règles derrière elles.

## Comment une recette se branche

Vos changements vivent dans `user/config/config.ce`, qu'ouvre `C-c f c`. Cemacs appelle sa fonction `Changed` avec la
config qu'il a faite : le record de fonctions sur lequel tourne l'éditeur, ses keymaps, ses réglages et ses hooks. Ce que
`Changed` rend est ce sur quoi l'éditeur tourne. Chaque recette ci-dessous est donc une fonction d'une config vers une
config, qui change quelques champs de la config et la rend, et votre `Changed` appelle les recettes que vous voulez, l'une
dans l'autre :

```text
defn Changed(config)
  (** Cemacs with my changes. *)
  Tools(MySettings(config))
end
```

Copiez une recette dans `user/config/config.ce`, ses lignes `use` en haut du fichier, et appelez-la dans `Changed`. La
dernière section, [Toutes ensemble](#toutes-ensemble), fait tourner un `Changed` qui appelle chaque recette de cette
page.

Le code ci-dessous essaie chaque recette comme `src/cemacs.ce` la fait tourner. `cemacs` fait la config de Cemacs, ses
touches, les réglages de `src/emacs` et les hooks de la vérification, telle que la reçoit votre `Changed`, et la donne à une
recette ; `tried` fait l'éditeur sur cette config avec un buffer vide, puis ouvre les fichiers donnés et fait tourner le
`Start` de la config, comme le fait la fenêtre à son démarrage. [press.Press] joue ensuite des touches à travers
l'éditeur, comme le font les tests de Cemacs.

```cesia fold=code
use src/buffers
use src/check
use src/emacs
use src/folders
use src/help
use src/output
use src/project
use src/rope
use src/ui
use core/commands
use core/panes
use core/press
use core/text
use core/view
use std/dict
use std/value

(* The keys of Cemacs as src/cemacs.ce merges them: that file opens the window when it loads, so the page makes the same merge. *)
appKeys() = dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()), project.Keys()), check.Keys()),
  output.Keys())

defn cemacs(changed)
  (** The config as src/cemacs.ce makes it, with changed in place of the Changed of user/config. *)
  c = changed(check.Hooked(emacs.Config(appKeys)))
  keys = c.Keys
  c.Keys = () -> help.WithHelp(keys())
  c
end

defn tried(changed, files)
  (** The editor on the config of changed, with no window: one empty buffer, then the files opened and the Start of the config run, as at the start. *)
  s = view.Start([text.Of("", missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
  s.Config = () -> cemacs(changed)
  commands.Settled(cemacs(changed).Start(commands.OpenAll(files, s)))
end

here(state) = state.Buffers[state.Current]   (** The buffer being edited. *)
textOf(state) = rope.Text(here(state).Rope)   (** Its text. *)
```

Cette page tourne dans un dossier qui contient les fichiers qu'ouvrent ses recettes : `notes.md`, `todo.md`, `shop.ce`,
`shop.test.ce` et `user/notes/notes.md`.

## Votre police, votre tab, votre thème et votre fenêtre

**Ce qu'elle fait.** Le texte à 17 points au lieu de 15, Tab qui tape quatre espaces au lieu de deux, le thème clair au lieu
du sombre, et une fenêtre de 1600 sur 900 pixels au démarrage au lieu de 1280 sur 720.

```cesia
use src/ui

defn MySettings(config)
  (** My settings: larger text, a tab of four spaces, the light theme and a larger window. *)
  c = config
  c.FontSize = () -> 17
  c.TabText = () -> "    "
  c.Theme = () -> ui.Light
  c.Window = () -> {Width: 1600, Height: 900}
  c
end
```

Chaque champ de la config est une fonction, ici écrite sur place : `() -> 17` est une fonction sans paramètre qui donne 17.
`c = config` puis `c.FontSize = ...` font un nouveau record, `config` restant tel qu'il était. Un champ que vous ne posez pas
garde la valeur de Cemacs : un réglage que Cemacs ajoute plus tard passe donc.

**Comment l'employer.** Appelez-la dans `Changed`, `MySettings(config)`, et redémarrez Cemacs : la fenêtre lit la taille du
texte, le thème et sa propre taille une seule fois, quand elle s'ouvre. Sous `cesia do dev`, le tab marche dès le Tab
suivant, sans redémarrage.

**Ce que vous voyez.** La fenêtre s'ouvre en 1600 sur 900, dans le thème clair, et Tab tape quatre espaces :

```cesia
mine = cemacs(MySettings)
[mine.FontSize(), mine.Window()] --> [17, {Width: 1600, Height: 900}]
value.Equal(mine.Theme(), ui.Light) --> true
textOf(press.Press(["tab"], tried(MySettings, []))) --> "    "
```

Un thème est un record de couleurs, chacune un nombre comme `0x0E1013` : le rouge, le vert et le bleu, en deux chiffres
hexadécimaux chacun. Un thème à vous peut partir de l'un des deux de [src/ui] et changer certaines de ses couleurs, ici un
fond noir autour des panes :

```cesia
defn Black()
  (** The dark theme on a black ground. *)
  t = ui.Dark
  t.Ground = 0x000000
  t
end

Black().Ground --> 0
```

`c.Theme = Black` l'emploie alors : `Black` est une fonction sans paramètre, c'est donc le champ tel quel.

Plus : [ui.Dark], [ui.Light], [emacs.FontSize], [emacs.TabText], [emacs.Theme], [emacs.Window], et chaque réglage dans
[Modifier Cemacs](customising.md#les-réglages).

## Deux fichiers côte à côte au démarrage

**Ce qu'elle fait.** Chaque démarrage ouvre deux de vos fichiers, l'un dans un pane à gauche et l'autre à droite, et vous
laisse dans celui de droite. Un pane est une partie de la fenêtre qui montre un buffer :
[Fenêtres et panes](windows.md#les-panes) les décrit.

```cesia allow=read
use core/commands

(** The two files that I start with. *)
startFiles() = ["notes.md", "todo.md"]

defn SideBySide(state)
  (** The first file on the left, the second on the right, the right one being edited. *)
  files = startFiles()
  left = commands.OpenAll([files[1]], state)
  commands.OpenFile(files[2], commands.NextPane(commands.SplitRight(left)))
end

defn TwoFiles(config)
  (** Cemacs that starts on my two files, side by side. *)
  c = config
  c.Start = SideBySide
  c
end
```

`Start` est le champ de la config qui tourne une fois, après l'ouverture des fichiers donnés à `bin/cemacs` : une fonction
d'un état de l'éditeur vers un nouvel état, comme une commande. [commands.OpenAll] ouvre le premier fichier à la place du
buffer vide avec lequel Cemacs démarre, là où [commands.OpenFile] garderait ce buffer à côté ; [commands.SplitRight] coupe
le pane en deux, côte à côte, tous deux sur le premier fichier ; [commands.NextPane] va à celui de droite ; et le second
fichier s'y ouvre.

Écrivez les chemins complets de vos fichiers, comme `/home/moi/notes.md` : un chemin relatif, comme les deux d'ici, se lit
depuis le dossier où Cemacs a démarré.

**Comment l'employer.** Appelez-la dans `Changed`, `TwoFiles(config)`, et redémarrez Cemacs : `Start` ne tourne qu'au
démarrage.

**Ce que vous voyez.** Deux panes, `notes.md` à gauche et `todo.md` à droite, celui que vous modifiez, et aucun autre
buffer :

```cesia
s = tried(TwoFiles, [])
[view.BufferName(s.Buffers[leaf.Buffer]) for leaf in panes.Leaves(panes.Tree(s))] --> ["notes.md", "todo.md"]
[panes.Active(s), value.Len(s.Buffers)] --> [2, 2]
```

Plus : [commands.OpenAll], [commands.OpenFile], [commands.SplitRight], [commands.NextPane], [panes.Leaves],
[panes.Active], [emacs.Start].

## Un nouveau buffer vide sur une touche

**Ce qu'elle fait.** `C-c b e` crée un nouveau buffer, sans texte et sans fichier, et le montre dans le pane que vous
modifiez : un endroit où écrire ce qui n'appartient encore à aucun fichier, comme le buffer `*scratch*` d'Emacs. Un buffer
est un texte en cours de modification et ce que Cemacs en sait, son curseur, son fichier et son annulation :
[Fichiers et buffers](files.md#les-buffers) les décrit. Cemacs n'a pas de telle commande, la voici donc :

```cesia
use core/text
use std/dict
use std/list
use std/value

defn NewBuffer(state)
  (** A new empty buffer with no file, in the pane being edited. *)
  s = state
  s.Buffers = list.Append(text.Of("", missing), state.Buffers)
  s.Current = value.Len(s.Buffers)
  s
end

defn NewBufferKey(config)
  (** Cemacs with C-c b e for a new empty buffer, in the group of the buffers. *)
  c = config
  c.Keys = () -> dict.Put("C-c b e", NewBuffer, config.Keys())
  c
end
```

L'état de l'éditeur contient ses buffers, `state.Buffers`, et le numéro de celui qu'on modifie, `state.Current` ; le pane
que vous modifiez montre toujours le buffer courant, si bien que rendre le nouveau courant suffit. [text.Of] fait un buffer
à partir d'un texte et d'un chemin, `missing` pour aucun. Les nouvelles touches sont celles de la config, `config.Keys()`,
avec une de plus mise par [dict.Put].

**Comment l'employer.** Appelez-la dans `Changed`, `NewBufferKey(config)`, et enregistrez : sous `cesia do dev`, la touche
marche dès la touche suivante. `C-c b` est le groupe des buffers : la bande des hints après `C-c b` liste donc `e` avec les
autres.

**Ce que vous voyez.** Un buffer nommé `untitled` dans la mode line. Tapez-y ; `C-x C-s` demande un nom, `Save as: `
(enregistrer sous), et l'y enregistre.

```cesia
s = press.Press(["C-c", "b", "e", "hello"], tried(NewBufferKey, []))
[value.Len(s.Buffers), view.BufferName(here(s)), textOf(s)] --> [2, "untitled", "hello"]
press.Press(["C-x", "C-s"], s).Prompt.Label --> "Save as: "
```

Plus : [text.Of], [dict.Put], [list.Append], [commands.Save], [view.BufferName].

## Dupliquer une ligne

**Ce qu'elle fait.** La ligne du curseur réécrite sous elle, le curseur sur la copie, en une seule étape d'annulation :
`C-/` la reprend d'un coup.

```cesia
use core/text
use src/rope

defn DuplicateLine(state)
  (** The line of the cursor written again below it, the cursor on the copy. *)
  b = state.Buffers[state.Current]
  words = rope.Line(b.Cursor.Line, b.Rope)
  s = state
  s.Buffers[state.Current] = text.InsertWords("\n$words", text.ToLineEnd(b))
  s
end
```

Le texte d'un buffer est une rope, `b.Rope`, un arbre de morceaux de texte que lit [src/rope] : [rope.Line] donne le texte
d'une ligne. [text.ToLineEnd] amène le curseur à la fin de sa ligne, et [text.InsertWords] y tape un texte, en une seule
étape d'annulation. Chaque fonction de [core/text] prend un buffer et en donne un nouveau, que la commande remet dans
l'état.

**Comment l'employer.** C'est une commande : [Un groupe de touches à vous](#un-groupe-de-touches-à-vous) la lie à `C-c t d`.

**Ce que vous voyez.** Sur un buffer qui contient `hello` :

```cesia
one = press.Press(["hello"], tried(c -> c, []))
textOf(DuplicateLine(one)) --> "hello\nhello"
here(DuplicateLine(one)).Cursor --> {Line: 2, Column: 5}
textOf(press.Press(["C-/"], DuplicateLine(one))) --> "hello"
```

Plus : [rope.Line], [text.ToLineEnd], [text.InsertWords], [core/text].

## Le test à côté du code

**Ce qu'elle fait.** Dans un fichier de Cesia, `shop.ce`, ouvre ses tests, `shop.test.ce`, dans un pane à droite ; dans les
tests, ouvre le code. Cesia garde les tests d'un package dans des fichiers à côté de son code, dont le nom finit par
`.test.ce`.

```cesia allow=read
use core/commands
use std/text as str
use std/value

defn otherOf(path)
  (** The test file of a file of Cesia, or the code of a test file. *)
  if str.EndsWith(".test.ce", path)
    "$(str.Slice(1, value.Len(path) - 8, path)).ce"
  else
    "$(str.Slice(1, value.Len(path) - 3, path)).test.ce"
  end
end

defn TestBeside(state)
  (** The tests of the file being edited in a pane on its right, or its code beside its tests. *)
  path = state.Buffers[state.Current].Path
  if value.IsMissing(path) or not str.EndsWith(".ce", path)
    return commands.Say("This buffer is no file of Cesia.", state)
  end
  commands.OpenFile(otherOf(path), commands.NextPane(commands.SplitRight(state)))
end
```

[commands.Say] met un message sur la prompt line, la ligne du bas de la fenêtre. Un fichier de test qui n'existe pas encore
s'ouvre comme un buffer vide pour ce chemin, que `C-x C-s` écrit.

**Comment l'employer.** Une commande : [Un groupe de touches à vous](#un-groupe-de-touches-à-vous) la lie à `C-c t t`.

**Ce que vous voyez.** `shop.ce` à gauche, `shop.test.ce` à droite, celui que vous modifiez ; dans un buffer qui n'est pas
un fichier de Cesia, un message :

```cesia
[otherOf("src/shop/shop.ce"), otherOf("src/shop/shop.test.ce")] --> ["src/shop/shop.test.ce", "src/shop/shop.ce"]
s = commands.Settled(TestBeside(tried(c -> c, ["shop.ce"])))
[view.BufferName(s.Buffers[leaf.Buffer]) for leaf in panes.Leaves(panes.Tree(s))] --> ["shop.ce", "shop.test.ce"]
TestBeside(tried(c -> c, ["notes.md"])).Message --> "This buffer is no file of Cesia."
```

Plus : [commands.OpenFile], [commands.SplitRight], [commands.NextPane], [commands.Say], [text.EndsWith], [text.Slice].

## Demander, puis confirmer : remplacer un mot

**Ce qu'elle fait.** Demande un mot et ce qui le remplace, puis demande `y` ou `n` avec le nombre trouvé, et les remplace
tous dans le buffer, en une seule étape d'annulation. Cemacs n'a pas de remplacement à lui : cette recette en fait un
simple, d'un texte tel qu'il est écrit, sans pattern (sans motif à reconnaître).

```cesia
use core/commands
use core/text
use src/rope
use std/text as str

defn Replace(state)
  (** Asks for a word and what replaces it, then, after y, replaces it everywhere in the buffer. *)
  commands.Ask("Replace: ", "", (old, s) -> if old == "" commands.Say("Nothing to replace.", s) else askedBy(old, s) end, state)
end

askedBy(old, state) = commands.Ask("Replace $old with: ", "", (by, s) -> confirmed(old, by, s), state)   (** Asks for what replaces old. *)

defn confirmed(old, by, state)
  (** Counts old in the buffer, and asks before it replaces them. *)
  n = str.Count(old, rope.Text(state.Buffers[state.Current].Rope))
  if n == 0
    return commands.Say("$old isn't in this buffer.", state)
  end
  commands.Confirm("Replace $n of $old? (y or n)", (yes, s) -> if yes == "y" replaced(old, by, n, s) else commands.Say("Nothing replaced.", s) end, state)
end

defn replaced(old, by, n, state)
  (** Every old of the buffer replaced by by, as one step of undo, the cursor back on its line, and the count said. *)
  b = state.Buffers[state.Current]
  words = str.Replace(old, by, rope.Text(b.Rope))
  all = text.ToFileEnd(text.SetMark(text.ToFileStart(b)))
  done = text.ClearMark(text.ReplaceRegion(e -> text.InsertWords(words, e), all))
  s = state
  s.Buffers[state.Current] = text.Place(b.Cursor.Line, b.Cursor.Column, done)
  commands.Say("Replaced $n.", s)
end
```

[commands.Ask] ouvre une question sur la prompt line : un label (l'étiquette de la question), la réponse par laquelle elle
commence, et une fonction qui reçoit la réponse et l'état une fois qu'Enter a fermé la question. [commands.Confirm] demande
de la même façon `y` ou `n`. Tout le texte est sélectionné, de la marque que [text.SetMark] pose à son début jusqu'au
curseur à sa fin, et [text.ReplaceRegion] donne ce que sa fonction fait du buffer sans la sélection, en une seule étape
d'annulation. [text.Count] et [text.Replace] comptent et remplacent dans un texte ; [text.Place] remet le curseur sur sa
ligne, ou sur la dernière ligne si le texte a raccourci.

**Comment l'employer.** Une commande : [Un groupe de touches à vous](#un-groupe-de-touches-à-vous) la lie à `C-c t r`.

**Ce que vous voyez.** `Replace: `, puis `Replace TODO with: `, puis `Replace 2 of TODO? (y or n)` sur la prompt line ;
après `y`, le texte remplacé et `Replaced 2.` ; `C-/` reprend le tout.

```cesia allow=read
todo = tried(c -> c, ["todo.md"])
asked = press.Press(["TODO", "enter", "DONE", "enter"], Replace(todo))
asked.Prompt.Label --> "Replace 2 of TODO? (y or n)"
done = press.Press(["y"], asked)
[done.Message, str.Count("DONE", textOf(done))] --> ["Replaced 2.", 2]
textOf(press.Press(["C-/"], done)) == textOf(todo) --> true
press.Press(["n"], asked).Message --> "Nothing replaced."
```

Plus : [commands.Ask], [commands.Confirm], [text.SetMark], [text.ReplaceRegion], [text.Place], [text.Count], [text.Replace].

## Une liste à vous : les lignes à faire

**Ce qu'elle fait.** Liste les lignes du buffer qui contiennent `TODO`, chacune avec son numéro ; taper les filtre, et Enter
va à celle sous le curseur. Une liste est un buffer de rangées, en lecture seule, qu'une app ouvre et dont les touches
agissent sur la rangée sous le curseur : la liste des buffers et le gestionnaire de dossiers sont des listes.

```cesia
use core/commands
use core/lists
use core/text
use src/rope
use std/text as str

defn ToDo(state)
  (** Lists the lines of the buffer that hold TODO, and Enter goes to the one under the cursor. *)
  b = state.Buffers[state.Current]
  rows = [{Words: "$n  $(str.Trim(rope.Line(n, b.Rope)))", Item: n} for n in 1..rope.LineCount(b.Rope) if str.Contains("TODO", rope.Line(n, b.Rope))]
  commands.ShowList("To do", rows, () -> {"enter": wentTo}, state)
end

defn wentTo(n, state)
  (** Back to the buffer the list was opened from, the cursor at the start of line n. *)
  s = commands.ToBuffer(lists.Of(state.Buffers[state.Current]).Back, state)
  s.Buffers[s.Current] = text.Place(n, 0, s.Buffers[s.Current])
  s
end
```

[commands.ShowList] ouvre une liste : son nom, ses rangées, chacune `{Words, Item}` où `Item` est ce que la rangée
représente, ici un numéro de ligne, et une fonction qui donne les touches de la liste, dont les commandes reçoivent l'item
de la rangée et l'état. [lists.Of] lit ce que sait une liste, `Back` le buffer depuis lequel elle a été ouverte, et
[commands.ToBuffer] y retourne, en fermant la liste. L'`occur` d'Emacs fait cela pour n'importe quel pattern.

**Comment l'employer.** Une commande : [Un groupe de touches à vous](#un-groupe-de-touches-à-vous) la lie à `C-c t l`.

**Ce que vous voyez.** La liste `To do` avec deux rangées ; `pap` puis Enter, qui garde la rangée de `paper`, va à la
ligne 5 :

```cesia allow=read
todo = tried(c -> c, ["todo.md"])
textOf(ToDo(todo)) --> "3  - TODO write the tests of the shop\n5  - TODO read the paper on ropes"
here(press.Press(["pap", "enter"], ToDo(todo))).Cursor --> {Line: 5, Column: 0}
```

Plus : [commands.ShowList], [commands.ToBuffer], [lists.Of], [rope.Line], [rope.LineCount], [text.Place],
[Recherche](search.md#les-listes) pour la façon dont un filtre retient une rangée.

## Un groupe de touches à vous

**Ce qu'elle fait.** `C-c t` devient un groupe à vous, `tools` (outils), avec les quatre commandes ci-dessus : `C-c t d`
duplique la ligne, `C-c t t` ouvre le test à côté du code, `C-c t r` remplace un mot, `C-c t l` liste les lignes à faire. Un
groupe est une prefix key, une touche qui attend la suivante, dont le binding est un nom : la bande des hints, qui
s'affiche au-dessus de la prompt line une demi-seconde après une prefix key, le montre comme `+tools`, puis les touches qui
le suivent.

```cesia
use std/dict

defn Tools(config)
  (** Cemacs with my group of tools under C-c t. *)
  c = config
  c.Keys = () -> dict.Merge(config.Keys(), {"C-c t": "tools", "C-c t d": DuplicateLine, "C-c t t": TestBeside, "C-c t r": Replace, "C-c t l": ToDo})
  c
end
```

Une keymap est un dictionnaire qui va de key sequences, des textes comme `"C-c t d"`, vers ce qu'elles lancent.
[dict.Merge] donne le dernier mot aux touches de son second argument : une touche à vous l'emporte donc sur une de Cemacs ;
`C-c t` est libre dans Cemacs, dans chaque buffer et chaque liste, comme le montre [Touches](keys.md).

**Comment l'employer.** Appelez-la dans `Changed`, `Tools(config)`, et enregistrez : sous `cesia do dev`, les touches
marchent dès la touche suivante.

**Ce que vous voyez.** Attendez après `C-c` : la bande montre `+tools` parmi les groupes. Attendez après `C-c t` : elle
montre `?`, `d`, `l`, `r` et `t`, chacune avec le nom de sa commande. `C-c t ?` les liste dans une liste, avec la première
phrase de leur commentaire :

```cesia
waited(keys) = commands.Update({Kind: "tick", Seconds: 1.0}, press.Press(keys, tried(Tools, [])))   (** The editor a second after keys. *)
[h.Name for h in waited(["C-c"]).Hints if h.Key == "t"] --> ["+tools"]
[h.Name for h in waited(["C-c", "t"]).Hints] --> ["ShowKeys", "DuplicateLine", "ToDo", "Replace", "TestBeside"]
textOf(press.Press(["C-c", "t", "?"], tried(Tools, []))) -->
```

Le `?` après chaque prefix key, les vôtres comprises, vient de [help.WithHelp], que `src/cemacs.ce` passe sur les touches
que rend votre `Changed`. Une commande écrite sur place, comme `s -> commands.Say("hi", s)`, n'a pas de nom : la bande la
montre comme `a function`, et la liste de `?` comme `(a function)`. Donnez-lui un nom et un commentaire `(** *)` pour
qu'il soit montré.

Plus : [dict.Merge], [help.WithHelp], [keys.Hints], [Touches](keys.md), [la bande des hints](windows.md#la-bande-des-hints).

## Quelque chose après chaque enregistrement

**Ce qu'elle fait.** Après chaque enregistrement, la prompt line dit aussi les lignes du fichier :
`Saved notes.md, 5 lines`. Un hook est une fonction que le core appelle à un moment donné, ici `Saved`, après chaque
enregistrement ; la vérification du code Cesia y a déjà le sien, qui marque les buffers Cesia à vérifier de nouveau. Cette
recette l'enveloppe, pour que les deux tournent.

```cesia allow=read,write
use core/commands
use src/rope

defn counted(state)
  (** The message of the save, with the number of lines of the file. *)
  commands.Say("$(state.Message), $(rope.LineCount(state.Buffers[state.Current].Rope)) lines", state)
end

defn AfterSave(config)
  (** Cemacs that tells the lines of a file after each save, after the hook of the check. *)
  c = config
  c.Saved = s -> counted(config.Saved(s))
  c
end
```

`config.Saved` est le hook qu'avait la config, celui de la vérification, que [check.Hooked] lui a donné avant `Changed` :
le nouveau l'appelle d'abord, puis ajoute ses mots. Un hook posé sans celui d'avant laisserait les buffers Cesia sans
vérification après un enregistrement. [rope.LineCount] compte les lignes, une de plus que les fins de ligne.

**Comment l'employer.** Appelez-la dans `Changed`, `AfterSave(config)`, et enregistrez : sous `cesia do dev`,
l'enregistrement suivant le dit.

**Ce que vous voyez.**

```cesia
saved = press.Press(["- buy bread", "enter", "C-x", "C-s"], tried(AfterSave, ["notes.md"]))
saved.Message --> "Saved notes.md, 5 lines"
```

Plus : [check.Hooked], [commands.Say], [rope.LineCount], [Modifier Cemacs](customising.md#les-hooks), qui décrit les trois
hooks.

## Votre première app, dans user/notes/

**Ce qu'elle fait.** Une app de notes : `C-c n n` ouvre votre fichier de notes à sa fin, et `C-c n a` demande une note,
l'écrit à la fin du fichier et l'enregistre, sans quitter le buffer où vous étiez. Les notes vivent à côté de l'app, dans
`user/notes/notes.md` : `git pull` ne les touche donc jamais non plus. Une app est un package, un dossier de fichiers
Cesia : ici `user/notes/`, avec ce fichier dedans, `user/notes/notes.ce` :

```cesia allow=read,write
use core/commands
use core/text

(** The file of my notes, beside this app in user/notes/. *)
notesPath(state) = "$(commands.Home(state))/user/notes/notes.md"

defn Open(state)
  (** Opens my notes, the cursor at their end, ready for the next one. *)
  s = commands.OpenFile(notesPath(state), state)
  s.Buffers[s.Current] = text.ToFileEnd(s.Buffers[s.Current])
  s
end

Add(state) = commands.Ask("Note: ", "", added, state)   (** Asks for a note, and writes it at the end of my notes. *)

defn added(note, state)
  (** The note written at the end of my notes, saved, and the buffer that was being edited being edited again. *)
  s = Open(state)
  s.Buffers[s.Current] = text.InsertWords("- $note\n", s.Buffers[s.Current])
  s = commands.Save(s)
  s.Current = state.Current
  commands.Say("Noted.", s)
end

(** The keys of my notes. *)
Keys() = {"C-c n": "notes", "C-c n n": Open, "C-c n a": Add}
```

[commands.Home] est le dossier de Cemacs, où est `user/`. `C-c n`, n pour notes, est libre sauf dans le gestionnaire de
dossiers, où il garde son propre sens, un nouveau fichier : les touches d'une liste passent devant les touches globales.
Les touches de l'app entrent par `Changed`, dans `user/config/config.ce`, qui reçoit le package par `use user/notes` en
haut, et le nomme `notes` :

```cesia
use std/dict

defn WithNotes(config)
  (** Cemacs with the keys of my notes. *)
  c = config
  c.Keys = () -> dict.Merge(config.Keys(), notes.Keys())
  c
end
```

Cette page n'a pas de package `user/notes` : un record avec sa fonction en tient donc la place ici, `notes = {Keys: Keys}` ;
dans votre `config.ce`, `use user/notes` donne le vrai.

```cesia
notes = {Keys: Keys}
```

**Comment l'employer.** Créez le dossier `user/notes/` et le fichier `notes.ce`, ajoutez `use user/notes` et `WithNotes` à
`config.ce`, et redémarrez Cemacs : un programme qui tourne ne peut pas charger un package qu'il n'a pas chargé à son
démarrage, et sous `cesia do dev` Cesia le dit, `A running program can't load a new module. Restart it to use this one.`
(un programme qui tourne ne peut pas charger un nouveau module ; redémarrez-le pour employer celui-ci). Après cela, chaque
changement de l'app se recharge dès la touche suivante. `cesia test user` lance les tests de votre dossier : un fichier
`notes.test.ce` à côté de `notes.ce`, avec des fonctions dont le nom commence par `is`, comme le dit le livre de Cesia.

**Ce que vous voyez.** `C-c n n` ouvre `notes.md` avec le curseur à sa fin ; `C-c n a`, une note et Enter l'écrivent et
enregistrent le fichier, et vous restez où vous étiez :

```cesia
opened = press.Press(["C-c", "n", "n"], tried(WithNotes, ["todo.md"]))
[view.BufferName(here(opened)), here(opened).Cursor] --> ["notes.md", {Line: 4, Column: 0}]
noted = press.Press(["C-c", "n", "a", "call the bank", "enter"], tried(WithNotes, ["todo.md"]))
[noted.Message, view.BufferName(here(noted))] --> ["Noted.", "todo.md"]
rope.Text(noted.Buffers[2].Rope) --> "# My notes\n\n- Cemacs keeps user/ out of git\n- call the bank\n"
```

Plus : [commands.Home], [commands.OpenFile], [commands.Ask], [commands.Save], [text.ToFileEnd], [text.InsertWords],
[Modifier Cemacs](customising.md#une-app-à-vous).

## Toutes ensemble

Voici un `Changed` qui appelle chaque recette de cette page, tel que le contient `user/config/config.ce` une fois les
recettes copiées :

```cesia
defn Changed(config)
  (** Cemacs with every recipe of this page. *)
  WithNotes(AfterSave(Tools(NewBufferKey(TwoFiles(MySettings(config))))))
end
```

Chaque recette change ses propres champs : leur ordre ne compte donc que là où deux changent le même. Ici `NewBufferKey`,
`Tools` et `WithNotes` ajoutent chacune des touches à celles de la recette d'avant, et le dernier mot va à la plus
extérieure. L'éditeur que cela donne :

```cesia
all = tried(Changed, [])
[cemacs(Changed).FontSize(), panes.Count(panes.Tree(all)), view.BufferName(here(all))] --> [17, 2, "todo.md"]
textOf(press.Press(["C-c", "t", "d"], all)) == "$(rope.Line(1, here(all).Rope))\n$(textOf(all))" --> true
```

`Changed` tourne à chaque touche : un changement de sa part s'applique donc dès la suivante sous `cesia do dev` ;
`FontSize`, `Theme` et `Window` attendent le démarrage suivant, comme `Start`, et un nouveau package de `user/` demande un
redémarrage.
