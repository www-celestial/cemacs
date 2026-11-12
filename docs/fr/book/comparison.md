# Cemacs et les autres éditeurs

Ce chapitre met Cemacs à côté des éditeurs que connaissent la plupart des programmeurs : GNU Emacs 31.1, Neovim 0.12.6 et
Vim 9.2, qui étaient installés sur la machine où Cemacs est mesuré, et Visual Studio Code, d'après sa documentation publiée
seulement. Il dit simplement où ils gagnent, et pourquoi. Cemacs est jeune et petit, environ 7 200 lignes ; chacun des autres
est le travail de beaucoup de personnes pendant des années, des décennies pour Emacs et Vim.

## En chiffres

Mesuré sur une seule machine, comme le dit [Vitesse](performance.md), avec la méthode qui y est décrite : chaque éditeur a
démarré sans configuration de l'utilisateur, les trois autres dans un terminal de 160 sur 50 caractères, Cemacs dans sa
propre fenêtre dessinée par le dummy driver de SDL, en mémoire, ou, là où une ligne dit OpenGL, dans une fenêtre Wayland.
Chaque nombre est la médiane de n exécutions, avec son intervalle à 95 %. L'ouverture, la recherche, le collage,
l'annulation, l'enregistrement et la mémoire ont été mesurés avec les quatre chacun à son tour ; les touches et les lignes
défilées dans une série pour Cemacs et une pour les autres, le même après-midi.

