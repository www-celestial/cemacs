# Fenêtre et panes

Cemacs a une seule fenêtre, celle que montre votre système. Ce chapitre en décrit les parties : les panes, qui montrent des
buffers côte à côte ou l'un au-dessus de l'autre, la mode line de chaque pane, la sortie, la prompt line et la bande des
hints. Emacs emploie d'autres mots pour deux d'entre elles : il appelle la fenêtre du système une frame, et chaque pane une
window. Cemacs garde les mots du reste du bureau : la fenêtre (window) et le pane.

```cesia fold=code
use core/panes
use core/press
use core/text
use core/view
use src/emacs
use src/ui
use std/value

defn editor(width, height)
  (** The editor with one empty buffer and the Emacs keys, in a window of this size, with characters 8 by 19 pixels. *)
  s = view.Start([text.Of("", missing)], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, width, height)
  s.Config = () -> emacs.Config(emacs.Keys)
  s
end
```

## La fenêtre

La fenêtre s'ouvre à 1280 sur 720 pixels, ou à la taille du `Window` de votre config, et vous pouvez changer sa taille
ensuite. Son titre est le nom du buffer courant. Elle est découpée, de bas en haut, en :

| Partie | Hauteur | Ce qu'elle montre |
|---|---|---|
| la prompt line | 22 pixels | le dernier message, une question en train d'être posée, le filtre d'une liste, ou l'erreur sous le curseur |
| la sortie | une fois qu'un programme a tourné : un tiers de la hauteur au-dessus de la prompt line, après qu'on lui a retiré 24 pixels | ce que le programme a affiché, ou ses variables à un arrêt |
| les panes | le reste | les buffers, chaque pane avec sa mode line en bas |

[view.Layout] calcule ces rectangles, chacun `{X, Y, Width, Height}` depuis le coin en haut à gauche de la fenêtre, à
partir de sa taille et de la taille d'un caractère de la police du code :

```cesia
lay = view.Layout(800, 600, {Width: 8, Height: 19}, true)
[lay.Area.Height, lay.Output.Height, lay.Prompt.Height] --> [394, 184, 22]
```

Le thème est sombre, [ui.Dark] de `src/ui`, à moins que le `Theme` de votre config n'en donne un autre, comme [ui.Light] ;
la fenêtre le lit une fois, quand elle s'ouvre, comme elle lit sa taille : [Modifier Cemacs](customising.md#les-réglages) dit
les deux. Le texte est dessiné avec trois polices, à la taille de [emacs.FontSize] : Adwaita Sans pour la mode line, la
prompt line et les noms dans la bande des hints, Noto Sans Medium pour le titre de la sortie, et JetBrains Mono pour le code,
les numéros des lignes, les touches dans la bande et la sortie elle-même.

## Les panes

