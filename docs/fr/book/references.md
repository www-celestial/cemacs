# Références

Les travaux, les normes et les programmes que suit Cemacs, chacun avec ce qu'il en a pris. Chaque entrée a été vérifiée sur
sa source ; un travail que Cemacs ne suit pas n'est pas ici, sauf sous le dernier titre, où sont les outils auxquels il est
comparé. Les titres des travaux restent dans leur langue.

## Éditeurs

- Richard M. Stallman. *EMACS: The Extensible, Customizable Self-Documenting Display Editor.* Proceedings of the ACM
  SIGPLAN SIGOA Symposium on Text Manipulation, 1981 ; aussi MIT AI Lab Memo 519a, mars 1981.
  [doi:10.1145/800209.806466](https://doi.org/10.1145/800209.806466),
  [le memo au MIT](https://dspace.mit.edu/handle/1721.1/5736).
  Ce que Cemacs en a pris : un éditeur écrit et modifié dans son propre langage, dont les commandes sont des fonctions que
  n'importe quelle touche peut nommer, et qui se documente lui-même : la bande des hints et les listes de `?` viennent des
  commentaires du code.
- Free Software Foundation. *GNU Emacs Manual.* https://www.gnu.org/software/emacs/manual/.
  Ce que Cemacs en a pris : les touches, de `C-f` à `C-x C-s` et `M-g n`, et les mots : buffer, mark, region, mode line,
  prefix key, kill, yank.
- Free Software Foundation. *GNU Emacs Lisp Reference Manual*, section *The Buffer Gap*.
  https://www.gnu.org/software/emacs/manual/html_node/elisp/Buffer-Gap.html.
  Ce que Cemacs en a pris : rien ; c'est la source de ce que [À l'intérieur de Cemacs](internals.md#pourquoi-une-rope) dit du gap
  buffer d'Emacs, auquel Cemacs préfère une rope.
- Robert S. Boyer et J Strother Moore. *A Fast String Searching Algorithm.* Communications of the ACM 20(10):762–772,
  octobre 1977. [doi:10.1145/359842.359859](https://doi.org/10.1145/359842.359859).
  Ce que Cemacs en a pris : rien ; c'est la source de ce que [Vitesse](performance.md#recherche) dit de la recherche d'Emacs,
  qui compare le mot depuis sa fin et saute en avant d'après des tables, avec le case folding dans ces tables.
- James Gosling. *A Redisplay Algorithm.* Proceedings of the ACM SIGPLAN SIGOA Symposium on Text Manipulation, SIGPLAN
  Notices 16(6):123–129, juin 1981. [doi:10.1145/800209.806463](https://doi.org/10.1145/800209.806463).
  Ce que Cemacs en a pris : rien encore ; c'est la source de ce que [Vitesse](performance.md#taper-et-faire-défiler) dit de la
  façon dont Emacs redessine un terminal, l'écran voulu comparé à l'écran montré et la modification de lignes la moins chère
  trouvée par programmation dynamique, là où Cemacs dessine sa frame entière à chaque événement.
- GNU Emacs 31.1, `lisp/jit-lock.el`, la documentation de `jit-lock-mode` et de `jit-lock-stealth-time`, et
  `lisp/emacs-lisp/syntax.el`, la documentation de `syntax-ppss-max-span`, lues dans l'Emacs installé.
  Ce que Cemacs en a pris : colorer à la demande ce que l'écran montre, puis, après une pause, d'après le vrai contexte des
  lignes du dessus, pour un endroit lointain ; et un cache des états du parser gardé clairsemé, ses entrées espacées d'au
  moins 20 000 caractères, que Cemacs suit avec ses états en chunks de 1 024 lignes. Voir
  [À l'intérieur de Cemacs](internals.md#les-couleurs).
- Henrik Lissner et ses contributeurs. *Doom Emacs*, un framework de configuration pour GNU Emacs.
  https://github.com/doomemacs/doomemacs.
  Ce que Cemacs en a pris : les touches réunies en groupes sous une seule leader key (une touche qui ouvre tous les groupes),
  chaque groupe nommé par sa première lettre, `C-c f` pour les fichiers, avec la bande des hints après une pause.
- Justin Burkett. *which-key*, qui fait partie de GNU Emacs depuis la version 30.1.
  Ce que Cemacs en a pris : la bande qui montre, après une pause sur une prefix key, les touches qui peuvent la suivre.

## Structures de données

- Hans-J. Boehm, Russ Atkinson et Michael Plass. *Ropes: an Alternative to Strings.* Software: Practice and Experience
  25(12):1315–1330, décembre 1995. [doi:10.1002/spe.4380251203](https://doi.org/10.1002/spe.4380251203).
  Ce que Cemacs en a pris : la rope, un texte gardé comme un arbre de morceaux plats que les modifications partagent et ne
  changent jamais ; deux morceaux courts joints n'en font qu'un ; une modification ne copie que les nœuds le long de son
  chemin. Voir [À l'intérieur de Cemacs](internals.md#la-rope).
- G. M. Adelson-Velsky et E. M. Landis. *An algorithm for the organization of information.* Doklady Akademii Nauk SSSR
  146(2):263–266, 1962 ; en anglais, Soviet Mathematics Doklady 3:1259–1263, 1962.
  [L'article sur Math-Net.Ru](https://www.mathnet.ru/eng/dan26964).
  Ce que Cemacs en a pris : l'équilibre de sa rope, où les hauteurs des deux côtés d'un nœud diffèrent d'au plus un, gardé
  par des rotations.
- Charles Crowley. *Data Structures for Text Sequences.* University of New Mexico, Computer Science Department, 10 juin
  1998. https://www.cs.unm.edu/~crowley/papers/sds.pdf.
  Ce que Cemacs en a pris : la piece table, un texte gardé comme des morceaux qui voient le fichier lu, jamais copié ni
  changé, et les textes des modifications ; Crowley compare six structures dans un seul modèle et un simulateur d'édition, et
  la trouve la meilleure. Les feuilles de la rope de Cemacs sont de telles vues : voir
  [À l'intérieur de Cemacs](internals.md#la-rope).
- Peng Lyu. *Text Buffer Reimplementation.* Blog de Visual Studio Code, 23 mars 2018.
  https://code.visualstudio.com/blogs/2018/03/23/text-buffer-reimplementation.
  Ce que Cemacs en a pris : des morceaux dans un arbre équilibré dont les nœuds comptent les octets et les sauts de ligne qui
  sont sous eux, et un fichier gardé dans les textes où il a été lu, sans les joindre ; l'array d'objets de ligne de VS Code
  avait pris environ 600 MB pour un fichier de 35 MB.
- *Html.lazy*, dans *An Introduction to Elm*, le chapitre sur l'optimisation. https://guide.elm-lang.org/optimization/lazy.html.
  Ce que Cemacs en a pris : ne pas refaire une partie de la vue dont les arguments sont les mêmes qu'à la frame d'avant ; Elm
  les compare par référence, Cemacs compare par valeur le texte, la largeur et l'état d'une ligne. Voir
  [À l'intérieur de Cemacs](internals.md#la-frame).
- The Elm Architecture, dans *An Introduction to Elm*. https://guide.elm-lang.org/architecture/.
  Ce que Cemacs en a pris : le nom de sa forme, un état, une mise à jour à partir d'un événement et une vue. Voir
  [À l'intérieur de Cemacs](internals.md#l-état-la-mise-à-jour-et-la-vue).

## Normes

- F. Yergeau. *UTF-8, a transformation format of ISO 10646.* RFC 3629, STD 63, IETF, novembre 2003.
  https://www.rfc-editor.org/rfc/rfc3629.
  Ce que Cemacs en a pris : ce qu'est l'UTF-8 valide, que vérifie [files.IsText] : pas d'overlong form, pas de surrogate,
  rien au-dessus de U+10FFFF.
- The Open Group. *The Open Group Base Specifications Issue 8*, IEEE Std 1003.1-2024 (POSIX), `rename`.
  https://pubs.opengroup.org/onlinepubs/9799919799/functions/rename.html.
  Ce que Cemacs en a pris : la garantie qu'un renommage par-dessus un nom qui existe garde le nom menant à l'ancien fichier ou
  au nouveau à chaque instant, sur laquelle repose son enregistrement sûr. Voir
  [Fichiers et buffers](files.md#ne-jamais-perdre-le-texte).
- Mikhail Ramendik, David Faure, Alexander Larsson et Ryan Lortie. *Trash Specification*, version 1.0, freedesktop.org,
  2014-01-02. https://specifications.freedesktop.org/trash/latest/.
  Ce que Cemacs en a pris : la corbeille dans le dossier personnel, ses dossiers `files/` et `info/`, le fichier `.trashinfo`
  écrit en premier, le chemin percent-encoded, et la date sur l'horloge locale. Là où Cemacs s'en écarte est dit dans
  [Fichiers et buffers](files.md#créer-renommer-et-mettre-à-la-corbeille).
- *XDG Base Directory Specification*, version 0.8, freedesktop.org, 2021-05-08.
  https://specifications.freedesktop.org/basedir/latest/.
  Ce que Cemacs en a pris : `$XDG_DATA_HOME`, et `$HOME/.local/share` quand il n'a pas de valeur, pour la place de la
  corbeille.

## Le cas de la recherche d'un fichier

Les travaux sur lesquels repose [Un cas : trouver un fichier à partir de quelques lettres](finding.md), dans l'ordre de ses
étapes.

- George Pólya. *How to Solve It: A New Aspect of Mathematical Method.* Princeton University Press, 1945.
  Ce que Cemacs en a pris : la première étape du chapitre, comprendre le problème par son inconnue, ses données et sa
  condition.
- George H. Heilmeier. *The Heilmeier Catechism.* DARPA. https://www.darpa.mil/about/heilmeier-catechism.
  Ce que Cemacs en a pris : les questions qui cadrent le problème : ce que vous essayez de faire, comment on le fait
  aujourd'hui et ses limites, ce qui est nouveau, et les « exams » (les examens) qui vérifient le succès.
- Robert B. Miller. *Response time in man-computer conversational transactions.* Proceedings of the AFIPS Fall Joint
  Computer Conference, part I, 1968, pages 267–277. [doi:10.1145/1476589.1476628](https://doi.org/10.1145/1476589.1476628).
  Ce que Cemacs en a pris : le budget d'une lettre : une touche montre son effet en moins de 0,1 seconde, et son écho en
  0,1 à 0,2 seconde (page 271).
- Stuart K. Card, George G. Robertson et Jock D. Mackinlay. *The Information Visualizer, an information workspace.*
  Proceedings of CHI '91, ACM, 1991, pages 181–186. [doi:10.1145/108844.108874](https://doi.org/10.1145/108844.108874).
  Ce que Cemacs en a pris : 0,1 seconde, la constante de temps du traitement perceptif, en deçà de laquelle l'écran doit être
  redessiné pour garder l'illusion d'une animation (tableau 3, page 185).
- Raj Jain. *The Art of Computer Systems Performance Analysis.* Wiley, 1991. ISBN 978-0-471-50336-1.
  Ce que Cemacs en a pris : une baseline avant tout changement, et la méthode d'une mesure.
- Andy Georges, Dries Buytaert et Lieven Eeckhout. *Statistically rigorous Java performance evaluation.* Proceedings of
  OOPSLA 2007, ACM, pages 57–76. [doi:10.1145/1297027.1297033](https://doi.org/10.1145/1297027.1297033).
  Ce que Cemacs en a pris : beaucoup d'exécutions et un intervalle, jamais un seul chronométrage.
- Tomas Kalibera et Richard Jones. *Rigorous benchmarking in reasonable time.* Proceedings of ISMM 2013, ACM, pages 63–74.
  [doi:10.1145/2464157.2464160](https://doi.org/10.1145/2464157.2464160).
  Ce que Cemacs en a pris : la même chose, avec les versions mesurées chacune à son tour.
- Andreas Zeller et Ralf Hildebrandt. *Simplifying and isolating failure-inducing input.* IEEE Transactions on Software
  Engineering 28(2):183–200, 2002. [doi:10.1109/32.988498](https://doi.org/10.1109/32.988498).
  Ce que Cemacs en a pris : le delta debugging, `ddmin`, qui a réduit chaque requête qui ne trouvait rien à une seule
  espace.
- T. F. Smith et M. S. Waterman. *Identification of common molecular subsequences.* Journal of Molecular Biology
  147(1):195–197, 1981. [doi:10.1016/0022-2836(81)90087-5](https://doi.org/10.1016/0022-2836(81)90087-5).
  Ce que Cemacs en a pris : l'idée du score : un alignement qui récompense les correspondances et fait payer les gaps, le
  meilleur étant trouvé en remplissant une table.
- Osamu Gotoh. *An improved algorithm for matching biological sequences.* Journal of Molecular Biology 162(3):705–708,
  1982. [doi:10.1016/0022-2836(82)90398-9](https://doi.org/10.1016/0022-2836(82)90398-9).
  Ce que Cemacs en a pris : un poids de gap $w(k) = uk + v$ en environ un pas par case, par une seconde table : la table D
  de fzy.
- John Hawthorn. *fzy*, son `ALGORITHM.md`, `src/config.def.h`, `src/bonus.h` et `src/match.c`. https://github.com/jhawthorn/fzy.
  Ce que Cemacs en a pris : le score de [lists.Score], ses bonus et ses gaps, en millièmes.
- The Vim project. Patch 9.1.1627, *fuzzy matching can be improved*, de Girish Palya, août 2025, et `:help
  fuzzy-matching` dans Vim 9.2 et Neovim 0.12.6. https://github.com/vim/vim.
  Ce que Cemacs en a pris : les mots d'un filtre qui correspondent séparément, dans n'importe quel ordre ; et le
  `matchfuzzy()` de Vim comme vérification de ses rangs.
- Junegunn Choi. *fzf*, son `src/algo/algo.go` et son manuel. https://github.com/junegunn/fzf.
  Ce que Cemacs en a pris : rien de ses points ; c'est la source de ce que le chapitre dit de fzf, et de son
  `--scheme=path`.
- Free Software Foundation. *GNU Emacs Manual*, section *Completion Styles*, et `project.el` et `minibuffer.el` d'Emacs
  31.1. https://www.gnu.org/software/emacs/manual/html_node/emacs/Completion-Styles.html.
  Ce que Cemacs en a pris : la touche `C-x p f`, et `git ls-files -z -c -o --exclude-standard` pour les fichiers d'un projet.
- Ellen M. Voorhees. *The TREC-8 Question Answering Track Report.* The Eighth Text REtrieval Conference (TREC-8), NIST
  Special Publication 500-246, 1999, pages 77–82. https://trec.nist.gov/pubs/trec8/papers/qa_report.pdf.
  Ce que Cemacs en a pris : le mean reciprocal rank, la mesure du classement.
- Koen Claessen et John Hughes. *QuickCheck: a lightweight tool for random testing of Haskell programs.* Proceedings of
  ICFP 2000, ACM, pages 268–279. [doi:10.1145/351240.351266](https://doi.org/10.1145/351240.351266).
  Ce que Cemacs en a pris : les property-based tests, par le `test.ForAll` de Cesia.
- Todd Mytkowicz, Amer Diwan, Matthias Hauswirth et Peter F. Sweeney. *Producing wrong data without doing anything
  obviously wrong!* Proceedings of ASPLOS 2009, ACM, pages 265–276.
  [doi:10.1145/1508244.1508275](https://doi.org/10.1145/1508244.1508275).
  Ce que Cemacs en a pris : les threats to validity d'un chronométrage, et pourquoi les versions tournent de la même façon,
  chacune à son tour.

## Bibliothèques et polices

- *SDL3*, Simple DirectMedia Layer, version 3.2 ou plus. https://www.libsdl.org/. La fenêtre, le clavier, la souris et le
  dessin.
- *SDL3_ttf*. https://github.com/libsdl-org/SDL_ttf. Le texte, à partir de polices TrueType.
- SIL International. *SIL Open Font License*, version 1.1. https://openfontlicense.org/. La licence des trois polices de
  `fonts/` : JetBrains Mono, Adwaita Sans et Noto Sans.
- *The Cesia book.* https://www-celestial.github.io/cesia-lang/. Le langage dans lequel Cemacs est écrit, et les
  `cesia check`, `cesia run --debugger`, `cesia do` et `--watch` qu'emploie Cemacs.

## Comparés, pas suivis

Voici les outils à côté desquels [Cemacs et les autres éditeurs](comparison.md) met Cemacs ; Cemacs ne suit aucun de ces
deux protocoles.

- Microsoft. *Language Server Protocol.* https://microsoft.github.io/language-server-protocol/. Cemacs lance `cesia check`
  au lieu d'un language server.
- Microsoft. *Debug Adapter Protocol.* https://microsoft.github.io/debug-adapter-protocol/. Cemacs parle un protocole à lui
  avec son debugger.
- Visual Studio Code, *Debugger Extension*. https://code.visualstudio.com/api/extension-guides/debugger-extension. Comment
  VS Code débogue par des debug adapters, et comment ses extensions, écrites en TypeScript, en branchent un.
- GNU Emacs 31.1, https://www.gnu.org/software/emacs/ ; Neovim 0.12.6, https://neovim.io/ ; Vim 9.2, https://www.vim.org/.
