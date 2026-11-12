# Touches

Ce chapitre liste chaque touche de Cemacs, et dit comment une touche que vous pressez devient une commande. Les tables
ci-dessous ne sont pas écrites à la main : la page lit les keymaps dans le code de Cemacs chaque fois que le site est
construit, si bien qu'elles ne peuvent pas être périmées.

## Les mots

- Une key binding (une liaison de touche) relie une touche à ce qu'elle lance. Dans Cemacs, c'est une entrée d'un
  dictionnaire dont la clé est un texte, comme `"C-x C-s"`, et dont la valeur est la fonction elle-même, comme
  [commands.Save].
- Une keymap (une table de touches) est un ensemble de key bindings. Cemacs en a quelques-unes, listées ci-dessous : la
  keymap globale, celles d'une question, d'une liste et de la souris.
- Une commande est ce qu'une touche lance : n'importe quelle fonction qui va de l'état de l'éditeur à un nouvel état. Emacs
  demande qu'une commande soit marquée interactive ; Cemacs ne demande rien, si bien que toute fonction de cette forme peut
  être liée, même une fonction écrite sur place.
- Un chord (un accord) est une touche avec les modifiers (les touches Control, Alt ou Shift) tenus en même temps qu'elle,
  écrit comme `C-x`, `M-<` ou `S-right`. Une key sequence est un ou plusieurs chords, écrits avec une espace entre eux :
  `C-x C-s`, `C-c f f`.
- Une prefix key est une key sequence par laquelle commence une key binding plus longue, comme `C-x` ou `C-c f` : seule,
  elle ne lance rien, et elle attend la touche suivante. Un groupe est une prefix key dont la key binding est un texte, son
  nom : `"C-c f": "files"`.

## La keymap globale

Ces touches marchent dans chaque buffer de texte. Elles viennent de `src/emacs/emacs.ce` et des apps que `src/cemacs.ce`
fusionne avec elles, avec `?` après chaque prefix key : le code ci-dessous fait la même fusion, et la table à partir d'elle.
Vos propres touches, que le `Changed` de `user/config/config.ce` fusionne par-dessus celles-ci, n'y sont pas : la table vient
du code de Cemacs, et `user/` est à vous.

```cesia output=md fold=code
use src/buffers
use src/check
use src/emacs
use src/folders
use src/help
use src/ide
use src/notebook
use src/output
use src/project
use std/cesia
use std/dict
use std/io
use std/list
use std/text as str
use std/value

(* The keys as src/cemacs.ce merges them: that file opens the window when it loads, so the page makes the same merge. *)
all = help.WithHelp(dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()),
  project.Keys()), check.Keys()), output.Keys()), notebook.Keys()), ide.Keys()))

defn about(f)
  (** The name of a command as the reference writes it, as a link, and the first sentence of its text. *)
  doc = cesia.Doc(f)
  name = str.Split("(", str.Split("\n", doc)[1])[1]
  body = str.Replace("\n", " ", str.Split("\n\n", doc)[2])
  first = str.Split(". ", body)[1]
  "[$name] | $(if str.EndsWith(".", first) first else "$first." end)"
end

defn row(k, bindings)
  (** The row of the table for the key k. *)
  v = bindings[k]
  if value.IsText(v) "| `$k` | the group $v | waits for one of the keys below it |" else "| `$k` | $(about(v)) |" end
end

(* The rows in order: the keys of one chord first, then each prefix key with what follows it. *)
chords(k) = value.Len(str.Split(" ", k))
first(k) = str.Split(" ", k)[1]
defn table(bindings)
  sorted = list.Sort(dict.Keys(bindings))
  ones = [k for k in sorted if chords(k) == 1 and not value.IsText(bindings[k])]
  more = [k for k in sorted if chords(k) > 1 or value.IsText(bindings[k])]
  io.Print("| Key | Command | What it does |")
  io.Print("|---|---|---|")
  for k in list.Concat(ones, more)
    io.Print(row(k, bindings))
  end
end

table(all)
```

Cela fait ce nombre de touches, groupes compris :

```cesia
value.Len(dict.Keys(all)) -->
```