| Mesure | n | Cemacs | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|---|
| du lancement à la première frame, avec la prochaine version de Cesia | 62 ; 20 pour les autres | 51,3 ms [50,8 ; 51,9] | 89,1 ms [88,3 ; 92,9] | 13,8 ms [13,6 ; 13,9] | 9,3 ms [9,2 ; 9,4] |
| la même chose avec Cesia 1.1.0 | 62 | 57,4 ms [57,0 ; 58,0] | | | |
| du lancement à la première frame, dans une fenêtre Wayland, avant cette version | 10 | 236 ms [232 ; 241] | | | |
| lancer et ouvrir 0,79 MB | 7 | 66,9 ms [66,2 ; 71,0] | 98,4 ms [97,7 ; 109] | 20,5 ms [20,4 ; 42,7] | 18,0 ms [17,4 ; 19,8] |
| lancer et ouvrir 15,9 MB | 7 | 97,8 ms [97,1 ; 139] | 145 ms [142 ; 149] | 53,2 ms [52,8 ; 61,9] | 51,5 ms [50,4 ; 52,0] |
| lancer et ouvrir 99,9 MB | 7 | 266 ms [262 ; 281] | 393 ms [392 ; 460] | 235 ms [231 ; 317] | 247 ms [241 ; 294] |
| une touche tapée à la ligne 19 000, à l'intérieur, avec son redessin | 7 | 2,6 ms [2,6 ; 3,2], OpenGL | 1,06 ms [1,04 ; 1,08] | 0,045 ms [0,042 ; 0,063] | 0,059 ms [0,056 ; 0,068] |
| une ligne défilée, à l'intérieur, avec son redessin | 7 | 2,6 ms [2,5 ; 3,1], OpenGL | 1,51 ms [1,49 ; 1,60] | 0,020 ms [0,018 ; 0,030] | 0,052 ms [0,051 ; 0,083] |
| une touche tapée à la ligne 1 416 745 de 99,9 MB, à l'intérieur | 7 | 1,57 ms [1,41 ; 1,97], sans dessin | 1,05 ms [1,04 ; 1,10] | 0,042 ms [0,042 ; 0,053] | 0,057 ms [0,052 ; 0,060] |
| Enter qui indente, dans une fonction au milieu d'un fichier de 52 KB, d'un fichier Python de 107 KB pour les autres, à l'intérieur | 30 | 0,734 ms [0,701 ; 0,819], sans dessin | 0,197 ms [0,191 ; 0,211] | 18,8 ms [18,2 ; 19,2] | |
| la même chose au milieu de 100,5 MB, d'un fichier Python de 104,7 MB pour les autres | 30 | 0,832 ms [0,812 ; 0,859], sans dessin | 201 ms [200 ; 205] | 3,78 ms [3,70 ; 3,86] | |
| les mots qui complètent `co`, au milieu de 52 KB, d'un fichier Python de 107 KB pour les autres, à l'intérieur | 30 | 0,81 ms [0,79 ; 0,83], Tab, sans dessin | 4,07 ms [4,00 ; 4,12], `dabbrev` | 1,51 ms [1,15 ; 1,85], `Ctrl-N` | |
| la même chose dans 100,5 MB, d'un fichier Python de 104,7 MB pour les autres | 30 ; 3 et 7 pour les autres | 1,43 ms [1,39 ; 1,47], dans 128 KB | 23,2 s, tout le buffer | 948 ms [918 ; 995], tout le buffer | |
| chercher dans 15,9 MB un mot de la dernière ligne, le trouver | 7 | 7,6 ms [7,4 ; 7,9] | 7,6 ms [7,4 ; 7,9] | 28,3 ms [27,7 ; 29,6] | 33,6 ms [32,4 ; 36,8] |
| chercher dans 99,9 MB un mot de la dernière ligne, le trouver | 7 | 48,8 ms [48,4 ; 53,5] | 48,4 ms [47,8 ; 51,6] | 181 ms [179 ; 265] | 300 ms [290 ; 315] |
| la même chose, jusqu'à l'endroit montré | 7 | 87,6 ms [86,7 ; 88,6] | | | |
| collage de 1 MB au milieu de 99,9 MB | 7 | 44,7 ms [44,5 ; 46,7] | 238 ms [234 ; 250] | 2,82 ms [2,77 ; 2,96] | 2,84 ms [2,80 ; 3,04] |
| son annulation | 7 | 1,47 ms [1,45 ; 1,52] | 230 ms [228 ; 244] | 61,0 ms [60,6 ; 61,5] | 3,11 ms [3,07 ; 3,18] |
| enregistrer 15,9 MB, `fsync` avant `Saved` sauf pour Emacs | 7 | 64,0 ms [42,9 ; 102] | 131 ms [125 ; 131] | 85,6 ms [73,8 ; 107] | 83,4 ms [76,7 ; 127] |
| 288 préfixes de 41 requêtes, chacun classé parmi 1 933 noms de fichiers | 20 | 1 544 ms [1 537 ; 1 554] | 617 ms [604 ; 622], `flex` | 136 ms [135 ; 137], `matchfuzzy()` | 180 ms [179 ; 181], `matchfuzzy()` |
| les mêmes requêtes : mean reciprocal rank du fichier voulu | – | 0,898 | 0,748, `flex` | 0,898 | 0,898 |
| mémoire au repos, vide, PSS | 5 | 41,8 MB [41,7 ; 41,9] | 49,0 MB [48,0 ; 49,1] | 10,1 MB [9,8 ; 10,2] | 7,8 MB [7,7 ; 8,0] |
| mémoire avec 99,9 MB ouverts, RSS de tous ses processus | 7 | 220 MB [220 ; 220] | 151 MB [151 ; 151] | 137 MB [137 ; 138] | 133 MB [133 ; 133] |
| processeur au repos, % d'un cœur | 5 | 0,0 % [0,0 ; 0,0], dans une fenêtre Wayland | 0,0 % [0,0 ; 0,0] | 0,0 % [0,0 ; 0,0] | 0,0 % [0,0 ; 0,0] |

Avec $n = 5$, l'intervalle est celui de l'exécution la plus rapide et de la plus lente, à 93,75 % ; avec $n = 3$, seule la
médiane est donnée. Le mean reciprocal rank (la moyenne, sur les requêtes, de 1 divisé par le rang du fichier voulu : 1 quand
il vient toujours en premier) est expliqué dans le chapitre « Un cas : trouver un fichier à partir de quelques
lettres ».

