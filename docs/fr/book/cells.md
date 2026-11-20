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
| `C-c e f` | [notebook.FocusControl] | donne les touches au premier slider de la cell du curseur, à la barre de son animation, ou à son graphe 3D : voir Sliders, Animations et Graphes 3D |

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
L'écran glisse sur un graphe une rangée à la fois, sa partie basse visible quand l'écran commence dedans : voir
[L'écran d'un pane](windows.md#lécran-dun-pane).

## Sliders

Un *slider* (un curseur) est une barre avec un bouton que l'on fait glisser pour changer un nombre. Une cell de sliders
ne contient que des lignes `name = cells.Slider(value, min, max)`, chacune avec ses nombres écrits là, comme
[std/cells](https://www-celestial.github.io/cesia-lang/cells.html) le demande :

```cesia norun
use std/cells
use std/ode
use std/result

(* %% Parameters *)
rho = cells.Slider(28.0, 0.0, 50.0, step = 0.5)

(* %% Lorenz *)
lorenz(t, y) = [10.0 * (y[2] - y[1]), y[1] * (rho - y[3]) - y[2], y[1] * y[2] - 8.0 / 3.0 * y[3]]
s = result.Unwrap(ode.Solve(lorenz, [0.0, 50.0], [1.0, 1.0, 1.0]))
```

Sous chacune de ces lignes, Cemacs dessine son slider, d'après le texte seul, avant que rien ne tourne : le nom, une piste,
un bouton, et le nombre tel que le fichier l'écrit. Un mouvement écrit le nouveau nombre dans le buffer, à la place de
l'ancien : le fichier dit ce que montre la fenêtre, et une fois qu'il est enregistré, `cesia run` et la page de `C-c e h`
lisent le même nombre. Le nombre bouge par steps (des pas), du min au max, et s'écrit avec les décimales du min et du
step, `0.3` et jamais `0.30000000000000004`.

- **La souris.** Un clic sur la piste y met le bouton, si bien qu'un seul clic suffit ; un glissé suit le pointeur. La
  molette fait défiler le buffer, comme partout, et ne fait jamais bouger un slider.
- **Les touches.** `C-c e f` donne les touches au premier slider de la cell du curseur, dessiné avec un anneau, et la
  bande des hints liste ses touches, telles que les donne le slider pattern de WAI-ARIA (les règles du W3C qui rendent un
  contrôle utilisable au clavier et par un lecteur d'écran) : `right` et `up` le font avancer d'un step, `left` et
  `down` reculer d'un step, `pageup` et `pagedown` de dix steps, `home` et `end` l'amènent à son min et à son max ; `tab`
  et `S-tab` vont au slider suivant de la cell et au précédent, en boucle. `C-g`, un clic dans le texte, une lettre tapée
  ou toute autre touche le quittent, et cette touche fait ce qu'elle fait toujours.
- **Undo.** Un glissé, du clic au relâchement, est une seule étape d'undo (l'annulation), et les touches pressées à la
  suite sur un même slider aussi, comme la frappe.

Un mouvement ne relance que les cells qui lisent le nom du slider, directement ou par d'autres cells : la session du
fichier reçoit le nouveau nombre par [cells.Set](https://www-celestial.github.io/cesia-lang/cells.html), *en place* (le
nom garde sa place, sans être défini de nouveau), si bien qu'une fonction d'une autre cell qui le lit le voit tout de
suite, et la cell du slider, qui ne contient rien d'autre, ne tourne pas. Sans session encore, une session démarre et
toutes les cells tournent, depuis le haut. Le bouton et le nombre suivent le pointeur tout de suite ; les résultats
suivent aussi vite que les cells tournent, et restent affichés jusqu'à ce que les nouveaux arrivent, avec `waiting` ou
`running…` au-dessus d'eux. Après le slider s'affiche le temps de son dernier rerun (sa dernière relance), comme
`rerun 104 ms`, pour que vous voyiez pourquoi un graphe est en retard.

**Le dernier nombre gagne.** Pendant que les cells d'un mouvement tournent, le slider ne garde que le dernier nombre vers
lequel on l'a bougé ; quand elles finissent, ce nombre est donné à la session et elles tournent une fois de plus. Deux
reruns d'un slider n'attendent jamais l'un derrière l'autre, rien n'est annulé, et un résultat ne vient jamais de deux
nombres.

**Les résultats périmés.** Un résultat calculé avec un autre nombre que celui que le fichier écrit maintenant le dit, sur
une ligne au-dessus de lui : `stale: computed with rho = 28.0` (périmé : calculé avec rho = 28.0). Cela arrive après que
`C-c e s` a arrêté un rerun, ce qui abandonne le nombre qui attendait, après un undo d'un mouvement, et après que vous
avez tapé un autre nombre à la main ; la ligne s'en va dès que la cell tourne de nouveau. Un nombre tapé à la main ne
lance rien par lui-même, comme toute modification : `C-c e e` le lance.

## Animations

Une cell dont la dernière expression est une animation, comme
`plot.Frames([plot.Line(x, math.Sin(x - t)) for t in ts], fps = 30)` de
[std/plot](https://www-celestial.github.io/cesia-lang/graphs.html), montre sa première image, en pause, au-dessus d'une
barre :

```
  ▶ 12 / 120  ───────●──────────────────  30/s
```

`▶` quand elle est en pause, `‖` quand elle se joue, l'image montrée et leur nombre, une piste avec un bouton à l'image,
et le rythme. Elle démarre en pause, à chaque lancement de sa cell aussi, comme WCAG 2.2 (les règles du W3C pour des
pages accessibles) le demande de ce qui bouge plus de 5 secondes.

- **Les touches.** `C-c e f` dans sa cell donne les touches à la barre, dessinée avec un anneau, et la bande les liste :
  `space` (la barre d'espace) la joue ou la met en pause, `right` et `up` avancent d'une image, `left` et `down` reculent
  d'une image, `pageup` et `pagedown` de dix, `home` et `end` vont à la première image et à la dernière ; chacune de ces
  touches la met d'abord en pause. `C-g`, un clic dans le texte ou toute autre touche la quittent.
- **La souris.** Un clic sur `▶` la joue ou la met en pause ; un clic sur la piste va à l'image sous le pointeur, et un
  glissé le suit. Un clic sur le graphe ne fait rien.

**Une image à la fois.** Les images restent dans la session : Cemacs demande chacune par
[cells.Scene](https://www-celestial.github.io/cesia-lang/cells.html), `frame = k`, à la largeur du pane, pendant que
l'image d'avant se montre, et la garde jusqu'à son heure. Il y a donc au plus deux images dans la mémoire de Cemacs, et
une animation de 300 images ne traverse jamais en entier. Aucune image n'est sautée : chacune est un état de ce que vous
avez calculé, et une image en retard se montre en retard, pendant que la barre dit le rythme réel, comme `24/s of 30`
(24 par seconde sur 30). Après la dernière image vient la première, jusqu'à ce que vous la mettiez en pause.

**Seulement à l'écran.** Elle se joue tant que son graphe est à l'écran : défilée hors de vue, ou avec son buffer dans
aucun pane, elle attend là où elle est, et Cemacs ne prend aucun tick (aucun tour de la boucle d'affichage) pour elle ;
une animation en pause n'en prend pas non plus. Une cell qui tourne, ou le nombre d'un slider qu'on donne à la session,
passe avant l'image suivante, qui attend.

## Graphes 3D

Une cell dont la dernière expression est un graphe 3D, une surface de `plot.Surface` ou des courbes de `plot.Line3` de
[std/plot](https://www-celestial.github.io/cesia-lang/graphs.html#3d), le montre à la vue que donne son code,
`view = [az, el]` ou le `[-37.5, 30]` de MATLAB, avec une ligne en dessous qui dit la vue (*view*) :

```
  view −62.5°, 20° (code −37.5°, 30°)
```

Le premier angle est l'*azimut*, le tour autour de l'axe vertical, et le second l'*élévation*, l'angle de l'œil au-dessus
du plan de x et y ; la ligne dit aussi la vue du code tant que le graphe en montre une autre.

- **La souris.** Un glissé sur le graphe le tourne comme si vous le teniez, 0,5° par pixel : vers la droite, son avant
  va à droite ; vers le bas, son dessus vient vers vous. Un clic sur le graphe lui donne aussi les touches.
- **Les touches.** `C-c e f` dans sa cell lui donne les touches, dessiné avec un anneau autour, et la bande les liste :
  les flèches déplacent votre œil de 10°, `right` et `left` autour du graphe, `up` et `down` plus haut et plus bas,
  jusqu'à la verticale au plus ; `home` revient à la vue du code. `C-g`, un clic dans le texte ou toute autre touche le
  quittent.

**Chaque vue est dessinée par la session.** Cemacs la demande par
[cells.Scene](https://www-celestial.github.io/cesia-lang/cells.html), `view = [az, el]` : std/plot y projette la surface,
comme il le fait pour la page, et seules les places de ses points à l'écran reviennent, avec l'ordre où dessiner ses
quads (ses quadrilatères) ; les couleurs des quads restent dans Cemacs tant que seule la vue change. Une question à la
fois : pendant qu'une est posée, un glissé ou une touche ne change que la vue voulue, que la ligne montre tout de suite,
et une fois la réponse venue, c'est la dernière vue voulue qui est demandée, si bien que le graphe suit la souris sans file
de vieilles vues. Rien n'est écrit dans le fichier : le code garde sa vue, la page la montre, et un lancement de la cell
la remontre. Pour garder la vue trouvée, écrivez les deux nombres de la ligne comme `view` de la cell.

Un graphe 3D de `*repl*` tourne de la même façon, avec la session de son fichier. Un graphe 3D dans une grille ou dans une
animation ne tourne pas.

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
d'un tel nom dans sa cell, ou sous un autre nom. Une animation montre sa première image, sans barre, et dit qu'une cell la
joue. Un graphe 3D y tourne comme sous une cell.

## La page

`C-c e h` lance toutes les cells du fichier, tel qu'il est enregistré, dans une nouvelle session, et écrit `name.html` à
côté de lui : le titre de chaque cell, son code coloré comme les docs de Cesia le colorent, ce qu'elle a affiché et sa
valeur, en table ou en texte, ou son erreur. La page n'a besoin d'aucun autre fichier ni d'aucun script, et montre ce que
`cesia run` calcule, pas l'état de la fenêtre. Une animation démarre en pause sur sa première image sous une case *Play*,
qui la joue par le CSS (les règles de style de la page) seul. Un graphe 3D se montre à la vue de son code, pas à celle où
on l'a tourné dans la fenêtre.

## Sécurité

Un slider n'écrit que le nombre de sa propre valeur, sur sa propre ligne : avant la modification, Cemacs vérifie que cette
ligne est toujours dans la cell du slider et contient toujours le nombre qu'il y a lu, et refuse le mouvement sinon ; le
texte est relu à la touche suivante. Le nombre écrit est l'un des steps du slider, entre son min et son max, fait par
[cells.Snap](https://www-celestial.github.io/cesia-lang/cells.html), et la session ne l'accepte que pour un nom qui tient
déjà un nombre. Le fichier lui-même est écrit quand vous l'enregistrez, comme tout buffer : par un nouveau fichier à côté
de lui qu'un rename (un renommage) met à sa place, et jamais par-dessus un fichier qui a changé sur le disque depuis qu'il
a été lu.

Une scene vient de la session, un autre processus, et Cemacs la lit comme une entrée : avant que quoi que ce soit en soit
fait, sa taille, la sorte et les champs de chaque élément, et les sommets (les points des formes) que tous feraient sont
vérifiés contre [notebook.SceneLimits], quatre millions de sommets et vingt mille éléments au plus ; une scene qui les
dépasse, ou d'une forme que std/plot ne donne jamais, est refusée, et la cell dit pourquoi en rouge. Une image d'une
animation dit son nombre d'images, de 1 à 300, et son rythme, de 1 à 60 par seconde, et elle est refusée sinon, ou quand
son nombre diffère de celui de l'animation : l'animation se met en pause et dit pourquoi. Les quads d'une surface viennent
avec leurs nombres, de 1 à 200 par côté, les places d'exactement leurs points, chacune un nombre de -1 000 000 à
1 000 000, une palette de 1 à 256 couleurs `#rrggbb`, une couleur de celle-ci ou -1 pour chaque quad, et un ordre de 1 ou
-1 pour leurs lignes et leurs colonnes ; la vue d'un graphe 3D est faite de deux nombres, l'élévation de -90 à 90 : tout
le reste est refusé, et une vue refusée laisse le graphe à celle qu'il montre, et dit pourquoi. Cemacs pose à la session
une question à la fois, une image, le nombre d'un slider, une vue ou une scene, pour qu'aucune réponse n'aille à une autre
question. La
vérification lit chaque nombre une fois : 16 ms pour 100 000 marques, 25 ms pour une heatmap (une carte de chaleur, une grille de cases
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

Une animation de la courbe de Lorenz vue en rotation, 120 images de 5 000 points à 30 par seconde, dans un pane large de
1 834 pixels, dessinée par le renderer OpenGL de SDL dans une fenêtre hors écran : elle se joue à 29 ou 30 images par
seconde, de 115 à 119 images montrées en 4 secondes, sur 119 au plus. Une image prend environ 10 ms de la question à la session jusqu'à sa réponse
dans Cemacs, dessinée par la session pendant que Cemacs dessine l'image d'avant, et la frame qui la montre environ 20 ms,
surtout pour faire les triangles d'une courbe de 5 000 points. Sous le pilote factice de SDL, qui dessine ses triangles
en logiciel, une frame immobile de ce graphe prend 38 ms, et l'animation se joue à 6 images par seconde.

Une surface de 100 par 100 quads tournée avec les touches, dans un pane de 1 834 pixels de large, dessinée par le
renderer OpenGL de SDL dans une fenêtre hors écran : de la touche à la frame qui montre la nouvelle vue, il faut 30 ms,
la médiane de 63 pas, sous les 33 ms de 30 images par seconde. Là-dedans, la session projette la surface et écrit sa
scene en 6,3 ms, Cemacs lit ses 192 Ko de JSON en 3,5 ms et les vérifie en 1,3 ms, et la frame prend
8,2 ms, surtout pour choisir les places des 40 000 sommets des quads parmi celles des 10 201 points. Quand l'ordre des
quads change, quand l'œil passe un axe, Cemacs refait leurs couleurs et leur ordre, environ 10 ms de plus pour ce pas.
