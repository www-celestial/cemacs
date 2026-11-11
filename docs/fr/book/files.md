# Fichiers et buffers

Un buffer est un texte que Cemacs garde en mémoire, le plus souvent le texte d'un fichier. Vous modifiez le buffer ;
l'enregistrer l'écrit dans le fichier, et jusque-là le fichier sur le disque ne change pas. Chaque buffer a son propre
curseur, sa mark, son historique d'annulation et ses erreurs vérifiées. Ce chapitre dit comment les fichiers s'ouvrent et
s'enregistrent, quels fichiers s'ouvrent, comment les fins de ligne sont gardées, comment aller d'un buffer à un autre, et
présente le gestionnaire de dossiers. Les commandes sont dans [core/commands], le gestionnaire de dossiers dans
[src/folders].

## Ouvrir un fichier

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-x C-f`, `C-c f f` | [commands.FindFile] | demande `Find file: ` (trouver le fichier) sur la prompt line, puis ouvre le fichier nommé |

La réponse commence par le dossier du fichier courant, pour qu'un fichier à côté de lui ne demande que son nom. C'est un
chemin tel que le système le lit : à partir du dossier où Cemacs a démarré pour un chemin relatif ; `~` n'y est qu'un nom,
pas votre dossier personnel. La prompt line accepte les lettres, Backspace, `C-y`, qui colle la première ligne du
presse-papiers, Enter et `C-g`, et vous ne modifiez la réponse qu'à son bout. Elle n'a pas de completion (l'aide qui finit
un nom à partir des fichiers qui existent).

Un fichier s'ouvre dans un nouveau buffer, qui devient le buffer courant, celui que vous modifiez. Un fichier déjà ouvert
n'est pas relu : Cemacs va à son buffer. Deux chemins nomment le même fichier quand ils sont pareils une fois enlevés les `.`,
les `..` et les barres obliques doublées, comme le fait [files.Normal] ; un lien symbolique n'est pas suivi : un fichier
ouvert par un lien et par sa cible a donc deux buffers.

```cesia
use core/files
files.Normal("./src/../src//main.ce") --> "src/main.ce"
```

Emacs appelle l'ouverture d'un fichier visiting (le visiter). `bin/cemacs a.ce b.ce` ouvre chaque fichier qu'on lui donne,
dans l'ordre, et reste sur le premier.

### Quels fichiers s'ouvrent

Un fichier qui n'existe pas s'ouvre comme un buffer vide, et il est créé au premier enregistrement. Sinon [files.ReadFile]
le lit, à moins qu'il ne soit l'un de ceux-ci, qui restent fermés avec un message sur la prompt line, le fichier intact :

| Le fichier | Le message |
|---|---|
| un dossier | `PATH is a folder.` (PATH est un dossier) |
| pas un fichier ordinaire : un device (un fichier spécial qui mène à un périphérique), une FIFO (un named pipe, un tuyau nommé), un socket | `PATH is not a regular file: it may be a device, a pipe or a socket.` (PATH n'est pas un fichier ordinaire : ce peut être un device, un pipe ou un socket) |
| plus grand que 1 GiB, 1 073 741 824 octets | `PATH is too large to open: SIZE bytes, and the limit is 1073741824.` (PATH est trop grand pour s'ouvrir : SIZE octets, et la limite est 1073741824) |
| pas de l'UTF-8 valide, ou contenant un octet nul | `PATH is not valid UTF-8 text, or holds a zero byte.` (PATH n'est pas un texte UTF-8 valide, ou contient un octet nul) |
| illisible, par exemple sans la permission du système | la raison que donne Cesia |

Un device ou une FIFO dit avoir la taille 0, et en lire un peut ne jamais finir ou remplir la mémoire : Cemacs demande donc
au système ce qu'est un fichier avant de le lire. La limite de taille empêche un fichier trop grand pour la mémoire d'arrêter
l'éditeur, avec le texte non enregistré de chaque buffer : un fichier prend un moment environ deux fois sa taille en mémoire
pendant qu'il s'ouvre, 193 MB au plus haut pour 99,9 MB, et [Vitesse](performance.md#opening-a-file) donne ce que coûte un
grand fichier.

### Les encodages

Un encodage est la façon dont les caractères d'un texte deviennent des octets dans un fichier. Cemacs ne lit et n'écrit que
l'UTF-8, l'encodage du code Cesia et de la plupart des textes d'aujourd'hui, où un caractère prend de un à quatre octets. Un
fichier est de l'UTF-8 valide quand chacune de ses suites d'octets est une de celles que permet la RFC 3629 :
[files.IsText] refuse une overlong form (un caractère écrit en plus d'octets qu'il n'en faut) ; un surrogate (un code de
U+D800 à U+DFFF, qu'UTF-16 emploie par paires et qui n'est pas un caractère) ; et un code au-dessus de U+10FFFF, le dernier
d'Unicode. Un fichier en Latin-1 enfreint ces règles dès qu'il contient un caractère hors d'ASCII, et un fichier en UTF-16
contient des octets nuls : un tel fichier reste donc fermé, au lieu de montrer de faux caractères et d'être enregistré
abîmé.

[files.IsText] fait deux vérifications du texte entier, chacune un appel de la bibliothèque standard de Cesia, écrite en
OCaml, qui lit le texte là où il est, sans copie : [text.Count] compte ses octets nuls, qui doivent être zéro, et
[text.IsUtf8] dit s'il est de l'UTF-8 valide tel que le définit la RFC 3629. L'octet nul demande sa propre vérification,
car il est de l'UTF-8 valide, le caractère U+0000, qu'aucun fichier texte ne contient. Les deux lisent huit octets à la
fois : un mot de 64 bits contient huit octets, et quelques opérations sur le mot entier répondent pour les huit d'un coup,
une méthode appelée SWAR, SIMD within a register (SIMD, single instruction, multiple data, est la façon qu'a un processeur
de faire une seule opération sur plusieurs valeurs ensemble ; SWAR l'obtient avec les opérations ordinaires sur les
entiers). [text.IsUtf8] ne décode un caractère que là où un octet n'est pas ASCII. Sur 99,9 MB de code Cesia, mesurés
comme le dit [Vitesse](performance.md#opening-a-file) : 34 ms pour compter les octets nuls, 24 ms pour vérifier l'UTF-8,
60 ms pour [files.IsText].

```cesia
use std/text
files.IsText("café") --> true
files.IsText(text.FromBytes([0x63, 0x61, 0x66, 0xE9])) --> false
files.IsText(text.FromBytes([0x61, 0, 0x62])) --> false
```

Le deuxième texte est `café` en Latin-1, où `é` est le seul octet `E9`. Un fichier qui commence par le byte order mark
d'UTF-8 (les octets `EF BB BF`, que certains programmes écrivent en premier) est de l'UTF-8 valide : il s'ouvre, la marque
reste le premier caractère du buffer, et un enregistrement la réécrit.

GNU Emacs, Neovim et Vim testent eux aussi l'UTF-8 quand ils lisent un fichier, mais là où le test échoue, ils prennent un
autre encodage : les quatre octets de `café` en Latin-1 s'ouvrent dans GNU Emacs 31.1 avec le coding system
`iso-latin-1-unix`, et dans Neovim 0.12.6 et Vim 9.2 avec le `fileencoding` `latin1`, le dernier de leur liste par défaut
`ucs-bom,utf-8,default,latin1` (chacun vérifié sur cette machine). Leur façon ouvre n'importe quel fichier, au risque de se
tromper : un fichier dans un autre encodage d'un octet par caractère, comme Windows-1252, montre de faux caractères en
Latin-1. Cemacs garde un seul encodage, et refuse ce qui n'en est pas plutôt que de deviner.

### Les fins de ligne

Une fin de ligne est le caractère, ou les deux, qui finissent une ligne : `\n`, un line feed (saut de ligne), sous Linux et
macOS, et `\r\n`, un carriage return (retour chariot) et un line feed, sous Windows. Cemacs garde celle de chaque ligne :

- Un `\r` juste avant un `\n` appartient à la fin de ligne : le curseur ne va jamais entre eux, et les colonnes ne le
  comptent pas.
- Enter insère la fin de ligne de la ligne où il est : `\r\n` dans une ligne qui finit ainsi, sinon `\n`. La dernière ligne,
  qui n'en a pas, prend celle de la ligne du dessus.
- Un `\r` partout ailleurs est un caractère ordinaire.
- L'enregistrement écrit le texte tel qu'il est : un fichier en `\r\n` le reste, un mélange reste un mélange, et aucune fin
  de ligne n'est ajoutée ni enlevée à la fin du fichier.

## Enregistrer

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-x C-s`, `C-c f s` | [commands.Save] | enregistre le buffer courant dans son fichier ; un buffer sans fichier demande d'abord `Save as: ` (enregistrer sous) |

