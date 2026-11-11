# Premiers pas

Dans ce chapitre, vous ouvrez un fichier, vous apprenez les quelques touches qui permettent d'avancer, et vous écrivez du
Cesia : les erreurs s'affichent dans les lignes, une touche exécute le fichier avec les permissions de son projet, et une
autre l'exécute sous le debugger. Pour finir, vous modifiez Cemacs lui-même. Chaque partie mène au chapitre qui la raconte
en entier.

Il vous faut Cemacs installé, comme le dit [Installation](install.md) : Cesia, SDL3 et SDL3_ttf, et le code.

## Ouvrir un fichier

```bash
bin/cemacs notes.ce
```

La fenêtre s'ouvre sur `notes.ce`. Un fichier qui n'existe pas encore s'ouvre vide, et il est créé au premier
enregistrement. Sans fichier, Cemacs ouvre un seul buffer vide.

Un buffer est un texte que Cemacs garde en mémoire, le plus souvent le texte d'un fichier : vous modifiez le buffer, et
l'enregistrer l'écrit dans le fichier. Jusque-là, le fichier sur le disque ne change pas. Plusieurs buffers peuvent être
ouverts à la fois, un pour chaque fichier.

La fenêtre a quatre parties, de haut en bas :

```text
+--------------------------------------------------------------+
|  1  use std/io                                               |
|  2  io.Print("Hello")                       the code         |
|                                                              |
| notes.ce *                           2:17   Cesia            |  the mode line
+--------------------------------------------------------------+
| Output   ended, code 0                                       |  the output, after a run
| Hello                                                        |
+--------------------------------------------------------------+
| Saved notes.ce                                               |  the prompt line
+--------------------------------------------------------------+
```

- Le code (`the code`), avec le numéro de chaque ligne à sa gauche, et le curseur, une barre fine : ce que vous tapez
  s'insère là.
