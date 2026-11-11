# Vitesse

Ce chapitre donne ce que Cemacs coûte en temps et en mémoire, comment chaque nombre a été mesuré, et pourquoi il est ce
qu'il est. Cemacs garde quatre objectifs depuis sa première version, pour un fichier de 20 000 lignes dans une fenêtre de
1920 sur 1080 : une touche jusqu'à sa frame en moins de 16 ms, le temps d'une frame à 60 frames par seconde ; un défilement
à 60 lignes par seconde ; une ouverture en moins de 300 ms ; et aucune frame du tout de la part d'un éditeur qui attend.
Chaque section met Cemacs à côté de GNU Emacs 31.1, Neovim 0.12.6 et Vim 9.2 là où la même chose peut se mesurer sur eux ;
[Cemacs et les autres éditeurs](comparison.md) rassemble les nombres et les fonctions.

## Comment c'est mesuré

- **La machine :** un Intel Core i7-4720HQ, 4 cœurs et 8 threads (fils d'exécution) à 2,6 GHz, sa fréquence laissée au
  système ; 11 GB de mémoire ; Arch Linux, Linux 7.2.11. Cesia 1.0.0+dev, à a548741 pour les nombres qui comparent cette
  version à la précédente, SDL3 3.4.18, SDL3_ttf 3.2.2, Mesa 26.2.6, tmux 3.8.
- **Seul :** chaque mesure a tourné pendant qu'aucune autre tâche lourde de la machine ne tournait, sous un même lock (ce
  qui réserve la machine à une seule tâche lourde à la fois et fait attendre les autres) que partagent les tâches lourdes.
