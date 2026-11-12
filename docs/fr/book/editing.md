# Édition

Ce chapitre dit comment le curseur se déplace, comment le texte se tape et s'efface, où va une ligne de code Cesia,
comment un mot se complète, comment une sélection se fait, se coupe, se copie et se colle, comment marche l'annulation, et
ce que fait la souris. Chaque touche ici est dans la table de `src/emacs/emacs.ce`, et lance une commande de
[core/commands] : une fonction publique qui va de l'état de l'éditeur à un nouvel état.

## Les exemples de ce chapitre

Les exemples ci-dessous pilotent le vrai éditeur, sans fenêtre : [press.Press] joue des touches et des textes à travers
[commands.Update], comme la fenêtre les enverrait, et le résultat est l'état qui les suit. C'est aussi ainsi que les tests de
Cemacs le pilotent.

```cesia
use core/press
use core/text
use core/view
use src/emacs
use src/rope
use src/ui
use std/value

defn editor(words, path = missing)
  (** The editor with one buffer holding words, of the file path or of none, the Emacs keys and no window: 800 by 600 pixels,
      characters 8 by 19. Nothing is read from the disk. *)
  s = view.Start([text.Of(words, path)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
  s.Config = () -> emacs.Config(emacs.Keys)
  s
end

textOf(state) = rope.Text(state.Buffers[state.Current].Rope)   (** The text of the current buffer. *)
cursorOf(state) = state.Buffers[state.Current].Cursor   (** Its cursor. *)

textOf(press.Press(["Hello", "C-a", "Oh, "], editor(""))) --> "Oh, Hello"
```

Un texte comme `"Hello"` se tape un caractère à la fois ; un nom comme `"C-a"` est une touche.

## Le curseur

Le curseur est l'endroit où ce que vous tapez s'insère : toujours entre deux caractères, ou avant le premier, ou après le
dernier. Il est dessiné comme une barre fine qui ne clignote pas, car un curseur qui clignote dessinerait des frames (des
images complètes de la fenêtre) sans fin, alors qu'un éditeur immobile ne dessine rien. Emacs appelle cet endroit le point ;
Cemacs l'appelle le curseur.

Le curseur est une ligne et une colonne, `{Line, Column}`. Les lignes se comptent à partir de 1. Les colonnes comptent les
caractères à partir de 0 : la colonne est donc le nombre de caractères de la ligne qui viennent avant le curseur. La mode
line les montre sous la forme `line:column` (ligne, deux-points, colonne) :

```cesia
cursorOf(press.Press(["ab", "enter", "cd"], editor(""))) --> {Line: 2, Column: 2}
```

Un caractère, ici, est ce que Cesia compte comme un caractère : `é` est un seul caractère, même si UTF-8 l'écrit en deux
octets. Chaque caractère prend une colonne à l'écran, un caractère large comme `中` aussi, qui peut alors déborder sur le
suivant.

## Se déplacer

| Touches | Commande | Déplace le curseur |
|---|---|---|
| `C-f`, `right` | [commands.ForwardChar] | d'un caractère en avant ; au bout d'une ligne, au début de la suivante |
| `C-b`, `left` | [commands.BackwardChar] | d'un caractère en arrière ; au début d'une ligne, au bout de celle du dessus |
| `C-n`, `down` | [commands.NextLine] | d'une ligne vers le bas |
| `C-p`, `up` | [commands.PreviousLine] | d'une ligne vers le haut |
| `M-f` | [commands.ForwardWord] | à la fin du mot, ou du suivant |
| `M-b` | [commands.BackwardWord] | au début du mot, ou du précédent |
| `C-a`, `home` | [commands.LineStart] | au début de la ligne |
| `C-e`, `end` | [commands.LineEnd] | au bout de la ligne |
| `C-v`, `pagedown` | [commands.PageDown] | d'une page vers le bas : autant de lignes que le pane en montre |
| `M-v`, `pageup` | [commands.PageUp] | d'une page vers le haut |
| `M-<` | [commands.FileStart] | au début du fichier |
| `M->` | [commands.FileEnd] | à la fin du fichier |

`M-<` et `M->` demandent Shift sur la plupart des claviers, et les deux façons marchent : Alt, Shift et `,` donne `M-S-,`,
qui est lié à la même commande, et `M-S-.` aussi. Un déplacement s'arrête aux bouts du fichier : `C-p` sur la première ligne
ne fait rien.