Les temps intérieurs d'Emacs, de Neovim et de Vim ne comptent pas le dessin du terminal, que fait un autre programme ; ceux de
Cemacs comptent le sien. Les autres montrent ces fichiers comme du texte simple, là où Cemacs les colore. Neovim et Vim
appellent `fsync` avant de dire qu'un fichier est écrit, Emacs 31 non ; Cemacs le fait depuis cette version.

Ce qu'ils disent :

- **Vim et Neovim démarrent plusieurs fois plus vite que Cemacs.** Ce sont des programmes en C compilés en code machine, qui
  démarrent en quelques millisecondes et dessinent des caractères dans un terminal. Cemacs est un programme Cesia : Cesia lit
  et prépare environ 8 000 lignes de code à chaque démarrage, celles de Cemacs et des packages de Cesia qu'il emploie,
  environ 24 ms avec la prochaine version de Cesia et 38 ms avec la 1.1.0, puis SDL3 ouvre une fenêtre, et SDL3_ttf charge trois polices et dessine la première frame en pixels. Dans
  une vraie fenêtre sur GNOME, le démarrage par SDL de sa barre de titre à travers GTK et d'OpenGL le porte à 236 ms. Emacs,
  qui charge son propre Lisp au démarrage, prend 89 ms dans un terminal.
- **Cemacs ouvre un fichier plus vite qu'Emacs à chaque taille mesurée, 99,9 MB en 0,68 de son temps, mais Vim et Neovim
  ouvrent un grand fichier plus vite encore**, en 0,9 du temps de Cemacs à 99,9 MB, en la moitié à 15,9 MB. La rope de
  Cemacs ne copie plus le fichier : ses feuilles sont des vues du seul texte lu. Ce qui reste, c'est le démarrage, la
  vérification de l'UTF-8 en OCaml, et le compte des fins de ligne de chaque vue, là où Vim et Neovim remplissent des blocs
  de lignes en C.
- **Cemacs trouve un mot dans un grand fichier aussi vite qu'Emacs**, 48,8 contre 48,4 ms pour 99,9 MB, dans les
  intervalles, et quatre à six fois plus vite que Neovim et Vim : un seul appel de Cesia qui cherche dans le texte du fichier
  en place, huit octets à la fois, avec le case folding dans la même passe. Le Boyer–Moore d'Emacs saute des octets ; Neovim
  et Vim font passer une regular expression sur leurs lignes. Un endroit lointain est montré tout de suite, ses couleurs
  exactes quelques secondes plus tard.
- **L'annulation est la plus rapide dans Cemacs** : 1,5 ms pour le collage de 1 MB aux deux tailles, là où Vim prend 3 ms,
  Neovim 13 à 61 et Emacs 46 à 230, car Cemacs garde des états entiers, des valeurs qui ne changent jamais, et en reprend un
  en $O(1)$. **Un collage** coûte à Cemacs environ 45 ms, surtout les couleurs des lignes collées, contre 2,8 ms pour Vim et
  Neovim, qui ajoutent des lignes en C ; Emacs prend 238 ms à 99,9 MB, car il déplace son gap.
- **Un enregistrement de 15,9 MB qui attend le disque**, `fsync`, prend à Cemacs moins qu'à Vim et Neovim, qui attendent
  aussi, quand le texte est celui qui a été lu : ses vues couvrent encore le texte du fichier, écrit tel quel. Emacs, qui
  n'attend pas, prend plus, 131 ms, et fait un backup du fichier à son premier enregistrement, `FILE~`.
