# Cells et résultats

Un fichier de Cesia coupé en *cells* (des cellules : des morceaux de code qui tournent chacun à part) tourne comme un
notebook (un carnet où le code alterne avec ses résultats) : chaque cell tourne seule, et son résultat s'affiche sous elle,
dans le buffer. Une cell commence à une ligne qui ne contient qu'un commentaire commençant par `%%`, comme
`(* %% Data *)` ; les lignes avant la première sont la première cell, en général les uses. Le fichier reste un programme :
`cesia run` le lance depuis le haut et calcule ce que les cells montrent. Le moteur est
[std/cells](https://www-celestial.github.io/cesia-lang/cells.html) de Cesia, dont le chapitre dit les règles ; ce chapitre
dit ce que Cemacs en fait. Les cells sont une app de Cemacs, [src/notebook].

```cesia norun
use std/io
use std/list

(* %% Data *)
n = 1000
xs = [i * i for i in 1..n]

(* %% Mean *)
io.Print("mean of $n squares")
list.Mean(xs)
```

## Les touches

Les touches des cells sont un groupe de `C-c`, `e` pour *execute* (exécuter), que la bande des hints (la bande qui montre
à quoi mène une touche) montre comme elle montre les autres :

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-c e e` | [notebook.RunCell] | lance la cell du curseur, puis chaque cell qui lit, directement ou par d'autres, un nom qu'elle définit |
| `C-c e a` | [notebook.RunAll] | lance toutes les cells, depuis le haut |
| `C-c e i` | [notebook.InsertCell] | écrit un marqueur, `(* %%  *)`, au-dessus de la ligne du curseur, le curseur là où va son titre |
| `C-c e v` | [notebook.ShowVariables] | ouvre `*variables*` à côté : les noms que les cells ont définis |
| `C-c e r` | [notebook.OpenRepl] | ouvre `*repl*` en dessous : un prompt dans la même session que les cells |
| `C-c e s` | [notebook.StopCell] | arrête la cell qui tourne ; les cells qui attendent après elle ne tournent pas |
| `C-c e h` | [notebook.WriteHtml] | écrit la page du fichier à côté de lui, `name.html` |
| `C-c e k` | [notebook.ClearResults] | efface les résultats dessinés ; les noms de la session restent |

Dans `*repl*`, Enter lance ce qui a été tapé, et `M-p` et `M-n` reculent et avancent dans ce qui a été tapé avant ;
partout ailleurs, Enter est un saut de ligne, comme toujours.

## Les résultats sous une cell

Un résultat est dessiné sous la dernière ligne non vide de sa cell, après une fine barre : ce que la cell a affiché, puis
sa valeur, ou son erreur en rouge avec sa ligne, comme `cesia run` la montre. Un graphe de
[std/plot](https://www-celestial.github.io/cesia-lang/graphs.html) est dessiné, haut de 400 pixels et aussi large que le pane (la partie de la fenêtre qui montre un buffer). Une frame (un tableau de données en colonnes) s'affiche comme une table de ses 20 premières rangées et leur nombre, une
matrice comme sa forme et ses 10 × 10 premières valeurs, toute autre valeur comme son texte. Une cell qui tourne montre
`running…` (en cours) et les secondes écoulées ; les cells qui la suivent dans la file montrent `waiting` (en attente). Une
cell qui n'a rien affiché et ne donne aucune valeur ne dessine rien. Chaque partie est coupée à 40 lignes, la dernière
disant combien il en reste.

Un résultat n'est pas du texte : le curseur n'y entre jamais, il n'est jamais enregistré, et une modification ne peut pas
le toucher. Il bouge avec les lignes de sa cell quand vous tapez au-dessus ou dedans, et une demi-seconde après la dernière
touche, il revient sous la dernière ligne de sa cell. L'écran, la souris et le curseur comptent ses rangées : une page
montre moins de lignes quand des résultats y prennent de la place.

## Les graphes

Une cell dont la dernière expression est un graphe, comme `plot.Line(t, y)` ou `plot.Of([...])`, le montre sous son code.
La session calcule sa *scene* (sa scène), les formes du graphe en pixels à la largeur du pane, et Cemacs dessine la scene :
ses lignes aux bords adoucis, ses aires, ses barres, ses marques et ses cases, et ses textes en Noto Sans Medium, la police
avec laquelle std/plot les a mesurés, sans kerning, l'ajustement de l'espace entre deux lettres, et sans hinting (le
calage des lettres sur la grille des pixels), si bien que chaque texte prend la largeur que std/plot lui a donnée. Les
axes, la grille et les textes prennent les couleurs du thème ; les données gardent les leurs. Quand le pane change de
largeur, la session dessine à nouveau la scene à la nouvelle ; le graphe garde sa forme jusqu'à ce qu'elle arrive.
`*repl*` dessine un graphe sous sa réponse de la même façon, et la page de `C-c e h` contient chaque graphe en SVG.

## Ce qui tourne à nouveau

`C-c e e` lit les cells du buffer tel qu'il est, ses changements non enregistrés aussi, et lance la cell du curseur et
celles qui en dépendent, dans l'ordre du fichier : une cell qui a changé et les cells qui utilisent ce qu'elle calcule. Les
autres cells gardent leurs résultats. La première cell, celle des uses, les lance toutes. Une cell qui enfreint une règle
des cells, comme un nom défini dans deux cells ou un nom lu avant sa cell, montre cette erreur à la place d'un résultat, et
ne tourne pas. Une cell qui tourne à nouveau refait ce qu'elle fait en plus de sa valeur : elle affiche à nouveau, et écrit
à nouveau ses fichiers.

## La session

Chaque fichier de cells a une *session* : un processus Cesia, `cesia run --cells`, qui garde les noms que ses cells ont
définis, si bien qu'une cell tourne sans que celles d'avant tournent à nouveau. Elle démarre à la première cell lancée, avec
les permissions de la tâche de `cesia.toml` qui lance le fichier, comme `C-c c r` les donne, ou aucune ; Cemacs la démarre
avec le même `cesia` que celui qui fait tourner Cemacs, ce que `bin/cemacs` permet. Le code d'une cell y tourne aussi vite
que sous `cesia run`.

`C-c e s` arrête la cell qui tourne à sa prochaine attente ou à son prochain checkpoint (un point où le programme peut être
arrêté sans risque), et la session garde les noms définis avant elle. Une cell qui ne s'arrête pas en 2 secondes, comme
une cell à l'intérieur d'un seul long appel à du code natif, termine la session : une nouvelle démarre, et chaque cell
tourne à nouveau depuis le haut, ce que dit la prompt line.

## \*variables\*

`C-c e v` coupe le pane en deux et liste dans le nouveau les noms de la session, un par rangée : son nom, son type, sa
taille ou sa forme, et le début de sa valeur, que la session donne en quelques mots : un grand array (un tableau de
valeurs) ne vient jamais en entier. La liste est relue après chaque lancement. Taper la filtre, comme toute liste. Enter
sur une rangée ouvre une vue de cette valeur, une frame ou une matrice en entier, chaque rangée sous son numéro : les
rangées viennent de la session 200 à la fois, à mesure que le curseur approche de la dernière affichée.

## \*repl\*

`C-c e r` coupe le pane en deux et ouvre `*repl*` sous lui : un prompt, `> `, dans la session du fichier ; un REPL (une
boucle qui lit du code, le lance et affiche son résultat). Enter lance le code après le dernier prompt, et sa sortie et sa
valeur s'affichent dessous, puis un nouveau prompt. Une ligne qui ne finit pas le code, comme `if x`, continue avec `. `
sur la suivante. `*repl*` lit chaque nom que les cells ont défini, mais une définition d'un nom que définit une cell est
refusée, avec le titre de cette cell : le fichier ne dirait plus ce que la session contient. Essayez une nouvelle valeur
d'un tel nom dans sa cell, ou sous un autre nom.

## La page

`C-c e h` lance toutes les cells du fichier, tel qu'il est enregistré, dans une nouvelle session, et écrit `name.html` à
côté de lui : le titre de chaque cell, son code coloré comme les docs de Cesia le colorent, ce qu'elle a affiché et sa
valeur, en table ou en texte, ou son erreur. La page n'a besoin d'aucun autre fichier ni d'aucun script, et montre ce que
`cesia run` calcule, pas l'état de la fenêtre.

## Sécurité

Une scene vient de la session, un autre processus, et Cemacs la lit comme une entrée : avant que quoi que ce soit en soit
fait, sa taille, la sorte et les champs de chaque élément, et les sommets (les points des formes) que tous feraient sont
vérifiés contre [notebook.SceneLimits], quatre millions de sommets et vingt mille éléments au plus ; une scene qui les
dépasse, ou d'une forme que std/plot ne donne jamais, est refusée, et la cell dit pourquoi en rouge. La vérification lit
chaque nombre une fois : 16 ms pour 100 000 marques, 25 ms pour une heatmap (une carte de chaleur, une grille de cases
colorées selon leur valeur) d'un million de cases. La mémoire que prennent les formes est écrite par `c.Write`, qui vérifie
sa longueur entière contre le bloc avant d'écrire.

## Vitesse

Taper dans un fichier de cells coûte ce que coûte taper dans n'importe quel fichier : les cells ne sont relues que lorsqu'une
cell tourne, et une demi-seconde après la dernière touche pour remettre les résultats sous leurs cells, jamais à chaque
touche. Mesuré dans une fenêtre de 1920 sur 1080 dessinée par le pilote factice (dummy driver) de SDL, 21 échantillons de 50
touches chacun, à tour de rôle : un caractère tapé avec l'écran d'un fichier de 50 cells avec leurs résultats, 9,5 ms, la
médiane des échantillons ; le même fichier sans cells ni résultats, 10,0 ms, puisque les résultats prennent des rangées que
des lignes prendraient. Une frame (une image dessinée à l'écran d'un coup) avec huit résultats à l'écran prend 9,4 ms, la
médiane de 21, sous les 16,7 ms d'un rafraîchissement d'un écran à 60 Hz.

Un graphe de 100 000 points, que la scene de std/plot ramène à quatre points par colonne de pixels, sous une cell d'un pane
large de 1 800 pixels, avec des marques, une bande, un titre, une légende et ses axes : dessiné par le renderer OpenGL de
SDL dans une fenêtre hors écran, 21 frames à tour de rôle avec une nouvelle scene, une frame prend 2,2 ms. La première frame
d'une nouvelle scene, après un changement de largeur, fait les arrays de ses 29 000 sommets et donne chacun à C en un seul
`c.Write`, et prend 12,7 ms, dans un seul rafraîchissement ; la scene elle-même prend 6,6 ms dans la session. Un graphe
immobile coûte un appel par forme : ce qui est écrit reste jusqu'à ce que la scene change. 100 000 marques prennent 249 ms
pour la première frame de leur scene et 53 ms pour les suivantes, puisque SDL envoie à nouveau leurs 900 000 sommets à
chaque frame ; une heatmap de 1 000 sur 1 000, une image d'un pixel par case, 116 ms et 3,0 ms.
