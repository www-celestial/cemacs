# Édition

Ce chapitre dit comment le curseur se déplace, comment le texte se tape et s'efface, comment une sélection se fait, se
coupe, se copie et se colle, comment marche l'annulation, et ce que fait la souris. Chaque touche ici est dans la table de
`src/emacs/emacs.ce`, et lance une commande de [core/commands] : une fonction publique qui va de l'état de l'éditeur à un
nouvel état.

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

defn editor(words)
  (** The editor with one buffer holding words, the Emacs keys and no window: 800 by 600 pixels, characters 8 by 19. *)
  s = view.Start([text.Of(words, missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
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
| `enter`, `S-enter` | [commands.NewLine] | une fin de ligne, puis les espaces et les tabulations qui commencent la ligne courante, jusqu'au curseur |
| `tab`, `S-tab` | [commands.Tab] | le texte de [emacs.TabText] : deux espaces |

Enter garde donc l'indentation, les espaces au début d'une ligne qui montrent le code à l'intérieur d'un bloc :

```cesia
textOf(press.Press(["  if x", "enter", "y"], editor(""))) --> "  if x\n  y"
```

Tab insère des espaces, et jamais un caractère de tabulation, car le code Cesia est indenté avec des espaces : changez
[emacs.TabText] pour avoir une autre largeur. Taper sur une sélection la remplace, comme dans la plupart des éditeurs ; dans
Emacs, c'est `delete-selection-mode` qui le fait.

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