Après un enregistrement, la prompt line dit `Saved PATH` (PATH enregistré), l'étoile de la mode line s'en va, et chaque
buffer Cesia est vérifié à nouveau, puisqu'un autre fichier peut employer celui qu'on vient d'enregistrer : voir
[Les erreurs dans les lignes](check.md).

### Ne jamais perdre le texte

L'enregistrement est construit pour qu'aucun échec ne perde de texte, ni le texte sur le disque, ni celui du buffer :

1. Le nouveau texte va dans un nouveau fichier à côté de l'ancien, nommé `PATH.cemacs-` suivi de l'heure en microsecondes,
   avec `-1`, `-2` et ainsi de suite jusqu'à `-20` quand ce nom est pris ; après quoi l'enregistrement s'arrête avec
   `No free name next to PATH for a new file.` (pas de nom libre à côté de PATH pour un nouveau fichier). Le nouveau fichier
   est le seul que Cemacs enlève jamais.
2. Le nouveau fichier est écrit avec `sys.Write(..., sync = true)`, qui ne répond qu'une fois que le système a mis le
   fichier sur le disque, puis son dossier, avec `fsync` : l'appel qui demande au système d'écrire ce qu'il garde dans ses
   caches, pour qu'une coupure de courant ne puisse pas le reprendre.
