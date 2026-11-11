# Exécuter et déboguer

Cemacs exécute le fichier Cesia que vous modifiez, montre ce qu'il affiche au fur et à mesure, et l'arrête. Il l'exécute
aussi sous un debugger, un programme qui exécute le vôtre et peut l'arrêter à une ligne pour montrer ses variables. Ce
chapitre décrit les deux. Les commandes sont dans [core/commands], et ce qu'elles demandent au programme est dans
[core/run].

## Exécuter un fichier

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-c c r`, `C-c C-c` | [commands.Run] | exécute le fichier du buffer courant |
| `C-c c k`, `C-c C-k` | [commands.Stop] | demande au programme qui tourne de se terminer |
| `C-c c h` | [commands.ToggleOutput] | cache la sortie, ou la montre à nouveau |
| `C-c c o`, `C-c C-o` | [output.ShowOutput] | ouvre toute la sortie comme une liste, sur sa dernière erreur |

`C-c c r` exécute le fichier tel qu'il est sur le disque : Cemacs ne l'enregistre pas d'abord. Un buffer dont le texte n'est
pas enregistré exécute son dernier enregistrement, et la prompt line dit
`Running PATH as saved, without the changes here.` (PATH s'exécute tel qu'il est enregistré, sans les changements faits
ici) ; sinon elle dit `Running PATH.` (PATH s'exécute). Un buffer sans fichier dit
`This buffer has no file to run: save it first.` (ce buffer n'a pas de fichier à exécuter : enregistrez-le d'abord)

Le programme est un processus à lui, lancé depuis le dossier où Cemacs a démarré, de l'une de deux façons :

- `cesia run PATH`, aussi vite que depuis un terminal, et sans aucune permission : il calcule et affiche, et s'arrête au
  premier fichier qu'il lit, avec dans sa sortie la permission qui lui manque. La première ligne de la sortie est la
  commande, `> cesia run PATH`.
- `cesia do TASK`, quand le `cesia.toml` de ce dossier a une tâche dont le `file` est ce fichier : voir plus bas.

`C-c c r` pendant qu'un programme tourne le termine d'abord : il lui envoie le signal TERM, la demande habituelle de se
terminer, et attend jusqu'à 2 secondes, en lisant ce qu'il écrit pendant ce temps, pour qu'un serveur rende son port avant
que le nouveau démarre. Un programme qui ne s'est pas terminé d'ici là est laissé en marche, rien de nouveau ne démarre, et la
prompt line dit `The program that runs doesn't end: C-c c k asks it again.` (le programme qui tourne ne se termine pas :
C-c c k le lui redemande). Un programme qui ne peut pas démarrer du tout, parce que `cesia` n'est pas dans le `PATH` par
exemple, dit `PATH doesn't run: REASON` (PATH ne s'exécute pas : la raison).

### La tâche qui exécute un fichier

Une tâche de `cesia.toml` est un programme à exécuter avec ses permissions, comme le dit le livre de Cesia dans son chapitre
sur les packages. Quand le `cesia.toml` du dossier où Cemacs a démarré a une tâche dont le `file` est le fichier du buffer,
`C-c c r` lance cette tâche, par `cesia do`, et la prompt line dit `Running PATH as the task NAME.` (PATH s'exécute comme la
tâche NAME) :

```toml
[tasks.serve]
file = "src/server.ce"
allow = ["read=data", "net=:8080"]
watch = true
```

La tâche apporte son `allow`, son `limit`, son `watch` et les tâches dont elle a besoin (`needs`), que `cesia do` lance
d'abord. `cesia do` écrit sa propre commande comme première ligne de la sortie, avec les permissions :
`> cesia run --allow read=data,net=:8080 ...`. Avec `watch = true`, le programme tourne sous `--watch` : chaque
enregistrement d'un de ses fichiers charge le nouveau code dans le programme qui tourne, un hot reload (un rechargement à
chaud, sans arrêter le programme), et un programme qui s'est terminé redémarre.

