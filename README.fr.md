# Cemacs

Cemacs est un éditeur de texte pour [Cesia](https://github.com/www-celestial/cesia-lang), écrit en Cesia. Il a les touches
d'Emacs et les couleurs du code de Cesia. Une bande montre à quoi une touche peut mener : vous n'avez donc pas besoin
d'apprendre les touches avant de commencer. Les erreurs s'affichent dans les lignes pendant que vous tapez, `M-.` va à la
définition d'un nom et `M-?` à chaque endroit qui le lit, les tests et les programmes tournent dans la fenêtre, où ils s'arrêtent à
leurs breakpoints (les lignes où vous avez demandé qu'ils s'arrêtent), et `C-x g` montre Git. Vous modifiez Cemacs en
Cesia, dans un dossier à vous que `git pull` ne touche jamais, et il se recharge pendant qu'il tourne.

**Documentation : https://www-celestial.github.io/cemacs/** (commencez par
[First steps](https://www-celestial.github.io/cemacs/first-steps.html)). Les mêmes pages, en français, sont dans
[docs/fr/book/](docs/fr/book/).

## Installation

Cemacs est essayé sous Linux. Il lui faut trois choses :

1. Cesia dans votre `PATH` : voir [sa page d'installation](https://www-celestial.github.io/cesia-lang/install.html).
2. SDL3 et SDL3_ttf, en version 3.2 ou plus, les deux bibliothèques C qui dessinent sa fenêtre :
   ```bash
   sudo pacman -S sdl3 sdl3_ttf     # Arch Linux
   ```
   Sur un système qui n'a pas ces paquets, `tools/sdl-libs.sh ~/.sdl` construit les deux à partir de leurs sources.
3. Son code, que Cesia exécute tel quel, sans étape de build (de compilation préalable) :
   ```bash
   git clone https://github.com/www-celestial/cemacs
   cd cemacs
   bin/cemacs notes.ce
   ```

Ses polices viennent avec lui, dans `fonts/`. Le premier démarrage crée `user/`, le dossier de vos changements, que git
ignore : [Changing Cemacs](https://www-celestial.github.io/cemacs/customising.html) dit ce qu'on y met, et
[Recipes](https://www-celestial.github.io/cemacs/recipes.html) montre de petites tâches faites là. Le
[chapitre d'installation](https://www-celestial.github.io/cemacs/install.html) donne les détails : les versions, les autres
systèmes, les permissions avec lesquelles Cemacs tourne.

## Licence

MIT, voir [LICENSE](https://github.com/www-celestial/cemacs/blob/main/LICENSE). Les polices sont sous la SIL Open Font License 1.1, dont les textes sont à côté d'elles, dans
`fonts/`.