3. Une fois qu'il est sur le disque en entier, un renommage le met à la place de l'ancien fichier. Sous Linux, un renommage
   à l'intérieur d'un même système de fichiers, comme ici, est atomique : à chaque instant, le nom mène à tout l'ancien
   fichier ou à tout le nouveau, jamais à une partie de l'un ou de l'autre.
4. Si l'écriture ou le renommage échoue, le nouveau fichier est enlevé, l'ancien reste entier, le buffer garde son texte et
   son étoile, et la prompt line dit la raison, en nommant votre fichier, pas le nouveau.

Cela protège le fichier d'un échec de Cemacs, d'un disque plein, d'une permission, et d'une coupure de courant : une fois
que la prompt line dit `Saved`, tout le nouveau texte est sur le disque, sous le nom de votre fichier, ou, si le courant a
été coupé à l'instant du renommage avant que le système ait réécrit le dossier, sous le nom du nouveau fichier
`PATH.cemacs-...`, à côté de l'ancien fichier, qui est alors entier. Vim et Neovim font de même par défaut (leur option
`'fsync'`) ; GNU Emacs 31 non, car son `write-region-inhibit-fsync` est activé. Le coût est le temps que prend le disque :
[Vitesse](performance.md#paste-undo-and-save) le donne.

Comme le fichier enregistré est un nouveau fichier, il ne garde pas ce qui appartenait à l'ancien : ses permissions sont
celles d'un nouveau fichier, `rw-r--r--` avec l'`umask` habituel (le masque par lequel le système retire des droits à
chaque nouveau fichier), si bien qu'un script perd son droit d'être exécuté et qu'un fichier en lecture seule devient
modifiable ; un lien symbolique (un fichier qui ne fait que pointer vers un autre) est remplacé par un fichier ordinaire, sa
cible laissée telle qu'elle était ; et un hard link (un second nom du même fichier) ne partage plus le texte. Le dossier doit
vous permettre d'y écrire, pour le nouveau fichier.

### Un fichier changé par un autre programme

Quand Cemacs lit un fichier, il note sa taille et l'heure de son dernier changement. Un enregistrement regarde d'abord à
nouveau : si un autre programme, `git` par exemple, a changé le fichier depuis, ou a créé un fichier là où Cemacs n'en avait
vu aucun, rien n'est écrit et la prompt line demande `File changed on disk. Overwrite? (y or n)` (le fichier a changé sur le
disque ; l'écraser ? y pour oui, n pour non). `y` écrit votre texte par-dessus, de la même façon sûre ; `n` dit `Not saved.`
(pas enregistré) et laisse les deux textes tels qu'ils sont. [files.SaveFile] fait la vérification :

```cesia allow=read,write
use std/result
use std/sys
sys.Write("notes.txt", "one")
read = result.Unwrap(files.ReadFile("notes.txt"))
result.IsOk(files.SaveFile("notes.txt", "second", read.Disk)) --> true
files.SaveFile("notes.txt", "third", read.Disk) --> result.Err({Kind: "changed", Message: "notes.txt changed on disk since it was read."})
```

Le second enregistrement donne la taille et l'heure de la première lecture, et le fichier a changé depuis : l'enregistrement
entre les deux en a fait un nouveau fichier. Cemacs ne regarde qu'au moment d'enregistrer : il ne recharge pas un fichier qui
change pendant qu'il est ouvert, comme le ferait l'`auto-revert-mode` d'Emacs, et il n'a pas de commande pour le relire.

### Enregistrer sous

Un buffer sans fichier demande `Save as: ` et enregistre au chemin donné, qui ne devient son fichier qu'une fois
l'enregistrement réussi. Une réponse vide dit `No file name.` (pas de nom de fichier) ; un fichier ouvert dans un autre
buffer est refusé avec `PATH is open in another buffer.` (PATH est ouvert dans un autre buffer), car un même fichier aurait
alors deux buffers avec deux textes ; et pour un fichier qui existe déjà à cet endroit, Cemacs demande
`File changed on disk. Overwrite? (y or n)`, comme ci-dessus. Une liste, comme la liste des buffers, n'a pas de fichier :
l'enregistrer dit `A list has no file.` (une liste n'a pas de fichier)

