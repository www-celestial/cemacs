# Recherche

Cemacs cherche dans un buffer comme Emacs, de façon incrémentale : `C-s` ouvre la prompt line, et chaque lettre que vous
tapez déplace le curseur jusqu'à l'endroit suivant des mots tapés jusque-là, qui s'affiche sélectionné. Ce chapitre décrit
cette recherche, puis ce que Cemacs trouve d'autre : des rangées dans les listes, des touches, des erreurs, et les endroits
que nomme la sortie d'un programme. La recherche par regular expression (un motif comme `[0-9]+`, qui correspond à beaucoup
de textes), le remplacement (le `M-%` d'Emacs) et la recherche à travers les fichiers d'un projet ne sont pas encore là.

## Chercher dans un buffer

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-s`, `C-c s s` | [commands.SearchForward] | cherche en avant depuis le curseur pendant que vous tapez ; dans une recherche, va à l'endroit suivant |
| `C-r`, `C-c s r` | [commands.SearchBackward] | la même chose, en arrière |

Une incremental search (une recherche incrémentale) est une recherche qui cherche pendant que vous tapez, au lieu d'attendre
les mots entiers : après `C-s` et `t`, le curseur est après le premier `t` qui le suit ; après `tw`, après le premier `tw`,
qui peut être au même endroit ou plus loin. L'endroit trouvé s'affiche sélectionné, de son début à sa fin, et l'écran le
suit. En avant, le curseur finit après l'endroit ; en arrière, à son début. Tant que la recherche dure, la prompt line dit ce
qu'elle fait :

| La prompt line | Quand |
|---|---|
| `I-search: WORDS` | une recherche en avant, qui a trouvé WORDS |
| `I-search backward: WORDS` | une recherche en arrière |
| `Failing I-search: WORDS` | il ne reste plus d'endroit de WORDS dans ce sens ; le dernier endroit trouvé reste sélectionné |
| `Wrapped I-search: WORDS` | après que la recherche a fait le tour de la fin du fichier jusqu'à son début, ou, en arrière, du début jusqu'à la fin |
| `Failing wrapped I-search: WORDS` | même en faisant le tour, rien |

Les touches pendant qu'une recherche est ouverte :

| Touches | Ce qu'elles font |
|---|---|
| un texte tapé, `C-y` | l'ajoute aux mots, et cherche à nouveau depuis le début de l'endroit trouvé, pour que l'endroit reste tant qu'il correspond encore |
| `C-s` | l'endroit suivant en avant ; une fois que la recherche échoue, le `C-s` suivant fait le tour jusqu'au début du fichier |
| `C-r` | l'endroit suivant en arrière, et le tour par la fin une fois qu'elle échoue dans ce sens |
| `C-s` ou `C-r` sans mots encore | cherche à nouveau les mots de la dernière recherche |
| `backspace` | défait la dernière étape, une lettre ou un `C-s`, avec l'endroit qu'elle avait |
| `enter` | finit la recherche, le curseur à l'endroit |
| `C-g` | quand la recherche échoue, défait les lettres qui n'ont rien trouvé ; sinon finit la recherche là où elle a commencé, et dit `Quit` |
| toute autre touche | finit la recherche à l'endroit, puis fait ce qu'elle fait : `C-a` va au début de cette ligne |

```cesia
use core/press
use core/view
use core/text
use src/emacs
use src/rope
use src/ui
start = view.Start([text.Of("one two\nthree two", missing)], ui.Look(ui.Dark, (w, f) -> 8, 19), {Width: 8, Height: 19}, 800, 600)
start.Config = () -> emacs.Config(emacs.Keys)
found = press.Press(["C-s", "two", "C-s"], start)
found.Prompt.Label --> "I-search: "
found.Buffers[1].Cursor --> {Line: 2, Column: 9}
press.Press(["C-s", "two", "C-s", "C-s"], start).Prompt.Label --> "Failing I-search: "
press.Press(["C-s", "two", "C-s", "C-s", "C-s"], start).Buffers[1].Cursor --> {Line: 1, Column: 7}
press.Press(["C-s", "three", "C-g"], start).Buffers[1].Cursor --> {Line: 1, Column: 0}
```

Le case folding (traiter une majuscule et une minuscule comme la même lettre) suit Emacs : des mots sans majuscule
correspondent dans les deux casses, et des mots avec une majuscule correspondent exactement. `two` trouve `Two` et `TWO` ;
`Two` ne trouve que `Two`. Cesia ne connaît la casse que des lettres d'ASCII : `é` ne correspond donc jamais à `É`.
[commands.Folds] dit lequel des deux s'applique :

```cesia
use core/commands
commands.Folds("two") --> true
commands.Folds("Two") --> false
```

Les mots sont des octets à trouver, pas un motif : `a.b` trouve les trois caractères `a.b`. Une recherche vit dans la prompt
line : le buffer ne peut donc pas changer pendant qu'elle est ouverte ; une touche qui le changerait, comme `C-k`, finit
d'abord la recherche.

### Comment elle trouve

En avant, [rope.Find] parcourt la rope (l'arbre de morceaux de texte dans lequel Cemacs garde un buffer) par runs de ses
feuilles. Un run est une suite de feuilles qui voient le même texte, chacune commençant là où la précédente a fini : un
fichier qu'on vient d'ouvrir est un seul run, le fichier entier ; une modification le coupe en deux autour de ce qui a été
tapé, un texte à part. Un run qui voit son texte jusqu'au dernier octet, comme le fichier entier qu'on vient d'ouvrir ou la
partie après la dernière modification, est cherché dans ce texte lui-même, sans copie, par un seul appel au [text.ByteFind]
de Cesia. Toute autre partie de la rope est lue une fenêtre à la fois (un morceau de texte d'une taille donnée) : 64 KiB
d'abord, puis deux fois plus à chaque fenêtre, jusqu'à 1 MiB, chaque fenêtre étant une seule slice (une tranche) de la rope ;
chacune chevauche la précédente de la longueur des mots moins un octet, pour qu'un endroit à cheval sur deux fenêtres soit
trouvé, et les endroits à cheval sur la fin d'un run sont cherchés à part, dans une slice de deux fois la longueur des mots.
En arrière, [rope.FindBefore] lit des fenêtres en remontant depuis le curseur, car Cesia n'a pas de recherche qui va en
arrière.

[text.ByteFind] trouve les mots huit octets à la fois : il cherche l'octet le plus rare des mots avec le test de SWAR, SIMD
within a register, qui dit en quelques instructions si un octet d'un mot de 64 bits est celui qu'on cherche, puis compare les
mots à chaque endroit qu'il donne. Avec le folding, `fold = true`, les lettres d'ASCII correspondent dans les deux casses
dans la même passe, sans copie du texte en minuscules.

```cesia
r = rope.Of("ab ab ab")
[rope.Find("ab", 1, r), rope.FindBefore("ab", 6, r)] --> [3, 3]
rope.Find("AB", 1, r, fold = true) --> 3
```

Montrer un endroit lointain coûte plus cher que le trouver : les couleurs des lignes de l'écran dépendent de toutes les
lignes d'avant, car un commentaire ou un texte ouvert sur une ligne continue sur les suivantes. L'endroit est montré tout de
suite, avec ses couleurs devinées, et elles deviennent exactes dans les instants qui suivent : voir
[À l'intérieur de Cemacs](internals.md#un-endroit-lointain-d-abord-ses-couleurs-exactes-ensuite) et [Vitesse](performance.md#recherche).

## Les listes

Une liste est un buffer de rangées que Cemacs fait pour vous : les buffers (`C-x C-b`), les fichiers d'un dossier
(`C-x d`), les touches après un préfixe (`C-x ?`), la sortie d'un programme (`C-c c o`). Chaque rangée représente quelque
chose, un buffer, un fichier, une touche ou une ligne de sortie, et Enter agit sur la rangée sous le curseur. Une liste est
en lecture seule : une commande qui changerait son texte, comme `C-w` ou annuler, est défaite, et la prompt line dit
`This list is read only.` (cette liste est en lecture seule). Les déplacements, la sélection et `M-w` y marchent comme dans
tout buffer : une rangée peut donc être copiée.

Taper dans une liste la filtre : seules restent les rangées qui correspondent à ce que vous avez tapé, dans leur ordre. La
prompt line montre le filtre après `Filter: `, ou après le chemin dans le gestionnaire de dossiers. Backspace défait le
dernier caractère ; `C-g` efface le filtre, et, sans filtre, ferme la liste et revient au buffer d'où elle a été ouverte.

| Touches dans une liste | Commande | Ce qu'elle fait |
|---|---|---|
| un texte tapé | [commands.AddToFilter] | l'ajoute au filtre |
| `backspace`, `S-backspace` | [commands.ListBack] | défait le dernier caractère du filtre |
| `C-g` | [commands.ListCancel] | efface le filtre, ou ferme la liste |

### Quand une rangée correspond à un filtre

Une rangée correspond quand les caractères du filtre viennent dans ses mots dans le même ordre, côte à côte ou non, quelle
que soit leur casse : `cmd` correspond à `commands.ce`. C'est le subsequence matching (la correspondance par sous-suite),
la sorte de fuzzy matching (de correspondance approximative) qu'emploient beaucoup d'éditeurs pour trouver un fichier à partir
de quelques-unes de ses lettres ; la completion d'Emacs l'appelle le style `flex`. Une espace coupe le filtre en mots, et
chaque mot doit correspondre, dans n'importe quel ordre, comme dans Vim et Neovim : `ce cmd` correspond aussi à
`commands.ce`. [lists.Matches] dit si un filtre correspond :

```cesia
use core/lists
lists.Matches("cmd", "commands.ce") --> true
lists.Matches("CMD", "commands.ce") --> true
lists.Matches("dmc", "commands.ce") --> false
lists.Matches("ce cmd", "commands.ce") --> true
```

Le filtre lit les mots d'une rangée, ou sa clé quand elle en a une : une rangée du gestionnaire de dossiers a pour clé le nom
du fichier, si bien qu'un filtre ne correspond jamais à une taille ou à une date. Chaque caractère est cherché en code natif,
avec [text.ByteFind], après le précédent, comme le fait [lists.Filtered]. Dans une liste dont les rangées sont faites une
seule fois, comme les fichiers d'un dossier et les touches, une lettre ajoutée ne filtre que les rangées montrées avant elle ;
les buffers et la sortie sont refaits à chaque événement, puisqu'ils changent. [Vitesse](performance.md) donne les temps d'un
dossier de 10 000 fichiers.

```cesia
rows = [{Words: "editor.ce", Item: 1}, {Words: "commands.ce", Item: 2}, {Words: "commands.test.ce", Item: 3}]
[r.Item for r in lists.Filtered("cmt", rows)] --> [3]
```

Quand un filtre change les rangées, le curseur reste sur la rangée où il était si elle est encore montrée, sinon sur la même
ligne.

La plupart des listes gardent leurs rangées dans leur ordre. La liste des [fichiers d'un projet](files.md#les-fichiers-d-un-projet),
`C-x p f`, les classe à la place : les rangées que le filtre garde viennent la meilleure d'abord, d'après [lists.Score], le
score de fzy qu'emploient Vim et Neovim, qui récompense les lettres trouvées au début d'un mot ou côte à côte, et, de deux
chemins semblables, le plus court. [lists.Ranked] donne cet ordre ;
[Un cas : trouver un fichier à partir de quelques lettres](finding.md) dit pourquoi, et le mesure.

```cesia
[r.Item for r in lists.Ranked("cmt", rows)] --> [3]
[r.Item for r in lists.Ranked("cmd", rows)] --> [2, 3]
```

## Les touches

Pour trouver une touche sans la connaître :

- Appuyez sur une prefix key et attendez une demi-seconde : la bande des hints liste ce qui peut suivre. Sous `C-c`, les
  touches sont en groupes, `C-c f` pour les fichiers et ainsi de suite : voir
  [Fenêtre et panes](windows.md#la-bande-des-hints).
- Appuyez sur `?` après une prefix key, comme `C-x ?`, `C-c ?` ou `C-c f ?` : une liste de chaque touche qui commence par ce
  préfixe, à n'importe quelle profondeur, avec le nom de sa commande et la première ligne de sa documentation. Taper la
  filtre, et Enter ferme la liste et lance la touche sous le curseur, comme si vous l'aviez pressée.

Les touches que seule une liste a, comme `C-c n` dans le gestionnaire de dossiers, ne sont pas dans ces listes.
[Touches](keys.md) a la table entière.

## Les erreurs

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `M-g n`, `C-c c n` | [check.NextError] | le curseur sur l'erreur ou le warning suivant, et ses mots sur la prompt line |
| `M-g p`, `C-c c p` | [check.PreviousError] | le curseur sur celui d'avant |

Les deux font le tour par les bouts : après la dernière vient la première. Un buffer qui n'en a aucune dit
`No error here.` (pas d'erreur ici). [Les erreurs dans les lignes](check.md) dit d'où viennent les erreurs.

## Les endroits dans la sortie

`C-c c o`, ou `C-c C-o`, ouvre la sortie de la dernière exécution comme une liste, avec le curseur sur sa dernière erreur.
Enter sur une ligne qui nomme un endroit d'un fichier ouvre ce fichier, ou va à son buffer, avec le curseur là. Deux formes
nomment un endroit, comme Cesia écrit ses erreurs : `PATH:LINE:COLUMN: ` au début de la ligne, l'endroit d'une erreur, et
`(PATH:LINE)` à sa fin, l'endroit d'un appel sous elle. [output.PlaceIn] les lit, avec des colonnes comptées à partir de 1 :

```cesia
use src/output
output.PlaceIn("src/a.ce:4:11: Index 5 is outside this array of 2 elements.") --> {Path: "src/a.ce", Line: 4, Column: 11}
output.PlaceIn("  called from f (a.ce:3)") --> {Path: "a.ce", Line: 3, Column: 1}
output.PlaceIn("> cesia run a.ce") --> missing
```

Une ligne qui ne nomme aucun endroit dit `This line names no place of a file.` (cette ligne ne nomme aucun endroit d'un
fichier), et un fichier qui n'est pas là dit `PATH isn't there.` (PATH n'est pas là). Un chemin se lit à partir du dossier
où Cemacs a démarré, tel que Cesia l'a écrit.
