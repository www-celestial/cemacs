# Installation

Il faut trois choses à Cemacs : Cesia, les deux bibliothèques C qui dessinent sa fenêtre, et son propre code. Il n'a pas
d'étape de build (de compilation préalable) : Cesia exécute sa source telle quelle.

## Ce qui le fait tourner

Cemacs est essayé sous Linux : à la main sur Arch Linux sous Wayland, et sur Ubuntu 22.04 par sa CI (les tests que GitHub
lance à chaque changement), avec le dummy driver de SDL (le pilote factice, qui dessine en mémoire au lieu de dessiner sur
un écran). Rien dans son code n'est propre à Linux, mais aucun autre système n'est essayé : macOS peut marcher avec les
bibliothèques de Homebrew, et Windows n'a pas de `bash` pour `bin/cemacs`.

## Cesia

Cemacs est un programme Cesia : Cesia vient donc en premier. Son livre dit comment l'installer, à
https://www-celestial.github.io/cesia-lang/install.html. `cesia` doit être dans votre `PATH`, car Cemacs le lance pour
vérifier votre code (`cesia check`) et pour exécuter vos programmes (`cesia run` et `cesia do`). `git`, en version 2.31 ou
plus, dans le `PATH`, donne la liste des fichiers d'un projet, `C-x p f` ; sans lui, cette liste dit que git ne peut pas
tourner, et le reste marche.

La ligne `cesia` du `cesia.toml` de Cemacs nomme la plus ancienne version de Cesia dont il a besoin :

```toml
[project]
name = "cemacs"
cesia = "1.1"
src = ["core", "src"]
native = ["SDL3", "SDL3_ttf"]
```

Un Cesia plus ancien s'arrête aussitôt, avec `This project needs Cesia 1.1 or later, and this is ...: run cesia upgrade.`
(ce projet demande Cesia 1.1 ou plus, et celui-ci est en version ... : lancez cesia upgrade). `cesia version` dit laquelle
vous avez.

## SDL3 et SDL3_ttf

