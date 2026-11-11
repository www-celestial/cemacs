# À l'intérieur de Cemacs

Ce chapitre dit comment Cemacs est construit : l'état et sa mise à jour, la rope qui contient le texte d'un buffer,
l'historique d'annulation, les couleurs, la frame, la boucle des événements, et le démarrage. Il est pour le lecteur qui veut
changer le core, ou savoir ce que coûte chaque opération. Le code fait 6 201 lignes de Cesia dans `core/` et `src/`, sans
leurs tests, et chaque fichier peut se lire seul.

## L'état, la mise à jour et la vue

Cemacs est une valeur et deux fonctions :

- l'état, une map qui contient tout : les buffers, lequel est courant, les panes, la question posée, le message, le
  programme qui tourne, la taille de la fenêtre, la config ;
- [commands.Update], qui prend un événement et l'état et donne l'état suivant, ou `missing` quand l'éditeur se termine ;
- [view.View], qui prend l'état et donne la frame : un array (une liste) de commandes de dessin, chacune une map comme
  `{Kind: "text", X, Y, Text, Color, Font}`.

La boucle de la fenêtre, [sdl.Run], lit les événements, appelle la mise à jour sur chacun, et dessine la vue. Rien d'autre
ne contient l'état de l'éditeur : pas de variable globale, pas d'objet qui change. C'est la forme que le langage Elm a fait
connaître sous le nom d'Elm architecture : un modèle, une mise à jour et une vue.

Le core, dans `core/`, est pur là où il peut l'être : [core/text], [core/color], [core/keys], [core/view], [core/lists] et
[core/panes] prennent des valeurs et donnent des valeurs, et ne touchent à aucun fichier ni à aucune fenêtre. Une fonction
pure est une fonction dont le résultat ne dépend que de ses arguments, et qui ne change rien au-dehors : elle peut se tester
avec de simples valeurs, comme le font les exemples de ce livre. [core/files], [core/run] et le presse-papiers touchent le
dehors, en aussi peu d'endroits qu'ils peuvent.

Chaque valeur de Cesia est immutable (elle ne change jamais une fois faite) : `s.Buffers[k] = b` donne au nom `s` un nouvel
état, qui partage avec l'ancien chaque partie qu'il n'a pas changée. Partager ainsi les parties s'appelle le structural
sharing, et une structure qui garde ses anciennes versions entières est une persistent data structure. C'est ce qui rend les
sections suivantes peu coûteuses : une copie d'un état, ou du texte d'un buffer, ne coûte rien, si bien que l'historique
d'annulation garde des textes entiers, et que deux panes gardent deux endroits d'un même buffer.

### Les champs