### Ce que Cemacs n'écrit pas

Cemacs ne fait pas de fichier de backup (de copie de sauvegarde), comme le `notes.ce~` d'Emacs, pas de fichier d'autosave
(d'enregistrement automatique), et pas de lock file (le fichier qui signale aux autres éditeurs qu'un fichier est en cours de
modification). Le texte non enregistré ne vit qu'en mémoire : quitter demande d'abord, mais un crash de l'éditeur le perd.
Enregistrez souvent.

## Les buffers

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-x b`, `C-c b n` | [commands.NextBuffer] | va au buffer suivant, du dernier au premier |
| `C-x C-b`, `C-c b b` | [buffers.Open] | ouvre la liste des buffers |
| `C-x k`, `C-c b k` | [commands.CloseBuffer] | ferme le buffer courant, en demandant d'abord si son texte n'est pas enregistré |
| `C-x C-c`, `C-c q q` | [commands.Quit] | termine Cemacs, en demandant d'abord si un texte n'est pas enregistré |

Le nom d'un buffer est la dernière partie de son chemin, comme la mode line et le titre de la fenêtre le montrent,
`untitled` (sans titre) pour un buffer sans fichier, ou le nom d'une liste. Deux fichiers du même nom dans deux dossiers
montrent le même nom : la liste des buffers donne leurs chemins.

La liste des buffers a une rangée pour chaque buffer, avec une étoile pour un texte non enregistré, son nom, et son chemin.
C'est une liste : un buffer de rangées que la frappe filtre, en lecture seule, où Enter sur une rangée va à ce buffer et
ferme la liste. Voir [Recherche](search.md#les-listes) pour la façon dont un filtre trouve une rangée.

Fermer un buffer dont le texte n'est pas enregistré demande `Text not saved. Close anyway? (y or n)` (texte non enregistré ;
fermer quand même ?). Fermer le dernier buffer laisse un buffer vide, pour qu'il y en ait toujours un. Un pane qui montrait
le buffer fermé montre celui qui prend sa place.

Quitter demande `Text not saved. Quit anyway? (y or n)` (texte non enregistré ; quitter quand même ?) quand un buffer n'est
pas enregistré, et il en va de même pour la fermeture de la fenêtre et pour le signal TERM ou INT, comme celui qu'envoie
`Ctrl-C` dans le terminal qui a lancé Cemacs : une question qui était ouverte cède sa place à celle-ci.

## Le gestionnaire de dossiers

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-x d`, `C-c f d` | [folders.Open] | ouvre le dossier du fichier courant, ou le dossier où Cemacs a démarré |

Le gestionnaire de dossiers est une liste des fichiers et des dossiers d'un dossier, comme Dired dans Emacs. La liste est
nommée par le chemin absolu du dossier, et la prompt line montre ce chemin, terminé par `/`, suivi de ce que vous tapez.
Voici les rangées d'un dossier, telles que [folders.Rows] les fait à partir de ses entrées, deux heures après le dernier
changement de chacune :

```cesia
use src/folders
use std/io
entries = [{Name: "cesia.toml", IsDir: false, Size: 262, Modified: 0}, {Name: "src", IsDir: true, Size: 0, Modified: 0},
  {Name: ".git", IsDir: true, Size: 0, Modified: 0}, {Name: "LICENSE", IsDir: false, Size: 1069, Modified: 0}]
for row in folders.Rows(entries, false, 7200)
  io.Print(row.Words)
end
```