- **Enter qui indente une ligne de code** coûte à Cemacs moins d'une milliseconde à toutes les tailles de fichier, là où le
  python-mode d'Emacs, deux à quatre fois plus rapide dans un petit fichier, prend 0,2 s dans un fichier de 100 MB, et
  l'indentation de Python de Neovim de 3,8 à 19 ms : Cemacs lit une ligne depuis la ligne à la marge la plus proche au-dessus
  d'elle, comme le dit [Vitesse](performance.md#enter-et-tab-dans-un-fichier-de-cesia). Les deux autres n'ont pas de mode pour
  Cesia, aussi ont-ils été mesurés sur du Python.
- **La completion** d'un début de deux ou trois lettres prend à Cemacs de 0,7 à 1,4 ms à toute taille de fichier ; le
  `Ctrl-N` de Neovim est aussi rapide ou plus dans un petit fichier, et gagne sur un début d'une lettre, mais il lit tout le
  buffer, de 0,4 à 1 s dans 100 MB ; le `dabbrev` d'Emacs prend de 3 à 15 ms, et de 13 à 23 s, tandis que son `M-/`, qui ne
  cherche qu'un seul mot, prend de 0,04 à 0,2 ms.
- **Une touche et une ligne défilée** prennent à Cemacs 2,6 ms à l'intérieur, avec OpenGL, contre 1,1 à 1,5 ms pour Emacs et
  0,02 à 0,06 ms pour Neovim et Vim, qui écrivent quelques cases d'un terminal en C et laissent le terminal les dessiner.
  Tous tombent dans une même frame de l'écran, 16,7 ms à 60 Hz. Dans un fichier de 99,9 MB, à sa ligne du milieu, une touche
  coûte à Cemacs 1,6 ms sans dessin, à Emacs 1,05.