- La mode line (`the mode line`, la ligne d'état), sous le code : le nom du buffer, une étoile `*` quand son texte n'est pas
  enregistré, la ligne et la colonne du curseur, et le nombre d'erreurs quand il y en a.
- La sortie (`the output`) du dernier programme que vous avez exécuté, dès que vous en exécutez un.
- La prompt line (`the prompt line`), en bas : elle dit ce qu'a fait la dernière touche, et c'est là qu'une question est
  posée, comme le nom d'un fichier à ouvrir. Emacs appelle cette ligne l'echo area quand elle montre un message, et le
  minibuffer quand elle lit une réponse.

Le chapitre [Fenêtre et panes](windows.md) raconte chaque partie en entier.

## Les touches

Les touches sont celles d'Emacs. `C-` désigne la touche Control et `M-` la touche Alt : `C-x C-s`, c'est Control et `x`,
puis Control et `s`. Une telle touche, faite de deux touches ou plus, est une key sequence (une suite de touches), et sa
première touche, ici `C-x`, est une prefix key (une touche préfixe) : seule, elle ne fait rien, et elle attend la touche qui
la suit.

Quelques touches pour commencer :

| Touches | Ce qu'elles font |
|---|---|
| `C-f`, `C-b`, `C-n`, `C-p`, ou les flèches | un caractère en avant ou en arrière, une ligne vers le bas ou vers le haut |
| `M-f`, `M-b` | un mot en avant ou en arrière |
| `C-a`, `C-e`, ou Home et End | le début et la fin de la ligne |
| `C-v`, `M-v`, ou Page Down et Page Up | un écran vers le bas ou vers le haut |
| `M-<`, `M->` | le début et la fin du fichier |
| `C-space`, puis un déplacement, ou Shift et un déplacement | sélectionner à partir de là |
| `C-w`, `M-w`, `C-y` | couper, copier, coller |
| `C-k` | couper le reste de la ligne |
| `C-/`, `C-?` | annuler, rétablir |
| `C-g` | arrêter ce que les touches ont commencé : une sélection, une question, une prefix key |
| `C-x C-f`, `C-x C-s` | ouvrir un fichier, enregistrer |
| `C-x C-c` | quitter |

Le texte coupé va dans le presse-papiers de votre système : vous pouvez donc le coller dans un autre programme, et coller ici
ce qui vient des autres. [Édition](editing.md) donne chaque touche qui déplace et qui modifie.

## Les groupes sous C-c

Vous n'avez pas besoin d'apprendre les touches ci-dessus. Sous `C-c`, chaque touche est dans un groupe, comme dans Doom
Emacs. Appuyez sur `C-c` et attendez une demi-seconde : une bande au-dessus de la prompt line montre chaque groupe. Appuyez
sur la lettre d'un groupe et attendez encore : la bande montre ses touches.

| Groupe | Ses touches |
|---|---|
| `C-c f`, fichiers | `f` ouvrir, `s` enregistrer, `d` le dossier, `c` le code de Cemacs |
| `C-c b`, buffers | `b` la liste, `n` le suivant, `k` fermer |
| `C-c w`, fenêtres | `s` couper en deux vers le bas, `v` couper en deux vers la droite, `o` le pane suivant, `d` le fermer, `m` ne garder que celui-ci |
| `C-c s`, recherche | `s` chercher en avant pendant que vous tapez, `r` en arrière : voir [Recherche](search.md) |
| `C-c c`, code | `r` exécuter le fichier, `k` l'arrêter, `o` sa sortie, `h` cacher ou montrer la sortie, `n` et `p` l'erreur suivante et la précédente |
| `C-c d`, débogage | `r` exécuter sous le debugger, `b` un breakpoint, `e` évaluer, `c` continuer, `n` suivant, `s` entrer, `u` sortir |
| `C-c q`, quitter | `q` quitter |

Ainsi `C-c f f` ouvre un fichier, comme le fait `C-x C-f`. `?` après une prefix key liste tout ce qui peut la suivre,
chaque touche avec le nom de sa commande et ce qu'elle fait : `C-x ?`, `C-c ?` ou `C-c d ?`. Taper du texte filtre cette
liste, et Enter lance la touche sous le curseur. Vous pouvez toujours trouver une touche à partir de son groupe, sans la
connaître : `C-c`, puis regardez. [Touches](keys.md) liste chaque touche.

## Fichiers, buffers et panes

| Touches | Ce qu'elles font |
|---|---|
| `C-x b`, `C-x C-b` | le buffer suivant, la liste des buffers |
| `C-x k` | fermer le buffer |
| `C-x d` | le dossier du fichier courant, comme un gestionnaire de fichiers |
| `C-x 2`, `C-x 3` | couper le pane en deux vers le bas, ou vers la droite |
| `C-x o`, `C-x 0`, `C-x 1` | le pane suivant, fermer celui-ci, ne garder que celui-ci |

Un pane est une partie de la fenêtre qui montre un buffer, avec sa propre mode line ; Emacs l'appelle une window, et la
fenêtre entière une frame. Deux panes peuvent montrer le même buffer à deux endroits.

La liste des buffers et le dossier sont des listes : des buffers faits de rangées. Taper du texte filtre une liste, et
Enter ouvre la rangée sous le curseur. Dans le dossier, tapez une partie du nom d'un dossier puis `/` pour y entrer, et
Backspace remonte ; `C-c n` crée un fichier ou un dossier, `C-c r` renomme, et `C-c k` met à la corbeille.
[Fichiers et buffers](files.md) raconte tout cela.

## Écrire du Cesia

Cemacs colore le code Cesia pendant que vous tapez : les mots-clés, les noms appelés, les textes, les nombres et les
commentaires ont chacun leur couleur.

### Les erreurs dans les lignes

Cemacs vérifie un fichier Cesia pendant que vous l'écrivez, comme le fait `cesia check`, sans l'exécuter. Une demi-seconde
après votre dernière touche, il lit le buffer, même avant qu'il soit enregistré. Une erreur est soulignée en rouge, un
warning (un avertissement) en ambre, le numéro de sa ligne prend la même couleur, et les mots de son message s'affichent au
bout de la ligne. La prompt line donne l'erreur sous le curseur, avec son hint, les mots qui disent comment la corriger. La
mode line les compte.

| Touches | Ce qu'elles font |
|---|---|
| `M-g n`, ou `C-c c n` | l'erreur suivante, à partir du curseur ; après la dernière, la première |
| `M-g p`, ou `C-c c p` | l'erreur précédente |

Un warning porte sur un résultat dont l'`Err` passerait inaperçu, comme un `sys.Read` employé comme une simple valeur : le
livre de Cesia explique chaque sorte, dans son chapitre sur les erreurs. [Les erreurs dans les lignes](check.md) dit quand la
vérification tourne et ce qu'elle montre.

### Exécuter un fichier

`C-c c r` exécute le fichier du buffer courant, tel qu'il est enregistré, comme le ferait `cesia run`, et aussi vite. Ce
qu'il affiche apparaît dans la sortie sous les panes, au fur et à mesure, ses erreurs aussi ; sa première ligne est la
commande qui l'exécute. `C-c c k` arrête un programme qui continue de tourner, comme un serveur, et `C-c c r` à nouveau
l'arrête et exécute le fichier une nouvelle fois. `C-c c h` cache ou montre la sortie.

`C-c c o` ouvre toute la sortie comme une liste, sur sa dernière erreur. Taper du texte la filtre, et Enter sur une ligne
qui nomme un endroit y va : une erreur de Cesia commence par son fichier, sa ligne et sa colonne, comme `src/main.ce:4:11:`,
et chaque appel en dessous finit par son fichier et sa ligne.

### Les permissions

Un programme tourne sans aucune permission, comme le fait `cesia run file.ce` : il calcule et il affiche. Un programme qui
lit un fichier s'arrête, et la sortie dit quelle permission lui manque. Les permissions s'écrivent une seule fois, dans une
tâche de `cesia.toml`, comme le montre le livre de Cesia dans son chapitre sur les permissions :

```toml
[tasks.serve]
file = "src/server.ce"
allow = ["read=data", "net=:8080"]
```

Quand le `cesia.toml` du dossier où vous avez lancé Cemacs a une tâche dont le `file` est le fichier courant, `C-c c r`
lance cette tâche, comme le fait `cesia do serve` : avec ses permissions, et d'abord les tâches dont elle a besoin
(`needs`). La première ligne de la sortie montre la commande, avec son `--allow`. Ajoutez `watch = true` à la tâche, et
`C-c c r` la lance sous `--watch` : chaque enregistrement charge vos changements dans le programme qui tourne, sans
l'arrêter.

### Déboguer

`C-c d r` exécute le fichier sous le debugger, un programme qui exécute le vôtre et peut l'arrêter, pour montrer ses
variables. Il tourne presque aussi vite que sans lui, jusqu'à ce qu'il atteigne un breakpoint, une ligne où vous lui
demandez de s'arrêter. Il tourne sans aucune permission, même quand une tâche exécute le fichier.

- `C-c d b` pose un breakpoint sur la ligne du curseur, un point dans la marge, ou l'enlève.
- Quand le programme s'arrête, à un breakpoint ou sur une erreur, sa ligne prend une bande de couleur, et la sortie montre
  les variables de la fonction où il s'est arrêté, avec leurs valeurs.
- `C-c d e` évalue la ligne du curseur, ou la sélection, dans le programme, et montre sa valeur au bout de la ligne, en
  gris : elle ne fait pas partie du fichier.
- `C-c d c` continue jusqu'à l'arrêt suivant. `C-c d n` exécute une ligne, un appel comptant comme un tout ; `C-c d s`
  exécute une ligne et entre dans un appel ; `C-c d u` continue jusqu'à la fin de la fonction.

Pendant que le programme est arrêté, vous pouvez modifier son code et l'enregistrer : quand il repart, le code qui a changé
est chargé. [Exécuter et déboguer](running.md) raconte tout cela.

## Modifier Cemacs

Cemacs est un projet Cesia, et ses réglages sont du code Cesia. `C-c f c` ouvre `src/cemacs.ce`, où se rejoignent les apps
de Cemacs et leurs touches. `src/emacs/emacs.ce` contient les touches d'Emacs et les réglages, chacun une fonction. En voici
deux, tels qu'ils étaient quand cette page a été construite :

```cesia
use src/emacs
emacs.FontSize() -->
emacs.HintDelay() -->
```

Pour en changer un, changez sa fonction et enregistrez :

```cesia norun
(* in src/emacs/emacs.ce *)
FontSize() = 17
HintDelay() = 0.3
```

Une touche lance n'importe quelle fonction qui va de l'état de l'éditeur à un nouvel état. Voici un groupe `t` à vous, avec
une touche dedans, dans un nouveau package `src/mine/` :

```cesia
(* src/mine/mine.ce *)
use core/commands
Keys() = {"C-c t": "tools", "C-c t s": commands.Save}
```

Dans `src/cemacs.ce`, ajoutez `use src/mine`, et `mine.Keys()` aux touches que `Keys` fusionne. Lancez Cemacs avec
`cesia do dev` depuis son dossier : chaque enregistrement d'un de ses fichiers le recharge alors dans la fenêtre, sans la
fermer, si bien qu'une touche ou un réglage changé marche dès la touche suivante. Un nouveau package, comme `src/mine/` ici,
demande d'abord un redémarrage, car un programme qui tourne ne peut pas charger un nouveau package.
[Modifier Cemacs](customising.md) raconte tout cela, avec une app à vous.

`cesia do test` lance la suite de tests de Cemacs, et `SDL_VIDEODRIVER=dummy cesia do test` la lance sans montrer de
fenêtre.