Les dossiers viennent d'abord, chacun avec un `/` après son nom, puis les fichiers, chaque groupe dans l'ordre des noms. Un
fichier montre sa taille, comptée par 1000 : `B` pour les octets jusqu'à 999, puis `kB`, `MB`, `GB` et `TB`, avec une
décimale en dessous de 10, comme le fait [folders.SizeText]. Son âge dit quand il a changé pour la dernière fois : `now`
(maintenant) en dessous d'une minute, puis les minutes, les heures, et les jours jusqu'à 30, puis la date, comme le fait
[folders.AgeText].

```cesia
folders.SizeText(142) --> "142 B"
folders.SizeText(3250) --> "3.3 kB"
folders.AgeText(7200, 0) --> "2 h"
```

La date est en UTC, l'heure de Greenwich, et une rangée ne montre pas l'heure du jour. Les noms prennent les couleurs du code
selon ce qu'ils sont : un dossier comme un nom, un dossier ou un fichier caché pâle comme un commentaire, le code comme un
texte (`.ce`, `.ml`, `.c`, `.py`, `.sh`, `.el` et d'autres langages), les réglages et les données comme un mot-clé
(`.toml`, `.json`, `.yaml`, `.csv`, `.lock` et d'autres), les images, les polices et les archives comme un champ (`.png`,
`.svg`, `.ttf`, `.pdf`, `.zip`, `.tar` et d'autres), tout le reste sans couleur.

Un nom qui commence par un point est caché, comme le font la plupart des gestionnaires de fichiers sous Linux : `C-c .`
montre les noms cachés, ou les cache à nouveau.

### Se déplacer dans les dossiers

Ce que vous tapez s'ajoute au chemin de la prompt line :

| Vous tapez | Ce que cela fait |
|---|---|
| des lettres | filtrer les noms, comme dans toute liste |
| une partie du nom d'un dossier, puis `/` | entre dans le dossier sous le curseur si c'en est un, sinon dans le premier dossier montré, ou dit `No folder matches.` (aucun dossier ne correspond) |
| `/` sans rien de tapé | va à la racine, `/` |
| `~`, puis `/` | va à votre dossier personnel, d'après `HOME`, ou dit `HOME is not set.` (HOME n'a pas de valeur) |
| `backspace` | défait la dernière lettre, ou, s'il n'y en a pas, va au dossier du dessus, le curseur sur celui qu'on vient de quitter |
| `C-y` | va au chemin du presse-papiers : un dossier s'ouvre, un fichier montre son dossier avec le curseur sur lui |
| `enter` | un dossier s'ouvre dans la liste ; un fichier s'ouvre dans un buffer, et la liste se ferme |

`backspace` à la racine dit `This is the root.` (c'est la racine). Un chemin collé peut commencer par `/`, par `~`, ou être
relatif au dossier montré ; un chemin qui ne mène nulle part dit `No file or folder at PATH.` (pas de fichier ni de dossier à
PATH)

### Créer, renommer et mettre à la corbeille

| Touches | Ce qu'elles font |
|---|---|
| `C-c n` | demande `New file, or folder/: ` (nouveau fichier, ou dossier/) : un nom qui finit par `/` crée un dossier, avec les dossiers au-dessus de lui ; tout autre nom, un fichier vide |
| `C-c r` | demande `Rename NAME to: ` (renommer NAME en), avec le nom à changer ; un chemin dans la réponse déplace le fichier ou le dossier là |
| `C-c k` | demande `Move NAME to the trash? (y or n) ` (mettre NAME à la corbeille ?), puis met la rangée sous le curseur à la corbeille |

Ces touches ne marchent que dans le gestionnaire de dossiers. Un nom qui existe déjà est refusé avec `NAME already exists.`
(NAME existe déjà), et un nom vide dit `No name.` (pas de nom). Après chacune, le dossier est relu, et le curseur va au nom.

Rien n'est jamais effacé pour de bon : `C-c k` met à la corbeille, le dossier d'où le gestionnaire de fichiers de votre
bureau peut restaurer un fichier. Cemacs suit la Trash specification de freedesktop.org, version 1.0, pour la corbeille de
votre dossier personnel :

- La corbeille est `$XDG_DATA_HOME/Trash`, ou `~/.local/share/Trash` quand `XDG_DATA_HOME` n'a pas de valeur. Sans `HOME`
  non plus, elle dit `There is no trash: HOME is not set.` (il n'y a pas de corbeille : HOME n'a pas de valeur)
- Le fichier ou le dossier va dans `files/`, sous son propre nom, ou `NAME.2`, `NAME.3` et ainsi de suite quand celui-ci est
  pris.
- Ses informations vont d'abord dans `info/NAME.trashinfo`, comme le demande la spécification : son chemin depuis la racine,
  chaque partie percent-encoded (chaque caractère spécial écrit `%` et deux chiffres, comme les URL écrivent une espace
  `%20`), et la date de sa mise à la corbeille. Si le déplacement échoue ensuite, les informations sont enlevées.

```cesia
use std/date
folders.TrashInfo("/home/me/my notes.ce", date.FromUnix(0)) --> "[Trash Info]\nPath=/home/me/my%20notes.ce\nDeletionDate=1970-01-01T00:00:00\n"
```

Les informations sont datées sur l'horloge de cette machine, dans son fuseau horaire, comme le demande la spécification :
[folders.TrashInfo] écrit la date qu'on lui donne sous la forme `YYYY-MM-DDThh:mm:ss`, et la corbeille lui donne le
[date.Local] du moment.

Cemacs s'écarte de la spécification sur deux points. Il trouve un nom libre en regardant les noms pris, là où la
spécification demande une création exclusive (une création qui échoue quand quelque chose existe déjà à ce nom, `O_EXCL`
sous Unix) : deux programmes qui mettent le même nom à la corbeille au même instant pourraient donc se heurter, car Cesia
n'a pas encore une telle création. Et pour un fichier sur un autre disque que votre dossier personnel, où un renommage ne
peut pas atteindre la corbeille, il n'emploie pas le dossier de corbeille que la spécification met au sommet de ce disque :
le déplacement échoue, et la prompt line dit `Can't move NAME to the trash: REASON` (impossible de mettre NAME à la
corbeille : la raison), le fichier laissé là où il était.

Le dossier est lu une fois chaque fois qu'il est montré, une liste et un regard sur chaque entrée ; la frappe ne fait que
filtrer les rangées lues alors. [Vitesse](performance.md) donne les temps.

## Les fichiers d'un projet

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-x p f`, `C-c f p` | [project.Files] | liste les fichiers du projet du fichier courant, classés pendant que vous tapez ; Enter en ouvre un |

Un projet, ici, est un dépôt Git : le dossier qui contient un `.git`, et tout ce qui est en dessous. `C-x p f`, la touche
du `project-find-file` d'Emacs, ouvre une liste de chaque fichier du projet du fichier courant, ou du dossier où Cemacs a
démarré, par son chemin depuis la racine du projet. Les fichiers sont ceux que Git liste, comme le `project.el` d'Emacs les
lit : ceux que Git suit, et les nouveaux qu'il n'ignore pas d'après les fichiers `.gitignore`, avec `git ls-files -z -c -o
--exclude-standard --deduplicate`. `_build/` et les autres dossiers ignorés restent donc dehors. [project.Listed] le fait :
depuis n'importe quel dossier du projet, il demande à Git la racine, `git rev-parse --show-toplevel`, puis les fichiers, et
donne `{Root, Paths}` dans un Ok, ou, dans un Err, les mots que montre la prompt line.

La prompt line montre `Find file in NAME: ` (trouver un fichier dans NAME), le nom du dossier du projet, puis ce que vous
tapez. Taper filtre la liste comme dans [toute liste](search.md#les-listes), et la classe : le fichier qui correspond le mieux
vient en premier, d'après le score qu'emploient Vim et Neovim, et des mots séparés, `ml lib`, correspondent dans n'importe
quel ordre. Enter ouvre le fichier sous le curseur et ferme la liste.
[Un cas : trouver un fichier à partir de quelques lettres](finding.md) dit pourquoi elle classe ainsi, et le mesure sur les
1 933 fichiers de Cesia.

La liste est lue une fois, quand elle s'ouvre : un fichier créé après n'y est pas avant un nouveau `C-x p f`. Hors de tout
dépôt Git, la prompt line dit `FOLDER/ is in no Git repository.` (FOLDER/ n'est dans aucun dépôt Git), et rien ne s'ouvre.
Cemacs lance Git avec la permission `exec=git` : voir [Installation](install.md#le-lancer).