Un mot est une suite de lettres, de chiffres et de soulignés, `_`. Un caractère qui n'est pas ASCII (les 128 caractères du
texte anglais simple) compte comme une lettre : `été` est donc un seul mot. Cesia ne connaît la casse (majuscule ou
minuscule) que des lettres ASCII, et traiter les autres caractères comme des lettres garde chaque alphabet dans les mots.
`M-f` saute d'abord ce qui n'est pas un mot, puis le mot :

```cesia
cursorOf(press.Press(["one two", "C-a", "M-f"], editor(""))) --> {Line: 1, Column: 3}
cursorOf(press.Press(["one two", "C-a", "M-f", "M-f", "M-b"], editor(""))) --> {Line: 1, Column: 4}
```

Se déplacer par lignes garde la colonne que vous vouliez, la goal column (la colonne visée), à travers les lignes plus
courtes : depuis la colonne 3, une ligne d'un caractère met le curseur à son bout, et la longue ligne suivante le remet à la
colonne 3. Tout autre déplacement, et toute modification, l'oublie.

```cesia
cursorOf(press.Press(["C-e", "C-b", "C-n"], editor("abcd\nx\nabcd"))) --> {Line: 2, Column: 1}
cursorOf(press.Press(["C-e", "C-b", "C-n", "C-n"], editor("abcd\nx\nabcd"))) --> {Line: 3, Column: 3}
```

Une page fait autant de lignes que le pane en montre, sans garder de ligne de l'écran d'avant : dans un pane de 28 lignes,
`C-v` sur la ligne 1 va à la ligne 29. L'écran suit le curseur, pour qu'il reste visible.

## Taper

Une touche qui tape, une lettre ou un chiffre avec ou sans Shift, insère son caractère au curseur ; une touche du pavé
numérique aussi, et le texte d'une input method (le programme du système qui compose les caractères qu'un clavier n'a pas).
Une touche avec Control ou Alt ne tape rien, et lance sa commande.

| Touches | Commande | Insère |
|---|---|---|
| `enter`, `S-enter` | [commands.NewLine] | une fin de ligne ; dans un fichier de Cesia, puis les espaces qui mettent la nouvelle ligne là où `cesia fmt` la met ; dans un autre fichier, les espaces et les tabulations qui commencent la ligne courante, jusqu'au curseur |
| `tab`, `S-tab` | [commands.Tab] | dans un fichier de Cesia, rien : la ligne, ou les lignes sélectionnées, vont à leur place, ou le mot avant le curseur est complété ; dans un autre fichier, le texte de [emacs.TabText] : deux espaces |

L'indentation d'une ligne, ce sont les espaces à son début, qui montrent le code à l'intérieur d'un bloc. Dans un fichier
d'un autre langage, Enter garde l'indentation de la ligne :

```cesia
textOf(press.Press(["  if x", "enter", "y"], editor(""))) --> "  if x\n  y"
```

Dans un autre fichier, Tab insère des espaces, et jamais un caractère de tabulation : changez [emacs.TabText] pour avoir une
autre largeur. Dans un fichier de Cesia, Enter et Tab donnent à chaque ligne sa place, comme le dit la section suivante.
Taper sur une sélection la remplace, comme dans la plupart des éditeurs ; dans Emacs, c'est `delete-selection-mode` qui le
fait.

## L'indentation dans un fichier de Cesia

Un fichier de Cesia est un buffer dont le chemin finit par `.ce`, [indent.IsCesia]. Cemacs y met chaque ligne là où la
mettrait `cesia fmt`, le formatter de Cesia (le programme qui remet le code dans le style de Cesia), selon la règle même de
fmt, si bien que le code tapé dans Cemacs est déjà tel que fmt le laisse :

- Une ligne qui commence un statement (une instruction, un pas du programme comme `x = 1` ou `if a`) reçoit deux espaces
  pour chaque bloc où elle se trouve. Un bloc est ce qu'ouvre `defn`, `if`, `for`, `while`, `match`, `struct` ou
  `interface` et que ferme `end` ; `else` ferme une partie d'un `if` ou d'un `match` et ouvre la suivante, aussi se
  place-t-il un bloc plus à gauche.
- Une ligne qui continue un statement, une continuation line (une ligne de suite), se déplace avec la ligne qui le commence.
  Un statement continue entre parenthèses, crochets ou accolades, `(`, `[` et `{`, que la suite de ce chapitre appelle
  toutes « parenthèses », après un token (un mot ou un signe du code) qui en demande plus, comme `,`, `+`, `and` ou `then`,
  et à l'intérieur d'un commentaire.
