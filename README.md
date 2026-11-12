# Cemacs

Cemacs is a text editor for [Cesia](https://github.com/www-celestial/cesia-lang), written in Cesia. It has the keys of Emacs
and the colours of Cesia's code. A band shows what a key can lead to, so you don't need to learn the keys before you start.
Errors show in the lines as you type, and a program runs, and stops at its breakpoints, inside the window. You change Cemacs
in Cesia, in a folder of your own that `git pull` never touches, and it reloads while it runs.

**Documentation: https://www-celestial.github.io/cemacs/** (start with
[First steps](https://www-celestial.github.io/cemacs/first-steps.html)). The same pages are in [docs/book/](docs/book/).

## Install

Cemacs is tried on Linux. It needs three things:

1. Cesia on your `PATH`: see [its install page](https://www-celestial.github.io/cesia-lang/install.html).
2. SDL3 and SDL3_ttf, 3.2 or later, the two C libraries that draw its window:
   ```bash
   sudo pacman -S sdl3 sdl3_ttf     # Arch Linux
   ```
   On a system without these packages, `tools/sdl-libs.sh ~/.sdl` builds both from their sources.
3. Its code, which Cesia runs as it is, with no build step:
   ```bash
   git clone https://github.com/www-celestial/cemacs
   cd cemacs
   bin/cemacs notes.ce
   ```

Its fonts come with it, in `fonts/`. The first start makes `user/`, the folder of your changes, which git ignores:
[Changing Cemacs](https://www-celestial.github.io/cemacs/customising.html) tells what goes in it, and
[Recipes](https://www-celestial.github.io/cemacs/recipes.html) shows small tasks done there. The
[install chapter](https://www-celestial.github.io/cemacs/install.html) gives the details: versions, other systems, the
permissions Cemacs runs with.

## License

MIT, see [LICENSE](https://github.com/www-celestial/cemacs/blob/main/LICENSE). The fonts are under the SIL Open Font License 1.1, whose texts are beside them in `fonts/`.