Une commande liée à deux touches, comme `C-x C-f` et `C-c f f`, est la même fonction : la seconde touche n'est pas une copie
de la première. Sous `C-c`, la lettre de chaque groupe est la première lettre de son nom, comme dans Doom Emacs : `f` files
(fichiers), `b` buffers, `w` windows (fenêtres), `c` code, `d` debug (débogage), `e` execute (exécuter), les [cellules](cells.md), `t` test, les [tests](running.md#les-tests), `g` [git](git.md), `q` quit
(quitter).

## Une question sur la prompt line

Pendant qu'une question est ouverte, comme `Find file: `, ces touches marchent, les lettres vont dans la réponse, et toute
autre touche ne fait rien. Une question n'a pas de key sequences.

```cesia output=md fold=code
table(emacs.PromptKeys())
```

## Une liste

Dans une liste, ces touches passent devant les touches globales, et les touches propres à la liste passent devant elles :
Enter dans chaque liste, et les touches du gestionnaire de dossiers, `C-c n`, `C-c r`, `C-c k`, `C-c .`, `C-y` et
Backspace, que décrit [Fichiers et buffers](files.md#le-gestionnaire-de-dossiers).

```cesia output=md fold=code
table(emacs.ListKeys())
```

Quand deux keymaps lient une même touche, celle qui vient en premier ici gagne : dans une liste, les touches de la liste,
puis celles qui n'ont pas besoin de rangée, puis [emacs.ListKeys], puis les touches globales. Dans une liste, la bande des
hints montre aussi les touches de la liste, celles du gestionnaire de dossiers sous le nom `a function`, puisqu'elles sont
écrites sur place dans son code ; les listes de `?` ne montrent que les touches globales.

## La liste des completions

Pendant que la liste des completions qu'ouvre Tab dans un fichier de Cesia est sous le curseur, ces touches passent devant
les touches globales ; une lettre tapée refait la liste pour le mot plus long, et toute autre touche ferme la liste et fait
ce qu'elle fait. [Édition](editing.md#la-completion) dit comment.

```cesia output=md fold=code
table(emacs.CompleteKeys())
```

## La souris

La souris a aussi ses keymaps, selon l'action de son événement : `down` (appui), `move` (déplacement), `up` (relâchement) et
`wheel` (molette). Leurs commandes prennent l'événement en plus de l'état. Pendant qu'une question est ouverte, seuls `up` et
`wheel` marchent.

```cesia output=md fold=code
table(emacs.MouseKeys())
```

## Comment une touche devient un chord

La fenêtre donne à Cemacs deux sortes d'événements pour le clavier : un événement de touche pour chaque touche pressée, avec
le nom de la touche et les modifiers tenus, et un événement de texte pour le texte qu'une touche tape. [keys.Chord] fait d'un
événement de touche un chord, ou rien quand la touche ne fait que taper :

- Les modifiers viennent d'abord, toujours dans l'ordre `C-` (Control), `M-` (Alt), `S-` (Shift) : `C-M-S-x`.
- Une touche qui a un nom s'écrit par ce nom : `enter`, `tab`, `backspace`, `delete`, `escape`, `space`, `home`, `end`,
  `pageup`, `pagedown`, `left`, `right`, `up`, `down`, et `f1` à `f12`. Toute autre touche est son caractère, en minuscule.
- Une touche qui tape, un caractère ou la barre d'espace sans Control ni Alt, avec Shift ou non, n'est pas un chord : son
  événement de texte la tape, pour que `A`, `é` et les caractères d'une input method arrivent comme il faut.
- Shift ne s'écrit pas pour `<`, `>`, `?` et `_`, qui le contiennent déjà : une touche qui annonce `<` avec Alt est `M-<`. Un
  clavier où la touche annonce plutôt `,` et Shift donne `M-S-,`, et Cemacs lie les deux à la même commande.
- Une touche avec Super, la touche au logo du système, est laissée au système : pas de chord.

```cesia
use core/keys
keys.Chord({Key: "s", Ctrl: true, Alt: false, Shift: false, Super: false}) --> "C-s"
keys.Chord({Key: "right", Ctrl: false, Alt: false, Shift: true, Super: false}) --> "S-right"
keys.Chord({Key: "a", Ctrl: false, Alt: false, Shift: true, Super: false}) --> missing
```

Certains systèmes envoient aussi un événement de texte après un chord avec Control ou Alt, la même lettre à nouveau ; Cemacs
ignore ce texte, si bien que `C-a` ne tape jamais un `a`.

`escape` est une touche qui a un nom, et rien ne lui est lié. Dans Emacs, Escape suivi d'une touche est la même chose que
Meta avec elle ; dans Cemacs, non : employez Alt.

## Comment une key sequence est lue

[keys.Lookup] lit chaque chord après les prefix keys qui attendent avant lui, et donne l'une de trois réponses :

```cesia
use std/text as str
keys.Lookup("C-x", "C-s", {"C-x C-s": str.Lower}) --> {Command: str.Lower}
keys.Lookup("C-c", "f", {"C-c f": "files", "C-c f f": str.Lower}) --> {Pending: "C-c f"}
keys.Lookup("", "C-t", {"C-x C-s": str.Lower}) --> {Unknown: "C-t"}
```

- `Command` : les touches tapées jusque-là sont liées à une fonction, qui est lancée.
- `Pending` : une key binding continue après elles : elles attendent donc la touche suivante. La prompt line les montre avec
  un tiret, comme `C-c f -`, et la bande des hints s'ouvre après [emacs.HintDelay] secondes.
- `Unknown` : rien ne leur est lié, et rien ne commence par elles. La prompt line dit `C-x C-t is not bound.`, et rien ne
  change.

Une key sequence liée à une commande est lancée dès qu'elle est tapée : une plus longue qui commence par elle ne peut donc
pas être atteinte. Liez `C-c t` à une commande, et `C-c t s` est perdue.

`C-g` après une prefix key l'oublie, garde la sélection, et dit `Quit`, qu'une key binding le prenne ou non, comme le font
`C-x C-g` et `C-c C-g` : [commands.CancelPair].

### Les touches après un préfixe

Après une prefix key, une touche qui tape, sans Control, Alt ni Super, n'est pas lue depuis son événement de touche : Cemacs
attend le texte qu'elle tape, et prend ce texte, en minuscules, comme chord ; la barre d'espace est `space`. Ainsi, sur un
clavier américain, Shift et `/` après `C-x` donnent `C-x ?`, que l'événement de touche seul appellerait `C-x /`. Les
minuscules font que Shift et `b` après `C-x` donnent `C-x b`, comme `b` seul.

## Changer une touche

Les key bindings sont du code : changer une touche, c'est une ligne de votre `Changed`, dans `user/config/config.ce`, qu'ouvre
`C-c f c`, et toute fonction qui va d'un état à un état peut être liée. [Modifier Cemacs](customising.md#des-touches-à-vous)
montre comment, avec vos propres touches et vos propres groupes, et [Recettes](recipes.md#un-groupe-de-touches-à-vous) fait un
groupe de quatre commandes.