[view.Start] fait le premier état ; ses champs sont `Buffers`, `Current`, `Pending` (les prefix keys qui attendent),
`Prompt` (la question posée, ou `missing`), `Message`, `Run` (le programme, ou `missing`), `Window`, `Width`, `Height`,
`Cell` (la taille d'un caractère de la police du code), `Look` (le thème et les largeurs des polices), `Clip` (le
presse-papiers quand il n'y a pas de fenêtre), `Chorded`, `Chain` (true après `C-k`), `Dragging`, `Pressed`, `Wheel`,
`Ending`, `Title`, `Config`, `Home` (le dossier de Cemacs), `Second`, `Panes`, `Pane`, `Waited`, `Hints` et `Chords`. Du code
plus tardif a ajouté `Still`, `Breaks` et `Checking`, lus par un `match` avec une valeur par défaut, pour la raison que donne
[Modifier Cemacs](customising.md#recharger-cemacs-pendant-qu-il-tourne).

Un buffer, fait par [text.Of], contient `Rope` (son texte), `Cursor`, `Mark`, `Origin` (ce qui a posé la mark : `"key"`,
`"shift"`, `"mouse"`, ou `""`), `History`, `Version`, `Clock`, `Saved`, `Path`, `Disk` (la taille et l'heure de son fichier
au moment de la lecture), `Top` et `Left` (la première ligne et la première colonne à l'écran), `Colors`, `Guess` (les états
des couleurs devinés pour un écran au-delà de ceux qui sont connus, ou `missing`), `Screen` (ce que la vue garde des lignes
de l'écran d'une frame à la suivante), `Wanted` (la goal column), `Typing`, `Free` (true après la molette), `Marks` (les
erreurs de la vérification) et `MarksNote` (des mots pour la mode line quand il n'y en a pas, comme la raison pour laquelle
le texte n'a pas été vérifié) ; une liste a aussi `List`, et la vérification ajoute `Checked`, la version qu'elle a lue.

Un buffer est modifié quand sa `Version` diffère de `Saved`. Chaque modification prend un nouveau numéro à `Clock`, qui ne
recule jamais, si bien que deux textes différents ne partagent jamais un numéro, et l'annulation ramène le numéro de l'état
auquel elle revient : comparer deux numéros dit si le texte est celui qui est enregistré, là où comparer deux textes
coûterait un passage sur les deux.

## La rope

Le texte d'un buffer est une rope, [src/rope] : un arbre binaire dont les feuilles contiennent des morceaux du texte et dont
les nœuds internes joignent deux ropes, le texte de celle de gauche d'abord. Chaque nœud garde trois nombres sur le texte
qui est sous lui : `Size`, ses octets ; `Lines`, ses fins de ligne ; et `Height`, le plus long chemin jusqu'à une feuille.
Boehm, Atkinson et Plass ont décrit les ropes en 1995, d'après leur emploi dans le système Cedar au Xerox PARC, comme une
autre solution que les strings (les textes) tenus dans un seul bloc de mémoire, où joindre deux textes copie les deux : voir
[Références](references.md).

Une feuille ne contient pas ses octets : c'est une vue d'un texte, `{Text, Start, Size, Lines}`, les `Size` octets de `Text`
à partir de l'octet `Start`, et les fins de ligne parmi eux. Le texte est gardé par référence : un fichier lu sur le disque
est un seul texte de Cesia, et toutes les feuilles faites à partir de lui en voient des parties, sans que ce texte soit
jamais copié ni changé ; un texte tapé ou collé est un texte à lui. C'est l'idée de la piece table, que Crowley a trouvée la
meilleure de six structures pour le texte d'un éditeur, en 1998 : le fichier lu n'est jamais copié, une modification ne fait
qu'ajouter des morceaux ; le piece tree de Visual Studio Code, en 2018, a mis les morceaux dans un arbre équilibré dont les
nœuds comptent les octets et les fins de ligne qui sont sous eux, comme le fait la rope de Cemacs.

```cesia
use src/rope
r = rope.Of("one\ntwo\nthree")
[rope.Size(r), rope.LineCount(r), rope.LineStart(2, r), rope.Line(3, r)] --> [13, 3, 4, "three"]
```

Les positions comptent les octets à partir de 0, les lignes se comptent à partir de 1. Chaque opération descend l'arbre en
suivant ces nombres :

- [rope.SplitAt], les octets avant une position et les autres, descend par les tailles, et joint ce qu'il passe sur le chemin
  du retour ; une feuille qu'il coupe devient deux vues du même texte, et seules les fins de ligne de la première sont
  comptées.
- [rope.JoinRopes] met deux ropes l'une après l'autre. Deux vues qui se touchent dans le même texte, la seconde commençant là
  où la première finit, deviennent une seule vue si elles contiennent au plus 16 KiB ensemble ; deux feuilles courtes
  d'autres textes dont les octets tiennent en 1 024 deviennent une seule feuille, une copie des deux.
- [rope.Insert] est une coupe, puis deux jointures ; [rope.Delete], deux coupes et une jointure.
- [rope.LineStart] trouve l'octet où commence la ligne n en descendant par les nombres de fins de ligne, puis, dans la vue
  qu'il atteint, compte les fins de ligne de ses blocs de 2 KiB jusqu'à celui qui la contient, et ne cherche que dans ce
  bloc.
- [rope.Slice], le texte entre deux positions, et [rope.Text], le texte entier, visitent les feuilles entre elles, dans
  l'ordre, et joignent les parties qu'elles voient : ils ne font aucun nœud, si bien que lire les lignes de l'écran ne fait
  que lire l'arbre. Une slice à l'intérieur d'une seule vue, et le texte entier d'une rope dont les vues couvrent encore un
  seul texte de son premier octet à son dernier, comme après une ouverture ou après une annulation qui y revient, sont ce
  texte ou une partie de lui, sans jointure : enregistrer un fichier qui n'a pas changé, ou le vérifier, ne copie rien.

L'arbre est gardé équilibré comme l'est un arbre AVL, d'après Adelson-Velsky et Landis : à chaque nœud, les hauteurs des deux
côtés diffèrent d'au plus un. Une jointure de deux ropes de hauteurs très différentes descend le côté de la plus haute, et
remet en équilibre chaque nœud qu'elle reconstruit avec une rotation ou deux, une rotation étant le tour de trois nœuds qui
raccourcit le côté le plus haut. Un arbre équilibré de $n$ feuilles a une hauteur d'au plus environ $1{,}44 \log_2 n$ :
une coupe, une jointure, une insertion, un effacement et la recherche d'une ligne visitent donc $O(\log n)$ nœuds ; leur coût
croît avec le logarithme de la taille, et doubler le texte ajoute environ un niveau. L'article sur les ropes cite les arbres
AVL comme une façon de rendre ces opérations logarithmiques ; ses propres ropes se joignent plutôt en temps constant, et ne se
rééquilibrent que quand un arbre devient plus profond qu'une borne. Cemacs garde l'équilibre AVL à chaque jointure, et, comme
le fait l'article, fait une seule feuille de deux feuilles courtes jointes, et ne copie que les nœuds le long du chemin d'une
modification. À l'intérieur d'une feuille, le travail porte sur au plus 16 KiB, par blocs de 2 KiB. Le texte entier d'un
buffer modifié, `rope.Text`, coûte $O(n)$, et l'éditeur ne le demande que pour enregistrer ou pour vérifier.

[rope.Of] fait une rope à partir d'un texte entier, comme un fichier qu'on vient de lire : il découpe des vues de 16 KiB
l'une après l'autre, la dernière plus courte, sans copier un octet, puis les met sous des nœuds deux par deux, niveau par
niveau, et joint une rope impaire restante avec [rope.JoinRopes], qui garde l'équilibre. Chaque vue compte ses fins de
ligne, ses `Lines`, avec le [text.Count] de Cesia, huit octets à la fois, sur des slices de 2 KiB qui sont faites et
jetées jeunes : le minor heap d'OCaml (la zone de mémoire des valeurs jeunes) les libère à sa minor collection suivante,
sans coût pour chaque valeur morte. Un fichier de 99,9 MB fait 6 097 vues et autant de nœuds. La taille d'une vue pèse
deux coûts : Cesia fait un record en quelques centaines de nanosecondes, là où C en fait un en quelques-unes, si bien que
moins de records ouvrent un fichier plus vite, tandis qu'une vue plus grande rend plus long de trouver une ligne à
l'intérieur. Mesuré sur 99,9 MB, $n = 7$ : [rope.Of] en 105 ms [104 ; 118] avec des vues de 16 KiB, là où des feuilles de
1 024 octets, chacune une copie, ont pris 258 ms [256 ; 352] ; des vues de 4 et de 64 KiB, mesurées à côté de celles de
16 KiB avec un Cesia plus ancien, ont pris 117 et 89 ms contre 94 ; et trouver une ligne dans une vue de 64 KiB compte
jusqu'à 32 blocs de 2 KiB au lieu de 8. Une modification au hasard peut laisser une petite feuille, jusqu'à quelques octets,
qu'une jointure plus tardive peut fusionner.

Une rope est persistante : une modification fait de nouveaux nœuds le long d'un chemin, $O(\log n)$ d'entre eux, et partage
chaque autre nœud avec la rope d'avant, qui reste entière : cette façon de rendre un arbre persistant s'appelle le path
copying. Une vue garde en vie son texte entier, même quand une modification a effacé l'essentiel de ce qu'elle montrait ;
l'historique d'annulation garde ce texte de toute façon, comme il garde les états d'avant la modification.

```cesia
before = rope.Of("abc")
after = rope.Insert(1, "X", before)
[rope.Text(before), rope.Text(after)] --> ["abc", "aXbc"]
```

### Pourquoi une rope

GNU Emacs garde un buffer dans un gap buffer : un seul bloc de mémoire avec un trou à l'endroit de la dernière modification,
si bien que taper là remplit le trou et ne coûte rien, tandis qu'une modification lointaine déplace d'abord le trou, et
copie les octets entre les deux. Une rope coûte quelques visites de nœuds pour chaque modification, où qu'elle soit, et rend
les copies gratuites. Cemacs a besoin de copies : chaque état de l'historique d'annulation est un texte entier, et chaque
état de l'éditeur contient chaque buffer, à chaque événement. Avec un gap buffer, chacun copierait le texte ; avec une rope,
chacun le partage.

Le curseur est une ligne et une colonne, comptées en caractères ; la rope compte des octets. [core/text] ne passe de l'un à
l'autre qu'à une modification, à l'intérieur d'une ligne : le début de la ligne d'après la rope, puis les octets des
caractères avant la colonne. Un caractère UTF-8 prend de un à quatre octets : cela coûte donc la longueur de la ligne, pas
celle du texte.

## L'historique d'annulation

[src/history] garde les états passés, le présent, et les futurs, ceux qu'on a annulés et que rétablir peut ramener :

```cesia
use src/history
h = history.Record(2, history.Record(1, history.Of(0)))
[history.Current(history.Undo(h)), history.Current(history.Redo(history.Undo(h)))] --> [1, 2]
```

Chaque état de l'historique d'un buffer contient la rope, le curseur, la version, l'endroit du curseur avant l'étape, et la
première ligne que l'étape a changée. Annuler recule d'un état, et remet le texte, la version et le curseur d'avant l'étape ;
rétablir avance. Enregistrer un nouvel état oublie les futurs : l'historique est donc une ligne, pas un arbre, et il garde au
plus 1 000 états passés, en oubliant les plus anciens. Comme les ropes partagent leurs nœuds, 1 000 états d'un grand fichier
ne coûtent guère plus que le texte lui-même et les nœuds que les modifications ont faits.

Un caractère tapé après un autre, dans la même étape de frappe, remplace le dernier état au lieu d'en ajouter un : c'est
ainsi qu'un mot devient une seule étape d'annulation, comme le dit [Édition](editing.md#annuler-et-rétablir).

## Les couleurs

[core/color] lit une ligne à la fois, et donne ses tokens, les morceaux de la ligne chacun avec son rôle : mot-clé, nom
appelé, texte, nombre, commentaire, champ après un point, ou rien de particulier. Ensemble, les tokens contiennent chaque
caractère de la ligne, dans l'ordre : la frame les dessine l'un après l'autre. C'est un lexer, la première étape de la
lecture du code, qui le découpe en mots ; il ne lit que des mots, et ne connaît aucune structure.

```cesia
use core/color
color.Tokens("defn f() (* a", color.FirstState).Tokens --> [[1, "defn"], [6, " "], [2, "f"], [6, "() "], [5, "(* a"]]
color.Tokens("defn f() (* a", color.FirstState).State --> {Comment: 1, Text: false}
```

Une ligne ne se tient pas seule : un commentaire `(* ... *)` peut s'étendre sur plusieurs lignes et en contenir un autre, et
un texte peut courir sur plusieurs lignes. Le lexer prend donc l'état au début d'une ligne, la profondeur de commentaires où
il est et s'il est dans un texte, et donne l'état à sa fin. Un éditeur doit colorer du code cassé, puisqu'il est en train
d'être écrit : ce lexer ne s'arrête jamais sur une erreur, et un texte ou un commentaire pas fini ne fait que porter son état
jusqu'à la ligne suivante.

Chaque buffer garde l'état au début de chaque ligne, connu jusqu'à une certaine ligne, [color.StartOf]. Une modification à
la ligne n oublie les états après n ; le dessin ne les relit que jusqu'à la dernière ligne de l'écran, et une ligne sans
guillemet et sans marque de commentaire n'est même pas lue, puisqu'elle ne peut pas changer l'état. Taper à la ligne
19 000 d'un fichier ne lit donc que les lignes de l'écran, et un saut à la fin d'un grand fichier lit chaque ligne une fois,
la première fois.

Les états sont gardés en chunks (en morceaux) de 1 024 lignes, une liste de listes : oublier les lignes après une
modification garde les chunks d'avant et en coupe un, et lire plus de lignes remplit le dernier chunk et en ajoute de
nouveaux. Chaque opération coûte le nombre de chunks plus un chunk, là où une liste plate d'un état par ligne était coupée et
prolongée par des copies de chaque état d'avant la modification : à la ligne 1 416 745 d'un fichier de 99,9 MB, 1 384 chunks
au lieu de 1,4 million d'états, et une touche à cet endroit est passée d'environ 40 ms à environ 1 ms. GNU Emacs garde le
cache de son `syntax-ppss`, l'état de son parser (la partie qui lit la structure du code) à des endroits du buffer, clairsemé
pour la même raison : ses entrées sont espacées d'au moins `syntax-ppss-max-span`, 20 000 caractères.

Cette lecture n'a besoin que de l'état, pas des mots : elle ne passe donc pas par le lexer. [color.StateAfter] donne l'état à
la fin d'une ligne en sautant de marque en marque, chacune cherchée en code natif avec [text.ByteFind]. Dans un commentaire,
il cherche le prochain `(*` ou `*)`, car les commentaires s'emboîtent ; dans un texte, le prochain guillemet, un guillemet
doublé `""` et le caractère après une barre oblique inverse faisant partie du texte ; ailleurs, le prochain guillemet ou
`(*`. Les lignes viennent 100 000 à la fois, une seule slice de la rope coupée à ses fins de ligne. L'état est celui que donne
le lexer, et un test le vérifie sur 2 000 lignes au hasard, à partir de chaque sorte d'état :

```cesia
color.StateAfter("x = \"a (* b", color.FirstState) --> {Comment: 0, Text: true}
color.StateAfter("a *) \"b\"", {Comment: 1, Text: false}) --> {Comment: 0, Text: false}
```

### Un endroit lointain d'abord, ses couleurs exactes ensuite

Un saut loin des couleurs connues, `M->` à la fin d'un fichier de 99,9 MB, ou une recherche qui trouve son mot là-bas,
lirait les états de millions de lignes avant de pouvoir dessiner : environ 4 s. [view.Follow] lit donc au plus
[view.ColorBatch] lignes d'un coup, 25 000, environ 35 ms ici, bien en dessous du dixième de seconde en deçà duquel une
personne voit une réponse comme immédiate. Quand l'écran est plus loin que cela, il est dessiné tout de suite avec ses états
devinés, `Guess` : à partir du dernier état connu, comme si aucun commentaire ni aucun texte ne s'ouvrait dans les lignes
entre les deux, puis portés le long des lignes de l'écran. Tant qu'un pane montre des couleurs devinées, l'éditeur demande des
ticks, [view.Colouring], et chaque tick lit [view.ColorBatch] lignes de plus, jusqu'à ce que les couleurs connues atteignent
l'écran, qui est alors redessiné avec ses couleurs exactes. Un commentaire qui s'ouvre loin au-dessus peut rendre fausses les
couleurs de l'écran pendant ces secondes ; rien d'autre n'est deviné. C'est ce que fait le jit-lock d'Emacs par ses propres
moyens : il colore à la demande la partie du buffer que montre l'écran, et, avec `jit-lock-contextually`, la colore à
nouveau après une pause d'après le vrai contexte des lignes du dessus.

## La frame

[view.View] fait la frame à partir de l'état : un effacement de la fenêtre, puis chaque pane, son code, sa mode line et le
trait entre les panes, puis la sortie, la bande des hints et la prompt line. Elle ne lit que les lignes de l'écran, coupées
aux colonnes qui tiennent : un grand fichier ne coûte donc pas plus à dessiner qu'un petit. Elle ne fait que lire :
[view.FollowState], que la mise à jour appelle en dernier, est le seul endroit qui déplace l'écran de chaque pane pour garder
son curseur en vue, et qui prolonge les couleurs connues jusqu'à la dernière ligne montrée.

La frame est refaite entière à chaque événement, à partir de l'état : le programme dit quoi dessiner, pas ce qui a changé.
C'est la façon d'une interface en immediate mode, comme on l'appelle, où aucun widget (élément d'interface) ne garde un état à
lui d'une frame à l'autre. Ce qui coûte à faire est gardé en dessous, rangé par ce à partir de quoi c'est fait, si bien que
le garder ne change jamais ce qui est dessiné :

- [view.Follow] garde, dans le `Screen` du buffer, les tokens de chaque ligne de l'écran sous le texte de la ligne, avec la
  largeur à laquelle elle a été coupée et l'état des couleurs à son début. La vue lit les lignes de l'écran avec une seule
  slice de la rope, et ne prend les tokens d'une ligne dans `Screen` que si son texte, sa largeur et son état sont les mêmes ;
  sinon, elle les lit elle-même. Une touche tapée relit les tokens d'une ligne, une ligne qui défile ceux de la ligne qui
  entre. C'est l'idée du `Html.Lazy` d'Elm, qui ne refait pas la vue d'une partie dont les arguments sont les mêmes qu'à la
  frame d'avant ; Elm les compare par référence, Cemacs par valeur, pour qu'un état changé après le dernier follow soit quand
  même bien dessiné. Un test fait des modifications au hasard à des endroits au hasard, ne fait le follow qu'après certaines
  d'entre elles, et compare les frames dessinées avec et sans les rangées gardées.
- [src/sdl] garde les objets de texte de SDL3_ttf, chacun passé une seule fois par le shaping, rangés par la police et les mots
  qu'ils contiennent : le shaping, le travail de HarfBuzz, qu'appelle SDL3_ttf, qui fait des lettres d'un texte les glyphes de
  la police et leurs places, est fait quand un texte apparaît pour la première fois, et une ligne qui bouge à l'écran est
  dessinée à partir de l'objet fait avant. Jusqu'à 8 192 objets sont gardés ; au-delà, tous sont oubliés et refaits à mesure
  que les frames en ont besoin.

Les frames attendent le rafraîchissement de l'écran, que SDL appelle vsync : Cemacs ne dessine donc aucune frame que l'écran
ne peut pas montrer.

## La boucle des événements

[sdl.Run] est une boucle des événements, une event loop :

1. Elle prend chaque événement qui attend : une touche, un texte, la souris, un changement de taille, la fenêtre fermée. Un
   signal TERM ou INT qui demande au programme de se terminer arrive comme la fenêtre fermée.
2. Elle appelle la mise à jour sur chacun, dans l'ordre.
3. Si l'état demande des frames à lui, [commands.Moving], elle donne à la mise à jour un tick, un événement `{Kind: "tick",
   Seconds}` avec le temps depuis le dernier tour, au plus 0,05 seconde pour que rien ne saute après une pause, puis dessine
   une frame, et laisse tourner les autres fibers.
4. Sinon, elle ne dessine une frame que si un événement est arrivé, puis dort dans SDL jusqu'à ce que l'événement suivant
   arrive, `SDL_WaitEventTimeout`, pendant au plus 250 millisecondes, [sdl.RestMs] ; puis les autres fibers tournent, et la
   boucle recommence.

Un éditeur immobile ne dessine rien, et se réveille environ quatre fois par seconde. Pendant qu'il dort, le processus est
bloqué dans le système : il attend sur la connexion à l'affichage, un file descriptor (le numéro par lequel un programme
désigne un fichier ou une connexion ouverts), jusqu'à ce que le display server (le programme qui gère l'écran, comme Wayland
ou X11) y écrive un événement, comme GNU Emacs, Vim et Neovim attendent dans `select` ou `poll` sur leur terminal. Un
événement le réveille tout de suite : une touche est donc lue environ 0,7 ms après avoir été envoyée, voir
[Vitesse](performance.md#au-repos). La borne de 250 ms est pour les fibers de Cesia, qui ne peuvent pas réveiller SDL :
pendant que l'éditeur dort dans SDL, aucune fiber ne tourne, et Cesia n'a aucun moyen de dire quand la suivante doit tourner.
Les fibers de Cemacs lui-même, une vérification et la sortie d'un programme, tournent pendant que l'état demande des frames :
la borne ne retarde donc que ce que rien n'attend, un rechargement sous `--watch` que personne ne regarde encore, une fiber
d'une app qui ne demande pas de frames. Le dummy driver de SDL, qu'emploient les tests, ne peut pas attendre un événement :
là, SDL en cherche un lui-même toutes les millisecondes. L'état demande des frames pendant qu'une prefix key attend que la
bande des hints s'ouvre, ce qui demande de compter le temps ; pendant qu'une vérification tourne ou qu'un buffer est à
vérifier ; pendant qu'un programme tourne, dont la sortie arrive à chaque tour ; et pendant qu'un pane montre des couleurs
devinées, dont chaque tick lit un peu plus.

La vérification et la sortie du programme attendent dans des fibers. Une fiber est une tâche de Cesia qui tourne à côté des
autres dans le même programme, et prend son tour avec elles : une fiber attend que `cesia check` se termine, une autre lit ce
que le programme écrit, et chacune envoie ce qu'elle a reçu sur un channel, une file d'attente entre fibers. À chaque tick,
l'éditeur prend ce que contiennent les channels sans attendre, si bien que la frappe ne les attend jamais. Le livre de Cesia
décrit les fibers et les channels dans son chapitre sur les fibers.

### D'une touche à une commande

Une touche passe par ces étapes, dans [commands.Update] :

1. [keys.Chord] fait son chord, ou rien pour une touche qui ne fait que taper : son événement de texte vient ensuite et la
   tape.
2. Avec une question ouverte, le chord va à [emacs.PromptKeys] ; dans une liste, à ses touches ; sinon, à la keymap globale.
3. [keys.Lookup] le trouve, avec les prefix keys qui attendent : une commande, un préfixe qui attend la suite, ou rien.
4. La commande tourne sur l'état. Si ce n'était pas [commands.CutLine], la chaîne des coupes finit ; dans une liste, une
   commande qui a changé le texte est défaite.
5. [commands.Settled] refait la liste du buffer courant à partir de ses rangées, met le pane que vous modifiez sur le buffer
   courant, déplace les écrans jusqu'à leurs curseurs, et pose le titre de la fenêtre.

## L'enregistrement

[core/files] écrit un nouveau fichier à côté de l'ancien, puis le renomme par-dessus l'ancien. POSIX, la norme des appels
système que suivent Linux et macOS, dit de `rename` que, quand le nouveau nom existe déjà, il continue de mener à l'ancien
fichier ou au nouveau à chaque instant de l'opération, jamais à aucun des deux : aucun lecteur ne voit donc jamais une partie
de l'un ou de l'autre fichier. [Fichiers et buffers](files.md#ne-jamais-perdre-le-texte) dit ce que cela garantit et ce que cela
ne garantit pas.

## Le démarrage

`src/cemacs.ce` appelle [editor.Start] avec la config. Il :

1. prend le dossier de Cemacs dans son premier argument, ou `.` s'il n'y en a pas ;
2. ouvre la fenêtre, 1280 sur 720, avec la police du corps à la taille de [emacs.FontSize], puis ajoute les deux autres
   polices, `strong` et `code` ;
3. mesure la police du code : un caractère est aussi large que `M`, et une ligne aussi haute que `Ag` plus
   [view.LineGap], un pixel ;
4. fait le premier état, avec un buffer vide, puis ouvre les fichiers donnés après le dossier, dans l'ordre : un buffer
   vide auquel rien n'a touché cède sa place au premier ;
5. fait tourner la boucle jusqu'à ce que la mise à jour donne `missing`, puis ferme la fenêtre et donne `Ok(missing)`, que
   `src/cemacs.ce` affiche.

[Vitesse](performance.md) donne le temps que prend tout cela.
