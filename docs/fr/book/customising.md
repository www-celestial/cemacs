# Modifier Cemacs

Cemacs se modifie en Cesia, comme Emacs se modifie en Emacs Lisp : ses réglages, ses touches et ses commandes sont des
fonctions de son propre code, et un changement peut se charger dans la fenêtre qui tourne. Vos changements vont dans un
dossier à vous, `user/`, que `git pull` ne touche jamais. Ce chapitre dit où est ce dossier et ce qu'il contient, comment
changer un réglage ou une touche, comment écrire une commande, une liste et une app à vous, et les règles qu'un changement
doit suivre pour se recharger sans risque. [Recettes](recipes.md) fait ainsi de petites tâches, chacune avec son code.

## Votre dossier, user/

`user/` est dans le dossier de Cemacs, à côté de `core/` et de `src/`, et il est à vous : Cemacs le crée une fois et n'y
écrit plus jamais. La première fois que `bin/cemacs` ou `cesia do dev` démarre sans trouver de `user/`, il y copie le
template (le modèle) de Cemacs, `tools/user-template/`, par `tools/user.sh` ; quand `user/` est là, même sous forme de lien
symbolique, rien n'est copié. `.gitignore`, la liste des noms que git laisse de côté, contient `/user/` : git ne voit pas le
dossier, `git status` ne le montre pas, et `git pull` apporte le nouveau code de Cemacs sans y toucher, là où un changement
de votre part dans `src/emacs/emacs.ce` devrait être fusionné avec ceux de Cemacs à chaque `git pull`. Pour garder
l'historique de vos changements, faites de `user/` un dépôt git à lui : voir [Installation](install.md#votre-dossier-user).

```text
cemacs/
  user/              yours: git ignores it
    config/
      config.ce      your settings, your keys and your start
    notes/
      notes.ce       an app of your own, as Recipes makes one
```

`user/config/config.ce` est votre init file (le fichier de code qu'un éditeur exécute à son démarrage pour appliquer vos
changements), comme `~/.emacs.d/init.el` l'est pour Emacs et `~/.config/nvim/init.lua` pour Neovim. `C-c f c` l'ouvre. Tel
que le template le crée, il ne change rien :

```cesia
(** Your changes to Cemacs: its settings, its keys and what it does at the start. Cemacs made this folder, user/, from tools/user-template the first time it
    started, and never writes to it again; git ignores it, so git pull leaves it as it is. C-c f c opens this file.
    src/cemacs.ce gives Changed the config that Cemacs makes, and runs on what it gives. Under cesia do dev, a change here works at the next key, but FontSize,
    Theme and Window, which the window reads when it opens, wait for the next start. An app of your own is a folder beside this one, as user/notes/ for
    use user/notes: use it here and merge its keys; a new package needs a restart. cesia test user runs the tests of this folder. *)
use core/commands
use src/ui
use std/dict

defn Changed(config)
  (** Cemacs with your changes. Each field of config is a function: set only those you change, so that a field Cemacs adds later still comes through. To try
      an example, take away the (* and *) around it, and save. *)
  c = config
  (* c.FontSize = () -> 17 *)
  (* c.TabText = () -> "    " *)
  (* c.Theme = () -> ui.Light *)
  (* c.Window = () -> {Width: 1600, Height: 900} *)
  (* c.Keys = () -> dict.Merge(config.Keys(), {"C-c t": "tools", "C-c t s": commands.Save}) *)
  (* c.Start = s -> commands.SplitRight(s) *)
  c
end
```

```cesia
use src/emacs
use std/value
value.Equal(Changed(emacs.Config(emacs.Keys)), emacs.Config(emacs.Keys)) --> true
```