[run.TaskFor] trouve la tâche. Les deux chemins se lisent à partir du dossier où Cemacs a démarré : `src/server.ce` et
`/home/me/app/src/server.ce` y nomment donc le même fichier ; la première tâche qui le nomme gagne, et une tâche dont le
`file` est `.`, le projet entier, n'exécute aucun fichier seul :

```cesia
use core/run
run.TaskFor("[tasks.serve]\nfile = \"src/a.ce\"\n", "/p/src/a.ce", "/p") --> "serve"
run.TaskFor("[tasks.all]\nfile = \".\"\n", "a.ce", "/p") --> missing
```

Seul le `cesia.toml` du dossier où Cemacs a démarré est lu, puisque `cesia do` lit celui du dossier où il tourne. Un fichier
d'un autre projet s'exécute avec `cesia run`, sans aucune permission.

### La sortie

Ce que le programme écrit, sur sa sortie standard comme sur sa sortie d'erreurs, arrive à Cemacs comme un seul stream (un
flux d'octets), lu par une fiber, une tâche de Cesia qui attend le programme pendant que l'éditeur continue ; le livre de
Cesia décrit les fibers dans leur chapitre. À chaque tour de sa boucle, Cemacs prend ce qui est arrivé, le coupe en lignes,
et montre dans la sortie les dernières qui tiennent, y compris la ligne pas encore terminée. Il garde les 1 000 dernières
lignes. [run.Read] fait la découpe :

```cesia
run.Lines(run.Read("one\ntwo\nthr", run.Empty())) --> ["one", "two", "thr"]
```

Le titre de la sortie est suivi de l'état du programme : `running` (en cours), puis `ended, code N` (terminé, code N) avec
son exit code, le nombre qu'un programme rend quand il se termine, 0 quand tout s'est bien passé. Un programme terminé par
`C-c c k` montre `ended, code -1`, car Cesia donne -1 pour un programme terminé par un signal.

Cemacs n'écrit rien sur l'entrée du programme : un programme qui lit son entrée standard attend jusqu'à ce que vous
l'arrêtiez. Une nouvelle exécution remplace la sortie de la précédente.

`C-c c o` ouvre toute la sortie comme une liste, avec le curseur sur la dernière erreur, une ligne qui commence par un
endroit comme `src/a.ce:4:11: `. La liste grandit à mesure que le programme écrit ; taper la filtre, et Enter sur une ligne
qui nomme un endroit d'un fichier y va : voir [Recherche](search.md#les-endroits-dans-la-sortie). La sortie reste sous les panes
pendant que la liste est ouverte.