- **La fenêtre :** le dummy driver de SDL, `SDL_VIDEODRIVER=dummy`, qui dessine en mémoire avec le software renderer de SDL
  (le dessin des pixels par le processeur) et ne montre rien. Un vrai écran ajoute le travail du driver graphique et du
  compositor (le programme qui assemble les fenêtres à l'écran), et le vsync, que ce driver n'a pas. Les autres éditeurs ont
  tourné dans un terminal de tmux, de 160 caractères sur 50, qui répond aux questions qu'ils posent à un terminal à leur
  démarrage comme le fait un vrai terminal.
- **Les nombres :** chaque mesure a tourné n fois, comme indiqué à côté d'elle, les éditeurs chacun à leur tour. Le nombre
  donné est la médiane, l'exécution du milieu, qu'une seule exécution lente ne peut pas déplacer comme elle déplace une
  moyenne. L'intervalle à 95 % qui le suit, comme [49,2 ; 50,3], va d'une exécution à une autre de la liste triée, choisies
  pour que la vraie médiane soit entre elles avec une probabilité d'au moins 95 %, quelle que soit la distribution des
  temps : avec $n = 20$, la 6e et la 15e ; avec $n = 10$, la 2e et la 9e. Avec $n = 5$, la plus rapide et la plus lente sont
  ce qu'on peut faire de mieux, à 93,75 % ; avec $n = 3$, seule la médiane est donnée.
- **Les scripts** sont sur cette page ou dans `bench/`, pour que chacun puisse les relancer.

## Le démarrage

De la commande à la première frame de la fenêtre, avec un seul buffer vide, $n = 20$ :

| Éditeur, tel que lancé | Du lancement à la première frame |
|---|---|
| Cemacs, dans sa fenêtre, dummy driver de SDL | 51,1 ms [50,9 ; 51,9] |
| Cemacs, la version d'avant celle-ci | 49,8 ms [49,5 ; 50,8] |
| GNU Emacs 31.1, `emacs -Q -nw` | 89,1 ms [88,3 ; 92,9] |
| Neovim 0.12.6, `nvim --clean -n` | 13,8 ms [13,6 ; 13,9] |
| Vim 9.2, `vim --clean -n` | 9,3 ms [9,2 ; 9,4] |

Chaque éditeur a démarré sans configuration de l'utilisateur, et on lui a dit de dessiner son écran et de quitter :
`--eval '(progn (redisplay t) (kill-emacs))'` pour Emacs, `'+redraw!' '+qa!'` pour Neovim et Vim. Chaque exécution est le
temps du processus, de son démarrage à sa fin, tel qu'un programme Python à l'intérieur du terminal l'a chronométré. Cette
version charge 1,3 ms de plus que la précédente : la recherche, le lecteur des états des couleurs et la recherche dans la
rope ajoutent environ 475 lignes de code, que Cesia lit à chaque démarrage. La vérification de l'UTF-8 de
[Ouvrir un fichier](#ouvrir-un-fichier), un seul appel de Cesia désormais, a retiré 94 lignes de ce que lit Cesia : mesurée plus
tard à côté de la version d'avant elle, à 8ee42e7, chacune à son tour, $n = 11$, 53,2 ms [52,7 ; 54,7] contre 54,1 ms [53,7 ;
55,4], pas plus lente.

Cette version contre la précédente, `main` à b2ab23f, chacune à son tour, $n = 15$ : 53,7 ms [53,4 ; 55,3] contre 54,7 ms
[54,3 ; 55,0]. Les étapes de cette version ont ajouté environ 200 lignes de code, ce qui a allongé le démarrage de 1,9 ms,
56,6 ms [56,2 ; 57,4] ; les widgets de `src/ui` que rien dans Cemacs n'employait, une barre de menus, une barre d'outils, des
curseurs de réglage, des listes et des nœuds de graphe d'un design plus ancien, environ 290 lignes, ont été retirés, et le
démarrage est maintenant plus court de 1 ms qu'avant.

Où sont passées les 51 ms, avec le dummy driver, avant cette version, chaque partie chronométrée depuis la précédente par le
programme ci-dessous, avec une marque après chaque partie, $n = 20$, médianes :

| Partie | Temps | À qui |
|---|---|---|
| le démarrage propre de Cesia, comme pour `io.Print(1)` | 3,2 ms | Cesia |
| la lecture et la préparation du code : 6 977 lignes de Cemacs et des packages de Cesia qu'il emploie, 29 fichiers | 25,9 ms | Cesia |
| la vidéo de SDL3, la fenêtre, son renderer, et SDL3_ttf avec la première police | 4,0 ms | SDL |
| les deux autres polices | 0,2 ms | SDL |
| la taille d'un caractère, les premiers textes mesurés | 2,8 ms | SDL |
| l'état, son buffer et son écran | 0,3 ms | Cemacs |
| la frame : ses commandes, puis SDL qui les dessine | 10,7 ms | Cemacs et SDL |
| la fermeture de la fenêtre, et la fin du processus | 2,1 ms | SDL et Cesia |

L'essentiel de la frame est SDL3_ttf qui fait les premières images des caractères, qu'il garde ensuite. Charger le code
coûte à Cesia environ 3,7 µs par ligne : le [livre de Cesia](https://www-celestial.github.io/cesia-lang/) dit comment il lit,
vérifie et compile un programme. `--no-spec` et `--no-jit` n'y changent rien : 30,8 et 30,4 ms contre 30,5 pour le seul
chargement, $n = 20$. Chargés seuls, avec ce que chacun emploie, $n = 20$ : les packages de Cesia que Cemacs emploie,
4,3 ms ; `src/ui`, 5,1 ; `src/sdl`, 6,5 ; `core/commands` et tout ce qu'il emploie, 26,6 ; tout Cemacs, 31,1 ms. Ces
nombres ont été mesurés avant cette version ; les widgets de `src/ui` sont partis depuis, et environ 300 lignes de sortes de
dessin de `src/sdl` que seuls ses tests emploient sont encore lues : anneaux, fondus, ombres, images, tuiles, icônes et
courbes.

Dans une vraie fenêtre, le démarrage coûte bien plus, et l'essentiel n'est pas à Cemacs. Mesuré dans une fenêtre Wayland du
driver Wayland de SDL, dans le compositor de GNOME lancé headless (sans écran),
`mutter --headless --wayland --no-x11 --virtual-monitor 1280x720`, qui ne montre rien sur un écran, $n = 10$ : 236 ms [232 ;
241], 237 ms [229 ; 244] pour la version d'avant. Sur ce temps, la vidéo de SDL démarre en environ 80 ms et fait la fenêtre en
environ 60 : sur GNOME, dont le compositor ne dessine pas de barre de titre, SDL demande à libdecor, une bibliothèque qui
dessine la barre dans le programme, et le plugin de libdecor pour GTK démarre GTK. Avec à la place le plugin de libdecor pour
cairo, une barre plus simple, les deux prennent environ 14 et 38 ms ; sans libdecor,
`SDL_VIDEO_WAYLAND_ALLOW_LIBDECOR=0`, 4 ms et 1 ms, et la fenêtre n'a pas de barre de titre du tout. Le renderer, ici
OpenGL, prend environ 40 ms de plus. Emacs, Vim et Neovim dessinent dans un terminal déjà ouvert, et ne paient rien de tout
cela.

Le démarrage de Cemacs a été mesuré avec ce programme, qui fait ce que fait `bin/cemacs` jusqu'à sa première frame, puis
ferme la fenêtre et se termine. Il a été lancé depuis le dossier de Cemacs avec
`cesia run --allow read,write,exec=cesia,env=HOME,env=PWD,env=XDG_DATA_HOME,ffi=SDL3,ffi=SDL3_ttf first-frame.ce . [FILE]` :

```cesia norun
use src/buffers
use src/check
use src/emacs
use src/folders
use src/help
use src/output
use src/project
use src/sdl
use src/ui
use core/commands
use core/text
use core/view
use std/dict
use std/io
use std/list
use std/result
use std/sys

Keys() = help.WithHelp(dict.Merge(dict.Merge(dict.Merge(dict.Merge(dict.Merge(emacs.Keys(), buffers.Keys()), folders.Keys()), project.Keys()), check.Keys()),
  output.Keys()))
Config() = check.Hooked(emacs.Config(Keys))

defn main()
  home = sys.Args[1]
  size = Config().FontSize()
  first = sdl.Open("Cemacs", 1280, 720, "$home/fonts/AdwaitaSans-Regular.ttf", size = size, light = true)?
  second = sdl.AddFont("strong", "$home/fonts/NotoSans-Medium.ttf", size, first, light = true)?
  window = sdl.AddFont("code", "$home/fonts/JetBrainsMono-Regular.ttf", size, second)?
  measured = sdl.Measure(window)
  look = ui.Look(ui.Dark, measured.Width, measured.Height)
  cell = {Width: look.Width("M", "code"), Height: sdl.TextSize("Ag", window, font = "code").Height + view.LineGap}
  empty = view.Start([text.Of("", missing)], look, cell, 1280, 720)
  empty.Window = window
  empty.Config = Config
  empty.Home = home
  state = commands.Settled(commands.OpenAll(list.Skip(1, sys.Args), empty))
  shown = sdl.Frame(view.View(state), window)
  sdl.Close(shown)
  result.Ok(state.Buffers[state.Current].Path)
end

io.Print(main())
```

## Ouvrir un fichier

De la commande à la première frame, avec le fichier donné, $n = 7$, cette version, la version d'avant elle, `main` à
b2ab23f, et les trois autres éditeurs chacun à son tour ; les fichiers sont la bibliothèque standard de Cesia mise bout à
bout, et la dernière ligne contient un mot qu'on ne trouve nulle part ailleurs, pour la [recherche](#recherche) :

| Fichier | Cemacs | Cemacs d'avant | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|---|
| 0,79 MB, 22 490 lignes | 66,9 ms [66,2 ; 71,0] | 68,5 ms [66,4 ; 83,9] | 98,4 ms [97,7 ; 109] | 20,5 ms [20,4 ; 42,7] | 18,0 ms [17,4 ; 19,8] |
| 15,9 MB, 449 762 lignes | 97,8 ms [97,1 ; 139] | 123 ms [122 ; 125] | 145 ms [142 ; 149] | 53,2 ms [52,8 ; 61,9] | 51,5 ms [50,4 ; 52,0] |
| 99,9 MB, 2 833 490 lignes | 266 ms [262 ; 281] | 416 ms [413 ; 500] | 393 ms [392 ; 460] | 235 ms [231 ; 317] | 247 ms [241 ; 294] |

Les autres éditeurs ne connaissent pas Cesia : ils montrent donc ces fichiers comme du texte simple, là où Cemacs colore les
lignes de l'écran. On a dit à Emacs de ne pas demander avant un grand fichier, `(setq large-file-warning-threshold nil)` ;
Neovim et Vim ont été lancés avec `-n`, qui ne fait pas de swap file (le fichier où ils copient le texte modifié).

Ce que coûte l'ouverture de 99,9 MB, mesurée seule, sans la fenêtre, $n = 7$, les deux versions chacune à son tour :

| Étape | Cette version | La version d'avant |
|---|---|---|
| la lecture du fichier sur le disque, `sys.Read` | 23,5 ms [22,4 ; 27,5] | 24,5 ms [22,6 ; 28,6] |
| la vérification de l'UTF-8 et des octets nuls, [files.IsText] | 63,4 ms [61,2 ; 74,4] | 62,4 ms [62,0 ; 68,9] |
| la rope, [rope.Of] | 105 ms [104 ; 118] | 258 ms [256 ; 352] |
| le pic de mémoire du processus, `VmHWM` | 193 MB | 245 MB |

Ce qui a changé : la rope ne copie plus le fichier. Ses feuilles étaient 97 540 morceaux de 1 024 octets, chacun une copie
de ses octets et un record de six champs, joints par autant de nœuds, environ 195 000 records faits en Cesia, à environ une
microseconde chacun ; ce sont maintenant 6 097 vues de 16 KiB du seul texte lu, sans copie, et autant de nœuds :
[À l'intérieur de Cemacs](internals.md#la-rope). Cesia lui-même lit maintenant un fichier en un seul texte de sa taille, là
où il remplissait un buffer (une zone de mémoire de travail) puis le copiait, et compte les fins de ligne et vérifie l'UTF-8
huit octets à la fois.

Cemacs ouvre maintenant 99,9 MB en 0,68 du temps d'Emacs, et 15,9 MB en 0,68 aussi ; Neovim et Vim ouvrent encore un grand
fichier plus vite, en 0,89 et 0,93 du temps de Cemacs à 99,9 MB, et en environ la moitié à 15,9 MB. Ce qui reste est
surtout à Cesia : le démarrage, environ 55 ms, comme le dit [Le démarrage](#le-démarrage), qui décide en dessous d'environ
20 MB ; la vérification des octets, 63 ms, deux passes huit octets à la fois en OCaml, là où une bibliothèque en C avec les
instructions vectorielles du processeur, comme simdutf, prendrait environ un sixième ; et les 105 ms de la rope, dont le
compte des fins de ligne de chaque vue, sur des slices de 2 KiB, fait environ 70 ms mesuré seul, car Cesia n'a pas d'appel
qui compte dans une partie d'un texte sans slice. Neovim et Vim remplissent des blocs de lignes en C, environ 2,3 ns par
octet en tout ; les battre à 100 MB demande l'un de ces deux appels dans Cesia.

## Taper et faire défiler

`bench/gate.ce` mesure le core et la frame sur un texte de 20 000 lignes, la bibliothèque standard de Cesia répétée telle
que le binaire de Cesia la porte, [cesia.Libraries], dans une fenêtre de 1920 sur 1080 à 13 points, sans vsync : 300 passes
d'un caractère tapé à la ligne 19 000, puis 300 passes d'une ligne défilée, chaque passe faite de `view.FollowState`,
`view.View` et `sdl.Frame`. Il affiche la médiane et la pire passe, et la médiane de chacune des trois parties :

```bash
SDL_VIDEODRIVER=dummy cesia run --allow read,ffi=SDL3,ffi=SDL3_ttf bench/gate.ce
```

Sept exécutions de cette version, chacune à son tour avec l'une de la version d'avant, `main` à b2ab23f, et avec chaque
étape entre elles ; la médiane des médianes des sept exécutions, et son intervalle :

| Version | Un caractère tapé | Une ligne défilée | La vue d'une passe | Premier saut à la ligne 19 000 |
|---|---|---|---|---|
| avant, b2ab23f | 11,7 ms [11,4 ; 11,8] | 18,5 ms [17,8 ; 19,5] | 2,9 ms | 30,6 ms [30,3 ; 49,0] |
| + objets de texte gardés selon leurs mots | 11,3 ms [11,1 ; 11,4] | 11,4 ms [11,0 ; 11,8] | 2,8 ms | |
| + rangées de l'écran gardées | 9,5 ms [9,4 ; 10,0] | 9,2 ms [9,1 ; 9,7] | 0,7 ms | 32,6 ms [31,1 ; 41,0] |
| + couleurs en chunks | 9,1 ms [9,0 ; 9,2] | 9,2 ms [9,0 ; 9,4] | 0,7 ms | 34,5 ms [31,7 ; 55,1] |
| cette version | 9,2 ms [9,0 ; 9,7] | 9,1 ms [8,9 ; 9,5] | 0,7 ms | 30,0 ms [29,7 ; 36,9] |

La deuxième ligne a été mesurée dans une série à elle, avant que Cesia change ses recherches cet après-midi-là, à côté de
11,4 ms [11,4 ; 12,0] et 18,6 ms [18,2 ; 18,9] pour la version d'avant. Une ligne défilée coûte maintenant ce que coûte une
touche, 9,1 ms, 110 lignes par seconde : l'objectif de 60 est atteint, là où il ne l'était pas avant (54 par seconde). Où est
passé le temps, et ce qui a changé :

- **Le shaping.** SDL3_ttf fait le shaping d'un texte (le calcul des glyphes de la police et de leurs places), avec
  HarfBuzz, la première fois qu'il est dessiné avec de nouveaux mots. Ses objets de texte appartenaient à des places dans
  l'ordre de la frame : quand chaque ligne montait d'une rangée, presque chaque objet recevait de nouveaux mots et repassait
  par le shaping, 227 des 232 textes d'une frame défilée, environ 32 µs chacun. Gardés selon leurs mots, ils ne passent
  qu'une fois par le shaping, et une ligne défilée ne fait le shaping que des mots de la ligne qui entre : la frame d'un
  défilement, 14,6 → 7,9 ms.
- **La vue.** Elle lisait chaque ligne de l'écran dans la rope, 55 lectures, et colorait chacune à nouveau ; les rangées
  gardées par [view.Follow] épargnent les deux : 2,9 → 0,7 ms pour une touche.
- **Ce qui reste** est la frame du software renderer de SDL, environ 7,8 ms : le raster (le calcul de chaque pixel) de toute
  la fenêtre de 1920 sur 1080, 8,3 MB de pixels, à chaque frame. Une vraie fenêtre dessine avec la carte graphique : voir
  plus bas.
- Le premier saut à la ligne 19 000 lit une fois l'état des couleurs de chaque ligne au-dessus d'elle : 30,0 ms contre 30,6
  avant. Le gate ne chronomètre là que `view.FollowState`, qui, depuis que les rangées sont gardées, fait aussi les tokens du
  premier écran, 1 à 2 ms que la vue ne fait plus ; les étapes entre les deux ont mesuré de 32,6 à 35,0 ms, avec des
  intervalles qui montent jusqu'à 41 à 58 ms : le gate fait un seul saut par exécution, un seul échantillon, là où une
  touche ou un défilement est la médiane de 300.

Le même gate dans une vraie fenêtre Wayland, avec OpenGL : le compositor de GNOME, `mutter --headless --wayland --no-x11
--virtual-monitor 1920x1080`, SDL sans libdecor, et le llvmpipe de Mesa, qui dessine l'OpenGL avec le processeur, car la
carte graphique de cette machine n'est pas joignable depuis le compositor headless, $n = 7$ :

| Version | Un caractère tapé | Une ligne défilée | Sa frame |
|---|---|---|---|
| avant, b2ab23f | 5,3 ms [5,1 ; 5,8] | 11,9 ms [11,4 ; 13,4] | 1,3 ms, 7,8 ms |
| + les trois étapes de la frame, jusqu'aux couleurs en chunks | 2,6 ms [2,5 ; 3,2] | 2,5 ms [2,4 ; 2,8] | 1,1 ms, 1,3 ms |
| cette version | 2,6 ms [2,6 ; 3,2] | 2,6 ms [2,5 ; 3,1] | 1,1 ms, 1,3 ms |

À côté des autres, chacun chronométrant sa propre touche et sa propre ligne défilée avec son redessin, à l'intérieur du
programme, dans un terminal de tmux, sur le texte du gate écrit dans un fichier, $n = 7$, les trois chacun à son tour dans
une série à eux, le même après-midi :

| Éditeur | Un caractère tapé à la ligne 19 000 | Une ligne défilée |
|---|---|---|
| Cemacs, OpenGL | 2,6 ms [2,6 ; 3,2] | 2,6 ms [2,5 ; 3,1] |
| Cemacs, software renderer de SDL | 9,2 ms [9,0 ; 9,7] | 9,1 ms [8,9 ; 9,5] |
| GNU Emacs 31.1, `(redisplay t)` | 1,06 ms [1,04 ; 1,08] | 1,51 ms [1,49 ; 1,60] |
| Neovim 0.12.6, `redraw` | 0,045 ms [0,042 ; 0,063] | 0,020 ms [0,018 ; 0,030] |
| Vim 9.2, `redraw` | 0,059 ms [0,056 ; 0,068] | 0,052 ms [0,051 ; 0,083] |

Les autres gagnent encore, et de loin pour Vim et Neovim : ils écrivent les quelques cases d'un terminal qui ont changé, en
C, et le terminal, un autre programme, dessine les pixels, ce que leur temps ne compte pas ; l'interface de terminal de
Neovim est même un processus à part. Emacs, dans un terminal lui aussi, compare les rangées qu'il veut avec celles de
l'écran, n'envoie que ce qui diffère, et trouve la façon la moins chère de décaler ses lignes par programmation dynamique,
dans son `src/scroll.c`, la méthode du redisplay de Gosling de 1981. Cemacs fait lui-même le shaping et dessine les pixels,
la frame entière à chaque événement. Une frame de l'écran dure 16,7 ms à 60 Hz : chacun de ces temps, les cinq, tombe dans
la même frame, et l'œil ne peut pas les distinguer. Le temps honnête d'une touche jusqu'à l'écran demande une caméra, ou un
outil qui regarde l'écran comme Typometer, et aucun n'a été employé.

### Une touche dans un grand fichier

Un caractère tapé à la ligne du milieu, 1 416 745, du fichier de 99,9 MB, sans dessin pour Cemacs : 100 touches, chacune
suivie de `view.FollowState` et `view.View`, comme le font la mise à jour et la vue, les couleurs d'abord lues jusqu'à
l'écran ; les autres avec leur redessin, $n = 7$, les versions de Cemacs chacune à son tour, et les autres dans une série à
eux :

| Éditeur | Médiane des médianes des exécutions | La pire touche des exécutions |
|---|---|---|
| Cemacs | 1,57 ms [1,41 ; 1,97] | 2,45 ms [2,23 ; 4,17] |
| Cemacs, avec seulement les couleurs en chunks | 1,37 ms [1,20 ; 1,96] | 2,28 ms [1,65 ; 3,59] |
| Cemacs d'avant, b2ab23f | 43,7 ms [40,8 ; 48,0] | 92,5 ms [70,9 ; 100,1] |
| GNU Emacs 31.1 | 1,05 ms [1,04 ; 1,10] | 23,3 ms [22,9 ; 23,3] |
| Neovim 0.12.6 | 0,042 ms [0,042 ; 0,053] | 0,25 ms [0,23 ; 0,33] |
| Vim 9.2 | 0,057 ms [0,052 ; 0,060] | 0,12 ms [0,09 ; 0,14] |

Les couleurs gardaient l'état au début de chaque ligne dans une seule liste plate, coupée et prolongée par des copies à
chaque modification : à la ligne 1,4 million, deux copies de 1,4 million d'états, 22 MB de garbage (de mémoire que plus rien
n'emploie), à chaque touche. En chunks de 1 024 lignes, une modification copie la liste de 1 384 chunks et un chunk :
[À l'intérieur de Cemacs](internals.md#les-couleurs). La taille du fichier ne compte plus : la touche coûte à peu près ce
qu'elle coûte à la ligne 19 000 du gate sans son dessin, et les deux lignes de Cemacs diffèrent de moins que leurs
intervalles. La touche médiane d'Emacs fait environ les deux tiers de celle de Cemacs, et sa pire touche dix fois la pire de
Cemacs ; Vim et Neovim, qui changent une ligne de leur memline et écrivent quelques cases du terminal, restent 30 fois plus
rapides.

## Recherche

Une recherche d'un mot qu'on ne trouve que sur la dernière ligne du fichier, depuis son début : les autres chacun dans un
processus, le fichier chargé, le `search-forward` d'Emacs dans `emacs --batch`, le `search()` de Neovim dans
`nvim --headless`, le `search()` de Vim dans `vim -es` ; Cemacs sans fenêtre, le fichier ouvert, puis `C-s` et le mot tapé
comme un seul texte à travers [commands.Update], jusqu'à l'état qui montre l'endroit ; $n = 7$, tous chacun à son tour :

| Mesure | 15,9 MB | 99,9 MB |
|---|---|---|
| GNU Emacs 31.1, `search-forward` | 7,6 ms [7,4 ; 7,9] | 48,4 ms [47,8 ; 51,6] |
| Neovim 0.12.6, `search()` | 28,3 ms [27,7 ; 29,6] | 181 ms [179 ; 265] |
| Vim 9.2, `search()` | 33,6 ms [32,4 ; 36,8] | 300 ms [290 ; 315] |
| Cemacs, trouver l'endroit, [rope.Find] seul | 7,6 ms [7,4 ; 7,9] | 48,8 ms [48,4 ; 53,5] |
| Cemacs d'avant, b2ab23f, la même chose | 92,5 ms [89,7 ; 144] | 583 ms [573 ; 596] |
| Cemacs, `C-s` et le mot, jusqu'à l'endroit montré | 45,9 ms [45,2 ; 49,4] | 87,6 ms [86,7 ; 88,6] |
| Cemacs d'avant, la même chose | 767 ms [762 ; 816] | 5 457 ms [5 302 ; 5 823] |
| Cemacs, la même chose tapée une lettre à la fois | 293 ms [288 ; 306] | 341 ms [338 ; 348] |
| Cemacs d'avant, la même chose | 767 ms [758 ; 831] | 5 591 ms [5 419 ; 5 864] |

Le mot n'a pas de majuscule : chaque recherche ici fait donc le case folding. Trouver l'endroit coûte à Cemacs ce que coûte
un seul appel au [text.ByteFind] de Cesia sur le texte du fichier, en place, huit octets à la fois, avec la casse traitée
dans la même passe : [Recherche](search.md#comment-elle-trouve). Il joignait chaque fenêtre de la rope en un seul texte, le mettait
en minuscules, puis le cherchait, un octet à la fois. Emacs cherche dans son buffer en place, en C, avec une recherche de
Boyer–Moore dont les tables font le case folding : elle compare le mot depuis sa fin et saute en avant d'après les tables, si
bien que la plupart des octets ne sont jamais regardés ; Neovim et Vim font passer leur moteur de regular expressions sur
leurs lignes. Cemacs trouve maintenant le mot aussi vite qu'Emacs, dans les intervalles, et 4 et 6 fois plus vite que Neovim
et Vim. Pour passer sous Emacs, la recherche elle-même devrait lire plus de huit octets par pas, avec les instructions
vectorielles du processeur, SIMD, qu'OCaml ne donne pas : une version en C avec SSE2, 16 octets par pas, a pris 8,8 ms pour
99,9 MB quand la recherche de Cesia a été conçue. Taper le mot une lettre à la fois coûte plus que le taper d'un coup :
chacune de ses neuf lettres cherche à nouveau depuis l'endroit où la recherche a commencé, comme le fait l'incremental search
d'Emacs, et chaque recherche qui trouve son endroit loin en bas relit le texte jusque-là.

Montrer l'endroit prenait bien plus que le trouver : les couleurs de l'écran dépendent de l'état de chaque ligne d'avant,
1,3 µs par ligne. Un endroit lointain est maintenant montré tout de suite avec ses couleurs devinées, et elles deviennent
exactes au fil des ticks suivants, [view.ColorBatch] lignes par tick :
[À l'intérieur de Cemacs](internals.md#un-endroit-lointain-dabord-ses-couleurs-exactes-ensuite). `M->` seul, l'endroit montré avec les
commandes de sa frame, puis les ticks de 16 ms jusqu'à ce que les couleurs soient exactes, chacun avec ses commandes,
$n = 7$ :

| Mesure | 15,9 MB | 99,9 MB |
|---|---|---|
| Cemacs, `M->`, l'endroit montré | 38,5 ms [37,7 ; 129] | 36,1 ms [35,4 ; 41,7] |
| Cemacs, les couleurs exactes | 673 ms [637 ; 1 173], 17 ticks | 4 072 ms [3 957 ; 4 259], 113 ticks |
| Cemacs, le tick le plus lent d'une exécution | 40,6 ms [38,2 ; 114] | 60,0 ms [45,0 ; 69,2] |
| Cemacs d'avant, b2ab23f, l'endroit montré, ses couleurs exactes | 699 ms [671 ; 737] | 4 615 ms [4 518 ; 4 800] |

Un tick lit 25 000 lignes en environ 36 ms avec les commandes de sa frame, le temps d'une exécution divisé par ses ticks ;
son plus lent, environ 60 ms, reste sous le dixième de seconde. Une touche tapée pendant ce temps lit aussi un lot : elle
attend donc jusqu'à autant de plus avant que les couleurs soient exactes ; et un commentaire ou un texte ouvert loin au-dessus
peut colorer l'écran de travers pendant ces secondes. Emacs, Neovim et Vim ont montré ces fichiers sans couleurs, car ils ne
connaissent pas Cesia. Dans un langage qu'il connaît, Vim colore à partir d'une supposition faite quelques lignes au-dessus
de l'écran, son `syntax sync` ; Emacs ne colore que ce qui est montré, son jit-lock, à partir de l'état de son parser, que
`syntax-ppss` lit depuis l'endroit le plus proche où il en a gardé un.

## Coller, annuler et enregistrer

Un collage de 1 MB à la ligne du milieu du fichier, son annulation, puis un enregistrement par-dessus le fichier, qui
contient alors le texte qu'il avait ; Cemacs sans fenêtre, les commandes de la frame faites après chaque étape, les couleurs
d'abord lues jusqu'à l'écran ; les autres dans un terminal de tmux, chaque étape chronométrée à l'intérieur avec son
redessin ; $n = 7$, tous chacun à son tour :

| Étape | Cemacs | Cemacs d'avant | GNU Emacs 31.1 | Neovim 0.12.6 | Vim 9.2 |
|---|---|---|---|---|---|
| collage de 1 MB, 15,9 MB | 52,4 ms [52,2 ; 69,8] | 67,2 ms [62,4 ; 67,6] | 42,9 ms [41,9 ; 44,1] | 2,71 ms [2,64 ; 2,81] | 2,57 ms [2,46 ; 2,72] |
| son annulation, 15,9 MB | 1,60 ms [1,52 ; 1,72] | 14,5 ms [13,8 ; 14,8] | 46,5 ms [45,4 ; 47,3] | 13,4 ms [13,3 ; 13,9] | 2,92 ms [2,68 ; 4,04] |
| enregistrement, 15,9 MB | 64,0 ms [42,9 ; 102] | 30,8 ms [29,2 ; 31,8] | 131 ms [125 ; 131] | 85,6 ms [73,8 ; 107] | 83,4 ms [76,7 ; 127] |
| collage de 1 MB, 99,9 MB | 44,7 ms [44,5 ; 46,7] | 93,6 ms [89,3 ; 125] | 238 ms [234 ; 250] | 2,82 ms [2,77 ; 2,96] | 2,84 ms [2,80 ; 3,04] |
| son annulation, 99,9 MB | 1,47 ms [1,45 ; 1,52] | 49,1 ms [47,9 ; 57,1] | 230 ms [228 ; 244] | 61,0 ms [60,6 ; 61,5] | 3,11 ms [3,07 ; 3,18] |
| enregistrement, 99,9 MB | 274 ms [250 ; 636] | 599 ms [380 ; 887] | 584 ms [578 ; 589] | 764 ms [449 ; 1 424] | 851 ms [580 ; 901] |

Cette version appelle `fsync` avant de dire `Saved`, comme le font Neovim et Vim et non Emacs, là où la version d'avant ne le
faisait pas : [Fichiers et buffers](files.md#ne-jamais-perdre-le-texte). La même version sans lui enregistrait les 15,9 MB en
7,4 ms [6,8 ; 7,6] : le disque prend donc le reste ; son temps varie avec ce que le système de fichiers a encore à écrire,
comme le montrent les larges intervalles des quatre éditeurs qui l'attendent. Elle reste plus rapide que les autres, parce
que le texte enregistré ici est le texte lu, après l'annulation : les vues de la rope couvrent encore le seul texte du
fichier, qui est donc écrit tel quel, là où la version d'avant joignait d'abord ses 97 540 feuilles en un nouveau texte. Un
buffer qui a été modifié est joint une fois, puis écrit.

- **L'annulation** prend environ 1,5 ms aux deux tailles, la plus rapide des quatre : l'historique garde des états entiers,
  des valeurs qui ne changent jamais, si bien qu'en reprendre un est en $O(1)$, 0,1 ms ; le reste, ce sont les commandes de
  la frame. Elle coûtait avant les copies des états des couleurs, 49 ms à 99,9 MB. Vim efface les lignes que le collage a
  ajoutées ; Emacs efface la region, en déplaçant son gap, une copie pouvant aller jusqu'au fichier entier.
- **Un collage** de 1 MB coûte environ 45 ms aux deux tailles, un tiers de ce qu'il coûtait à 99,9 MB, et le temps d'Emacs à
  15,9 MB est encore plus bas. L'essentiel, ce sont les couleurs des lignes collées jusqu'au curseur, 28 000 d'entre elles,
  dont les 25 000 premières sont lues tout de suite et le reste au tick suivant, et la découpe du texte collé en ses lignes
  pour placer le curseur après lui, `str.Split` ; la modification de la rope elle-même et la découpe prennent de 11 à
  15 ms. Vim et Neovim ajoutent les lignes à leurs blocs en C : 2,7 ms.

## Le gestionnaire de dossiers

Un dossier de 10 000 fichiers, le buffer du premier fichier courant, médianes de 21 passes, chacune avec
`commands.Settled` tel que l'éditeur l'appelle après chaque événement :

| Étape | Médiane de 21 | La plus rapide, la plus lente |
|---|---|---|
| l'ouverture du dossier, `C-x d` | 105 ms | 96, 127 ms |
| la première lettre tapée, `9`, qui garde 3 439 rangées | 7,4 ms | 5,8, 23,0 ms |
| une deuxième lettre, `9` à nouveau, qui filtre les rangées montrées | 8,4 ms | 7,6, 14,8 ms |

Le script a fait le dossier, 10 000 fichiers nommés de `file-1.ce` à `file-10000.ce`, puis a chronométré [folders.Open] avec
[commands.Settled], et deux événements de texte à travers [commands.Update], comme la fenêtre les envoie. L'ouverture lit le
dossier une fois : une liste et un regard sur chacune des 10 000 entrées, puis les rangées et leurs couleurs. Une lettre
filtre les rangées lues alors, à partir de celles déjà montrées quand le filtre n'a fait que grandir. Ces temps datent d'avant
que le filtre cherche chaque lettre en code natif ;
[Un cas : trouver un fichier à partir de quelques lettres](finding.md#la-vitesse--chaque-lettre-répond-tout-de-suite) mesure le filtre
depuis, sur 1 933 rangées : 288 lettres tapées en 210 ms contre 402 avant.

## La vérification

`cesia check --json --stdin` de `core/commands/commands.ce`, 1 160 lignes, tel que Cemacs le lance, $n = 10$ : 28,8 ms
[26,7 ; 31,5]. Les marques d'une erreur arrivent donc environ 30 ms après la demi-seconde de pause qui lance la vérification.
Elle tourne dans son propre processus, depuis une fiber : l'éditeur ne l'attend pas, et la frappe continue.

## Au repos

Un éditeur au repos, un seul buffer vide, 3 secondes après son démarrage ; la mémoire de chaque processus de l'éditeur,
$n = 5$ :

| Éditeur | RSS | PSS |
|---|---|---|
| Cemacs, `bin/cemacs`, dummy driver | 46,5 MB [46,4 ; 46,6] | 41,8 MB [41,7 ; 41,9] |
| GNU Emacs 31.1, `emacs -Q -nw` | 55,8 MB [55,7 ; 56,0] | 49,0 MB [48,0 ; 49,1] |
| Neovim 0.12.6, `nvim --clean -n` | 20,3 MB [20,3 ; 20,4] | 10,1 MB [9,8 ; 10,2] |
| Vim 9.2, `vim --clean -n` | 10,6 MB [10,5 ; 10,8] | 7,8 MB [7,7 ; 8,0] |

La RSS, la resident set size, est la mémoire d'un processus qui est en RAM, les bibliothèques qu'il partage avec d'autres
programmes comptées en entier ; la PSS, la proportional set size, compte une page partagée divisée par le nombre de
processus qui la partagent, ce qui est plus juste entre programmes. Cemacs contient le runtime de Cesia (la partie de Cesia
qui fait tourner le programme), SDL3, SDL3_ttf, ses trois polices et la fenêtre.

Avec un grand fichier ouvert, 8 secondes après le démarrage, $n = 7$, les éditeurs chacun à son tour : la RSS du processus
propre de l'éditeur, et de tous ses processus, ce qui, pour Cemacs, compte la vérification, `cesia check`, quand le fichier
est un fichier Cesia ; puis le processeur pendant les 10 secondes qui suivent :

| Éditeur, fichier de 99,9 MB | RSS, son propre processus | RSS, tous ses processus | Processeur |
|---|---|---|---|
| Cemacs, le fichier nommé `.txt`, pas de vérification | 219,5 MB [219,4 ; 219,6] | 219,5 MB | 2,9 % [1,8 ; 3,2] |
| Cemacs d'avant, b2ab23f, `.txt` | 269,6 MB [269,5 ; 269,8] | 269,6 MB | 2,6 % [2,4 ; 2,9] |
| Cemacs, le fichier nommé `.ce` | 220,0 MB [219,8 ; 220,1] | 220,0 MB | 2,7 % [2,6 ; 2,9] |
| Cemacs avec seulement la limite de la vérification, `.ce` | 270,0 MB [269,8 ; 270,1] | 270,0 MB | 2,6 % [2,5 ; 2,7] |
| Cemacs d'avant, `.ce` | 463,0 MB [462,9 ; 463,1] | 475,3 MB [475,3 ; 475,5] | 48,1 % [46,1 ; 51,4] |
| GNU Emacs 31.1 | 151,4 MB [151,1 ; 151,5] | 151,4 MB | 0,0 % [0,0 ; 0,0] |
| Neovim 0.12.6 | 9,7 MB [9,6 ; 9,8] | 137,4 MB [137,1 ; 137,6] | 0,0 % [0,0 ; 0,0] |
| Vim 9.2 | 133,0 MB [132,9 ; 133,0] | 133,0 MB | 0,0 % [0,0 ; 0,0] |

Deux choses sont parties, mesurées toutes deux sur le même fichier sous ses deux noms :

- **La vérification du grand fichier**, qui gardait une fois de plus le texte entier pour `cesia check`, dont le processus
  grandissait en le lisant, et occupait un cœur à moitié, 48 % sur les 10 secondes : un buffer Cesia de plus de 1 MB n'est
  plus vérifié, [Les erreurs dans les lignes](check.md#quand-elle-tourne). 475 → 270 MB, et le processeur comme pour un texte
  simple.
- **La copie du fichier dans la rope** : ses feuilles sont des vues du texte lu, si bien que les 99,9 MB ne sont gardés
  qu'une fois, là où 97 540 feuilles en gardaient une copie, à côté du texte lu que le collector (le garbage collector, la
  partie qui libère la mémoire que plus rien n'emploie) n'avait pas encore libéré. 270 → 220 MB.

Les autres gardent encore moins : Vim et Neovim environ le fichier et quelques octets par ligne, 133 et 137 MB, Emacs le
fichier dans son gap buffer, 151 MB. Le processus propre de Neovim est son interface de terminal ; son éditeur est un second
processus, qui garde le fichier. Sur les 220 MB de Cemacs, environ 46 MB sont l'éditeur vide (le runtime de Cesia, le code
qu'il a préparé, SDL et ses polices) et environ 100 MB le fichier ; le reste, ce sont les 12 000 records de la rope, et de
la mémoire que le collector d'OCaml a libérée ou va libérer mais que le processus garde : la mémoire de Cesia est gérée par
ce collector, qui libère peu à la fois, à un rythme fixé par ce que le programme fabrique, et un éditeur au repos ne fabrique
presque rien. Le processeur de Cemacs au repos est celui du dummy driver de SDL, qui cherche un événement chaque
milliseconde ; dans une vraie fenêtre, l'éditeur dort, comme le dit la table ci-dessous.

Le processeur au repos, pendant 10 secondes, 3 secondes après le démarrage, un seul buffer vide, en pour cent d'un cœur,
$n = 5$. Le temps est celui que le système a compté pour chaque processus de l'éditeur, en centièmes de seconde : 0,0 % veut
donc dire moins de 0,1 % :

| Éditeur, où | Processeur au repos | Avant que Cemacs dorme dans SDL |
|---|---|---|
| Cemacs, dans une fenêtre Wayland | 0,0 % [0,0 ; 0,0] | 1,4 % [0,9 ; 1,5] |
| Cemacs, dummy driver de SDL | 0,8 % [0,8 ; 1,2] | 0,7 % [0,7 ; 0,8] |
| GNU Emacs 31.1, dans tmux | 0,0 % [0,0 ; 0,0] | |
| Neovim 0.12.6, dans tmux | 0,0 % [0,0 ; 0,0] | |
| Vim 9.2, dans tmux | 0,0 % [0,0 ; 0,0] | |

Un Cemacs immobile dort maintenant dans SDL jusqu'à l'événement suivant, 250 ms au plus, comme le dit
[À l'intérieur de Cemacs](internals.md#la-boucle-des-événements) ; avant, il en cherchait un toutes les 5 millisecondes, et dormait
entre-temps. La fenêtre Wayland était une vraie fenêtre, du driver Wayland de SDL, dans un compositor à elle qui ne montrait
rien sur un écran : `mutter --headless --wayland --no-x11 --virtual-monitor 1280x720`, le compositor de GNOME, dans un
session bus à lui, `dbus-run-session`. Le dummy driver de SDL ne peut pas attendre un événement : SDL en cherche donc un
chaque milliseconde, là, en C ; les tests l'emploient, une personne jamais. Les autres dorment jusqu'à ce que le système les
réveille avec un événement, et ne coûtent rien pendant que vous lisez. Cemacs dessine une frame à chaque tour pendant qu'un
programme tourne, qu'une vérification tourne ou est à faire, ou qu'une prefix key attend sa bande des hints.

D'une touche à l'éditeur, dans cette fenêtre Wayland, $n = 120$ touches, 40 dans chacune de 3 exécutions, une touche toutes
les 0,25 à 0,5 secondes :

| De la touche envoyée à | Cette version | Avant |
|---|---|---|
| son événement lu par la mise à jour | 0,72 ms [0,71 ; 0,74] | 3,08 ms [2,45 ; 3,48] |
| les commandes de sa frame faites | 1,13 ms [1,12 ; 1,14] | 3,39 ms [2,83 ; 3,91] |

Les touches ont été envoyées comme un bureau à distance les envoie, par l'interface `RemoteDesktop` de mutter sur D-Bus, et
le temps de chacune commence juste avant cet appel : il contient donc l'appel, mutter, Wayland et SDL. L'éditeur se réveille
dès que la touche arrive, là où il pouvait dormir jusqu'à 5 ms avant. Le buffer était vide : faire les commandes de la frame
était donc court ; les dessiner prend ensuite le renderer de SDL, comme dans [Taper et faire défiler](#taper-et-faire-défiler).

## Les limites

- Un fichier de plus de 1 GiB ne s'ouvre pas : un fichier de 1 GiB prend environ deux fois sa taille en mémoire à son pic.
- L'historique d'annulation garde 1 000 états par buffer, et la sortie d'un programme ses 1 000 dernières lignes.
- SDL garde au plus 8 192 textes passés par le shaping ; au-delà, il les oublie tous et refait le shaping de ce que
  dessinent les frames suivantes.
- Un buffer Cesia de plus de 1 000 000 octets n'est pas vérifié : voir [Les erreurs dans les lignes](check.md#quand-elle-tourne).
- Une seule vérification tourne à la fois, pour un seul buffer.
