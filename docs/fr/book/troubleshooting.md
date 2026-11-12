# Dépannage

Ce chapitre liste chaque message de Cemacs, où il s'affiche, ce qu'il veut dire et que faire. Les messages du démarrage vont
dans le terminal qui a lancé Cemacs ; les messages pendant qu'il tourne vont sur la prompt line, en bas de la fenêtre ;
l'état d'un programme va après le titre de la sortie. Les messages restent en anglais, tels que Cemacs les écrit : les
tables les expliquent en français.

## Au démarrage

Quand la fenêtre ne peut pas s'ouvrir, Cemacs affiche la raison dans le terminal, sous la forme d'une valeur Cesia, et se
termine. Quand il se termine normalement, il affiche `Ok(missing)`.

| Ce que montre le terminal | Pourquoi | Que faire |
|---|---|---|
| `bash: cesia: command not found`, ou `cesia: command not found` | Cesia n'est pas installé, ou pas dans le `PATH` | installez Cesia : voir [Installation](install.md#cesia) |
| `This project needs Cesia 1.1 or later, and this is ...: run cesia upgrade.` | le Cesia du `PATH` est plus ancien que ce que demande `cesia.toml` | `cesia upgrade` |
| `Err({Kind: "c", Message: "Can't load SDL3: libSDL3.so.0: cannot open shared object file: No such file or directory."})` | SDL3 n'est pas installé, ou n'est pas là où le système cherche | installez-le, ou mettez dans `LD_LIBRARY_PATH` son dossier : voir [Installation](install.md#sdl3-et-sdl3_ttf) |
| la même chose avec `SDL3_ttf` et `libSDL3_ttf.so.0` | SDL3_ttf manque | la même chose |
| `Err({Kind: "sdl", Message: "This program needs SDL 3.2 or later."})` | le SDL3 trouvé est un 3.0 ou un 3.1 | un SDL3 plus récent, du système ou de `tools/sdl-libs.sh` |
| `Err({Kind: "sdl", Message: "Couldn't open .../fonts/AdwaitaSans-Regular.ttf: No such file or directory"})` | les polices ne sont pas dans le dossier que Cemacs a pris comme le sien | lancez Cemacs par `bin/cemacs`, qui trouve son dossier, ou lancez `cesia do dev` depuis le dossier de Cemacs |
| `Err({Kind: "sdl", Message: ...})` avec une autre raison, comme `No available video device` | SDL n'a trouvé aucun affichage où ouvrir une fenêtre | lancez Cemacs dans une session graphique ; `SDL_VIDEODRIVER=wayland` ou `x11` choisit le système d'affichage |
| `Permission "ffi" denied for SDL3.`, ou un autre `Permission ... denied` | Cemacs a été lancé avec `cesia run` sans ses permissions | lancez-le avec `bin/cemacs`, ou `cesia do dev` |
| `cesia.toml:4:1: The source folder "user" doesn't exist.` (le dossier de code « user » n'existe pas) | Cesia a tourné dans le dossier de Cemacs avant que `user/` soit créé, comme `cesia test`, `cesia check`, `cesia doc` ou `cesia run src/cemacs.ce` dans un nouveau clone : `cesia.toml` nomme `user` parmi les dossiers du code | démarrez Cemacs une fois par `bin/cemacs` ou `cesia do dev`, ou lancez `tools/user.sh` : chacun crée `user/` à partir du template. [Installation](install.md#votre-dossier-user) |
| `.../src/cemacs.ce:12:5: Module "user/config" doesn't exist.` (le module n'existe pas) | `user/` est là, mais pas son `config/` : Cemacs ne crée `user/` que quand il manque | remettez `user/config/config.ce`, ou déplacez `user/` ailleurs et redémarrez : un nouveau vient du template |
| `user/config/config.ce:LIGNE:COLONNE:` et une erreur, comme `Name "nothere" doesn't exist.` (le nom n'existe pas) | votre config ne se charge pas : Cesia montre la ligne et l'endroit | corrigez-la avec un autre éditeur ; ou déplacez `user/` ailleurs, et le démarrage suivant en crée un nouveau à partir du template. [Modifier Cemacs](customising.md#votre-dossier-user) |
| une erreur suivie de `in Config (.../src/cemacs.ce:...)` ou `called from Start (core/editor/editor.ce:...)`, comme `Changed needs the argument "more".` (Changed a besoin de l'argument « more ») | votre config se charge, mais `Changed`, ou une fonction qu'il a posée, échoue quand la fenêtre lit la config à son démarrage : un `Start` qui lit un champ que l'état n'a pas, par exemple | la même chose |

## Sur la prompt line

Voici les messages des commandes, dans l'ordre des chapitres. Un message reste jusqu'à la touche ou au clic suivant.

### Édition

| Message | Ce qui s'est passé |
|---|---|
| `Quit` | `C-g` a arrêté ce que les touches avaient commencé : la mark, une question, ou une prefix key |
| `KEYS is not bound.`, comme `C-t is not bound.` ou `C-x C-t is not bound.` | rien n'est lié à ces touches, et rien ne commence par elles ; rien n'a changé. [Touches](keys.md) liste chaque touche, et `C-x ?` ou `C-c ?` liste celles qui suivent un préfixe |
| `C-x -` | une prefix key attend la touche suivante ; `C-g` l'oublie |
| `Nothing is selected.` | `C-w` ou `M-w` sans sélection : posez la mark avec `C-space`, ou tenez Shift pendant que vous vous déplacez |
| `The clipboard is empty.` | `C-y` sans rien dans le presse-papiers |
| `Nothing to cut.` | `C-k` à la fin du fichier |
| `No completion for WORD.`, comme `No completion for Hzq.` | Tab au bout d'un mot dans un fichier de Cesia n'a trouvé aucun mot qui commence ainsi, ni dans le texte autour du curseur, ni dans les autres buffers, ni dans les noms de Cesia : [Édition](editing.md#la-completion) |
| `This list is read only.` | une commande a essayé de changer le texte d'une liste, et a été défaite |
| `Nothing here.` | une touche d'une liste sans rangée restante, comme Enter après un filtre qui ne correspond à rien : Backspace défait le filtre |

### Fichiers et buffers

| Message | Ce qui s'est passé, et que faire |
|---|---|
| `Saved PATH` | l'enregistrement a marché |
| `No file name.` | une réponse vide à `Find file: ` ou à `Save as: ` |
| `PATH is a folder.` | `C-x d` montre un dossier ; `C-x C-f` ouvre des fichiers |
| `PATH is not a regular file: it may be a device, a pipe or a socket.` | Cemacs n'ouvre que les fichiers ordinaires |
| `PATH is too large to open: SIZE bytes, and the limit is 1073741824.` | Cemacs ouvre des fichiers de 1 GiB au plus, qui prennent environ deux fois leur taille en mémoire pendant qu'ils s'ouvrent : voir [Fichiers et buffers](files.md#quels-fichiers-souvrent) |
| `PATH is not valid UTF-8 text, or holds a zero byte.` | le fichier est dans un autre encodage, ou n'est pas du texte ; convertissez-le en UTF-8, avec `iconv` par exemple |
| `PATH is open in another buffer.` | `Save as` vers un fichier déjà ouvert : enregistrez ce buffer, ou fermez-le d'abord |
| `A list has no file.` | un enregistrement dans une liste |
| `Not saved.` | vous avez répondu `n` à `File changed on disk. Overwrite?` : les deux textes sont tels qu'ils étaient |
| `No free name next to PATH for a new file.` | 21 noms pour le nouveau fichier d'un enregistrement étaient pris : enlevez les fichiers `PATH.cemacs-...` laissés à côté de lui |
| `PATH was saved, but its time couldn't be read: REASON` | le texte est sur le disque, mais le prochain enregistrement de ce buffer demandera avant d'écrire |
| une raison donnée par le système, comme une permission refusée | la lecture ou l'enregistrement a échoué ; après un enregistrement qui a échoué, l'ancien fichier est entier et le buffer garde son texte et son étoile |

### Le gestionnaire de dossiers

| Message | Ce qui s'est passé |
|---|---|
| `This is the root.` | Backspace à `/` |
| `No folder matches.` | `/` après des lettres qui ne correspondent à aucun dossier |
| `HOME is not set.` | `~/` sans `HOME` dans l'environnement |
| `No file or folder at PATH.` | `C-y` avec, dans le presse-papiers, un chemin qui ne mène nulle part |
| `No name.` | une réponse vide à `New file, or folder/: ` |
| `NAME already exists.` | un nouveau nom, ou un renommage, vers un nom qui est pris |
| `There is no trash: HOME is not set.` | ni `XDG_DATA_HOME` ni `HOME` n'a de valeur : il n'y a donc pas de corbeille où mettre le fichier |
| `Can't move NAME to the trash: REASON` | le plus souvent un fichier sur un autre disque que votre dossier personnel : voir [Fichiers et buffers](files.md#créer-renommer-et-mettre-à-la-corbeille). Le fichier reste là où il était |
| une raison donnée par le système | la lecture du dossier, la création ou le renommage a échoué |

### Les fichiers d'un projet

| Message | Ce qui s'est passé, et que faire |
|---|---|
| `FOLDER/ is in no Git repository.` | `C-x p f` depuis un fichier, ou un dossier de départ, hors de tout dépôt Git : ouvrez d'abord un fichier du projet, ou faites-en un dépôt avec `git init` |
| `Can't run git: no such file or directory.` | `git` n'est pas dans le `PATH` : installez-le |
| `git ls-files failed: REASON` | Git a trouvé le dépôt mais n'a pas pu le lister ; REASON, ce sont les mots de Git lui-même |

### Fenêtre et panes

| Message | Ce qui s'est passé |
|---|---|
| `This pane is too small to split.` | une moitié aurait moins de 2 lignes ou de 8 caractères : agrandissez la fenêtre, ou `C-x 1` |
| `This is the only pane.` | `C-x 0` sur le dernier pane |

### Les erreurs dans les lignes et la sortie

| Message | Ce qui s'est passé |
|---|---|
| `No error here.` | `M-g n` ou `M-g p` dans un buffer sans marque |
| `cesia check can't run: REASON` | la vérification n'a pas pu lancer `cesia` : est-il dans le `PATH` ? C'est dit une fois ; le prochain changement du buffer essaie à nouveau |
| `This line names no place of a file.` | Enter dans la sortie sur une ligne sans `PATH:LINE:COLUMN: ` ni `(PATH:LINE)` |
| `PATH isn't there.` | Enter dans la sortie sur l'endroit d'un fichier qui n'existe pas, vu du dossier où Cemacs a démarré |
| `There is no output yet: C-c c r runs the file.` | `C-c c h` ou `C-c c o` avant toute exécution |

### Exécuter et déboguer

| Message | Ce qui s'est passé |
|---|---|
| `Running PATH.`, `Running PATH as the task NAME.` | le programme a démarré ; le second exécute une tâche de `cesia.toml`, avec ses permissions |
| `Running PATH as saved, without the changes here.` | le buffer a des changements non enregistrés : le programme exécute le fichier qui est sur le disque. Enregistrez, puis `C-c c r` à nouveau |
| `This buffer has no file to run: save it first.` | `C-c c r` ou `C-c d r` dans un buffer sans fichier |
| `PATH doesn't run: REASON` | `cesia` n'a pas pu démarrer : est-il dans le `PATH` ? |
| `The program that runs doesn't end: C-c c k asks it again.` | `C-c c r` a demandé au programme qui tournait de se terminer, et il ne l'a pas fait en 2 secondes : rien de nouveau n'a démarré |
| `Stopping the program.` | `C-c c k` a envoyé le signal TERM |
| `No program is running.` | `C-c c k` sans rien qui tourne |
| `Breakpoint on line N.`, `Breakpoint removed.` | `C-c d b` |
| `A breakpoint needs a file: save the buffer first.` | `C-c d b` dans un buffer sans fichier |
| `No program runs under the debugger: C-c d r runs the file under it.` | `C-c d e` sans un programme lancé par `C-c d r` |
| `The program isn't stopped.` | `C-c d c`, `n`, `s` ou `u` pendant que le programme tourne : ils ne repartent que d'un arrêt |

### Les questions

| Question | Ce qu'elle demande |
|---|---|
| `Find file: ` | le chemin d'un fichier à ouvrir |
| `Save as: ` | le chemin où enregistrer un buffer sans fichier |
| `Text not saved. Close anyway? (y or n)` | `C-x k` sur un buffer non enregistré : `y` perd ses changements |
| `Text not saved. Quit anyway? (y or n)` | quitter avec un buffer non enregistré : `y` perd chaque changement non enregistré |
| `File changed on disk. Overwrite? (y or n)` | le fichier a changé depuis que Cemacs l'a lu, ou un fichier est déjà là : `y` écrit par-dessus |
| `New file, or folder/: ` | dans le gestionnaire de dossiers, le nom à créer |
| `Rename NAME to: ` | dans le gestionnaire de dossiers, le nouveau nom ou le nouveau chemin |
| `Move NAME to the trash? (y or n)` | dans le gestionnaire de dossiers |
| `I-search: `, `I-search backward: ` | une recherche est ouverte : ce que vous tapez est cherché, Enter reste à l'endroit, `C-g` revient en arrière ; voir [Recherche](search.md#chercher-dans-un-buffer) |
| `Failing I-search: ` | il ne reste plus d'endroit des mots dans ce sens : `C-s` ou `C-r` à nouveau fait le tour par le bout, `C-g` défait ce qui n'a rien trouvé |
| `Wrapped I-search: `, `Failing wrapped I-search: ` | la recherche a fait le tour par le bout du fichier ; si elle échoue, les mots n'y sont nulle part |

## Après le titre de la sortie

| État | Ce qu'il veut dire |
|---|---|
| `running` | le programme tourne, ou repart après un arrêt |
| `ended, code N` | le programme s'est terminé avec l'exit code N : 0 quand tout s'est bien passé, -1 quand un signal l'a terminé, comme le fait `C-c c k` |
| `stopped at PATH:LINE` | le programme attend à un breakpoint, ou après un step |
| `stopped on an error at PATH:LINE` | un bug a arrêté le programme sous le debugger ; la sortie montre l'erreur et les variables |
| `the fix doesn't load` | un fichier changé pendant que le programme était arrêté contient une erreur, et n'a pas été chargé ; le programme attend à son arrêt, et la sortie montre l'erreur après les variables. Corrigez et enregistrez, puis repartez : voir [Fix and continue](running.md#fix-and-continue) |

## Quand Cemacs s'arrête de lui-même

Cemacs peut s'arrêter sur une erreur, une panic (une erreur qui termine le programme) : le texte non enregistré de ses
buffers est perdu, puisqu'il n'a pas d'autosave. Cesia affiche l'erreur dans le terminal, avec son endroit dans le code. Sous
`cesia do dev`, le programme attend alors le prochain enregistrement d'un de ses fichiers, et redémarre, sans buffer.

Rien de tout cela ne devrait arriver avec le code tel qu'il est ; chaque cas vient d'un changement de Cemacs, ou d'une
limite :

| Erreur | Pourquoi |
|---|---|
| un appel avec un mauvais nombre d'arguments, depuis une touche | une fonction liée à une touche avec un autre nombre de paramètres que celui d'une commande, un seul, ou celui d'une key binding de la souris, deux : voir [Modifier Cemacs](customising.md#recharger-cemacs-pendant-quil-tourne) |
| un champ qui n'existe pas | du code lit un champ de l'état qu'un état d'avant un rechargement n'a pas : lisez-le par un `match` avec une valeur par défaut |
| `This window has no font "NAME".` | une commande de dessin a nommé une police que la fenêtre n'a pas ouverte ; Cemacs ouvre `body`, `strong` et `code` |
| `A frame has no command "KIND".`, `A radius goes from 0 to 24, not R.`, `A curves command holds at most 1024 curves.`, `A window can't hold more than 4096 images.` | une commande de dessin que `src/sdl` ne prend pas : la frame de Cemacs n'en emploie aucune |
| une raison donnée par SDL | un appel de dessin a échoué sur une fenêtre qui devrait le prendre : un bug de SDL ou du driver graphique |

## Lent ou occupé

- **Un grand fichier prend du temps à s'ouvrir, et de la mémoire.** Environ 0,27 s et 220 MB pour 100 MB, le démarrage, la
  vérification de l'UTF-8 et les fins de ligne de la rope en prenant l'essentiel : [Vitesse](performance.md#ouvrir-un-fichier)
  donne les chiffres.
- **Après un saut loin vers le bas d'un grand fichier, ou une recherche qui y va, les couleurs changent quelques secondes
  plus tard.** L'endroit s'affiche tout de suite, avec les couleurs de ses lignes devinées ; l'état de chaque ligne
  au-dessus de lui est ensuite lu, 25 000 lignes par tick, environ 4 s pour la dernière ligne de 100 MB, et l'écran est
  redessiné avec ses couleurs exactes. Pendant ce temps, une touche peut attendre jusqu'à environ 60 ms de plus. Les états
  sont gardés : les sauts suivants ne coûtent donc rien :
  [À l'intérieur de Cemacs](internals.md#un-endroit-lointain-dabord-ses-couleurs-exactes-ensuite).
- **Un grand fichier Cesia ne montre pas d'erreurs.** Sa mode line dit `not checked: over 1 MB` : Cemacs ne vérifie pas un
  buffer de plus de 1 000 000 octets. [Les erreurs dans les lignes](check.md#quand-elle-tourne) dit pourquoi.
- **Le processeur travaille pendant qu'un programme tourne.** Pendant qu'un programme tourne, qu'une vérification tourne ou
  qu'un buffer en attend une, Cemacs dessine une frame à chaque tour de sa boucle : voir
  [À l'intérieur de Cemacs](internals.md#la-boucle-des-événements). Arrêtez un programme dont vous n'avez pas besoin.
- **La sortie ne montre que ses dernières lignes.** Elle garde 1 000 lignes ; `C-c c o` les ouvre toutes comme une liste.

## Les tests

`cesia do test` s'arrête à son premier échec, et dit à quelle étape. `tests/color-std.ce`, une de ses étapes, et
`bench/gate.ce` lisent les sources de la bibliothèque standard de Cesia que porte le binaire de Cesia, par
[cesia.Libraries] : aucun clone de Cesia n'est nécessaire. `tests/files-check.ce` et `tests/commands-check.ce` font avec
`truncate` un sparse file (un fichier creux, qui ne prend pas de place sur le disque) de 1 GiB et un octet, pour vérifier la
limite de taille.