`C-c c k` dit `Stopping the program.` (arrêt du programme) et envoie TERM, ce qui termine un programme Cesia ; un programme
qui prend ce signal pour lui-même peut demander un second `C-c c k`. Sans programme qui tourne, il dit
`No program is running.` (aucun programme ne tourne), et `C-c c h` sans exécution encore dit
`There is no output yet: C-c c r runs the file.` (il n'y a pas encore de sortie : C-c c r exécute le fichier)

## Déboguer

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-c d r` | [commands.DebugRun] | exécute le fichier sous le debugger de Cemacs |
| `C-c d b` | [commands.ToggleBreak] | pose un breakpoint sur la ligne du curseur, ou l'enlève |
| `C-c d e` | [commands.Eval] | évalue la sélection, ou à défaut la ligne du curseur, dans le programme |
| `C-c d c` | [commands.Continue] | continue jusqu'à l'arrêt suivant |
| `C-c d n` | [commands.StepOver] | exécute une ligne, un appel qu'elle contient comptant comme un tout, et s'arrête |
| `C-c d s` | [commands.StepInto] | exécute une ligne, en entrant dans un appel qu'elle contient, et s'arrête |
| `C-c d u` | [commands.StepOut] | continue jusqu'à ce que la fonction rende sa valeur, et s'arrête |

`C-c d r` lance `cesia run --debugger HOME/tools/debugger.ce PATH`, `HOME` étant le dossier de Cemacs : le debugger de Cesia
lui-même tourne à côté du programme et appelle `tools/debugger.ce` à chaque arrêt. Le debugger de Cesia arrête chaque
programme avant sa première ligne ; là, `tools/debugger.ce` prend les breakpoints que vous avez posés, que Cemacs a envoyés
avec le démarrage, et laisse le programme continuer sans le dire à Cemacs : l'état reste donc `running`. Seul un breakpoint
sur cette première ligne en fait un arrêt que vous voyez. Le programme tourne presque aussi vite que sans le debugger,
jusqu'à ce qu'il atteigne un breakpoint : le livre de Cesia dit pourquoi dans son chapitre sur le prompt et le debugger. Il
tourne sans aucune permission, même quand une tâche exécute le fichier : `cesia do` ne peut pas lancer de debugger.

### Les breakpoints

Un breakpoint est une ligne où le programme s'arrête chaque fois qu'il l'atteint. `C-c d b` en pose un sur la ligne du
curseur, `Breakpoint on line N.` (breakpoint sur la ligne N), ou l'enlève, `Breakpoint removed.` (breakpoint enlevé) ; il
s'affiche comme un point de couleur avant le numéro de la ligne. Un programme qui tourne le prend tout de suite. Les
breakpoints restent dans l'éditeur d'une exécution à la suivante, chacun un fichier et un numéro de ligne : des lignes
ajoutées au-dessus d'un breakpoint ne le déplacent pas. Un buffer sans fichier dit
`A breakpoint needs a file: save the buffer first.` (un breakpoint demande un fichier : enregistrez d'abord le buffer)

### Un arrêt

Le programme s'arrête à un breakpoint, après un step (une ligne exécutée par `C-c d n`, `C-c d s` ou `C-c d u`), et sur une
erreur, un bug qui le terminerait, avec chaque variable encore là. Alors :

- l'état après le titre de la sortie dit `stopped at PATH:LINE` (arrêté à PATH:LINE), ou
  `stopped on an error at PATH:LINE` (arrêté sur une erreur à PATH:LINE) ;
- la ligne de l'arrêt a une bande de couleur, dans un buffer de ce fichier s'il y en a un d'ouvert : Cemacs n'ouvre pas le
  fichier pour vous ;
- la sortie a pour titre `Variables` et liste chaque variable de la fonction où le programme s'est arrêté, la frame la plus
  intérieure de ses appels (l'appel en cours le plus profond), sous la forme `name = value`, après le message de l'erreur
  pour un arrêt sur une erreur.

`C-c d c`, `C-c d n`, `C-c d s` et `C-c d u` repartent d'un arrêt ; quand le programme tourne, ils disent
`The program isn't stopped.` (le programme n'est pas arrêté). Après une erreur, `C-c d c` laisse l'erreur continuer, comme
elle le ferait sans le debugger.

### Évaluer du code

`C-c d e` envoie la sélection, ou à défaut la ligne du curseur, au programme, qui l'exécute et renvoie sa valeur. La valeur
s'affiche au bout de la ligne d'où elle vient, la dernière ligne de la sélection, deux caractères après elle, en gris et après
`= ` ; une erreur s'affiche sous la forme `= error: MESSAGE`. Elle ne fait pas partie du texte : elle est dessinée, pas
tapée, et un enregistrement ne l'écrit pas.

À un arrêt, le code tourne dans la frame la plus intérieure, et voit ses variables. Pendant que le programme tourne, il
tourne au niveau du fichier principal, comme le ferait le prompt de `cesia run --repl`. Une expression ne fait que lire :
elle ne change jamais le programme. Sans programme sous le debugger, `C-c d e` dit
`No program runs under the debugger: C-c d r runs the file under it.` (aucun programme ne tourne sous le debugger :
C-c d r y exécute le fichier)

### Fix and continue

