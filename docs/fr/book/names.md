# Noms : définitions, références et renommages

Un nom du code Cesia, comme `shop.Total`, `Rate` ou `list.Map`, mène quelque part : à sa *définition*, la ligne qui lui
donne sa valeur, et de là à ses *références*, chaque endroit qui le lit. Cemacs va aux deux, montre la documentation d'un
nom, dit la *signature* de l'appel que vous tapez, son nom et ses paramètres, et renomme un nom dans chaque fichier qui le
lit. Ces touches sont celles de [src/ide], qui demande à `cesia lsp` où un nom est défini et ce que dit sa documentation,
et demande à [src/lookup], par `tools/lookup.ce`, les endroits qui le lisent : [Comment l'IDE demande](#comment-lide-demande) dit comment.

```cesia norun
(** A shop. *)
use std/list

Rate = 20   (** The tax, in percent. *)

defn Total(prices)
  (** The total of prices, with the tax. *)
  sum = list.Reduce((a, b) -> a + b, 0, prices)
  sum + sum * Rate / 100
end
```

Avec le curseur sur `shop.Total` dans un autre fichier qui utilise ce package, `M-.` ouvre le fichier ci-dessus sur
`defn Total`, et `M-,` revient. `M-?` liste les trois endroits qui lisent `Total`, et `C-c c m` le renomme dans tous.

## Les touches

`M-.`, `M-,` et `M-?` sont les touches d'Emacs pour le même travail, qu'il appelle *cross references* (les renvois
croisés), xref ; le groupe du code de `C-c` les a aussi, avec la documentation et le renommage :

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `M-.`, `C-c c d` | [ide.Definition] | va à la définition du nom au curseur ; un nom du `std/` de Cesia elle-même montre sa documentation |
| `M-,`, `C-c c b` | [ide.Back] | revient à l'endroit que le dernier `M-.`, ou un endroit ouvert depuis une liste d'endroits, a quitté |
| `M-?`, `C-c c f` | [ide.References] | liste chaque endroit du projet qui lit le nom au curseur |
| `C-c c i` | [ide.Documentation] | montre la signature, le texte et les exemples du nom au curseur |
| `C-c c m` | [ide.Rename] | renomme le nom au curseur partout où le projet le lit (m comme move, déplacer, le mot de `cesia pkg move`) |

Sur un clavier où `?` est Shift et `/`, `M-?` arrive comme `M-S-/`, qui est lié à la même commande. Les endroits où revenir
sont gardés comme une pile (le dernier gardé est le premier repris), les 100 derniers : `M-,` à nouveau recule plus loin.

## Quelle définition

Où un nom est défini, c'est le language server de Cesia elle-même qui le dit, `cesia lsp` : le programme que tout éditeur
qui parle le Language Server Protocol (le protocole par lequel un éditeur demande à un programme ce qu'il sait d'un
langage) interroge, si bien que Cemacs et les autres trouvent le même endroit, par les mêmes règles. Au premier `M-.`,
`M-?`, `C-c c i`, `C-c c m` ou à la première signature de la session, Cemacs démarre `tools/names.ce`, qui démarre
`cesia lsp` et parle son protocole, si bien qu'aucun de ce code ne se charge avec l'éditeur ; les deux restent jusqu'à la
fin de Cemacs, et une question est alors un message à des processus qui tournent déjà, environ une milliseconde. Le nom
sous le curseur est lu avec ses points : sur `Map` de `list.Map(f)`, le nom est `list.Map` ; sur `list`, c'est le package.
Ensuite :

- un nom du package du fichier lui-même, comme `Rate` ou `extra`, est cherché dans les fichiers de son dossier, le fichier
  lui-même d'abord ; un fichier qui n'est dans aucun dossier source de son projet est un programme, et seuls ses propres
  noms comptent ;
- un nom après le nom d'un package que le fichier utilise, comme `shop.Total` avec `use src/shop`, est cherché dans ce
  package ;
- un nom de `std/`, comme `list.Map`, n'a pas de fichier dans un projet, à moins que le projet ne contienne une copie de ce
  package dans `std/` : sa documentation s'affiche, comme `cesia doc list.Map` la donne ;
- un nom après le point d'une valeur, comme `Area` dans `r.Area()`, est une méthode : celle de ce nom dans le package du
  fichier, ou dans les packages du projet qu'il utilise.

Avec une question, Cemacs donne le texte du buffer courant et de chaque buffer Cesia non enregistré, quand il a changé
depuis la dernière question, si bien qu'une définition que vous venez de taper est trouvée. La première fois qu'il donne un buffer, il donne d'abord le texte du disque, si bien qu'un texte
qui ne se lit pas encore, comme un appel à moitié tapé, tient lieu de son fichier avec les définitions que le serveur a
lues dans celui enregistré. Deux choses sont aujourd'hui du ressort du serveur : un nom passant par le nom d'un package,
comme `shop.Total`, est trouvé là où le fichier du package sur le disque l'a, pas dans un buffer de ce fichier non
enregistré, et sa documentation est sa signature sans son texte.

## La documentation et la signature

`C-c c i` ouvre une liste avec la signature du nom, son texte et ses exemples ; Enter dessus va à sa définition, et `C-g`
la ferme. La signature seule s'affiche sur la prompt line (la ligne du bas, où Cemacs parle) dès que le curseur reste
immobile dans un appel, une demi-seconde après la dernière touche, comme le fait *eldoc* dans Emacs : après `shop.Total(`
la ligne dit `Total(prices): The total of prices, with the tax.`, la signature et la première phrase de son texte. Rien
ne s'affiche quand une marque de la vérification est sur la ligne, ou qu'un message ou une question est sur la prompt
line : ils passent d'abord. Elle est demandée une fois pour une place du curseur, quand vient le moment de la
vérification, si bien qu'elle ne coûte rien tant que l'éditeur est immobile.

## Les références

`M-?` liste chaque endroit sous la forme `path:line:column` (le chemin, la ligne et la colonne) et les mots de sa ligne, la
définition d'abord, les chemins depuis la racine du projet, le dossier qui contient son `cesia.toml`. Taper filtre la
liste, Enter va à l'endroit et garde l'endroit quitté, pour `M-,`. Les endroits sont ceux qui lisent le nom, comme le
compilateur de Cesia le lit, par `cesia.Reads`, son resolver de noms (la partie du compilateur qui dit ce que désigne
chaque nom) :

- un paramètre ou une variable locale du même nom n'est pas une référence, pas plus qu'un mot dans un commentaire ou un
  texte ; un nom lu à l'intérieur d'un texte, comme `"$(Total(xs))"`, en est une ;
- un nom d'un package est trouvé dans les fichiers du package et leurs tests, écrit seul, et, pour un nom public, dans
  chaque fichier du projet qui utilise le package, après le nom que le fichier lui donne : `shop.Total`, ou `s.Total` après
  `use src/shop as s` ;
- un nom de `std/`, comme `list.Map`, est trouvé dans chaque fichier du projet qui utilise son package ;
- une méthode ou un champ est lu après le point de n'importe quelle valeur, qu'aucune lecture du code ne peut rattacher à
  un seul struct : il est trouvé par son nom, chaque `.Area` du projet, et la prompt line le dit.

`cesia.Reads` donne le premier endroit où une source lit chaque nom qu'elle ne définit pas. Cemacs le lui demande pour
chaque définition de premier niveau qui contient le nom, une à la fois ; quand le nom y est lu, cet endroit est une
référence, le nom y est remplacé par un placeholder (un nom bouche-trou) de la même longueur, un nom que la source ne
contient nulle part, et la définition est relue, jusqu'à ce qu'il ne reste aucune lecture du nom. Ainsi chaque endroit
trouvé en est un que le compilateur rattache à la définition, et les colonnes des autres ne bougent pas. Un fichier qui ne
se lit pas est laissé de côté, et la prompt line compte les fichiers laissés de côté.

## Un renommage

`C-c c m` demande `Rename Total to: ` (renommer Total en) ; après le nouveau nom et Enter, il trouve les références comme
le fait `M-?`, et demande `Rename Total to Sum in 3 places of 3 files? (y or n)` (renommer Total en Sum à 3 endroits de 3
fichiers ? y pour oui, n pour non). Après `y`, chaque fichier est ouvert s'il ne l'est pas, reçoit ses modifications comme
un seul pas d'annulation, et est enregistré à nouveau s'il était enregistré avant, si bien que le disque contient le projet
tel qu'il se lit maintenant et que la vérification le lit ; un buffer avec des changements à lui reçoit les modifications
et reste non enregistré. La prompt line dit combien de fichiers ont été enregistrés.

Un renommage est refusé, avec la raison sur la prompt line, quand le nouveau nom :

- n'est pas un nom : une lettre, puis des lettres et des chiffres ; ou est un mot de Cesia, comme `end` ;
- rendrait privé un nom public, ou l'inverse : en Cesia, une majuscule en première lettre dit qu'un nom est public, et un
  renommage garde ce qu'est le nom ;
- est déjà défini dans le package ;
- serait lu comme autre chose à l'un des endroits, comme une variable locale de ce nom autour d'un appel : chaque
  définition de premier niveau que touche une modification est relue avec le nouveau nom, et chaque modification doit y
  être lue comme le nom renommé.

Une méthode ou un champ ne peut pas être renommé, puisque ses appels ne peuvent pas être distingués de ceux des autres
méthodes du même nom ; un nom de `std/` non plus, ni un nom dans un fichier qui ne se lit pas, ce qui laisserait ses
endroits tels qu'ils étaient. Un fichier dont le texte a changé entre la question et le oui, où une modification ne trouve
plus l'ancien nom, est laissé tel qu'il est, et la prompt line le dit.

## Comment l'IDE demande

Les touches de ce chapitre, celles de [la recherche dans un projet](search.md#chercher-dans-un-projet), de [Git](git.md)
et [des tests](running.md#les-tests) sont toutes celles d'une seule app, [src/ide] (l'IDE, l'environnement de
développement intégré, la part de Cemacs qui sait le code), qui ne fait elle-même rien de leur travail : chaque touche
interroge un programme de Cemacs, lancé par `cesia run` à ce moment, et fait ce que dit sa réponse. La question part en
JSON sur l'entrée du programme : ce qu'il faut faire, le fichier du buffer courant, son texte et la place du curseur, le
dossier où Cemacs a démarré, et les textes des buffers Cesia non enregistrés. La réponse revient comme une ligne de JSON
sur sa sortie, en quelques mots que src/ide connaît :

| Mot | Ce que fait src/ide |
|---|---|
| `Say` | dit les mots sur la prompt line |
| `Open` | va à un endroit, `{Path, Line, Column}`, en gardant l'endroit quitté pour `M-,` |
| `List` | ouvre une liste de rangées, chacune avec ses mots, ses couleurs et l'élément qu'elle représente ; une touche de la liste, comme Enter, va à l'endroit de l'élément ou interroge à nouveau le programme avec lui ; dans l'état de Git, une lettre l'interroge |
| `Ask` | pose une question sur la prompt line, puis interroge à nouveau le programme avec la réponse |
| `Confirm` | demande un oui, puis fait dans des buffers les modifications qui viennent avec, comme le fait un renommage : aucune réponse ne modifie un buffer sans ce oui |
| `Run` | lance `cesia test`, et envoie sa sortie au programme une fois qu'il a fini |
| `Marks` | met les marques des échecs dans les lignes de leurs fichiers |
| `Insert` | écrit une forme de Cesia sous le curseur, venant du programme des formes seulement : [Édition](editing.md#les-formes-de-cesia) |

| Programme | Son travail | Ses permissions |
|---|---|---|
| `tools/names.ce` | [src/names] : pour la session, il demande à `cesia lsp` où un nom est défini et ce que dit sa documentation | `read`, `exec=cesia`, pour démarrer `cesia lsp` |
| `tools/lookup.ce` | [src/lookup] : les endroits qui lisent un nom, et les modifications d'un renommage, d'après l'endroit où `cesia lsp` dit qu'il est défini | `read` |
| `tools/grep.ce` | [src/grep] : la recherche dans un projet | `read`, `exec=git` |
| `tools/git.ce` | [src/git] : Git | `read`, `exec=git` |
| `tools/testing.ce` | [src/testing] : ce qu'une touche teste, les échecs | `read` |
| `tools/snippets.ce` | [src/snippets] : les formes de `C-c i` | aucune |
| `tools/shell.ce` | [le shell](shell.md) : il démarre votre shell et lui passe les commandes de son buffer, aussi longtemps que le buffer est ouvert | `exec=` votre shell, seul |

La question attend dans une fiber (une tâche de Cesia qui tourne à côté des autres dans le même programme), comme le fait
la vérification, et chaque tick de l'éditeur (chaque tour de sa boucle) prend la réponse une fois qu'elle est arrivée, si
bien que la frappe n'attend jamais ; une nouvelle question prend la place d'une question pas encore répondue.
`tools/names.ce` et `tools/shell.ce` tournent au contraire pour la session : une question aux noms part comme sa longueur
sur une ligne puis son JSON, leurs réponses viennent comme des lignes de JSON, dans l'ordre, lues depuis une fiber.
`tools/names.ce` parle à `cesia lsp` comme le dit le protocole : du JSON après un en-tête `Content-Length`, les colonnes en
unités de code UTF-16.
Ainsi rien de ce travail ne se charge quand Cemacs démarre :
chaque ligne de Cesia qui se charge au démarrage coûte environ 5 µs, davantage à mesure que le code grandit, et les quatre
programmes et leurs packages contiennent environ 2 000 lignes, qui ajouteraient plus de 8 ms à chaque démarrage. Une
question coûte plutôt un processus, environ 15 ms pour démarrer et charger, puis son travail.

## Sécurité

- La recherche des références ne lance aucun code : elle lit des fichiers, et demande à `cesia.Definitions` et à
  `cesia.Reads`, qui analysent et résolvent sans rien lancer. Sa seule permission est `read` : elle ne peut ni écrire, ni
  se connecter, ni démarrer un programme. `tools/names.ce` a `read` et `exec=cesia`, le seul programme qu'il démarre étant
  `cesia lsp`, qui lit des fichiers et n'en écrit jamais, comme le dit le livre de Cesia.
- Chaque programme tourne avec les permissions du tableau ci-dessus, que src/ide lui donne ; une réponse ne peut pas en
  demander d'autres, ni nommer un programme qui n'est pas dans le tableau : la demande d'une réponse qui le fait est
  refusée.
- Une réponse est lue comme une entrée venant d'un autre programme : chaque endroit est vérifié, un chemin depuis la
  racine, une ligne à partir de 1, une colonne à partir de 0 et une fin après elle, chaque liste, rangée et modification
  est vérifiée dans sa forme, 20 000 au plus, avant qu'un fichier soit ouvert ou un buffer modifié ; une mauvaise réponse
  est un message. Seul le programme des tests peut demander un lancement, et seulement de `cesia test`.
- Un renommage modifie des buffers, jamais les fichiers derrière eux : chaque modification est vérifiée contre le texte de
  son buffer, un buffer avec des changements à lui n'est jamais enregistré par lui, et un fichier qui a changé sur le
  disque demande avant d'être écrit, comme le fait `C-x C-s`.
- La recherche des références ne lit aucun fichier de plus de 1 MB, au plus 20 000 fichiers d'un projet, et aucun fichier
  des dossiers qu'un projet garde pour d'autres choses : ceux dont le nom commence par un point, `std/`, `deps/`, `site/`
  et `_build/`. Un fichier qui n'est dans aucun projet est regardé seul, avec les autres fichiers de son dossier, jamais
  les dossiers au-dessus.
- Une question qui prend plus de 10 secondes est terminée.

## Vitesse

Une définition, une documentation ou une signature est un message à `cesia lsp`, sous la milliseconde une fois qu'il
tourne, environ 20 ms pour son démarrage à la première question ; les références et un renommage ajoutent un processus, que
Cesia démarre, dans lequel elle charge src/lookup, et qu'elle lance, davantage pour un nom lu dans beaucoup de fichiers,
tout cela en arrière-plan ; [Vitesse](performance.md#les-questions-de-srcide) donne les mesures.
Taper ne coûte rien de plus : aucune touche qui tape ne demande quoi que ce soit, et la signature est demandée au plus une
fois pour une place du curseur, une demi-seconde après la dernière touche.