La fenêtre de Cemacs est dessinée par deux bibliothèques C : [SDL3](https://www.libsdl.org/), qui ouvre la fenêtre, lit
les touches et la souris et dessine des rectangles, et [SDL3_ttf](https://github.com/libsdl-org/SDL_ttf), qui dessine du
texte à partir de polices TrueType. Une bibliothèque C, ici, est un shared object (un fichier comme `libSDL3.so.0`, qu'un
programme charge pendant qu'il tourne) ; Cesia la charge par [std/c](https://www-celestial.github.io/cesia-lang/c.html),
sa façon d'appeler du C, et Cemacs appelle ensuite ses fonctions. Cesia n'apporte pas ces deux bibliothèques : installez-les
avec le gestionnaire de paquets de votre système :

```bash
sudo pacman -S sdl3 sdl3_ttf     # Arch Linux
brew install sdl3 sdl3_ttf       # macOS, untried
```

SDL doit être en version 3.2 ou plus : une plus ancienne n'ouvre rien, et Cemacs dit `This program needs SDL 3.2 or later.`
(ce programme demande SDL 3.2 ou plus).

Sur un système dont les paquets ne les ont pas encore, `tools/sdl-libs.sh` construit les deux à partir de leurs sources,
SDL 3.2.24 et SDL3_ttf 3.2.2 avec FreeType et HarfBuzz dedans, dans un dossier. Il lui faut `curl`, `git`, `cmake` et un
compilateur C, et, sous Linux, les fichiers de développement de X11 et de Wayland, les deux systèmes d'affichage ; la CI de
Cemacs les installe sur Ubuntu avec :

```bash
sudo apt-get install -y cmake libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev \
  libxkbcommon-dev libwayland-dev wayland-protocols libegl1-mesa-dev libgl1-mesa-dev libdrm-dev libgbm-dev
```

Construisez-les ensuite, et dites au système où elles sont avec `LD_LIBRARY_PATH`, la liste des dossiers où Linux cherche
les shared objects avant les siens :

```bash
tools/sdl-libs.sh ~/.sdl
export LD_LIBRARY_PATH=~/.sdl/lib
```

Les licences des deux bibliothèques sont copiées dans `~/.sdl/lib/licenses/`.

## Les polices

Cemacs apporte ses trois polices dans `fonts/` : il n'y a donc rien à installer. Adwaita Sans pour la mode line et les
messages, Noto Sans Medium pour les titres, et JetBrains Mono pour le code, une police monospace (où chaque caractère a la
même largeur, pour que les colonnes s'alignent). Les trois sont sous la SIL Open Font License 1.1, dont les textes sont à
côté d'elles. La fenêtre les lit dans le dossier de Cemacs quand elle s'ouvre, à la taille de [emacs.FontSize].

## Le code

Cemacs est un projet Cesia, avec un dépôt à lui. Clonez-le n'importe où :

```bash
git clone https://github.com/www-celestial/cemacs
cd cemacs
```

`git pull` apporte le code le plus récent. Une release de Cemacs (une version publiée) doit être un tag, comme `v0.2.0`,
avec ses notes, que prépare `tools/release.sh` : il n'y a pas de binaire à télécharger, puisque Cesia exécute le code du tag
tel quel. Aucune release n'a encore de tag.

## Le lancer

`bin/cemacs` ouvre les fichiers qu'on lui donne, ou un seul buffer vide (un buffer est le texte qu'un pane montre et que
l'on modifie, souvent celui d'un fichier) :

```bash
bin/cemacs notes.ce
```

C'est un petit script `bash`. Il trouve le dossier de Cemacs à partir de sa propre place, même à travers un lien
symbolique, et lance :

```bash
cesia run --allow read,write,exec=cesia,exec=git,env=HOME,env=PWD,env=XDG_DATA_HOME,ffi=SDL3,ffi=SDL3_ttf \
  "$home/src/cemacs.ce" "$home" "$@"
```

Un programme Cesia n'a aucune permission tant qu'on ne lui en donne pas : la liste `--allow` les nomme une à une, comme
l'explique le chapitre de Cesia sur les [permissions](https://www-celestial.github.io/cesia-lang/permissions.html). Cemacs
demande celles-ci :

| Permission | Pourquoi Cemacs en a besoin |
|---|---|
| `read`, `write` | pour ouvrir et enregistrer tout fichier que vous choisissez, et pour lister les dossiers |
| `exec=cesia` | pour lancer `cesia check` sur votre code et `cesia run` ou `cesia do` sur vos programmes |
| `exec=git` | pour lister les fichiers d'un projet, `git ls-files`, pour `C-x p f` : aucun autre programme |
| `env=HOME` | `~/` dans le gestionnaire de dossiers, et la corbeille |
| `env=PWD` | le dossier où vous avez lancé Cemacs : un chemin relatif, et le `cesia.toml` dont la tâche exécute un fichier |
| `env=XDG_DATA_HOME` | la place de la corbeille, comme le dit la spécification de freedesktop.org |
| `ffi=SDL3`, `ffi=SDL3_ttf` | pour charger les deux bibliothèques de la fenêtre |

Faites un lien vers le script dans un dossier de votre `PATH` pour lancer Cemacs de n'importe où :

```bash
ln -s "$PWD/bin/cemacs" ~/.local/bin/cemacs
```

Un chemin relatif que vous lui donnez se lit à partir du dossier où vous êtes, pas à partir du dossier de Cemacs.

### Depuis son dossier, avec rechargement

`cesia do dev`, depuis le dossier de Cemacs, lance la tâche `dev` de son `cesia.toml` : le même programme et les mêmes
permissions, sous `--watch`, pour qu'un changement du code de Cemacs se recharge dans la fenêtre qui tourne. Elle ouvre un
seul buffer vide, et lit ses polices dans `./fonts` : elle doit donc partir de ce dossier. Voir
[Modifier Cemacs](customising.md#recharger-cemacs-pendant-qu-il-tourne).

```toml
[tasks.dev]
file = "src/cemacs.ce"
watch = true
allow = ["read", "write", "exec=cesia", "exec=git", "env=HOME", "env=PWD", "env=XDG_DATA_HOME"]
```

`ffi=SDL3` et `ffi=SDL3_ttf` ne sont pas dans cette liste : la ligne `native` de `[project]` les donne à chaque tâche qui
exécute un fichier.

## Vérifier l'installation

`cesia do test` lance toute la suite de tests de Cemacs, `tests/run.sh` : les tests de chaque package sur les deux chemins
de Cesia, avec et sans ses versions d'une fonction par type, puis les tests qui ouvrent de vrais fichiers, exécutent de
vrais programmes et ouvrent de vraies fenêtres. Avec le dummy driver de SDL, aucune fenêtre ne s'affiche :

```bash
SDL_VIDEODRIVER=dummy cesia do test
```

Elle s'arrête au premier échec et le nomme. Un de ses tests, `tests/color-std.ce`, colore chaque package de la bibliothèque
standard de Cesia, dont le binaire de Cesia porte les sources : la suite n'a donc besoin de rien d'autre que Cemacs et un
Cesia installé. `tests/start-check.sh` seul vérifie seulement que Cemacs démarre, à la fois par `bin/cemacs` et par
`cesia do dev`.

Si Cemacs ne démarre pas, [Dépannage](troubleshooting.md#at-start) liste ce qu'il affiche et que faire.