Pendant que le programme est arrêté, vous pouvez modifier son code et l'enregistrer. Quand il repart, par l'une des quatre
touches, le debugger recharge les fichiers qui ont changé : la fonction qui tournait finit avec son ancien code, et son appel
suivant exécute le nouveau. Un fichier qui ne se charge pas, parce qu'il contient une erreur, n'est pas chargé : l'état dit
`the fix doesn't load` (la correction ne se charge pas), le programme reste arrêté là où il était, sa ligne toujours marquée,
et les erreurs du fichier s'affichent dans la sortie après les variables, les dernières lignes du pane, pour qu'on les voie ;
elles sont aussi ajoutées à la sortie entière, que liste `C-c c o`. À partir de là :

- corrigez le fichier, enregistrez-le, et repartez avec l'une des quatre touches : la correction se charge alors ;
- ou repartez sans le corriger : Cesia compte le fichier comme lu, si bien que le programme continue avec le code qu'il
  avait, et la prochaine correction que vous enregistrez se charge à l'arrêt suivant.

```cesia
atLine3 = "$(run.Mark){\"Kind\": \"stop\", \"File\": \"a.ce\", \"Line\": 3, \"Reason\": \"break\", \"Error\": \"\", \"Fiber\": 0, \"Vars\": []}\n"
refused = "$(run.Mark){\"Kind\": \"reload\", \"Ok\": false, \"Text\": \"a.ce:3:7: Expected an expression, found *.\"}\n"
after = run.Read(refused, run.Resume("continue", run.Read(atLine3, run.Empty())))
after.Status --> "the fix doesn't load"
run.StoppedAt("a.ce", after) --> 3
run.FixOf(after) --> ["a.ce:3:7: Expected an expression, found *."]
```

[run.Resume] garde l'arrêt qu'il quitte jusqu'à ce que le debugger ait chargé les corrections, et une correction qui ne se
charge pas le ramène.

### Comment Cemacs parle avec le debugger

Le debugger de Cemacs, `tools/debugger.ce`, est un petit programme Cesia qui parle avec l'éditeur par l'entrée et la sortie
du programme lui-même. Chacun de ses messages est une ligne qui commence par l'octet 1, un caractère de contrôle qu'aucune
sortie ordinaire ne contient, et continue avec une map en JSON :

| `Kind` | Ses champs | Quand |
|---|---|---|
| `"stop"` | `File`, `Line`, `Reason`, `Error`, `Fiber`, et `Vars`, chacune un `Name` et une `Value` | le programme s'est arrêté, mais pas avant sa première ligne, sauf si un breakpoint y est |
| `"value"` | `Id`, `Ok`, `Text` | la réponse à une évaluation |
| `"reload"` | `Ok`, `Text` | une correction ne s'est pas chargée, après un mot pour repartir : le programme attend toujours à son arrêt |

Cemacs écrit une commande par ligne, une map en JSON dont le `Do` est `"eval"` avec un `Id` et le `Code`, `"break"` ou
`"clear"` avec un `File` et une `Line`, ou `"continue"`, `"step"`, `"next"` ou `"out"`. Toute autre ligne que le programme
écrit est sa sortie. [run.Read] lit les deux :

```cesia
stop = "$(run.Mark){\"Kind\": \"stop\", \"File\": \"a.ce\", \"Line\": 3, \"Reason\": \"break\", \"Error\": \"\", \"Fiber\": 0, \"Vars\": []}"
r = run.Read("hello\n$stop\n", run.Empty())
r.Output --> ["hello"]
r.Status --> "stopped at a.ce:3"
```

C'est un protocole propre à Cemacs, pas le Debug Adapter Protocol que parlent VS Code et d'autres éditeurs : le côté du
debugger est un seul programme de 137 lignes, et le [std/debug] de Cesia donne le reste.

Comme l'entrée du programme porte les commandes de l'éditeur, un programme qui lit son entrée standard ne tourne pas bien
sous `C-c d r`. Et le debugger ne montre que la frame la plus intérieure : pour remonter les appels, surveiller une
expression à chaque arrêt, ou mettre une condition sur un breakpoint, employez le debugger de Cesia dans un terminal,
`cesia run --debugger debugger FILE`, qui a tout cela.