Un pane montre un buffer, avec une colonne de numéros de ligne à sa gauche et sa mode line en bas. Au début, il y a un seul
pane, qui remplit la place des panes.

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-x 2`, `C-c w s` | [commands.SplitBelow] | coupe en deux le pane que vous modifiez, l'un au-dessus de l'autre |
| `C-x 3`, `C-c w v` | [commands.SplitRight] | le coupe en deux, côte à côte |
| `C-x o`, `C-c w o` | [commands.NextPane] | va au pane suivant, du dernier au premier |
| `C-x 0`, `C-c w d` | [commands.ClosePane] | ferme le pane que vous modifiez |
| `C-x 1`, `C-c w m` | [commands.OnlyPane] | ne garde que le pane que vous modifiez |

Une coupe donne à chaque moitié sa moitié du pane, et à la seconde le pixel impair. Les deux moitiés montrent le même buffer
au même endroit, et vous restez dans la première. Chaque moitié doit avoir de la place pour 2 lignes de 8 caractères : sinon
rien n'est coupé, et la prompt line dit `This pane is too small to split.` (ce pane est trop petit pour être coupé). Un trait
de couleur sépare deux panes côte à côte.

Les panes forment un arbre, une structure où chaque coupe a deux branches, et où chaque branche est à son tour une coupe ou
un seul pane, une feuille de l'arbre. Une coupe est `{Along, First, Second}`, où `Along` vaut `"rows"` pour l'un au-dessus
de l'autre et `"columns"` pour côte à côte ; une feuille est `{Buffer, View}`, le numéro de son buffer et l'endroit qu'elle
montre. Les panes se comptent à partir de 1, dans l'ordre des feuilles depuis le haut à gauche, et `C-x o` suit cet ordre.
Couper vers le bas, puis couper la moitié du haut vers la droite, donne trois panes :

```cesia
s = press.Press(["C-x", "2", "C-x", "3"], editor(800, 600))
panes.Count(panes.Tree(s)) --> 3
[r.Width for r in panes.Rects(view.Layout(800, 600, {Width: 8, Height: 19}, false).Area, panes.Tree(s))] --> [400, 400, 800]
```

Fermer un pane donne sa place à l'autre branche de sa coupe, et vous modifiez le pane qui est alors à son numéro, ou le
dernier. Le dernier pane ne peut pas être fermé : `This is the only pane.` (c'est le seul pane).

### Deux panes sur un même buffer

Le texte appartient au buffer : une modification se voit donc dans chaque pane qui le montre. L'endroit appartient au pane :
chaque pane a son propre curseur, sa mark et son écran, si bien que deux panes sur un même fichier en montrent deux endroits.
Le pane que vous modifiez garde son endroit dans le buffer lui-même, et chaque commande y travaille ; chaque autre pane garde
son endroit dans sa feuille, et aller à lui les échange.

L'endroit qu'un autre pane garde est une ligne et une colonne : il ne bouge pas avec les lignes ajoutées ou enlevées
au-dessus de lui, comme Emacs déplace le point de chaque window. Quand le texte a changé sous lui, il est ramené à
l'intérieur du texte au moment d'être dessiné. Un buffer qu'aucun pane ne montre garde l'endroit où on l'a laissé.

### Quel pane vous modifiez

Le pane que vous modifiez a une bande de couleur sur la ligne de son curseur, un curseur vif, et une mode line plus claire ;
un autre pane montre son curseur d'une couleur pâle, et sans bande. Un clic dans un pane, dans son code ou sa mode line, en
fait celui que vous modifiez. La molette fait défiler le pane sous la souris sans en faire celui que vous modifiez.

## L'écran d'un pane

Un pane montre les lignes à partir de sa ligne du haut, autant qu'il en tient. Il ne renvoie jamais une ligne à la ligne :
une ligne plus longue que le pane est coupée à son bord, comme le fait Emacs avec `truncate-lines`. L'écran suit le curseur,
et bouge aussi peu qu'il peut : quand le curseur passe sous la dernière ligne montrée, cette ligne devient la dernière ;
au-dessus de la première, la première. Il en va de même sur le côté, où un curseur passé au-delà du bord droit déplace
l'écran vers la droite.

Après la molette, l'écran reste là où on l'a mis, même avec le curseur hors de vue, jusqu'à ce qu'une touche, un texte tapé
ou un clic ramène l'écran au curseur.

La colonne de gauche contient le numéro de chaque ligne ; elle fait 62 pixels de large avec ses marges. Une ligne avec une
erreur ou un warning a son numéro en rouge ou en ambre, et un breakpoint est un point de couleur avant le numéro : voir
[Les erreurs dans les lignes](check.md) et [Exécuter et déboguer](running.md).

## La mode line

Chaque pane a une mode line en bas, une ligne qui dit l'état de son buffer. Emacs a la même, sous le même nom, où il nomme
aussi les modes du buffer. Depuis la gauche :

- le nom du buffer, suivi de ` *` quand son texte n'est pas enregistré ;

et depuis la droite :

- le langage : `Cesia` pour un buffer de texte, `List` pour une liste. Chaque buffer de texte est coloré comme du Cesia,
  quelle que soit la fin du nom de son fichier ; seule la vérification des erreurs regarde la fin `.ce` ;
- l'endroit du curseur, `line:column` (ligne, deux-points, colonne), la colonne comptée à partir de 0 ;
- le nombre des erreurs et des warnings que la vérification a trouvés, comme `2 errors, 1 warning` (2 erreurs, 1 warning),
  en rouge quand il y a une erreur, en ambre quand il n'y a que des warnings. [view.MarkCount] fait les mots.

```cesia
view.MarkCount(text.WithMarks([{Line: 1, Column: 0, End: 1, Severity: "error", Message: "m", Hint: missing}], text.Of("a", "a.ce"))) --> "1 error"
```

## La prompt line

La ligne en bas de la fenêtre, sous tous les panes, est l'endroit où Cemacs vous parle et vous demande des choses. Emacs
sépare cela en deux mots : l'echo area, où s'affichent les messages, et le minibuffer, où vous tapez une réponse. La prompt
line de Cemacs est les deux, mais ce n'est pas un buffer : une réponse se tape et s'efface à son bout seulement, et aucun des
déplacements d'un buffer n'y marche.

Elle montre, la première chose qui s'applique :

1. une question et la réponse en train d'être tapée, avec une barre après elle : `Find file: src/` ;
2. sinon le dernier message, comme `Saved notes.ce` ou `C-t is not bound.` ;
3. sinon, dans une liste, les mots avant son filtre, `Filter: ` (filtre) ou le chemin d'un dossier, et ce que vous avez
   tapé ;
4. sinon l'erreur ou le warning sous le curseur, ou à défaut le premier de la ligne du curseur, avec son hint, dans sa
   couleur.

Un message dure jusqu'à la touche ou au clic suivant. Pendant qu'une prefix key attend la touche qui la suit, la prompt line
la montre avec un tiret, comme `C-x -`, à la façon dont Emacs affiche en écho une key sequence.

Une question qui attend `y` ou `n`, comme `Text not saved. Quit anyway? (y or n)`, attend l'une des deux lettres, en
majuscule ou en minuscule, et ignore les autres ; `C-g` la ferme sans réponse. Toute autre question se termine par Enter.

## La bande des hints

Quand une prefix key attend pendant [emacs.HintDelay] secondes, une demi-seconde, une bande s'ouvre au-dessus de la prompt
line. Elle liste chaque touche qui peut suivre, avec la commande qu'elle lance ou, pour un groupe, son nom après un `+` :
`C-c` montre `f +files`, `b +buffers` et les autres groupes, et `C-c f` montre `f FindFile`, `s Save`, et ainsi de suite.
Les touches sont de la couleur des mots-clés et les groupes de la couleur d'accent du thème, un bleu, en colonnes qui se
lisent de haut en bas. La touche suivante la ferme. [keys.Hints] donne ses rangées :

```cesia
use core/keys
use std/text as str
keys.Hints("C-c", {"C-c f": "files", "C-c f f": str.Lower, "C-c q": str.Upper}) --> [{Key: "f", Name: "+files", Group: true}, {Key: "q", Name: "Upper", Group: false}]
```

Le nom d'une commande est son nom dans le code, sans son package : `FindFile` pour [commands.FindFile]. Une fonction sans
nom, écrite sur place comme `s -> ...`, s'affiche `a function` (une fonction). Emacs montre une telle bande avec
`which-key-mode`, qui fait partie d'Emacs depuis sa version 30, et Doom Emacs l'active.

## La sortie

Une fois qu'un programme a tourné, la sortie prend le tiers du bas de la fenêtre, au-dessus de la prompt line. Son titre
est `Output` (sortie), ou `Variables` pendant que le programme est arrêté, suivi de l'état du programme, comme `running` (en
cours) ou `ended, code 0` (terminé, code 0). Elle montre les dernières lignes qui tiennent, chacune coupée au bord.
`C-c c h` la cache, ou la montre à nouveau. [Exécuter et déboguer](running.md) dit ce qu'elle contient.
