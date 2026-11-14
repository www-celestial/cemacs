# Git

Git garde l'histoire d'un projet : chaque *commit* est un état de ses fichiers avec un message, et l'*index*, que Git
appelle aussi la staging area (la zone de préparation), tient ce que le prochain commit prendra. Cemacs a une petite part
de ce que fait Magit, le client Git d'Emacs : l'état du dépôt (le dossier dont Git garde l'histoire), où une lettre stage
un fichier (le met dans l'index), l'unstage (l'en retire) ou commit, le log (la liste des commits), un commit, le diff d'un
fichier (ses lignes ajoutées et enlevées) et le commit de chaque ligne. Ces touches sont celles de [src/ide], qui
interroge `tools/git.ce`, avec [src/git], à chaque touche : [Noms](names.md#comment-lide-demande) dit comment.

## Les touches

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-x g`, `C-c g g` | [ide.Status] | liste l'état du dépôt du fichier : sa branche, puis les fichiers stagés, modifiés et nouveaux |
| `C-c g l` | [ide.Log] | liste les 500 derniers commits, le dernier en premier ; Enter en montre un |
| `C-c g b` | [ide.Blame] | liste les lignes du buffer, chacune avec le commit qui l'a modifiée en dernier et son auteur |
| `C-c g d` | [ide.Diff] | montre ce qui a changé dans le fichier du buffer, tel qu'il est enregistré, depuis ce qui en est stagé |

`C-x g` est la touche de Magit, et `C-c g g` la place de Git dans Doom Emacs, `SPC g g`. Le dépôt est celui qui contient
le fichier du buffer courant (le texte ouvert devant vous), ou le dossier où Cemacs a démarré.

## L'état

`C-x g` ouvre une liste : la première rangée nomme la branche et les lettres, `On main    s stage  u unstage ...`, puis une
rangée pour chaque fichier, `staged` (stagé), `changed` (modifié) ou `new` (nouveau) devant son chemin depuis la racine du
dépôt. Un fichier stagé et modifié depuis a une rangée de chaque sorte. Dans cette liste, comme dans Magit, une lettre est
une commande, là où taper filtre les autres listes de Cemacs : l'état a peu de rangées, et une lettre est le chemin le plus
rapide vers chaque chose.

| Lettre | Ce qu'elle fait |
|---|---|
| `s` | stage le fichier de la rangée : `git add -- PATH` |
| `u` | l'unstage : `git restore --staged -- PATH` |
| `c` | demande `Commit message: ` (le message du commit), puis commit ce qui est stagé : `git commit -q -m MESSAGE` |
| `d` | montre le diff du fichier de la rangée : ce qui en est stagé, ou ce qui a changé depuis, pour une rangée `changed` |
| `l` | liste le log, comme `C-c g l` |
| `g` | liste l'état à nouveau, après un changement fait ailleurs |

Enter ouvre le fichier de la rangée, et toute autre lettre dit les lettres. Après `s`, `u` ou `c`, l'état s'affiche à
nouveau, le curseur sur la même rangée. Un message tient en une ligne, puisque la prompt line (la ligne du bas, où Cemacs
pose ses questions) en prend une : le propriétaire d'un projet qui n'écrit qu'une ligne de sujet, comme les commits de
Cesia et de Cemacs eux-mêmes, n'a pas besoin de plus.

## Les diffs, le log et le blame

Un diff est une liste des lignes qu'écrit `git diff`, les lignes ajoutées dans la couleur des textes, les lignes enlevées
dans celle des mots-clés, les lignes qui commencent une partie, `@@ -1,2 +1,3 @@`, dans celle des commentaires. Enter sur
une ligne du nouveau côté, ajoutée ou gardée, ouvre le fichier à cette ligne. `C-c g l` liste `HASH  DATE  AUTHOR  SUBJECT`
(le hash, l'identifiant d'un commit, sa date, son auteur et son sujet) pour chaque commit ; Enter le montre comme le fait
`git show --stat --patch`, ses mots, les fichiers qu'il a modifiés et son diff, sous forme de liste. `C-c g b` donne à git
le texte du buffer, même non enregistré, par `git blame --contents -`, si bien que chaque ligne montre le commit et
l'auteur qui l'ont modifiée en dernier, `00000000` pour une ligne pas encore commitée ; c'est le blame (« à qui la faute »,
le nom que Git donne à cette vue). La liste s'ouvre sur la ligne du curseur, et Enter montre le commit de la ligne.

## Sécurité

git tourne par `sys.Run("git", ["-C", ROOT, ...])` : aucun shell (l'interpréteur de commandes) ne lit la ligne, chaque mot
est un argument, un chemin vient après `--` et un message après `-m`, si bien qu'un fichier nommé `--oops.ce` reste un
fichier et un message `--amend` reste un message, comme le teste la vérification de cette app. Un hash rendu à git, venu du
log ou d'un blame, est d'abord vérifié comme en étant un, des lettres `0` à `9` et `a` à `f`. Un git qui tourne plus de 20
secondes est terminé, et une liste contient au plus 20 000 rangées. Un commit lance les hooks du dépôt (les programmes que
Git lance à certains moments), comme le fait `git commit` depuis un terminal : ce sont les siens.