- Une ligne qui commence à l'intérieur d'un texte, de `"` à `"` sur plusieurs lignes, garde les espaces qu'elle contient,
  puisqu'ils font partie du texte.

Les exemples ci-dessous donnent au buffer un fichier, `a.ce` ; rien n'est lu sur le disque. `"end"` seul serait la touche
de ce nom, aussi le mot se tape-t-il en deux parties, `"en"` et `"d"`.

**Enter** commence la nouvelle ligne à sa place, un bloc plus loin après une ligne qui ouvre un bloc. **Les mots qui
déplacent une ligne**, `end`, `else` et `then`, et les parenthèses fermantes `)`, `]` et `}`, tapés au début d'une ligne, la
mettent aussi à sa place, dans la même étape d'annulation que la frappe :

```cesia
typed = press.Press(["if a", "enter", "b", "enter", "else", "enter", "c", "enter", "en", "d"], editor("", "a.ce"))
textOf(typed) --> "if a\n  b\nelse\n  c\nend"
```

Les mêmes touches, dans un fichier d'un autre langage, gardent l'indentation de la ligne du dessus :

```cesia
textOf(press.Press(["if a", "enter", "b", "enter", "en", "d"], editor(""))) --> "if a\nb\nend"
```

Enter enlève aussi les espaces autour du curseur qui resteraient au bout de la ligne, puisque fmt ne laisse aucune ligne
finir par des espaces. À l'intérieur d'un texte, il garde les espaces et les tabulations de la ligne, comme dans un autre
fichier.

Emacs appelle cela l'electric indentation (l'indentation refaite à certaines touches) : son `electric-indent-mode`, actif
par défaut, indente à nouveau à chaque caractère de `electric-indent-chars`, une fin de ligne par défaut, à laquelle chaque
mode d'un langage ajoute les siens ; Vim et Neovim font de même avec les `'indentkeys'` de chaque type de fichier, comme
`0=end` pour Lua.

**Tab** met la ligne du curseur à sa place, ou, avec une sélection, chaque statement qui y a une ligne. Un statement se
déplace tout entier : sa première ligne va à sa place, et les lignes qui le continuent se déplacent d'autant, si bien que
leur disposition est gardée. C'est une seule étape d'annulation, et cela met fin à la sélection :

```cesia
textOf(press.Press(["C-n", "tab"], editor("defn f()\nx = 1 +\n    2\nend", "a.ce"))) --> "defn f()\n  x = 1 +\n      2\nend"
```

Le curseur garde sa place dans les mots de sa ligne ; depuis l'intérieur de l'indentation, il va à sa fin. Sur une ligne
vide, Tab met le curseur là où commencerait une ligne tapée là. C'est l'`indent-for-tab-command` d'Emacs avec
`tab-always-indent` à `t`, sa valeur par défaut : Tab ne fait jamais qu'indenter. Dans un fichier de Cesia, Tab ne tape plus
deux espaces ; la barre d'espace le fait.

**Une ligne que fmt garde telle qu'elle est écrite.** fmt n'a pas de règle pour la place d'une continuation line : il la
déplace avec son statement, et la garde là où elle est par rapport à lui. Tab ne choisit donc pas de place pour une telle
ligne, mais une ligne que l'on tape en a besoin, et Enter et les mots qui déplacent une ligne la choisissent :

- entre parenthèses, comme la ligne du dessus entre les mêmes parenthèses, sinon deux colonnes plus loin que la ligne qui
  ouvre la parenthèse, et la parenthèse qui la ferme sous cette ligne ; un bloc écrit entre parenthèses, comme dans
  `fiber.Spawn(defn ()`, se dispose à partir de la ligne qui l'ouvre ;
- après un token qui en demande plus, ou avant un `then`, deux colonnes plus loin que le statement, ou comme la ligne du
  dessus qui le continue ;
- dans un commentaire, sous les mots qui suivent son ouverture, puis comme la ligne du dessus ; dans un commentaire de
  documentation, `(**`, deux colonnes plus loin après une ligne vide, là où vont ses exemples ;
- dans un texte, comme la ligne du dessus.

```cesia
textOf(press.Press(["ys = [f(x),", "enter", "g(x)", "enter", "]"], editor("", "a.ce"))) --> "ys = [f(x),\n  g(x)\n]"
```

