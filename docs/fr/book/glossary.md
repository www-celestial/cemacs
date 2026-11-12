# Glossaire

Les mots des éditeurs que ce livre emploie, dans l'ordre alphabétique de leur nom anglais : les mots techniques restent en
anglais, comme dans le reste du livre, et quand le livre emploie un mot français, il est donné au début de l'entrée. Chaque
entrée dit ce que le mot veut dire en général, puis comment Cemacs le fait, et mène au chapitre qui le raconte. Là où Emacs
a un autre mot pour la même chose, les deux sont donnés.

## Alignment

En français : l'alignement. Mettre les lettres d'une séquence sous celles d'une autre, en laissant l'une ou l'autre sauter
des lettres, les gaps, pour que le plus de lettres possible correspondent ; un score ajoute des points pour chaque
correspondance et en retire pour chaque gap, et le meilleur alignement a le meilleur score. Smith et Waterman l'ont trouvé
pour l'ADN en 1981. Une requête de quelques lettres alignée avec le chemin d'un fichier, c'est ce que notent les fuzzy
finders. Voir [Un cas](finding.md#4-la-recherche--comment-ce-genre-de-problème-se-résout).

## Anchor

La ligne d'ancrage d'où Cemacs lit le code au-dessus d'une ligne de Cesia pour lui donner sa place : la ligne la plus proche
au-dessus d'elle à la marge gauche, dans du code, qui commence un statement, après une suite de lignes qui finissent chacune
leur statement. De là, la lecture est sûre de partir hors de tout bloc et de toute parenthèse, comme le serait la lecture de
`cesia fmt` depuis le début du fichier. Voir [À l'intérieur de Cemacs](internals.md#lindentation).

## Atomic rename

En français : le renommage atomique. Un renommage que le système fait en un seul pas : à chaque instant, le nom mène à
l'ancien fichier ou au nouveau, jamais à une partie de l'un ou de l'autre. POSIX le demande à `rename`. Cemacs enregistre en
écrivant un nouveau fichier et en le renommant par-dessus l'ancien : voir
[Fichiers et buffers](files.md#ne-jamais-perdre-le-texte).

## AVL tree

En français : l'arbre AVL. Un arbre binaire gardé équilibré : à chaque nœud, les hauteurs des deux côtés diffèrent d'au plus
un, si bien que l'arbre reste profond d'environ $1{,}44 \log_2 n$ pour $n$ feuilles. Nommé d'après Adelson-Velsky et
Landis, qui l'ont décrit en 1962. La rope de Cemacs est équilibrée ainsi : voir
[À l'intérieur de Cemacs](internals.md#la-rope).

## Band of hints

En français : la bande des hints. La bande qui s'ouvre au-dessus de la prompt line quand une prefix key attend depuis une
demi-seconde, et qui liste les touches qui peuvent suivre. Emacs l'a avec `which-key-mode`. Voir
[Fenêtre et panes](windows.md#la-bande-des-hints).

## Baseline

Une mesure prise avant un changement, sur la même machine et de la même façon que la mesure d'après, sans laquelle aucun
« mieux » ne peut être montré. Voir [Un cas](finding.md#2-mesurer-avant-de-rien-changer).

## Breakpoint

Une ligne où un debugger arrête le programme chaque fois qu'il l'atteint, pour montrer ses variables. `C-c d b` dans
Cemacs : voir [Exécuter et déboguer](running.md#les-breakpoints).

## Buffer

Un texte que l'éditeur garde en mémoire, le plus souvent le texte d'un fichier : vous modifiez le buffer, et l'enregistrer
l'écrit dans le fichier. Chaque buffer de Cemacs a son propre curseur, sa mark, son historique d'annulation et ses erreurs.
Voir [Fichiers et buffers](files.md).

## Case folding

Faire correspondre une majuscule et une minuscule comme la même lettre, comme le fait une recherche quand ses mots ne
contiennent pas de majuscule, dans Emacs et dans Cemacs : `two` trouve `Two`. Voir [Recherche](search.md#chercher-dans-un-buffer).

## Chord

Une touche pressée avec les modifiers (Control, Alt, Shift) tenus en même temps qu'elle, écrite comme `C-x`, `M-<` ou
`S-right`. Voir [Touches](keys.md#comment-une-touche-devient-un-chord).

## Chunk

Une partie de taille fixe d'une longue liste, gardée comme un seul élément d'une liste plus courte, pour que couper ou
prolonger la longue liste copie une partie et la liste courte, pas tout ce qui vient avant l'endroit. Cemacs garde les états
de ses couleurs en chunks de 1 024 lignes. Voir [À l'intérieur de Cemacs](internals.md#les-couleurs).

## Clipboard

En français : le presse-papiers. L'endroit où un texte coupé ou copié attend d'être collé, partagé par les programmes du
bureau. Cemacs emploie celui du système, et y garde un seul texte : il n'a pas de kill ring. Voir
[Édition](editing.md#couper-copier-et-coller).

## Command

En français : la commande. Ce qu'une touche lance. Dans Cemacs, n'importe quelle fonction qui va de l'état de l'éditeur à un
nouvel état ; Emacs demande qu'une commande soit marquée interactive. Voir [Touches](keys.md#les-mots).

## Completion

Taper le début d'un mot et laisser l'éditeur écrire le reste, d'après les mots qu'il connaît. Dans un fichier de Cesia, Tab
complète à partir des mots autour du curseur, des autres buffers et des noms de Cesia, et les liste sous le curseur quand il
y en a plusieurs. Emacs le fait avec `completion-at-point` et `dabbrev-expand`, Vim avec `Ctrl-N`. Voir
[Édition](editing.md#la-completion).

## Config

Le record de fonctions sur lequel l'éditeur tourne : ses keymaps, ses réglages, son démarrage et ses hooks, fait par
`emacs.Config`, qui reçoit ses hooks de `check.Hooked` et que change le `Changed` de votre `user/config/config.ce`. Voir
[Modifier Cemacs](customising.md#la-config).

## Continuation line

Une ligne de suite : une ligne qui continue un statement commencé sur une ligne au-dessus d'elle, entre parenthèses, crochets
ou accolades, après un token qui en demande plus comme `,` ou `+`, ou dans un commentaire. `cesia fmt` la déplace avec la
ligne qui commence le statement, et le Tab de Cemacs aussi. Voir [Édition](editing.md#lindentation-dans-un-fichier-de-cesia).

## Cursor

En français : le curseur. L'endroit entre deux caractères où ce que vous tapez s'insère, une ligne et une colonne dans
Cemacs. Emacs l'appelle le point. Voir [Édition](editing.md#le-curseur).

## Debug adapter and language server

Un language server est un programme qui connaît un langage et donne à n'importe quel éditeur les erreurs, les completions et
les définitions de son code, par le Language Server Protocol ; un debug adapter fait de même pour un debugger, par le Debug
Adapter Protocol. Cemacs n'emploie ni l'un ni l'autre : voir [Cemacs et les autres éditeurs](comparison.md#en-fonctions).

## Delta debugging

Une façon de trouver la cause d'un échec en réduisant l'entrée qui échoue : enlever des morceaux, garder l'entrée plus petite
tant qu'elle échoue encore, et continuer avec des morceaux plus petits jusqu'à ce que plus rien ne puisse partir. Le `ddmin`
de Zeller et Hildebrandt (2002). Il a réduit chaque requête qui ne trouvait rien à une seule espace. Voir
[Un cas](finding.md#3-une-hypothèse-qui-pourrait-être-réfutée).

## Differential test

Un test qui fait tourner deux programmes qui résolvent le même problème sur les mêmes entrées et compare leurs réponses, si
bien que chacun vérifie l'autre. Les rangs des fichiers de Cemacs sont vérifiés contre le `matchfuzzy()` de Vim. Voir
[Un cas](finding.md#la-qualité--le-fichier-voulu-vient-en-premier).

## Dynamic programming

En français : la programmation dynamique. Résoudre un problème à partir des réponses de ses parties plus petites, chacune
gardée dans une table et calculée une seule fois, au lieu d'essayer chaque possibilité : le meilleur alignement de deux
textes, case par case, chacune à partir des cases d'avant. Voir [Un cas](finding.md#lalignement-et-sa-table).

## Echo area

Le nom que donne Emacs à la ligne du bas de la frame où s'affichent les messages. La prompt line de Cemacs le fait. Voir
[Fenêtre et panes](windows.md#la-prompt-line).

## Electric indentation

Indenter à nouveau une ligne quand un caractère ou un mot tapé change sa place, comme un `end` qui ferme un bloc. Emacs le
fait avec `electric-indent-mode`, Vim et Neovim avec `'indentkeys'`. Dans un fichier de Cesia, Cemacs le fait à `end`,
`else`, `then` et aux parenthèses, crochets et accolades fermants tapés au début d'une ligne. Voir
[Édition](editing.md#lindentation-dans-un-fichier-de-cesia).

## Elm architecture

Une façon de construire un programme interactif à partir d'un seul état, d'une fonction qui fait l'état suivant à partir
d'un événement, et d'une fonction qui dessine un état ; nommée d'après le langage Elm. Cemacs est construit ainsi : voir
[À l'intérieur de Cemacs](internals.md#létat-la-mise-à-jour-et-la-vue).

## Encoding

En français : l'encodage. La façon dont les caractères d'un texte deviennent des octets dans un fichier. Cemacs ne lit et
n'écrit que l'UTF-8 : voir [Fichiers et buffers](files.md#les-encodages).

## Event loop

En français : la boucle des événements. La boucle au cœur d'un programme qui a une fenêtre : elle attend un événement, une
touche, la souris, un changement de taille, le donne au programme, dessine ce qui a changé, et attend à nouveau. Bien
attendre veut dire dormir dans le système jusqu'à ce qu'un événement arrive, ce qui ne coûte pas de processeur, plutôt que
d'en chercher un encore et encore. Voir [À l'intérieur de Cemacs](internals.md#la-boucle-des-événements).

## Fiber and channel

Une fiber est une tâche de Cesia qui tourne à côté des autres dans un même programme, en prenant son tour avec elles ; un
channel est une file d'attente par laquelle des fibers s'envoient des valeurs. Cemacs attend une vérification et la sortie
d'un programme dans des fibers, pour que la frappe n'attende jamais. Voir
[À l'intérieur de Cemacs](internals.md#la-boucle-des-événements).

## Frame

Dans Emacs, une fenêtre du système, qui contient les windows d'Emacs ; Cemacs l'appelle la fenêtre. Aussi, une image
dessinée à l'écran d'un coup, comme dans « frames par seconde » : Cemacs en fait une à partir de son état à chaque
événement. Voir [Fenêtre et panes](windows.md) et [À l'intérieur de Cemacs](internals.md#la-frame).

## Gap and gap penalty

Dans un alignement, les lettres d'un texte que l'autre saute ; la penalty est ce que le score perd pour elles. fzy fait payer
0,01 par lettre sautée entre deux lettres qui correspondent, et 0,005 par lettre avant la première ou après la dernière ;
l'affine gap de Gotoh coûte un prix pour l'ouvrir et un prix plus petit par lettre. Voir [Un cas](finding.md#le-score-de-fzy).

## Gap buffer

Un texte dans un seul bloc de mémoire avec un trou à l'endroit de la dernière modification, si bien que taper là ne coûte
rien et qu'une modification lointaine déplace d'abord le trou. GNU Emacs garde ainsi ses buffers ; Cemacs emploie une rope.
Voir [À l'intérieur de Cemacs](internals.md#pourquoi-une-rope).

## Garbage collector

La partie d'un runtime qui libère la mémoire des valeurs que plus rien n'atteint, le garbage. Celui d'OCaml, sous Cesia, fait
les valeurs dans un petit minor heap et libère celles qui meurent jeunes à sa minor collection suivante, sans coût pour
chaque valeur morte ; les autres, il les libère peu à peu, à un rythme fixé par ce que le programme alloue : ce que laisse
l'ouverture d'un grand fichier peut rester en mémoire un moment après elle. Voir [Vitesse](performance.md#au-repos).

## Goal column

La colonne que les déplacements par lignes essaient de garder à travers les lignes plus courtes. Voir
[Édition](editing.md#se-déplacer).

## Group

En français : le groupe. Dans Cemacs, une prefix key sous `C-c` dont la key binding est un nom, comme `C-c f`, files : la
bande des hints la montre comme `+files`, comme le font les leader keys de Doom Emacs. Voir
[Touches](keys.md#la-keymap-globale).

## Hook

Une fonction qu'une app donne au core, qui l'appelle à un moment donné : Cemacs a `Idle`, `Saved` et `Moving`. Emacs en a
beaucoup, sous le même nom. Le `Start` de la config en est proche : il tourne une fois, après l'ouverture des fichiers donnés
au démarrage, comme Emacs fait tourner son `emacs-startup-hook` après les init files et la ligne de commande. Voir
[Modifier Cemacs](customising.md#les-hooks).

## Hot reload

En français : le rechargement à chaud. Du nouveau code chargé dans un programme pendant qu'il tourne, pour qu'il garde son
état. `cesia do dev` recharge ainsi Cemacs à chaque enregistrement d'un de ses fichiers. Voir
[Modifier Cemacs](customising.md#recharger-cemacs-pendant-quil-tourne).

## Ignored file

En français : un fichier ignoré. Un fichier ou un dossier que git laisse de côté, parce qu'une ligne du fichier `.gitignore`
le nomme : `git status` ne le montre pas, `git add .` le saute, et `git pull` ne le change jamais. Le `user/` de Cemacs en
est un, pour que vos changements et le nouveau code de Cemacs ne se rencontrent jamais. Voir
[Installation](install.md#votre-dossier-user).

## Immediate mode

Une façon de dessiner une interface où le programme refait la frame entière à partir de son état chaque fois, et où aucun
widget ne garde un état à lui. Cemacs dessine ainsi : voir [À l'intérieur de Cemacs](internals.md#la-frame).

## Incremental search

En français : la recherche incrémentale. Une recherche qui trouve la correspondance suivante à chaque lettre tapée, au lieu
d'attendre les mots entiers : `C-s` en avant et `C-r` en arrière, dans Emacs et dans Cemacs. La correspondance s'affiche
sélectionnée, `C-s` à nouveau va à la suivante, et fait le tour par le bout du fichier quand il n'en reste plus. Voir
[Recherche](search.md#chercher-dans-un-buffer).

## Indent

En français : l'indentation. Les espaces au début d'une ligne, qui montrent à quelle profondeur de blocs se trouve son code ;
indenter une ligne, c'est lui donner ces espaces. Dans un fichier de Cesia, Cemacs donne à chaque ligne l'indentation que
lui donne `cesia fmt`, deux espaces par bloc. Voir [Édition](editing.md#lindentation-dans-un-fichier-de-cesia).

## Init file

Le fichier de code qu'un éditeur exécute à son démarrage pour appliquer les changements de la personne :
`~/.emacs.d/init.el` ou `~/.config/emacs/init.el` pour Emacs, `~/.config/nvim/init.lua` ou `init.vim` pour Neovim,
`~/.vimrc` pour Vim. Celui de Cemacs est `user/config/config.ce`, dans le dossier de Cemacs, dont la fonction `Changed`
reçoit la config de Cemacs et la rend changée, à chaque touche ; `C-c f c` l'ouvre. Voir
[Modifier Cemacs](customising.md#votre-dossier-user).

## Just-in-time colouring

En français : la coloration à la demande. Colorer le code d'un buffer quand une partie en est montrée, et non en entier à son
ouverture : le jit-lock d'Emacs. Cemacs colore les lignes de l'écran à partir des états des lignes du dessus, et, quand
celles-ci sont loin, montre l'écran tout de suite avec ses états devinés, et les rend exacts au fil des ticks suivants. Voir
[À l'intérieur de Cemacs](internals.md#un-endroit-lointain-dabord-ses-couleurs-exactes-ensuite).

## Key binding and keymap

Une key binding relie une key sequence à ce qu'elle lance ; une keymap en est un ensemble. Les keymaps de Cemacs sont des
dictionnaires qui vont d'un texte, comme `"C-x C-s"`, à une fonction. Voir [Touches](keys.md#les-mots).

## Key sequence and prefix key

Une key sequence est un ou plusieurs chords tapés l'un après l'autre, comme `C-x C-s`. Une prefix key est le début d'une
key sequence plus longue, qui attend la touche suivante. Voir [Touches](keys.md#comment-une-key-sequence-est-lue).

## Kill ring

La liste d'Emacs des derniers textes coupés, que `M-y` parcourt après `C-y`. Cemacs n'en a pas : voir
[Édition](editing.md#couper-copier-et-coller).

## Lazy view

Une partie d'une vue refaite seulement quand ce à partir de quoi elle est faite a changé ; sinon, celle faite avant est
employée. Elm l'appelle `Html.Lazy`. Cemacs garde les tokens de chaque ligne de l'écran rangés par son texte, sa largeur et
l'état à son début. Garder un résultat rangé par les arguments à partir desquels il a été fait s'appelle la memoization. Voir
[À l'intérieur de Cemacs](internals.md#la-frame).

## Lexer

La première étape de la lecture du code, qui le découpe en mots, ses tokens. Les couleurs de Cemacs viennent d'un lexer à
lui, qui lit une ligne à la fois et ne s'arrête jamais sur une erreur. Voir [À l'intérieur de Cemacs](internals.md#les-couleurs).

## Line end

En français : la fin de ligne. Le caractère, ou les deux, qui finissent une ligne : `\n` ou `\r\n`. Cemacs garde celle de
chaque ligne. Voir [Fichiers et buffers](files.md#les-fins-de-ligne).

## List

En français : la liste. Dans Cemacs, un buffer de rangées en lecture seule qu'il fait pour vous, les buffers ou les fichiers
d'un dossier, que la frappe filtre et où Enter agit sur une rangée. Voir [Recherche](search.md#les-listes).

## Major mode

Dans Emacs, ce qui donne à un buffer ses touches, ses couleurs et son comportement pour une sorte de texte. Cemacs n'a pas de
modes : chaque buffer de texte est du Cesia, et une liste a ses propres touches devant les touches globales, ce qui
ressemble le plus à un major mode. Voir [Fenêtre et panes](windows.md#la-mode-line).

## Mark and region

La mark est un second endroit d'un buffer, que vous posez ; le texte entre elle et le curseur est la region, que Cemacs
appelle la sélection. Voir [Édition](editing.md#la-mark-et-la-sélection).

## Mean reciprocal rank

Une mesure d'un classement : chaque requête marque 1 divisé par le rang de sa bonne réponse, 1 quand elle est première, 1/2
deuxième, 0 quand elle n'y est pas, et on prend la moyenne sur les requêtes. Elle vient de TREC-8, en 1999. La liste des
fichiers d'un projet marque 0,898 sur 41 requêtes, contre 0,597 avant qu'elle classe. Voir
[Un cas](finding.md#comment-le-classement-se-mesure).

## Median and its interval

En français : la médiane et son intervalle. La médiane de n mesures est celle du milieu une fois qu'elles sont triées ; son
intervalle à 95 % va d'une mesure triée à une autre, et contient la vraie médiane avec une probabilité d'au moins 95 %. Voir
[Vitesse](performance.md#comment-cest-mesuré).

## Minibuffer

Le buffer d'Emacs, en bas de la frame, où vous tapez la réponse à une question. La prompt line de Cemacs le fait, et n'est
pas un buffer. Voir [Fenêtre et panes](windows.md#la-prompt-line).

## Mode line

La ligne au bas de chaque pane qui dit l'état de son buffer : son nom, une étoile quand il n'est pas enregistré, l'endroit du
curseur, le nombre d'erreurs. Voir [Fenêtre et panes](windows.md#la-mode-line).

## O(log n)

Un coût qui croît avec le logarithme de la taille $n$ : doubler la taille ajoute environ un pas. Une modification de la rope
de Cemacs coûte $O(\log n)$ visites de nœuds. Voir [À l'intérieur de Cemacs](internals.md#la-rope).

## Pane

Une partie de la fenêtre qui montre un buffer, avec sa propre mode line ; Emacs l'appelle une window. Voir
[Fenêtre et panes](windows.md#les-panes).

## Persistent data structure and structural sharing

Une persistent data structure garde ses anciennes versions entières quand elle change, en faisant de nouvelles parties et en
partageant les autres avec l'ancienne version : ce partage est le structural sharing. Chaque valeur de Cesia est
persistante, ce qui rend peu coûteux l'historique d'annulation et les copies d'un buffer. Voir
[À l'intérieur de Cemacs](internals.md#létat-la-mise-à-jour-et-la-vue).

## Piece table

Une façon de garder le texte d'un éditeur : le fichier lu reste tel qu'il était, jamais copié, et le texte est une suite de
morceaux, chacun un span du fichier ou d'un texte des modifications. Crowley l'a comparée à cinq autres en 1998 et l'a
trouvée la meilleure ; Visual Studio Code garde son texte dans un piece tree, les morceaux dans un arbre équilibré. La rope
de Cemacs en est une : ses feuilles sont des vues des textes. Voir [À l'intérieur de Cemacs](internals.md#la-rope).

## Project

En français : le projet. Les fichiers sur lesquels vous travaillez ensemble. Dans Cemacs, comme dans le `project.el`
d'Emacs, un dépôt Git : sa racine est le dossier qui contient `.git`, et ses fichiers sont ceux que Git liste. `C-x p f` les
liste : voir [Fichiers et buffers](files.md#les-fichiers-dun-projet).

## Prompt line

La ligne de Cemacs en bas de la fenêtre, qui montre les messages et pose les questions : l'echo area et le minibuffer
d'Emacs. Voir [Fenêtre et panes](windows.md#la-prompt-line).

## Property-based test

Un test qui énonce une règle qui doit tenir pour chaque entrée, puis l'essaie sur des centaines d'entrées faites au hasard,
les plus petites d'abord, et réduit une entrée qui échoue à la plus petite qui échoue encore. QuickCheck, de Claessen et
Hughes en 2000, l'a fait connaître ; Cesia a `test.ForAll`. Voir
[Un cas](finding.md#correct--des-tests-qui-échouent-avant-et-passent-après).

## Pure function

En français : la fonction pure. Une fonction dont le résultat ne dépend que de ses arguments, et qui ne change rien
au-dehors. L'essentiel du core de Cemacs est pur : voir
[À l'intérieur de Cemacs](internals.md#létat-la-mise-à-jour-et-la-vue).

## Ranking and score

En français : le classement et le score. Un score est un nombre donné à chaque rangée qu'un filtre garde, qui dit à quel
point le filtre lui va ; classer met les rangées dans l'ordre de leurs scores, la meilleure d'abord. La liste des fichiers
d'un projet classe par le score de fzy, [lists.Score] ; les autres listes gardent leur ordre. Voir
[Recherche](search.md#quand-une-rangée-correspond-à-un-filtre).

## Response time

En français : le temps de réponse. Le temps qui va d'une action, une touche, à ce que l'écran en montre. Miller (1968)
demande 0,1 seconde pour l'effet d'une touche, et Card, Robertson et Mackinlay (1991) donnent 0,1 seconde comme la
constante de temps du traitement perceptif, le plus qu'un écran puisse attendre entre deux redessins pour qu'un mouvement
paraisse fluide. Voir [Un cas](finding.md#1-le-problème-énoncé-précisément).

## Rope

Un texte gardé comme un arbre équilibré de morceaux, si bien qu'une modification n'importe où coûte $O(\log n)$ et qu'une
copie partage tout. Les buffers de Cemacs sont des ropes : voir [À l'intérieur de Cemacs](internals.md#la-rope).

## RSS and PSS

Deux mesures de la mémoire d'un programme : la RSS, la resident set size, est la part de lui qui est en RAM, les
bibliothèques partagées comptées en entier ; la PSS, la proportional set size, divise chaque page partagée entre les
programmes qui la partagent. Voir [Vitesse](performance.md#au-repos).

## Shaping

Faire des caractères d'un texte les glyphes d'une police et leurs places, le kerning (l'espacement propre à chaque paire de
lettres) et les ligatures compris : le travail de HarfBuzz, que SDL3_ttf appelle pour chaque texte. Cemacs garde chaque texte
passé par le shaping rangé par ses mots, pour qu'une ligne qui bouge à l'écran ne repasse pas par le shaping. Voir
[À l'intérieur de Cemacs](internals.md#la-frame).

## Shift selection

Une sélection faite en tenant Shift pendant un déplacement, que le déplacement suivant sans Shift finit. Voir
[Édition](editing.md#la-mark-et-la-sélection).

## Statement

Une instruction : un pas d'un programme, comme `x = 1`, `io.Print(x)` ou `if a`, qui peut s'étendre sur plusieurs lignes,
ses continuation lines. `cesia fmt` place la première ligne de chaque statement, et déplace les autres avec elle. Voir
[Édition](editing.md#lindentation-dans-un-fichier-de-cesia).

## Subsequence matching

Un filtre qui correspond quand ses caractères viennent dans un texte dans le même ordre, côte à côte ou non : `cmd`
correspond à `commands.ce`. Une sorte de fuzzy matching ; la completion d'Emacs l'appelle `flex`. Voir
[Recherche](search.md#quand-une-rangée-correspond-à-un-filtre).

## SWAR

SIMD within a register : travailler sur plusieurs petites valeurs à la fois avec les opérations ordinaires sur un seul grand
entier. Un mot de 64 bits contient huit octets : un seul test de `word AND 0x8080808080808080` dit donc si les huit sont
ASCII. SIMD, single instruction, multiple data, est le nom des instructions propres au processeur pour cela. Le
[text.IsUtf8] et le [text.Count] de Cesia marchent ainsi, et [files.IsText] et la rope les emploient. Voir
[Fichiers et buffers](files.md#les-encodages).

## Task

En français : la tâche. Un programme de `cesia.toml` à exécuter avec ses permissions, lancé par `cesia do NAME`. `C-c c r`
lance la tâche qui nomme le fichier du buffer : voir [Exécuter et déboguer](running.md#la-tâche-qui-exécute-un-fichier).

## Theme

En français : le thème. Les couleurs de l'éditeur, pour chaque partie de la fenêtre et chaque sorte de mot du code. Dans
Cemacs, un record de couleurs : [ui.Dark], celui avec lequel il démarre, ou [ui.Light], ou un thème à vous, que donne le
`Theme` de la config et que la fenêtre lit une fois, quand elle s'ouvre. Emacs charge ses thèmes par `load-theme`. Voir
[Recettes](recipes.md#votre-police-votre-tab-votre-thème-et-votre-fenêtre).

## Threat to validity

Une raison pour laquelle une preuve pourrait être fausse même quand chacun de ses nombres est vrai : des requêtes choisies
par l'auteur, un seul projet, une machine bruyante. Une étude nomme chaque threat et dit comment elle a été écartée. Voir
[Un cas](finding.md#les-threats-to-validity).

## Tick

Un événement que Cemacs fait lui-même à chaque tour de sa boucle tant que quelque chose demande que le temps soit compté,
comme l'attente de la bande des hints, ou une vérification. Voir [À l'intérieur de Cemacs](internals.md#la-boucle-des-événements).

## Undo history

En français : l'historique d'annulation. Les états du texte d'un buffer que l'annulation parcourt en arrière et le
rétablissement en avant. Celui de Cemacs est linéaire et garde 1 000 états. Voir [Édition](editing.md#annuler-et-rétablir).

## UTF-8

L'encodage d'Unicode où un caractère prend de un à quatre octets, un seul pour ASCII. La RFC 3629 le définit, avec ce qui est
valide : pas d'overlong form (un caractère écrit en plus d'octets qu'il n'en faut, comme `C0 AF` pour `/`) ; pas de
surrogate (les codes de U+D800 à U+DFFF qu'UTF-16 garde pour ses paires) ; rien au-dessus de U+10FFFF, le dernier code
d'Unicode. Voir [Fichiers et buffers](files.md#les-encodages).

## View of a text

En français : la vue d'un texte. Une partie d'un texte nommée par l'endroit où elle commence et sa taille, sans copie de ses
octets. Les feuilles de la rope de Cemacs sont des vues, `{Text, Start, Size, Lines}`, du fichier lu et des textes tapés.
Voir [À l'intérieur de Cemacs](internals.md#la-rope).

## Visit

Le mot d'Emacs pour l'ouverture d'un fichier dans un buffer. Voir [Fichiers et buffers](files.md#ouvrir-un-fichier).

## Vsync

Dessiner au rythme du rafraîchissement de l'écran, pour qu'aucune frame ne soit dessinée que l'écran ne peut pas montrer.
Voir [À l'intérieur de Cemacs](internals.md#la-frame).

## Yank

Le mot d'Emacs pour coller, `C-y`. Voir [Édition](editing.md#couper-copier-et-coller).
