# Modifier Cemacs

Cemacs se modifie en Cesia, comme Emacs se modifie en Emacs Lisp : ses réglages, ses touches et ses commandes sont des
fonctions de son propre code, et un changement peut se charger dans la fenêtre qui tourne. Ce chapitre dit où sont les
choses, comment changer un réglage ou une touche, comment écrire une commande, une liste et une app à vous, et les règles
qu'un changement doit suivre pour se recharger sans risque.

## Où sont les choses

| Dossier | Ce qu'il contient |
|---|---|
| `core/` | le core (le cœur de l'éditeur) : le buffer, les touches, la frame, les fichiers, les commandes, l'exécution d'un programme. Il ne lie aucune touche et ne connaît aucune app. |
| `src/emacs/` | les touches d'Emacs et les réglages |
| `src/buffers/`, `src/folders/`, `src/project/`, `src/check/`, `src/output/`, `src/help/` | les apps : la liste des buffers, le gestionnaire de dossiers, les fichiers d'un projet, la vérification, la sortie comme liste, les listes de `?` |
| `src/rope/`, `src/history/`, `src/sdl/`, `src/ui/` | la rope, l'historique d'annulation, la fenêtre par SDL3, le thème et les rectangles |
| `src/cemacs.ce` | le programme : il fusionne les touches de chaque app, fait la config, et ouvre la fenêtre |

`C-c f c` ouvre `src/cemacs.ce`, l'endroit par où commencer. Le voici, sans ses commentaires :

```cesia norun
use src/buffers
use src/check
use src/emacs
use core/editor
use src/folders
use src/help
use src/output
use src/project
use std/dict
use std/io

Keys() = help.WithHelp(dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()), project.Keys()), check.Keys()),
  output.Keys()))

Config() = check.Hooked(emacs.Config(Keys))

io.Print(editor.Start(Config))
```

[dict.Merge] donne le dernier mot aux touches de son second argument : pour une touche présente dans deux apps, c'est la
plus tardive qui gagne.

## Les réglages

Les réglages sont des fonctions de `src/emacs/emacs.ce`, chacune sans paramètre. Leurs valeurs aujourd'hui, lues dans le
code au moment où cette page a été construite :

```cesia
use src/emacs
[emacs.TabText(), emacs.WheelLines(), emacs.DragZone(), emacs.FontSize(), emacs.HintDelay(), emacs.CheckDelay()] --> ["  ", 3.0, 4, 15, 0.5, 0.5]
```

| Réglage | Unité | Ce qu'il dit | Lu |
|---|---|---|---|
| [emacs.TabText] | un texte | ce que tape Tab | à chaque Tab |
| [emacs.WheelLines] | des lignes, un float (un nombre à virgule) | les lignes dont un cran de la molette déplace l'écran ; un touchpad envoie des morceaux de cran | à chaque tour de molette |
| [emacs.DragZone] | des pixels | jusqu'où la souris peut aller depuis un appui, sur chaque axe, pour que cela reste un clic | à chaque déplacement de la souris |
| [emacs.FontSize] | des points | la taille des trois polices | une fois, quand la fenêtre s'ouvre |
| [emacs.HintDelay] | des secondes | l'attente après une prefix key avant que la bande des hints s'affiche | à chaque tick |
| [emacs.CheckDelay] | des secondes | le temps sans touche après lequel un buffer Cesia qui a changé est vérifié | à chaque tick |

Pour en changer un, changez sa fonction et enregistrez :

```cesia norun
(* in src/emacs/emacs.ce *)
TabText() = "    "
HintDelay() = 0.3
```

Avec `cesia do dev`, la nouvelle valeur marche tout de suite, puisque chacune est lue à son usage suivant ; `FontSize`
attend le démarrage suivant, puisque la fenêtre ne la lit qu'une fois. Avec `bin/cemacs`, chaque changement attend le
démarrage suivant.

Certaines valeurs ne sont pas des réglages mais des parties du code, et en changer une veut dire changer ce code :

| Valeur | Où |
|---|---|
| le thème, sombre | `ui.Dark` dans `core/editor/editor.ce` ; `src/ui` a aussi `ui.Light` |
| les polices | `fonts/`, ouvertes dans `core/editor/editor.ce` |
| la taille de la fenêtre au démarrage, 1280 sur 720 | `core/editor/editor.ce` |
| les 1 000 états de l'historique d'annulation | `src/history/history.ce`, le `limit` de `history.Of` |
| les 1 000 lignes gardées de la sortie | `kept` dans `core/run/run.ce` |
| le plus grand fichier ouvert, 1 GiB | `largest` dans `core/files/files.ce` |
| les couleurs des erreurs et des breakpoints | `core/view/view.ce` |

## La config

L'éditeur tourne sur une config, un record de fonctions (une map dont chaque champ est une fonction) que fait
`emacs.Config` et que `src/cemacs.ce` donne à la fenêtre :

| Champ | Ce qu'il donne |
|---|---|
| `Keys` | la keymap globale |
| `PromptKeys`, `PromptMouseKeys` | les touches et la souris pendant qu'une question est ouverte |
| `MouseKeys` | la souris, selon l'action de son événement |
| `ListKeys` | les touches de chaque liste, devant les touches globales |
| `CompleteKeys` | les touches de la liste des completions, devant les touches globales |
| `TabText`, `WheelLines`, `DragZone`, `FontSize`, `HintDelay`, `CheckDelay` | les réglages |
| `Idle`, `Saved`, `Moving` | les hooks, qu'ajoute [check.Hooked] : voir plus bas |

Chaque champ est une fonction, et la config elle-même aussi : l'état de l'éditeur contient la fonction `Config`, et
l'appelle chaque fois qu'il a besoin d'une touche ou d'un réglage. C'est ce qui fait qu'un changement s'applique dès la
touche suivante sous `--watch` : un rechargement donne un nouveau code à la fonction, et l'appel suivant l'exécute.

## Des touches à vous

Une key binding est une entrée d'une keymap : la key sequence sous forme de texte, et la fonction qu'elle lance. N'importe
quelle fonction qui va d'un état à un état fait l'affaire : une commande de [core/commands], une à vous, ou une écrite sur
place.

```cesia norun
(* in src/emacs/emacs.ce: three lines added at the top of Keys(), the others left as they are *)
Keys() = {
  "C-c t": "tools",
  "C-c t s": commands.Save,
  "C-c t h": s -> commands.Say("Hello", s)
}
```

- Une key sequence est ses chords avec une espace entre eux, autant que vous voulez : `"C-c t s"`.
- Un texte à la place d'une fonction nomme un groupe : `"C-c t": "tools"` fait de `C-c t` une prefix key, montrée comme
  `+tools` dans la bande des hints. Sans lui, la bande montre `+more`.
- `?` après le nouveau préfixe, `C-c t ?`, liste ses touches de lui-même, puisque `help.WithHelp` ajoute `?` après chaque
  prefix key.
- Une fonction écrite sur place n'a pas de nom : la bande et les listes de `?` la montrent donc comme `a function`.
  Donnez-lui un nom, avec un commentaire `(** *)`, pour qu'il soit montré.
- Pour enlever une touche, enlevez sa ligne.

Les key bindings de la souris prennent l'événement en plus de l'état : `"wheel": (event, s) -> ...`, comme dans
`MouseKeys`.

## Une commande à vous

Une commande prend l'état et donne le suivant. Rien n'y est spécial : l'état est une valeur, une map de champs, si bien
qu'une commande lit les champs dont elle a besoin et donne un état dont certains ont changé. Le buffer courant est
`state.Buffers[state.Current]`, et [core/text] a les fonctions qui se déplacent dans un buffer et le modifient, chacune d'un
buffer vers un buffer.

Voici une commande qui réécrit la ligne du curseur sous elle, en une seule étape d'annulation, essayée sur le vrai éditeur
avec [press.Press], comme les tests de Cemacs essaient les leurs :

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

Une app est un dossier de `src/` dont le package donne une fonction `Keys()`, les touches qui marchent partout :

```cesia norun
(* src/mine/mine.ce *)
(** My commands. *)
use core/commands

Keys() = {"C-c t": "tools", "C-c t d": DuplicateLine, "C-c t g": GoToLine, "C-c t o": Outline}   (** My keys. *)
```

Dans `src/cemacs.ce`, ajoutez `use src/mine`, et `mine.Keys()` aux touches que `Keys` fusionne. Un nouveau package demande
un redémarrage de Cemacs : un programme qui tourne ne peut pas charger un package qu'il n'a pas chargé à son démarrage, et
Cesia le dit, `A running program can't load a new module. Restart it to use this one.` (un programme qui tourne ne peut pas
charger un nouveau module ; redémarrez-le pour employer celui-ci). Après cela, chaque changement de l'app se recharge.

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

Keys() = mine()   (** In src/cemacs.ce, the keys it merges. *)
Config() = WithMine(check.Hooked(emacs.Config(Keys)))
value.IsFunction(Config().Idle) --> true
```

Ne demandez des ticks que tant qu'il y a quelque chose à attendre : un éditeur dont le `Moving` vaut false ne dessine rien
jusqu'à l'événement suivant, et dort jusqu'à ce qu'il arrive. Une fiber à vous ne tourne alors que toutes les
250 millisecondes, le plus long sommeil de l'éditeur : demandez des ticks tant qu'elle a du travail.

## Recharger Cemacs pendant qu'il tourne

`cesia do dev`, depuis le dossier de Cemacs, le lance sous `--watch` : à chaque enregistrement d'un de ses fichiers, Cesia
charge le nouveau code dans le programme qui tourne, sans fermer la fenêtre ni perdre les buffers. C'est un hot reload (un
rechargement à chaud), comme l'appelle le livre de Cesia.

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
3. **Un nouveau package demande un redémarrage**, comme plus haut.

Une erreur qui empêche le chargement, un nom qui n'existe pas ou une erreur de syntaxe, s'affiche dans le terminal qui fait
tourner `cesia do dev`, et l'ancien code reste. Une erreur qui se charge mais échoue quand elle tourne, comme une fonction liée
à une touche avec un mauvais nombre de paramètres, arrête le programme quand on presse la touche, et le texte non enregistré
est perdu : Cesia n'a aucun moyen de l'attraper. Enregistrez vos buffers avant d'essayer un changement sur l'éditeur dans
lequel vous l'écrivez.

`tests/reload-check.sh` prouve les règles dans une fenêtre : il change des touches et des réglages d'un Cemacs qui tourne,
comme une personne les enregistrerait, et vérifie chacun à la touche suivante.

## Tester un changement

`cesia test` lance les tests de chaque package, les exemples de ses commentaires `(** *)` et ses fonctions de test, comme le
dit le livre de Cesia dans son chapitre sur les tests ; `cesia test core/commands` lance ceux d'un seul package.
`cesia do test` lance toute la suite, les deux chemins de Cesia compris : voir [Installation](install.md#vérifier-linstallation).
[press.Press] joue des touches à travers l'éditeur sans fenêtre, comme le font les exemples ci-dessus.