Mesuré sur tous les fichiers de Cesia et de Cemacs, formatés par fmt, 768 fichiers de 36 038 lignes : Tab laisse chacune des
36 038 lignes là où elle est, et une ligne tapée avec Enter et son premier mot arrive là où le code formaté la met pour
36 000 d'entre elles, 99,89 %. Les 38 autres sont des dispositions que fmt garde et qu'aucune règle ne devine, comme un
exemple juste sous les mots d'un commentaire, sans ligne vide avant lui. [À l'intérieur de Cemacs](internals.md#lindentation)
dit comment une ligne se lit, et [Vitesse](performance.md#enter-et-tab-dans-un-fichier-de-cesia) ce que cela coûte.

## La completion

Compléter un mot, c'est en taper le début et laisser l'éditeur écrire le reste : la completion. Dans un fichier de Cesia,
Tab complète quand la ligne est déjà à sa place et que le curseur finit un mot : les lettres, les chiffres et les tirets bas
(`_`) juste avant lui, sans aucun juste après. Sinon, Tab met la ligne à sa place, comme plus haut. C'est ce que fait Emacs
avec `tab-always-indent` à `complete`.

Les mots viennent de trois endroits, dans cet ordre, chaque mot une fois, 100 au plus :

1. le texte du buffer autour du curseur, 64 KB avant lui et 64 KB après, le mot le plus proche d'abord ;
2. les autres buffers, de la même façon autour de leur curseur ;
3. les noms de Cesia : ses mots-clés, et les noms publics de sa bibliothèque standard sans leur module, comme `Concat` pour
   `list.Concat`, lus une fois, à la première completion.

Un mot tapé sans majuscule trouve aussi les mots qui en ont, comme le fait une recherche : `byte` trouve `ByteFind`. Un mot
avec une majuscule ne trouve que les mots qui commencent tels qu'il est écrit. Le `dabbrev-expand` d'Emacs, `M-/`, et le
`Ctrl-N` de Vim prennent eux aussi leurs mots dans les buffers.

Avec un seul mot trouvé, Tab le met en place tout de suite. Avec plusieurs, une liste s'ouvre sous le mot, le premier
choisi :

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-n`, `down` | [commands.CompleteNext] | choisit le mot suivant, et le premier après le dernier |
| `C-p`, `up` | [commands.CompletePrevious] | choisit le mot d'avant, et le dernier avant le premier |
| `tab` | [commands.CompleteAccept] | met le mot choisi à la place du début tapé, et ferme la liste |

Une lettre tapée pendant que la liste est ouverte va dans le mot, et la liste se refait pour le mot plus long ; toute autre
touche, comme Enter, `C-g` ou un déplacement, ferme la liste et fait ce qu'elle fait. Sans mot trouvé, la prompt line dit
`No completion for` (pas de completion pour) et le mot. Le mot mis en place est une seule étape d'annulation, et il déplace
sa ligne quand sa place change, comme le ferait `else` tapé.

```cesia
words = "Hello = 1\nHelp = 2\n"
listed = press.Press(["M->", "Hel", "tab"], editor(words, "a.ce"))
listed.Completion.Words[1] --> "Help"
listed.Completion.Words[2] --> "Hello"
textOf(press.Press(["C-n", "tab"], listed)) --> "Hello = 1\nHelp = 2\nHello"
textOf(press.Press(["M->", "Hell", "tab"], editor(words, "a.ce"))) --> "Hello = 1\nHelp = 2\nHello"
```

La liste montre huit mots à la fois, et défile avec le mot choisi. Dans un fichier d'un autre langage, Tab tape son texte
comme avant, et ne complète pas. [Vitesse](performance.md#la-completion) donne ce que coûte une completion.

## Les formes de Cesia

Le groupe `i`, insert (insérer), de `C-c` écrit les formes de Cesia, chacune à l'indentation de sa place, le curseur là où
va son nom : `C-c i d` une fonction, `C-c i s` une struct, `C-c i f` une boucle, `C-c i m` un match, `C-c i t` une fonction
de test, `C-c i c` le marqueur d'une cellule, comme `C-c e i` ([Cellules et résultats](cells.md)). Les formes viennent de
[src/snippets], par `tools/snippets.ce`, comme les autres questions de [src/ide](names.md#how-the-ide-asks) :
[ide.InsertDefn], [ide.InsertStruct], [ide.InsertFor], [ide.InsertMatch], [ide.InsertTest], [notebook.InsertCell].

## Effacer

| Touches | Commande | Efface |
|---|---|---|
| `backspace`, `S-backspace` | [commands.DeleteBefore] | le caractère avant le curseur ; au début d'une ligne, la fin de ligne qui la précède, ce qui joint les deux lignes |
| `C-d`, `delete`, `S-delete` | [commands.DeleteAfter] | le caractère après le curseur ; au bout d'une ligne, la fin de ligne, ce qui lui joint la ligne suivante |

Avec une sélection, les deux effacent la sélection à la place. Au début du fichier, `backspace` ne fait rien, et `delete` non
plus à sa fin.

## La mark et la sélection

La mark est un second endroit du buffer, que vous posez ; le texte entre la mark et le curseur, dans un ordre ou dans
l'autre, est la sélection. Emacs l'appelle la region. Elle est dessinée avec un fond de couleur, et une fin de ligne qu'elle
contient s'affiche comme un caractère de couleur de plus, après le bout de la ligne.

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-space` | [commands.SetMark] | pose la mark au curseur : les déplacements qui suivent sélectionnent |
| `S-right`, `S-left`, `S-down`, `S-up` | [commands.SelectForwardChar], [commands.SelectBackwardChar], [commands.SelectNextLine], [commands.SelectPreviousLine] | sélectionne un caractère, ou une ligne, à partir du curseur |
| `S-home`, `S-end` | [commands.SelectLineStart], [commands.SelectLineEnd] | sélectionne jusqu'au début ou jusqu'au bout de la ligne |
| `S-pageup`, `S-pagedown` | [commands.SelectPageUp], [commands.SelectPageDown] | sélectionne une page vers le haut ou vers le bas |
| `C-g` | [commands.Cancel] | enlève la mark, et dit `Quit` |

Il y a trois façons de commencer une sélection, et chacune finit à sa façon :

- `C-space` : la mark reste à travers tous les déplacements, jusqu'à `C-g`, une modification, une coupe ou une copie. Emacs
  marche ainsi avec `transient-mark-mode`, son réglage par défaut.
- Shift avec un déplacement : la mark est posée là où était le curseur, et le déplacement suivant sans Shift l'enlève, comme
  dans la plupart des éditeurs ; Emacs appelle cela la shift selection. Un déplacement avec Shift alors qu'une mark est déjà
  posée garde cette mark et agrandit la sélection.
- La souris : appuyez sur le premier bouton et faites glisser.

```cesia
s = press.Press(["abc", "S-left", "S-left"], editor(""))
text.Region(s.Buffers[1]) --> "bc"
textOf(press.Press(["abc", "S-left", "S-left", "X"], editor(""))) --> "aX"
```

## Couper, copier et coller

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-w` | [commands.Cut] | la sélection enlevée, et mise dans le presse-papiers |
| `M-w` | [commands.Copy] | la sélection mise dans le presse-papiers ; la mark s'en va, et le texte reste |
| `C-y` | [commands.Paste] | le presse-papiers inséré au curseur, à la place de la sélection |
| `C-k` | [commands.CutLine] | le reste de la ligne coupé, ou la fin de ligne elle-même quand le curseur est déjà au bout |

Le presse-papiers est celui de votre système, partagé avec les autres programmes : ce que Cemacs coupe, un autre programme
le colle, et l'inverse. Emacs parle de kill (tuer un texte) et de yank (le ramener), et garde chaque kill dans un kill ring,
une liste des dernières coupes que `M-y` parcourt. Cemacs n'a pas de kill ring : le presse-papiers contient un seul texte,
le dernier coupé ou copié. Une coupe sans rien de sélectionné dit `Nothing is selected.` (rien n'est sélectionné), un
collage avec un presse-papiers vide dit `The clipboard is empty.` (le presse-papiers est vide), et `C-k` à la fin du fichier
dit `Nothing to cut.` (rien à couper).

`C-k` encore et encore ajoute chaque coupe à la précédente : `C-k C-k C-k` met ensemble dans le presse-papiers la ligne, sa
fin de ligne et la ligne suivante, et `C-y` les remet d'un coup. Emacs appelle cela appending kills (ajouter les kills bout à
bout). Toute autre commande, une touche qui tape ou un clic, finit la chaîne : le `C-k` suivant commence un nouveau texte.

```cesia
s = press.Press(["C-k", "C-k", "C-k"], editor("one\ntwo\nthree"))
textOf(s) --> "\nthree"
s.Clip --> "one\ntwo"
```

Les exemples n'ont pas de fenêtre : ils gardent donc le presse-papiers dans l'état, sous le nom `Clip` ; dans la fenêtre,
c'est celui du système.

## Annuler et rétablir

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-/` | [commands.Undo] | la dernière étape annulée, le curseur là où il était avant cette étape |
| `C-?`, `C-S-/` | [commands.Redo] | l'étape annulée en dernier refaite, le curseur là où cette étape l'a laissé |

Chaque buffer garde son historique d'annulation : les états de son texte, un par étape, pour qu'une étape puisse être
défaite et refaite. Une étape est une commande qui change le texte, avec une exception : la frappe fait des mots. Un
caractère tapé juste après un autre rejoint son étape, et un espace tapé finit l'étape, comme son dernier caractère ; Enter
et Tab sont des étapes à eux seuls. Taper `hello world` puis annuler défait donc `world`, puis `hello ` :

```cesia
textOf(press.Press(["hello world", "C-/"], editor(""))) --> "hello "
textOf(press.Press(["hello world", "C-/", "C-/"], editor(""))) --> ""
```

Toute autre commande, un déplacement aussi, finit une étape de frappe. Un texte tapé qui remplace une sélection est une seule
étape, l'effacement et le nouveau texte ensemble.

L'historique est linéaire : après une annulation, une nouvelle modification oublie les étapes qui auraient pu être refaites.
Il garde jusqu'à 1 000 états avant l'état présent, et les plus anciens partent en premier. Emacs marche autrement : son
annulation est une modification à elle seule, qu'une annulation plus tardive défait, si bien qu'il n'a pas de commande
séparée pour rétablir. Dans Cemacs, `C-?` rétablit, comme `Ctrl-Shift-Z` dans beaucoup d'éditeurs.

```cesia
textOf(press.Press(["x", "C-/", "y", "C-?"], editor(""))) --> "y"
```

L'historique d'annulation sait quel état a été enregistré : annuler jusqu'au texte qui est sur le disque enlève l'étoile de
la mode line. Annuler et rétablir enlèvent aussi la mark, car une mark laissée à sa place sélectionnerait un texte que vous
n'avez jamais choisi.

## C-g

`C-g` arrête ce que les touches ont commencé :

- après une prefix key, la première touche d'une touche plus longue, comme `C-x` dans `C-x C-s`, il oublie le préfixe, garde
  la sélection, et dit `Quit` ;
- avec une question ouverte sur la prompt line, il ferme la question, sans réponse, et dit `Quit` ;
- dans une liste, il défait ce que vous avez tapé pour la filtrer, et, sans rien de tapé, il ferme la liste ;
- sinon, il enlève la mark, et dit `Quit`.

Une touche liée à rien le dit sur la prompt line, comme `C-t is not bound.` ou `C-x C-t is not bound.` (`C-t` n'est liée à
rien), et ne change rien.

## La souris

| Action | Commande | Ce qu'elle fait |
|---|---|---|
| appui sur le premier bouton | [commands.Press] | le pane sous la souris devient celui que vous modifiez ; dans son code, le curseur va à la limite entre deux caractères la plus proche de la souris |
| déplacement bouton tenu | [commands.Drag] | sélectionne de l'appui jusqu'à la souris, dès que la souris a quitté la zone autour de l'appui |
| relâchement | [commands.Release] | finit le glissement ; un clic qui n'a rien sélectionné ne laisse pas de mark |
| molette | [commands.Wheel] | fait défiler le pane sous la souris |

La zone autour d'un appui est [emacs.DragZone], 4 pixels sur chaque axe : une main qui bouge d'un pixel pendant qu'elle
clique ne fait pas de sélection. Dès que la souris a quitté la zone, le curseur la suit, même quand elle y revient. Un
glissement au-delà du bord du code continue de sélectionner, et l'écran suit. Un appui est une commande : il finit donc une
prefix key, une chaîne de `C-k` et une étape de frappe. Les autres boutons ne font que cela.

Un cran de la molette déplace l'écran de [emacs.WheelLines] lignes, 3, sans déplacer le curseur, et sans faire du pane sous
la souris celui que vous modifiez. Un touchpad envoie des morceaux de cran : ce qui fait moins d'une ligne est gardé pour
l'événement suivant, si bien qu'un geste lent fait quand même défiler. Après la molette, l'écran reste où il est, le curseur
peut-être hors de vue, jusqu'à ce qu'une touche ou un clic le ramène.

Pendant qu'une question est ouverte sur la prompt line, seuls la molette et la fin d'un glissement marchent, pour que le
texte ne puisse pas changer sous la question.