- **Au repos, Cemacs emploie une mémoire de l'ordre de celle d'Emacs vide, et quatre à cinq fois celle de Vim et de
  Neovim**, qui gardent les caractères d'un terminal là où Cemacs garde une fenêtre, ses polices et le runtime de Cesia. Avec
  un fichier de 99,9 MB ouvert, Cemacs garde 220 MB, 1,5 fois Emacs et 1,6 fois Vim et Neovim, qui gardent le fichier à peu
  près une fois : Cemacs le garde une fois aussi maintenant, les feuilles de sa rope voyant le texte lu, à côté des 46 MB de
  l'éditeur vide et de la mémoire que le collector d'OCaml (son garbage collector, la partie qui libère la mémoire que plus
  rien n'emploie) n'a pas rendue, comme le dit [Vitesse](performance.md#au-repos). Il gardait 475 MB avec un fichier Cesia
  avant, dont la vérification gardait le texte une fois de plus et occupait un cœur à moitié.
- **Au repos, aucun d'eux n'emploie le processeur** : chacun dort jusqu'à ce qu'un événement le réveille, Cemacs dans SDL,
  les autres sur leur terminal. Cemacs se réveille aussi quatre fois par seconde, pour les fibers de Cesia.
- La frappe n'est comparée qu'à l'intérieur de chaque programme : la mesure honnête du temps d'une touche jusqu'à l'écran
  demande une caméra ou un outil qui lit l'écran, comme Typometer, et aucun n'a été employé.

## En fonctions

D'abord deux mots. Un language server est un programme qui connaît un langage et donne à n'importe quel éditeur les
erreurs, les completions et les définitions de son code, par le Language Server Protocol, LSP ; un debug adapter fait de
même pour un debugger, par le Debug Adapter Protocol, DAP. Un éditeur qui parle les deux obtient chaque langage qui a un
server et un adapter.

| | Cemacs | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|
| Où il tourne | sa propre fenêtre, par SDL3 | un terminal, ou sa propre fenêtre | un terminal ; d'autres programmes peuvent le dessiner par son API | un terminal, ou sa propre fenêtre (gVim) |
| Touches | celles d'Emacs, avec des groupes sous `C-c` | les siennes | modal : un mode déplace, un autre tape | modal |
| Écrit en, modifié en | Cesia, les deux | C et Emacs Lisp ; modifié en Emacs Lisp | C et Lua ; modifié en Lua ou en Vimscript | C ; modifié en Vim9 script ou en Vimscript |
| Vos changements | `user/config/config.ce`, dans le dossier de Cemacs, que git ignore, créé à partir d'un template au premier démarrage | `~/.emacs.d/init.el`, ou `~/.config/emacs/init.el` | `~/.config/nvim/init.lua`, ou `init.vim` | `~/.vimrc`, `~/.vim/vimrc` ou `~/.config/vim/vimrc` |
| Changement pendant qu'il tourne | son code se recharge à chaque enregistrement sous `cesia do dev` ; un nouveau package demande un redémarrage | n'importe quel Lisp, à n'importe quel moment, change l'éditeur qui tourne | `:source` et `:lua` exécutent du nouveau code dans l'éditeur qui tourne | `:source` exécute du nouveau code dans l'éditeur qui tourne |
| Trouver une touche | la bande des hints après une demi-seconde, et `?` après toute prefix key | `which-key-mode`, inclus, désactivé tant qu'on ne l'active pas ; `C-h k`, `C-h b` | rien d'inclus : des plugins | rien d'inclus : des plugins |
| Une commande par son nom | aucune | `M-x` | les commandes `:` | les commandes `:` |
| Trouver un fichier d'un projet | `C-x p f` : les fichiers de `git ls-files`, classés par le score de fzy, les mots dans n'importe quel ordre | `C-x p f`, `project-find-file`, d'après `git ls-files` ; par défaut, correspondance par sous-texte et tri alphabétique, classement par son coût quand on choisit le style `flex` | rien pour les noms de fichiers : `:find` cherche dans `'path'` par wildcards (des motifs comme `*`) ; `'findfunc'` peut brancher `matchfuzzy()`, qui classe par le score de fzy | comme Neovim |
| Chercher et remplacer | incremental search, `C-s` et `C-r`, avec le case folding d'Emacs ; pas de regular expression, pas de remplacement | incremental search, par regular expression, remplacement | `/`, `:s` | `/`, `:s` |
| Les erreurs du code | celles de Cesia, d'après `cesia check`, une demi-seconde après une touche ; un fichier de plus de 1 MB n'est pas vérifié, et sa mode line le dit | Flymake, inclus, avec un vérificateur pour chaque langage | les diagnostics de son client LSP | par des plugins |
| Language servers (LSP) | pas de client ; les erreurs de Cesia viennent de `cesia check` | Eglot, inclus | un client inclus, `vim.lsp` | des channels qui parlent l'encodage de LSP ; le client est un plugin |
| Debugger | inclus, pour Cesia, avec breakpoints, steps, évaluations, fix and continue | GUD, inclus, pour gdb et d'autres debuggers | rien d'inclus : des plugins | Termdebug, inclus, pour gdb ; des channels qui parlent l'encodage de DAP |
| Indentation | pour Cesia, selon la règle de `cesia fmt` : Enter, Tab, et `end`, `else`, `then` et les parenthèses, crochets et accolades fermants au début d'une ligne | pour chaque langage, selon son mode : `indent-for-tab-command`, et `electric-indent-mode` à une fin de ligne et aux caractères qu'ajoute chaque mode | pour chaque type de fichier, selon son `'indentexpr'`, aux touches de ses `'indentkeys'`, comme `0=end` | comme Neovim |
| Completion | dans les fichiers de Cesia, Tab au bout d'un mot : les mots autour du curseur, ceux des autres buffers et les noms de Cesia, dans une liste sous le curseur | `completion-at-point` et `dabbrev-expand` (`M-/`), inclus ; `tab-always-indent` à `complete` | `Ctrl-N` et `Ctrl-P` en insert mode (le mode où l'on tape le texte) : les mots des buffers ; la completion du LSP | `Ctrl-N` et `Ctrl-P` |
| Annulation | linéaire, avec rétablir, 1 000 états | une annulation est enregistrée comme une modification, si bien qu'une annulation peut être annulée ; `undo-redo` | un arbre de chaque état | un arbre de chaque état |
| Encodages | UTF-8 seulement | beaucoup | beaucoup | beaucoup |
| Grands fichiers | ouvre jusqu'à 1 GiB | demande au-dessus de 10 MB, puis ouvre | ouvre | ouvre |
| Enregistrements à lui | aucun : pas de fichier d'autosave, de backup ni de swap file | fichiers d'autosave et backups | swap files | swap files, et backups si on le demande |

Les fonctions d'Emacs, de Neovim et de Vim ont été vérifiées sur les programmes installés : Eglot, Flymake, GUD et
`which-key` se chargent dans Emacs 31.1 sans package ajouté, et `large-file-warning-threshold` vaut 10 000 000 ; `vim.lsp`
est dans Neovim 0.12.6 ; Vim 9.2 a les modes `lsp` et `dap` de ses channels et le package Termdebug dans son runtime. Pour
les fichiers d'un projet, le `completion-category-defaults` d'Emacs 31.1 donne à `project-file` le style `substring`, et
`completions-sort` vaut `alphabetical` ; les `'wildoptions'` de Vim 9.2 et de Neovim 0.12.6 disent que la fuzzy completion
"is not supported for file and directory names" (n'est pas prise en charge pour les noms de fichiers et de dossiers).
[Un cas : trouver un fichier à partir de quelques lettres](finding.md) mesure le classement des quatre sur les mêmes
fichiers.

**Visual Studio Code**, d'après sa documentation, est une fenêtre à lui, étendue par des extensions écrites en TypeScript ou
en JavaScript avec son extension API, et il débogue par des debug adapters qui parlent le Debug Adapter Protocol, si bien
qu'une seule interface sert n'importe quel debugger qui a un adapter. Le debugger de Cemacs, au contraire, parle un petit
protocole à lui avec un seul debugger, celui de Cesia :
[Exécuter et déboguer](running.md#comment-cemacs-parle-avec-le-debugger).

## Où en est Cemacs

Ce que Cemacs fait et qu'ils ne font pas d'emblée :

- **Il se modifie dans le langage qu'il édite.** Un programmeur Cesia modifie Cemacs avec ce qu'il sait déjà, et les exemples
  de ce livre tournent sur son vrai code. Emacs est le modèle ici, avec le Lisp.
- **Son debugger et ses erreurs ne demandent aucune installation.** Chez les autres, un debugger pour un nouveau langage
  demande un adapter ou un plugin ; Cemacs connaît celui de Cesia.
- **Ses touches se montrent d'elles-mêmes.** La bande des hints est active dès le départ, et `?` après toute prefix key liste
  ce qui suit.

Ce qu'ils font et que Cemacs ne fait pas, et pourquoi cela compte :

- **La recherche par regular expression et le remplacement, la completion par un language server, une commande par son
  nom, d'autres langages et d'autres encodages, un terminal à l'intérieur.** Cemacs n'en a encore aucun, à part son
  incremental search et sa completion des mots : c'est un éditeur jeune pour un seul langage, et il grandit quand son usage
  le demande.
- **La vitesse au démarrage et sur les grands fichiers.** Du code natif qui lit et parcourt les octets d'un fichier à la
  vitesse de la mémoire.
- **La sûreté du texte.** Emacs, Vim et Neovim gardent sur le disque une copie de ce que vous tapez, si bien qu'un crash perd
  peu ; Cemacs ne la garde qu'en mémoire.
- **La maturité.** Leur code tourne depuis des décennies, sur beaucoup de systèmes ; Cemacs est essayé sous Linux, par son
  auteur et ses tests.