`Changed` reçoit la config, le record de fonctions sur lequel tourne l'éditeur, et la rend changée :
[La config](#la-config) liste ses champs. `c = config` puis `c.FontSize = ...` font un nouveau record, celui reçu restant
tel qu'il était ; chaque `(* *)` est un commentaire, que Cesia saute. Un champ que `Changed` ne pose pas garde la valeur de
Cemacs : un réglage qu'une version plus récente de Cemacs ajoute passe donc. `src/cemacs.ce` appelle `Changed` chaque fois
que l'éditeur lit sa config, à chaque touche : sous `cesia do dev`, un changement que vous enregistrez marche donc dès la
touche suivante, sauf pour `FontSize`, `Theme`, `Window` et `Start`, lus seulement au démarrage : voir
[Recharger Cemacs pendant qu'il tourne](#recharger-cemacs-pendant-quil-tourne).

Une erreur dans `config.ce` qui l'empêche de se charger, comme un nom qui n'existe pas, arrête Cemacs à son démarrage, avec
l'endroit de l'erreur dans le terminal : corrigez-la avec un autre éditeur, ou déplacez `user/` ailleurs, et Cemacs en crée
un nouveau à partir du template au démarrage suivant. [Dépannage](troubleshooting.md#au-démarrage) liste ce que montre le
terminal.

## Où sont les choses

| Dossier | Ce qu'il contient |
|---|---|
| `core/` | le core (le cœur de l'éditeur) : le buffer, les touches, la frame, les fichiers, les commandes, l'exécution d'un programme. Il ne lie aucune touche et ne connaît aucune app. |
| `src/emacs/` | les touches d'Emacs et les réglages |
| `src/buffers/`, `src/folders/`, `src/project/`, `src/check/`, `src/output/`, `src/help/` | les apps : la liste des buffers, le gestionnaire de dossiers, les fichiers d'un projet, la vérification, la sortie comme liste, les listes de `?` |
| `src/rope/`, `src/history/`, `src/sdl/`, `src/ui/` | la rope, l'historique d'annulation, la fenêtre par SDL3, le thème et les rectangles |
| `src/cemacs.ce` | le programme : il fusionne les touches de chaque app, fait la config, la donne à votre `Changed`, et ouvre la fenêtre |
| `tools/user-template/` | le template à partir duquel `user/` est créé |
| `user/` | à vous : votre config, `user/config/config.ce`, et vos apps |

Voici `src/cemacs.ce`, sans ses commentaires :

```cesia norun
use src/buffers
use src/check
use src/emacs
use core/editor
use src/folders
use src/help
use src/output
use src/project
use user/config as user
use std/dict
use std/io

Keys() = dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()), project.Keys()), check.Keys()), output.Keys())

defn Config()
  c = user.Changed(check.Hooked(emacs.Config(Keys)))
  keys = c.Keys
  c.Keys = () -> help.WithHelp(keys())
  c
end

io.Print(editor.Start(Config))
```

[dict.Merge] donne le dernier mot aux touches de son second argument : pour une touche présente dans deux apps, c'est la
plus tardive qui gagne. `use user/config as user` charge votre config, comme le package nommé ici `user`, et `Config`
donne à son `Changed` la config de Cemacs : les touches des apps, les réglages et les touches de [src/emacs] et les hooks
de [check.Hooked]. Après votre `Changed`, [help.WithHelp] ajoute `?` après chaque prefix key des touches qu'il a rendues,
les vôtres comprises, ce qui liste les touches qui la suivent.

Cesia s'arrête quand un dossier que `cesia.toml` nomme parmi ceux du code manque, et `cesia.toml` nomme `user`. Dans un
clone où Cemacs n'a jamais démarré, `cesia test`, `cesia check` et `cesia doc` disent donc
`cesia.toml:4:1: The source folder "user" doesn't exist.` (le dossier de code « user » n'existe pas) jusqu'à ce qu'un
démarrage, ou `tools/user.sh`, le crée. `cesia do test` le crée d'abord.

## Les réglages

Les réglages de Cemacs sont des fonctions de `src/emacs/emacs.ce`, chacune sans paramètre, sauf `Start`, qui prend un état.
Leurs valeurs aujourd'hui, lues dans le code au moment où cette page a été construite :

```cesia
use src/emacs
use src/ui
use std/value
[emacs.TabText(), emacs.WheelLines(), emacs.DragZone(), emacs.FontSize(), emacs.HintDelay(), emacs.CheckDelay()] --> ["  ", 3.0, 4, 15, 0.5, 0.5]
[value.Equal(emacs.Theme(), ui.Dark), emacs.Window()] --> [true, {Width: 1280, Height: 720}]
```

| Réglage | Unité | Ce qu'il dit | Lu |
|---|---|---|---|
| [emacs.TabText] | un texte | ce que tape Tab | à chaque Tab |
| [emacs.WheelLines] | des lignes, un float (un nombre à virgule) | les lignes dont un cran de la molette déplace l'écran ; un touchpad envoie des morceaux de cran | à chaque tour de molette |
| [emacs.DragZone] | des pixels | jusqu'où la souris peut aller depuis un appui, sur chaque axe, pour que cela reste un clic | à chaque déplacement de la souris |
| [emacs.FontSize] | des points | la taille des trois polices | une fois, quand la fenêtre s'ouvre |
| [emacs.HintDelay] | des secondes | l'attente après une prefix key avant que la bande des hints s'affiche | à chaque tick |
| [emacs.CheckDelay] | des secondes | le temps sans touche après lequel un buffer Cesia qui a changé est vérifié | à chaque tick |
| [emacs.Theme] | un record de couleurs | le thème : [ui.Dark], ou [ui.Light], ou un thème à vous avec les mêmes champs | une fois, quand la fenêtre s'ouvre |
| [emacs.Window] | des pixels, `{Width, Height}` | la taille de la fenêtre quand elle s'ouvre, que vous pouvez changer ensuite | une fois, quand la fenêtre s'ouvre |
| [emacs.Start] | une fonction d'un état vers un état | ce que fait l'éditeur à son démarrage, après avoir ouvert les fichiers qu'on lui a donnés : rien | une fois, après l'ouverture des fichiers |

Pour en changer un, posez son champ dans votre `Changed`, sous forme de fonction : le template a un exemple de chacun, et
une fonction d'une config vers une config peut rassembler les vôtres, comme le fait chaque recette de [Recettes](recipes.md) :

```cesia
use src/check

defn MySettings(config)
  (** A tab of four spaces, and the band of hints sooner. *)
  c = config
  c.TabText = () -> "    "
  c.HintDelay = () -> 0.3
  c
end

[MySettings(check.Hooked(emacs.Config(emacs.Keys))).TabText(), MySettings(check.Hooked(emacs.Config(emacs.Keys))).HintDelay()] --> ["    ", 0.3]
```

`Changed` rend alors `MySettings(config)`. Avec `cesia do dev`, la nouvelle valeur marche à son usage suivant ; `FontSize`,
`Theme` et `Window` attendent le démarrage suivant, puisque la fenêtre ne les lit qu'une fois, et `Start` ne tourne qu'au
démarrage. Avec `bin/cemacs`, chaque changement attend le démarrage suivant. Une config faite sans `Theme`, `Window` ni
`Start`, comme peut en faire un programme qui appelle [editor.Start] lui-même, reçoit le thème sombre, 1280 sur 720 et rien.

Changer une fonction de `src/emacs/emacs.ce` lui-même marche aussi, comme avant que `user/` existe, mais `git pull` doit
alors fusionner votre changement avec ceux de Cemacs.

Certaines valeurs ne sont pas des réglages mais des parties du code, et en changer une veut dire changer ce code :

| Valeur | Où |
|---|---|
| les polices | `fonts/`, ouvertes dans `core/editor/editor.ce` |
| les 1 000 états de l'historique d'annulation | `src/history/history.ce`, le `limit` de `history.Of` |
| les 1 000 lignes gardées de la sortie | `kept` dans `core/run/run.ce` |
| le plus grand fichier ouvert, 1 GiB | `largest` dans `core/files/files.ce` |
| les couleurs des erreurs et des breakpoints | `core/view/view.ce` |

## La config

L'éditeur tourne sur une config, un record de fonctions (une map dont chaque champ est une fonction) que fait
[emacs.Config], auquel [check.Hooked] ajoute les hooks, que votre `Changed` change, et que `src/cemacs.ce` donne à la
fenêtre :

| Champ | Ce qu'il donne |
|---|---|
| `Keys` | la keymap globale |
| `PromptKeys`, `PromptMouseKeys` | les touches et la souris pendant qu'une question est ouverte |
| `MouseKeys` | la souris, selon l'action de son événement |
| `ListKeys` | les touches de chaque liste, devant les touches globales |
| `CompleteKeys` | les touches de la liste des completions, devant les touches globales |
| `TabText`, `WheelLines`, `DragZone`, `FontSize`, `HintDelay`, `CheckDelay`, `Theme`, `Window` | les réglages |
| `Start` | ce que fait l'éditeur une fois, à son démarrage |
| `Idle`, `Saved`, `Moving` | les hooks, qu'ajoute [check.Hooked] : voir plus bas |

Chaque champ est une fonction, et la config elle-même aussi : l'état de l'éditeur contient la fonction `Config`, et
l'appelle chaque fois qu'il a besoin d'une touche ou d'un réglage, deux ou trois fois pour une touche. C'est ce qui fait
qu'un changement s'applique dès la touche suivante sous `--watch` : un rechargement donne un nouveau code à la fonction, et
l'appel suivant l'exécute. Votre `Changed` tourne à chacun de ces appels : qu'il se contente donc de poser des champs ;
celui du template coûte moins d'une microseconde, et [Vitesse](performance.md#le-démarrage) a les chiffres.

## Des touches à vous

Une key binding est une entrée d'une keymap : la key sequence sous forme de texte, et la fonction qu'elle lance. N'importe
quelle fonction qui va d'un état à un état fait l'affaire : une commande de [core/commands], une à vous, ou une écrite sur
place. Dans votre `Changed`, les nouvelles touches sont celles de la config avec les vôtres fusionnées par-dessus :

```cesia
use core/commands
use std/dict

defn MyKeys(config)
  (** A group of my own, tools, under C-c t. *)
  c = config
  c.Keys = () -> dict.Merge(config.Keys(), {"C-c t": "tools", "C-c t s": commands.Save, "C-c t h": s -> commands.Say("Hello", s)})
  c
end

value.Len(dict.Keys(MyKeys(emacs.Config(emacs.Keys)).Keys())) - value.Len(dict.Keys(emacs.Keys())) --> 3
```

- Une key sequence est ses chords avec une espace entre eux, autant que vous voulez : `"C-c t s"`.
- Un texte à la place d'une fonction nomme un groupe : `"C-c t": "tools"` fait de `C-c t` une prefix key, montrée comme
  `+tools` dans la bande des hints. Sans lui, la bande montre `+more`.
- `?` après le nouveau préfixe, `C-c t ?`, liste ses touches de lui-même, puisque `src/cemacs.ce` passe les touches que
  rend votre `Changed` à [help.WithHelp], qui ajoute `?` après chaque prefix key.
- Une fonction écrite sur place n'a pas de nom : la bande la montre donc comme `a function`, et les listes de `?` comme
  `(a function)`. Donnez-lui un nom, avec un commentaire `(** *)`, pour qu'il soit montré.
- Pour enlever une touche de Cemacs, retirez-la des touches : `c.Keys = () -> dict.Drop("C-x C-c", config.Keys())`.

Les key bindings de la souris prennent l'événement en plus de l'état : `"wheel": (event, s) -> ...`, comme dans
`MouseKeys`.

## Une commande à vous

Une commande prend l'état et donne le suivant. Rien n'y est spécial : l'état est une valeur, une map de champs, si bien
qu'une commande lit les champs dont elle a besoin et donne un état dont certains ont changé. Le buffer courant est
`state.Buffers[state.Current]`, et [core/text] a les fonctions qui se déplacent dans un buffer et le modifient, chacune d'un
buffer vers un buffer.

Une commande à vous va dans `user/config/config.ce`, ou dans une app à vous, et une touche de votre `Changed` la lie. En
voici une qui réécrit la ligne du curseur sous elle, en une seule étape d'annulation, essayée sur le vrai éditeur avec
[press.Press], comme les tests de Cemacs essaient les leurs :

```cesia
use core/commands
use core/press
use core/text
use core/view
use src/rope
use src/ui
use std/dict
use std/value

defn DuplicateLine(state)
  (** The line of the cursor written again below it, the cursor on the copy. *)
  b = state.Buffers[state.Current]
  words = rope.Line(b.Cursor.Line, b.Rope)
  s = state
  s.Buffers[state.Current] = text.InsertWords("\n$words", text.ToLineEnd(b))
  s
end

(** The keys of Emacs, with a group of our own. *)
mine() = dict.Merge(emacs.Keys(), {"C-c t": "tools", "C-c t d": DuplicateLine})

defn tried(words)
  (** The editor on these keys, with one buffer holding words and no window. *)
  s = view.Start([text.Of(words, missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
  s.Config = () -> emacs.Config(mine)
  s
end

textOf(state) = rope.Text(state.Buffers[state.Current].Rope)   (** The text of the current buffer. *)

textOf(press.Press(["C-c", "t", "d"], tried("hello"))) --> "hello\nhello"
textOf(press.Press(["C-c", "t", "d", "C-/"], tried("hello"))) --> "hello"
```

[commands.Say] met un message sur la prompt line, et [commands.Ask] y pose une question : son troisième argument reçoit la
réponse et l'état, une fois la question fermée. Une commande qui va à une ligne :

```cesia
use std/text as str

GoToLine(state) = commands.Ask("Go to line: ", "", wentTo, state)   (** Asks for a line, and puts the cursor at its start. *)

defn wentTo(answer, state)
  (** The cursor at the start of the line answered, or a message if the answer is no number. *)
  n = str.Number(answer)
  if not value.IsInt(n)
    return commands.Say("$answer is no line number.", state)
  end
  s = state
  s.Buffers[s.Current] = text.Place(n, 0, s.Buffers[s.Current])
  s
end

asked = dict.Put("C-c t g", GoToLine, mine())
s = view.Start([text.Of("a\nb\nc", missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
s.Config = () -> emacs.Config(() -> asked)
press.Press(["C-c", "t", "g", "3", "enter"], s).Buffers[1].Cursor --> {Line: 3, Column: 0}
press.Press(["C-c", "t", "g", "x", "enter"], s).Message --> "x is no line number."
```

[text.Place] ramène à l'intérieur du texte une ligne au-delà de la fin : `99` va donc à la dernière ligne.
[commands.Confirm] pose de la même façon une question à laquelle on répond `y` ou `n`.

Les briques de [core/commands] pour une app sont : [commands.Say], [commands.Ask], [commands.Confirm],
[commands.OpenFile], [commands.ShowList], [commands.ToBuffer], [commands.AddToFilter], [commands.Clipboard],
[commands.Bindings], [commands.Chords], [commands.Home] et [commands.Still] ; chaque commande des tables de
[Touches](keys.md) peut aussi être appelée.

## Une liste à vous

Une liste montre des rangées, et lance des touches sur la rangée sous le curseur. [commands.ShowList] en ouvre une : un nom,
les rangées, chacune `{Words, Item}` où `Item` est ce que la rangée représente, et une fonction qui donne les touches de la
liste, dont les commandes prennent l'item et l'état. Voici le plan d'un fichier, les lignes qui commencent une fonction, où
Enter va à l'une d'elles ; Emacs a `imenu` pour cela :

```cesia
use core/lists

defn Outline(state)
  (** Lists the lines that start a function, and Enter goes to the one under the cursor. *)
  b = state.Buffers[state.Current]
  rows = [{Words: "$n  $(rope.Line(n, b.Rope))", Item: n} for n in 1..rope.LineCount(b.Rope) if str.StartsWith("defn ", rope.Line(n, b.Rope))]
  commands.ShowList("Outline", rows, () -> {"enter": jumped}, state)
end

defn jumped(n, state)
  (** Back to the buffer the list was opened from, the cursor on line n. *)
  s = commands.ToBuffer(lists.Of(state.Buffers[state.Current]).Back, state)
  s.Buffers[s.Current] = text.Place(n, 0, s.Buffers[s.Current])
  s
end

listed = dict.Put("C-c t o", Outline, mine())
code = view.Start([text.Of("defn a()\n  1\nend\ndefn b()\n  2\nend", "f.ce")], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
code.Config = () -> emacs.Config(() -> listed)
textOf(press.Press(["C-c", "t", "o"], code)) --> "1  defn a()\n4  defn b()"
press.Press(["C-c", "t", "o", "b", "enter"], code).Buffers[1].Cursor --> {Line: 4, Column: 0}
```

Taper `b` a filtré la liste jusqu'à la deuxième rangée, et Enter y est allé, en fermant la liste. Les rangées peuvent aussi
être une fonction de l'état, que la liste appelle à chaque événement, pour des rangées qui changent, comme le fait la liste
des buffers ; `ShowList` prend trois arguments de plus par leur nom : `free`, des touches qui n'ont pas besoin de rangée,
`label`, les mots avant le filtre, et `typed`, une fonction qui reçoit chaque texte tapé à la place du filtre, comme le
gestionnaire de dossiers les emploie.

## Une app à vous

Une app est un package, un dossier de fichiers Cesia, qui donne une fonction `Keys()`, les touches qui marchent partout. La
vôtre est un dossier de `user/`, comme `user/mine/` :

```cesia norun
(* user/mine/mine.ce *)
(** My commands. *)
use core/commands

Keys() = {"C-c t": "tools", "C-c t d": DuplicateLine, "C-c t g": GoToLine, "C-c t o": Outline}   (** My keys. *)
```

Dans `user/config/config.ce`, `use user/mine` en haut la charge, comme le package `mine`, et `Changed` fusionne ses
touches :

```text
use user/mine

defn Changed(config)
  c = config
  c.Keys = () -> dict.Merge(config.Keys(), mine.Keys())
  c
end
```

Ces lignes ne peuvent pas tourner sur cette page, qui n'a pas de package `user/mine` :
[Recettes](recipes.md#votre-première-app-dans-usernotes) fait tourner une app entière, avec quelque chose qui tient la place de
son package. Un nouveau package demande un redémarrage de Cemacs : un programme qui tourne ne peut pas charger un package
qu'il n'a pas chargé à son démarrage, et Cesia le dit, `A running program can't load a new module. Restart it to use this
one.` (un programme qui tourne ne peut pas charger un nouveau module ; redémarrez-le pour employer celui-ci). Après cela,
chaque changement de l'app se recharge. Les apps de Cemacs lui-même sont des dossiers de `src/`, que `src/cemacs.ce`
fusionne de la même façon dans `Keys`.

### Les hooks

Une app qui a besoin d'apprendre que le temps passe, ou que des enregistrements ont lieu, comme la vérification, passe par
les hooks de la config (des fonctions que le core appelle à des moments donnés) :

| Hook | Quand le core l'appelle |
|---|---|
| `Idle(state)` | à chaque tick, l'événement qui compte le temps, avec [commands.Still] qui donne les secondes depuis la dernière touche |
| `Saved(state)` | après chaque enregistrement |
| `Moving(state)` | à chaque tour de la boucle : true demande des ticks, et une frame à chacun |

[check.Hooked] pose les trois. Une config sans eux a des hooks qui ne font rien. Pour ajouter les vôtres à côté de ceux de la
vérification, enveloppez-les, pour que les deux tournent :

```cesia
use src/check

myIdle(s) = s   (** What my app does at each tick: here, nothing. *)

defn WithMine(config)
  (** The config with my Idle after the one already there. *)
  c = config
  before = config.Idle
  c.Idle = s -> myIdle(before(s))
  c
end

value.IsFunction(WithMine(check.Hooked(emacs.Config(mine))).Idle) --> true
```

`Changed` rend alors `WithMine(config)` : la config qu'il reçoit a déjà les hooks de la vérification, que `before` garde.
[Recettes](recipes.md#quelque-chose-après-chaque-enregistrement) enveloppe `Saved` de la même façon.

Ne demandez des ticks que tant qu'il y a quelque chose à attendre : un éditeur dont le `Moving` vaut false ne dessine rien
jusqu'à l'événement suivant, et dort jusqu'à ce qu'il arrive. Une fiber à vous ne tourne alors que toutes les
250 millisecondes, le plus long sommeil de l'éditeur : demandez des ticks tant qu'elle a du travail.

## Recharger Cemacs pendant qu'il tourne

`cesia do dev`, depuis le dossier de Cemacs, le lance sous `--watch` : à chaque enregistrement d'un de ses fichiers, ceux de
`user/` compris, Cesia charge le nouveau code dans le programme qui tourne, sans fermer la fenêtre ni perdre les buffers.
C'est un hot reload (un rechargement à chaud), comme l'appelle le livre de Cesia. Il passe par `tools/dev.sh`, qui crée
d'abord `user/` s'il manque, comme le fait `bin/cemacs`.

Un rechargement change les fonctions, et n'exécute rien de nouveau au niveau du fichier. Un changement doit donc suivre trois
règles, que le code de Cemacs respecte partout :

1. **Les valeurs sont des fonctions.** `Keys() = {...}` et `TabText() = "  "` donnent ce que dit le code à chaque appel.
   Une variable au niveau du fichier, `Keys = {...}`, garderait son ancienne valeur jusqu'à un redémarrage ; et une
   nouvelle, ajoutée par un rechargement, serait lue avant d'avoir une valeur, ce qui arrête le programme, avec son texte
   non enregistré.
2. **Un champ ajouté à l'état se lit par un `match` avec une valeur par défaut.** L'état survit à un rechargement : il
   peut donc venir d'un code qui n'avait pas encore ce champ, et lire un champ qu'une map n'a pas arrête le programme. Le
   code de Cemacs lit ainsi chaque champ ajouté plus tard, comme le fait [commands.Still] :

   ```cesia norun
   defn Still(state)
     match state
       {Still: seconds} -> seconds
       else -> 0.0
     end
   end
   ```

   Écrire un champ l'ajoute : seule la lecture demande ce soin.
3. **Un nouveau package demande un redémarrage**, comme plus haut, un package de `user/` aussi.

Ce que la fenêtre lit une seule fois attend le démarrage suivant, quel que soit le rechargement : `FontSize`, `Theme` et
`Window` ; et `Start` ne tourne qu'au démarrage.

Une erreur qui empêche le chargement, un nom qui n'existe pas ou une erreur de syntaxe, s'affiche dans le terminal qui fait
tourner `cesia do dev`, et l'ancien code reste. Une erreur qui se charge mais échoue quand elle tourne, comme une fonction liée
à une touche avec un mauvais nombre de paramètres, arrête le programme quand on presse la touche, et le texte non enregistré
est perdu : Cesia n'a aucun moyen de l'attraper. Enregistrez vos buffers avant d'essayer un changement sur l'éditeur dans
lequel vous l'écrivez.

`tests/reload-check.sh` prouve les règles dans une fenêtre : il change des touches et des réglages d'un Cemacs qui tourne,
dans `src/emacs/emacs.ce` puis dans `user/config/config.ce`, comme une personne les enregistrerait, et vérifie chacun à la
touche suivante.

## Tester un changement

`cesia test` lance les tests d'un dossier, les exemples des commentaires `(** *)` de ses packages et leurs fonctions de
test, comme le dit le livre de Cesia dans son chapitre sur les tests : `cesia test core/commands` lance ceux d'un seul
package, et `cesia test user` ceux de votre dossier, les fichiers de test de vos apps, `user/mine/mine.test.ce` à côté de
`user/mine/mine.ce`. `cesia do test` lance toute la suite de Cemacs, les deux chemins de Cesia compris, sur `core/` et
`src/` seulement, pour qu'une app à vous en cours d'écriture ne la fasse jamais échouer : voir
[Installation](install.md#vérifier-linstallation). [press.Press] joue des touches à travers l'éditeur sans fenêtre, comme le
font les exemples ci-dessus.
