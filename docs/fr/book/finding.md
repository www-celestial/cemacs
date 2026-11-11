# Un cas : trouver un fichier à partir de quelques lettres

Ce chapitre suit un vrai problème du début à la fin, comme le ferait un chercheur : le problème dit précisément, une mesure
avant que rien ne change, une hypothèse qu'une expérience pourrait réfuter, la recherche qui a déjà résolu ce genre de
problème, le plus petit changement de Cemacs, et la preuve que le problème est résolu, avec ce qui pourrait rendre la
preuve fausse. Il finit par ce qui reste. Chaque bloc de code Cesia ci-dessous a tourné quand cette page a été construite,
sur le code de Cemacs, et les lignes avec `-->` ont été vérifiées. Les travaux cités sont dans
[Références](references.md#le-cas-de-la-recherche-d-un-fichier).

Le problème est ordinaire. Vous travaillez dans un projet de quelques milliers de fichiers, vous connaissez une partie du nom
d'un fichier, et vous voulez l'ouvrir en quelques touches.

## 1. Le problème, énoncé précisément

*How to Solve It* (1945), de George Pólya, commence chaque problème par les mêmes questions : quelle est l'inconnue, quelles
sont les données, quelle est la condition ? George Heilmeier, qui a dirigé la DARPA de 1975 à 1977, posait les mêmes à tout
projet, en mots simples, dans ce qu'on appelle aujourd'hui le Heilmeier catechism : qu'essayez-vous de faire, comment
le fait-on aujourd'hui et quelles en sont les limites, qu'est-ce qui est nouveau, et quels sont les examens qui vous diront
que cela a marché ? Les réponses, pour ce problème :

- **Ce que vous voulez.** Vous êtes dans un projet, le dépôt de Cesia lui-même pour les mesures de ce chapitre : 1 933
  fichiers, dont 1 574 tests. Vous vous souvenez d'une partie d'un nom, comme « le fichier des messages », ou « quelque
  chose avec reload et test ». Vous tapez quelques lettres, peut-être avec des trous, peut-être dans un autre ordre que celui
  du nom, et vous voulez le fichier que vous avez en tête sur la première rangée, où Enter l'ouvre.
- **Comment on le fait aujourd'hui.** Cemacs n'a pas de liste des fichiers d'un projet. `C-x C-f` demande un chemin, qu'il
  faut connaître ; `C-x d` liste un dossier à la fois, et il faut savoir lequel. Les deux listes filtrent par
  [subsequence matching](search.md#quand-une-rangée-correspond-à-un-filtre), et gardent leurs rangées dans leur propre ordre : les rangées ne
  sont pas classées, si bien que la rangée voulue n'est la première que quand chaque rangée avant elle est filtrée.
- **Ce que « résolu » veut dire**, sous la forme de trois propriétés qu'une mesure peut vérifier :
  1. *Exact.* La liste montre chaque fichier dont le chemin contient les lettres, et aucun autre : chaque mot de ce que vous
     avez tapé, les mots étant séparés aux espaces, doit venir dans le chemin dans l'ordre, lettres côte à côte ou non,
     quelle que soit leur casse.
  2. *Le fichier voulu vient en premier, ou presque.* Sur un ensemble fixe de requêtes écrites avant tout changement, le
     fichier voulu est sur la première rangée pour au moins trois requêtes sur quatre, et dans les cinq premières rangées pour
     neuf sur dix.
  3. *Chaque lettre répond tout de suite.* L'étude de Robert Miller sur les temps de réponse (1968) demande qu'une touche
     montre son effet en moins de 0,1 seconde, et qu'une touche s'affiche en écho à l'écran en 0,1 à 0,2 seconde ; Card,
     Robertson et Mackinlay (1991) donnent 0,1 seconde comme la constante de temps du traitement perceptif : pour garder
     l'illusion d'une animation, l'écran doit être redessiné au moins toutes les 0,1 seconde. La liste doit donc être
     filtrée, classée et dessinée en moins de 0,1 seconde après chaque lettre, sur la lettre la plus lente. L'objectif propre
     de Cemacs est plus strict : une touche jusqu'à sa frame en moins de 16 ms, une frame à 60 frames par seconde
     ([Vitesse](performance.md)).
- **Hors du sujet.** Une lettre mal tapée, que le subsequence matching ne peut pas pardonner ; ce que contiennent les
  fichiers, ce qui est une recherche à travers les fichiers ; les fichiers hors du projet ; et un classement qui apprend des
  fichiers que vous avez ouverts avant.

## 2. Mesurer avant de rien changer

Une mesure prise avant le changement est la baseline (la mesure de référence) : sans elle, rien après ne peut être dit
meilleur. *The Art of Computer Systems Performance Analysis* (1991), de Raj Jain, enseigne l'ordre d'une étude solide :
le but et ses métriques d'abord, puis le workload (la charge de travail mesurée), puis les mesures, chacune donnée avec sa
variation et non comme un seul nombre. Georges, Buytaert et Eeckhout (2007) et Kalibera et Jones (2013) montrent avec quelle
facilité un seul chronométrage trompe : un temps, ici, est la médiane de beaucoup d'exécutions, avec son intervalle, comme
le fait [Vitesse](performance.md#comment-c-est-mesuré).

### Les fichiers et les requêtes

Les fichiers sont ceux du dépôt de Cesia à son commit fa1701d, tels que Git les liste, dans l'ordre de Git, qui trie les
chemins octet par octet : `git ls-tree -r --name-only fa1701d`. Une liste à qui l'on donne ces rangées les montre dans cet
ordre.

Les requêtes ont été écrites avant toute ligne du changement, chacune avec le fichier qu'elle vise, en six sortes : le début
d'un nom ; des lettres avec des trous, comme quand on abrège ; un dossier et un nom ; des mots dans n'importe quel ordre,
séparés ; des initiales ; et un test. Elles sont dans `bench/find.ce`, et dans les tables de
[la preuve](#la-qualité-le-fichier-voulu-vient-en-premier).

### Comment le classement se mesure

La mesure est le mean reciprocal rank, venu de la question answering track de TREC-8, la Text REtrieval Conference de
1999, tel qu'Ellen Voorhees l'a défini. Chaque requête marque l'inverse du rang de son fichier : 1 quand le fichier est
premier, 1/2 quand il est deuxième, 1/5 cinquième, et 0 quand la liste ne le contient pas. La moyenne sur les requêtes est
entre 0 et 1, et 1 veut dire que chaque fichier est venu en premier. TREC-8 ne comptait que les cinq premières réponses ;
une liste montre toutes ses rangées, si bien qu'ici chaque rang compte. Deux comptes plus simples l'accompagnent : combien de
requêtes mettent leur fichier en premier, et combien dans les cinq premières rangées.

Le filtre tel qu'il était, avant ce chapitre, est la fonction ci-dessous, copiée du Cemacs d'alors. Une espace était un
caractère de plus à trouver :

```cesia
use core/lists
use core/press
use core/commands
use core/text
use core/view
use src/emacs
use src/rope
use src/ui
use std/list
use std/math
use std/text as str
use std/value

defn before(filter, words)
  (** The filter of a list before this chapter: every character of the filter, a space too, in the words in order, whatever the case. *)
  wanted = str.Chars(str.Lower(filter))
  k = 1
  for c in str.Chars(str.Lower(words))
    if k <= value.Len(wanted) and c == wanted[k]
      k += 1
    end
  end
  k > value.Len(wanted)
end

(* Eleven files of Cesia's repository, in Git's order. *)
files = ["bench/RESULTS.md", "docs/book/fibers.md", "src/lib/messages.ml", "src/lib/messages.mli", "src/std/result.ce", "tests/check/results.ce",
  "tests/project/checks/missing_need/cesia.toml", "tools/editors/cesia-mode.el", "tools/editors/nvim/syntax/cesia.vim", "tools/http-gate.sh",
  "tools/reload-test.sh"]
rows = [{Words: f, Item: f} for f in files]
kept(filter) = [f for f in files if before(filter, f)]

kept("cmel") --> ["src/lib/messages.ml", "src/lib/messages.mli", "tests/project/checks/missing_need/cesia.toml", "tools/editors/cesia-mode.el"]
kept("ml messages") --> []
```

### La baseline

Sur les 1 933 fichiers et les 41 requêtes, le filtre tel qu'il était donne :

| Mesure | Avant |
|---|---|
| mean reciprocal rank | 0,597 |
| le fichier en premier | 21 sur 41 |
| le fichier dans les cinq premières rangées | 30 sur 41 |
| aucune rangée du tout | 7 sur 41 : chaque requête de mots dans n'importe quel ordre |
| le pire rang | 207e, pour `rlt`, qui vise `tools/reload-test.sh` |

Il s'en sort bien quand la requête est longue et que le fichier vient tôt dans le tri : `src/` vient avant `tests/` et
`tools/`. Il s'en sort mal sur les initiales, mean reciprocal rank 0,318 : `cmel` met `tools/editors/cesia-mode.el` 48e,
derrière 47 fichiers qui contiennent les mêmes lettres dans l'ordre et viennent avant lui dans le tri.

Le temps de chaque lettre, tapée dans une liste de ces 1 933 rangées à travers la mise à jour de l'éditeur, comme la fenêtre
l'envoie, est dans [la preuve](#la-vitesse-chaque-lettre-répond-tout-de-suite), à côté du temps après le changement.

## 3. Une hypothèse qui pourrait être réfutée

Une hypothèse n'est utile que si une expérience peut la montrer fausse. Il y a ici deux causes à distinguer, donc deux
hypothèses :

- **H1 : le fichier est trouvé, mais enfoui.** Le filtre garde le fichier dans sa liste, et l'ordre des rangées en met
  d'autres avant lui. Si H1 était fausse, le fichier manquerait dans la liste, et son rang serait 0. L'expérience : dans la
  baseline, chaque requête d'un seul mot liste son fichier, 34 sur 34 ; seul l'ordre diffère. `rlt` contient
  `tools/reload-test.sh` parmi 207 rangées, et chacune des 206 autres vient avant lui dans le tri. H1 tient pour ces 34.
- **H2 : l'espace est la cause des 7 listes vides.** Si H2 était fausse, une requête de mots dans n'importe quel ordre
  échouerait pour une autre raison, une lettre d'un mot, par exemple. L'expérience réduit une requête qui échoue à sa plus
  petite partie qui échoue encore, par le *delta debugging* de Zeller et Hildebrandt (2002) : enlever des morceaux de
  l'entrée, garder une entrée plus petite tant qu'elle échoue encore, et continuer avec des morceaux plus petits jusqu'à ce
  que plus rien ne puisse partir. Ce qui reste est la cause.

```cesia
defn shrunk(fails, input)
  (** Zeller and Hildebrandt's ddmin on the characters of a text: the input, with pieces taken out as long as it still fails, from halves down to single
      characters. *)
  chars = str.Chars(input)
  n = 2
  while value.Len(chars) >= 2
    size = math.Div(value.Len(chars) + n - 1, n)
    smaller = missing
    for i in 1..n
      first = (i - 1) * size + 1
      last = list.Min(i * size, value.Len(chars))
      if first <= last
        rest = list.Concat(list.Take(first - 1, chars), list.Skip(last, chars))
        if fails(str.Join("", rest))
          smaller = rest
          break
        end
      end
    end
    if not value.IsMissing(smaller)
      chars = smaller
      n = list.Max(n - 1, 2)
    else if n >= value.Len(chars)
      break
    else
      n = list.Min(n * 2, value.Len(chars))
    end
  end
  str.Join("", chars)
end

shrunk(q -> not before(q, "src/lib/messages.ml"), "ml messages") --> " "
shrunk(q -> not before(q, "bench/maps.go"), "go maps") --> " "
```

Chacune des sept se réduit à une seule espace : un chemin ne contient pas d'espace, si bien qu'un filtre qui en contient
une ne peut jamais correspondre. H2 tient.

La cause des mauvais rangs est l'absence de classement, et la cause des listes vides est l'espace. Ce qui reste à trouver,
c'est comment classer.

## 4. La recherche : comment ce genre de problème se résout

### La correspondance est résolue ; le classement est la question

Chaque éditeur ci-dessous trouve les rangées par subsequence matching. Ils diffèrent par la façon dont ils ordonnent les
rangées trouvées, par un *score* : un nombre donné à chaque rangée, qui dit à quel point la requête lui va, le meilleur en
premier.

### L'alignement et sa table

L'idée du score vient de la biologie. Pour trouver les morceaux les plus semblables de deux séquences moléculaires, d'ADN
ou de protéines, Smith et Waterman (1981) les alignent : ils mettent les lettres de l'une sous les lettres de l'autre, en
permettant des *gaps* (des trous : des endroits où une séquence a des lettres que l'autre saute). Chaque paire de lettres
qui correspondent gagne des points, chaque gap coûte des points, et le meilleur alignement est celui qui a le plus de points.
Essayer chaque alignement prendrait bien trop longtemps ; ils remplissent plutôt une table, une case pour chaque lettre
d'une séquence et chaque lettre de l'autre, chaque case contenant le meilleur score de deux morceaux qui finissent là,
calculé à partir des cases d'avant. Cette façon de résoudre un problème à partir des réponses de ses parties plus petites,
gardées dans une table, s'appelle la *programmation dynamique* (dynamic programming). Un an plus tard, Gotoh (1982) a
montré comment faire coûter à un gap un prix pour l'ouvrir et un prix plus petit par lettre ensuite, un poids de gap de la
forme $w(k) = uk + v$ pour un gap de $k$ lettres, toujours en environ un pas par case, en gardant une seconde table à côté
de la première.

### Le score de fzy

Un nom de fichier et une requête sont deux séquences, et les lettres de la requête doivent toutes correspondre, dans l'ordre
: un alignement qui peut sauter des lettres du chemin mais aucune de la requête. fzy, de John Hawthorn, donne un score aux
noms de fichiers de cette façon, et le dit dans son `ALGORITHM.md` : un algorithme de programmation dynamique « similar to
Wagner–Fischer and Needleman–Wunsch » (semblable à ceux de Wagner–Fischer et de Needleman–Wunsch), avec une affine gap
penalty (un coût de gap fait d'un prix d'ouverture et d'un prix par lettre), « Inspired by the Gotoh algorithm » (inspiré
de l'algorithme de Gotoh), par une seconde table, nommée D, qui contient le meilleur score qui finit par une correspondance
dans cette case. Ses points, d'après son `config.def.h` :

| Où une lettre de la requête correspond | Points |
|---|---|
| juste après la lettre qui a correspondu avant elle | 1,0, et aucun autre bonus |
| au début du chemin, ou après un `/` | 0,9 |
| après un `-`, un `_` ou une espace : le début d'un mot | 0,8 |
| une majuscule après une minuscule, le début d'un mot en CamelCase | 0,7 |
| après un `.`, souvent une extension | 0,6 |
| une lettre sautée entre deux lettres qui correspondent | −0,01 chacune |
| une lettre sautée avant la première, ou après la dernière | −0,005 chacune |

Les lettres au début des mots et côte à côte gagnent donc, et, de deux chemins qui correspondent de la même façon, le plus
court gagne : il saute moins de lettres. Un bonus ne va qu'à une lettre ou à un chiffre qui correspond, jamais à un signe.

### Ce que font les géants

- **Vim 9.2 et Neovim 0.12.6** emploient l'algorithme de fzy pour leur fuzzy matching, d'après leur documentation,
  `:help fuzzy-matching` : « Vim's implementation is based on the algorithm from the fzy project » (l'implémentation de Vim
  se fonde sur l'algorithme du projet fzy). C'est venu avec le patch 9.1.1627 de Vim, d'août 2025, que Neovim a repris.
  Leur documentation dit aussi qu'une requête de plusieurs mots séparés par des blancs fait correspondre chaque mot à part,
  dans n'importe quel ordre. Leur fonction `matchfuzzy()` classe ainsi n'importe quelle liste. Aucun des deux n'a de fuzzy
  finder (un outil qui trouve un fichier d'après quelques lettres) des fichiers d'un projet inclus : `:find` cherche dans les
  dossiers de l'option `'path'`, par wildcards, et la fuzzy completion de `'wildoptions'` « is not supported for file and
  directory names » (n'est pas prise en charge pour les noms de fichiers et de dossiers), d'après leur documentation ;
  l'option `'findfunc'` permet à quelques lignes de script de donner plutôt à `:find` les fichiers de `git ls-files`.
- **GNU Emacs 31.1** trouve un fichier d'un projet avec `C-x p f`, `project-find-file`, qui lit les fichiers d'un dépôt Git
  avec `git ls-files -z -c --exclude-standard -o`, dans `project.el`. Son style de completion `flex`, nouveau dans Emacs
  27,1, fait correspondre par sous-suite ; Emacs 31.1 l'a réécrit, d'après son `NEWS`, « to be faster and more accurate »
  (pour être plus rapide et plus précis). Sa fonction `completion--flex-cost-gotoh`, écrite en C, calcule « the cost of PAT
  matching STR using modified Gotoh algorithm » (le coût de la correspondance de PAT avec STR par un algorithme de Gotoh
  modifié), d'après sa documentation, et `minibuffer.el` trie par un de plus que ce coût, multiplié par le nombre de lettres
  du nom que la requête n'emploie pas, pour que les noms courts viennent en premier. Une espace est une lettre à trouver,
  comme elle l'était dans Cemacs : les mots ne viennent pas dans n'importe quel ordre. `flex` n'est pas ce qu'emploie
  `C-x p f` à moins que vous ne le choisissiez : Emacs 31.1 donne aux fichiers d'un projet le style `substring`, la requête
  trouvée en entier, et les trie par ordre alphabétique. Ce chapitre compare avec `flex`, le style d'Emacs qui classe.
- **fzf**, de Junegunn Choi, pas installé ici, d'après sa source, `src/algo/algo.go` : « a modified version of
  Smith-Waterman algorithm to find the optimal solution (highest score) » (une version modifiée de l'algorithme de
  Smith-Waterman pour trouver la solution optimale, le plus haut score), avec des points à lui (16 pour une correspondance,
  un gap coûtant 3 à ouvrir et 1 par lettre ensuite, un bonus de 8 au début d'un mot), et des mots séparés par des espaces
  qui doivent tous correspondre, dans n'importe quel ordre.

### Ce qui s'applique

Le score de fzy, tel qu'il est : c'est celui que Vim et Neovim ont choisi, ses points sont publiés, et un éditeur qui classe
de la même façon peut être vérifié contre les leurs, rangée par rangée. Des mots séparés aux espaces, chacun avec son propre
score, et leurs scores additionnés, comme Vim, Neovim et fzf prennent plusieurs mots. Deux règles du `match.c` de fzy sont
laissées de côté : un chemin exactement aussi long que la requête, donc le même texte quelle que soit sa casse, a le plus
haut score, ce que les points de fzy lui donnent déjà, puisque rien ne bat une lettre juste après la précédente ; et un
chemin de plus de 1 024 octets a le plus bas score, une borne sur la table de fzy dont les endroits visités n'ont pas
besoin. Pas repris non plus : la syntaxe propre à fzf, `^`, `$`, `'` et `!`, ni ses points, qu'aucune mesure ici ne favorise
par rapport à ceux de fzy ; et aucun classement d'après les fichiers que vous avez ouverts, qui est hors du sujet.

## 5. La plus petite solution

Quatre changements, chacun dans le code de Cemacs, chacun avec ses tests.

**Des mots dans n'importe quel ordre.** [lists.Matches] coupe le filtre à ses espaces ; chaque mot doit correspondre, dans
n'importe quel ordre. Chaque lettre est maintenant cherchée par [text.ByteFind], en code natif, après la précédente, là où
l'ancien filtre lisait en Cesia chaque caractère de chaque rangée :

```cesia
lists.Matches("ml messages", "src/lib/messages.ml") --> true
lists.Matches("messages ml", "src/lib/messages.ml") --> true
lists.Matches("ml zz", "src/lib/messages.ml") --> false
```

**Le score.** [lists.Score] est le score de fzy, avec les points de fzy en millièmes, pour que ses sommes soient des
entiers exacts : 900 pour une lettre après une barre oblique, 1000 pour une lettre juste après la précédente, −10 pour une
lettre sautée entre deux. fzy remplit toute sa table, chaque lettre de la requête par chaque octet du chemin. Mais une case
ne peut contenir une correspondance que là où se trouve cette lettre : [lists.Score] ne visite donc que ces endroits. Pour
chaque lettre de la requête, les endroits où elle se trouve, cherchés avec [text.ByteFind], chacun prenant le meilleur des
endroits de la lettre d'avant, moins son gap, au fur et à mesure. Il donne le même score en environ un pas par endroit au
lieu d'un par case ; [la preuve](#correct-des-tests-qui-échouent-avant-et-passent-après) vérifie qu'il égale la table entière de
fzy.

```cesia
lists.Score("ml", "a/ml") --> 1890
lists.Score("ml", "a/m-l") --> 1680
lists.Score("lexer", "src/lib/lexer.ml") > lists.Score("lexer", "src/lib/lexer.mli") --> true
lists.Score("zz", "a/ml") --> missing
```

Dans `a/ml`, `m` vient après une barre oblique, 900, moins 10 pour les deux lettres avant lui, à 5 chacune ; `l` vient
juste après lui, 1000 ; 1890. Dans `a/m-l`, `l` vient après un tiret, 800, moins 10 pour le tiret sauté entre les deux
lettres, et se passe donc des 1000 d'une voisine : 1680.

**Le classement.** [lists.Ranked] donne les rangées que le filtre garde, la meilleure d'abord ; des rangées de même score
gardent leur ordre, pour que le résultat ne dépende jamais du hasard. Une liste dit si elle classe : [commands.ShowList]
prend `ranked = true`. La liste de la sortie d'un programme garde son ordre, comme doit le faire un log ; les autres listes
gardent aussi le leur pour l'instant, ce qui est un [choix laissé ouvert](#7-ce-qui-reste).

```cesia
[r.Item for r in lists.Ranked("cmel", rows)] --> ["tools/editors/cesia-mode.el", "src/lib/messages.ml", "src/lib/messages.mli", "tests/project/checks/missing_need/cesia.toml"]
[r.Item for r in lists.Ranked("vim syntax", rows)] --> ["tools/editors/nvim/syntax/cesia.vim"]
```

Une liste filtre une lettre ajoutée à partir des rangées que son filtre gardait avant, pas à partir de toutes, puisqu'un
filtre plus long ne peut qu'en garder moins. Une liste classée garde ces rangées dans leur propre ordre et ne les classe que
pour l'écran, pour que taper une requête lettre par lettre montre ce que montre la taper d'un coup. Voici une liste des onze
fichiers, classée, dans une fenêtre, où l'on tape comme la fenêtre envoie les lettres :

```cesia
start = view.Start([text.Of("", missing)], ui.Look(ui.Dark, (w, f) -> 8, 19), {Width: 8, Height: 19}, 800, 600)
start.Config = () -> emacs.Config(emacs.Keys)
opened = commands.ShowList("cesia", rows, () -> {}, start, ranked = true)
shown(state) = str.Lines(rope.Text(state.Buffers[state.Current].Rope))
shown(press.Press(["cmel"], opened))[1] --> "tools/editors/cesia-mode.el"
shown(press.Press(["msgs"], opened)) --> ["src/lib/messages.ml", "src/lib/messages.mli", "tests/project/checks/missing_need/cesia.toml"]
```

**Les fichiers d'un projet.** Une nouvelle app, `src/project`, ouvre la liste des fichiers du projet avec `C-x p f`, comme
Emacs, ou `C-c f p` dans le groupe des fichiers. Le projet est le dépôt Git qui contient le fichier courant, ou le dossier où
Cemacs a démarré ; ses fichiers sont ceux que Git liste, avec la même commande que le `project.el` d'Emacs :
`git ls-files -z -c -o --exclude-standard`, les fichiers que Git suit et les nouveaux qu'il n'ignore pas. La prompt line
dit `Find file in NAME: ` avant ce que vous tapez, et Enter ouvre le fichier sous le curseur. Cemacs demande maintenant une
permission de plus, `exec=git` : voir [Installation](install.md#le-lancer).
[Fichiers et buffers](files.md#les-fichiers-d-un-projet) dit le reste.

Le changement fait environ 250 lignes, commentaires compris : 180 dans `core/lists`, 10 dans `core/commands`, 55 dans
`src/project`.

## 6. La preuve

### Correct : des tests qui échouent avant et passent après

Un test qui passe après un changement prouve peu de chose, à moins qu'il ait échoué avant : il pourrait passer quel que soit
le code. Ceux-ci échouaient sur le code d'avant le changement, où `Ranked` et `Score` n'existaient pas et où une espace était
une lettre, et ils passent maintenant, dans `core/lists/lists.test.ce` :

| Test | Ce qu'il vérifie |
|---|---|
| `isWordsMatchInAnyOrder` | `ml messages` et `messages ml` correspondent à `src/lib/messages.ml` |
| `isSpacesAloneMatchAll` | un filtre fait seulement d'espaces garde chaque rangée |
| `isRankedBestFirst` | `rlt` met `tools/reload-test.sh` avant `tests/check/release-test.ce`, `msgml` met `src/lib/messages.ml` en premier |
| `isRankedOnlyMatches`, `isRankedTiesKeepOrder`, `isRankedEmptyKeepsAll` | seulement les rangées qui correspondent, les ex aequo dans leur ordre, toutes pour un filtre vide |
| `isScoreStartOfWordBest`, `isScoreShorterBest`, `isScoreWordsAddUp` | les bonus, le plus court de deux chemins, la somme des mots |

Quelques exemples ne prouvent guère plus que les cas qu'ils contiennent. Un *property-based test* énonce une règle qui doit
tenir pour chaque entrée, et un programme fabrique des centaines d'entrées au hasard pour l'essayer, les plus petites
d'abord ; quand l'une échoue, il la réduit à la plus petite qui échoue encore. Claessen et Hughes ont introduit cela avec
QuickCheck (2000) ; Cesia l'a sous le nom `test.ForAll`. Cinq règles, chacune essayée sur 300 ou 500 entrées faites de
quelques lettres, barres obliques, points, tirets, majuscules, espaces et `é`, pour que les entrées correspondent souvent :

| Règle | Entrées | Pourquoi elle compte |
|---|---|---|
| [lists.Score] égale la table entière de fzy, calculée case par case comme le fait le `match.c` de fzy | 500 | les endroits visités donnent le même score que la table |
| [lists.Matches] égale l'ancien filtre, caractère par caractère, pour un seul mot | 500 | rien de perdu ni d'ajouté, `é` aussi : une lettre de deux octets est trouvée entière |
| [lists.Score] est absent exactement quand [lists.Matches] est faux | 500 | une rangée est classée si et seulement si elle est montrée |
| [lists.Ranked] contient les mêmes rangées que [lists.Filtered], dans un ordre de scores qui ne monte jamais | 300 | le classement ne fait que réordonner |
| classer une lettre de plus à partir des rangées gardées avant égale la classer à partir de toutes | 300 | taper lettre par lettre montre ce que montre taper d'un coup |

La première règle a trouvé une erreur à sa 17e entrée, dans la référence écrite pour le test, pas dans Cemacs : pour la
requête `a` dans `aa`, la référence donnait 890 et le score 895, parce que Cesia lisait `if i == n -5` comme
`if i == n - 5`. Réduite à ces deux lettres, elle a pris une minute à voir. Voici la référence, qui remplit les tables de
fzy comme le fait `match.c`, et qui est d'accord avec [lists.Score] :

```cesia
lowest = -1000000000
trailing = -5
inner = -10
lowerByte(b) = if b >= 65 and b <= 90 b + 32 else b end
defn bonus(prev, b)
  (** fzy's bonus of a match on byte b after byte prev, in thousandths: only a letter or a digit earns one. *)
  small = (b >= 97 and b <= 122) or (b >= 48 and b <= 57)
  capital = b >= 65 and b <= 90
  if not (small or capital)
    0
  else if prev == 47
    900
  else if prev == 45 or prev == 95 or prev == 32
    800
  else if prev == 46
    600
  else if capital and prev >= 97 and prev <= 122
    700
  else
    0
  end
end
defn table(query, path)
  (** fzy's score of a query of one word in a path, from its two tables, cell by cell: D, the best score that ends with a match at this byte, and M, the
      best score up to this byte. *)
  if not lists.Matches(query, path)
    return missing
  end
  n = str.ByteLength(query)
  m = str.ByteLength(path)
  wanted = [lowerByte(b) for b in str.Bytes(query)]
  bytes = str.Bytes(path)
  lastD = list.Fill(lowest, m)
  lastM = list.Fill(lowest, m)
  for i in 1..n
    d = list.Fill(lowest, m)
    best = list.Fill(lowest, m)
    gap = if i == n trailing else inner end
    prev = lowest
    for j in 1..m
      if wanted[i] == lowerByte(bytes[j])
        here = bonus(if j == 1 47 else bytes[j - 1] end, bytes[j])
        d[j] = if i == 1 (j - 1) * trailing + here else if j > 1 list.Max(lastM[j - 1] + here, lastD[j - 1] + 1000) else lowest end
        prev = list.Max(d[j], prev + gap)
      else
        prev = prev + gap
      end
      best[j] = prev
    end
    lastD = d
    lastM = best
  end
  lastM[m]
end

pairs = list.Flatten([[[q, p] for p in files if lists.Matches(q, p)] for q in ["msgml", "rlt", "a", "cmel", "ml", "lib"]])
value.Len(pairs) --> 24
value.Equal([table(x[1], x[2]) for x in pairs], [lists.Score(x[1], x[2]) for x in pairs]) --> true
```

`tests/project-check.ce` vérifie l'app sur un vrai dépôt Git, fait pour lui : `C-x p f` depuis un fichier deux dossiers plus
bas liste les fichiers du dépôt entier, ceux que Git suit et un nouveau, jamais celui que nomme `.gitignore` ; `msgml` met
`src/lib/messages.ml` en premier ; `ml lib` garde les trois fichiers de `src/lib` dont les noms contiennent `ml` ; Enter
ouvre le fichier et ferme la liste ; et hors de tout dépôt, la prompt line le dit et rien ne s'ouvre.

### Une borne

Pour une requête de $n$ lettres et un chemin de $m$ octets, la table de fzy a $n \times m$ cases : $5 \times 27 = 135$ pour
une requête de cinq lettres dans un chemin de la longueur médiane des fichiers de Cesia, 27 octets. [lists.Score] visite,
pour chaque lettre de la requête, seulement les endroits de cette lettre dans le chemin, chacun une fois, et les endroits de
la lettre d'avant une fois en tout : au plus $2 \times n \times m$ pas en Cesia et $n \times m$ octets lus en code natif par
[text.ByteFind], et en pratique quelques endroits par lettre. Une lettre tapée coûte, pour chaque rangée que le filtre
gardait avant, un [text.ByteFind] par lettre de la requête pour la filtrer, puis le score de chaque rangée encore montrée.

### La qualité : le fichier voulu vient en premier

Les 41 requêtes, avec le rang de leur fichier avant le changement, après, dans le `matchfuzzy()` de Vim 9.2 et dans le style
`flex` d'Emacs 31.1 trié par son coût ; et combien de lettres de la requête étaient tapées quand le fichier est venu en
premier pour la première fois, avant et après. `–` veut dire jamais :

| Requête | Le fichier voulu | Avant | Après | Vim, Neovim | Emacs | Lettres avant | Lettres après |
|---|---|---|---|---|---|---|---|
| `messag` | `src/lib/messages.ml` | 2 | 1 | 1 | 1 | – | 5 |
| `parser.ml` | `src/lib/parser.ml` | 1 | 1 | 1 | 1 | 6 | 4 |
| `lexer` | `src/lib/lexer.ml` | 1 | 1 | 1 | 1 | 4 | 2 |
| `natives` | `src/std/natives.ce` | 4 | 1 | 1 | 1 | – | 7 |
| `infer.ml` | `src/lib/infer.ml` | 1 | 1 | 1 | 1 | 3 | 3 |
| `fibers.md` | `docs/book/fibers.md` | 1 | 1 | 1 | 1 | 8 | 8 |
| `bench.sh` | `tools/bench.sh` | 2 | 1 | 1 | 1 | – | 6 |
| `release.yml` | `.github/workflows/release.yml` | 1 | 1 | 1 | 1 | 4 | 9 |
| `CHANGE` | `CHANGELOG.md` | 1 | 1 | 1 | 1 | 2 | 2 |
| `site.ce` | `src/tools/site.ce` | 1 | 1 | 1 | 1 | 7 | 2 |
| `msgml` | `src/lib/messages.ml` | 1 | 1 | 1 | 1 | 5 | 5 |
| `prsml` | `src/lib/parser.ml` | 1 | 5 | 5 | 1 | 5 | – |
| `cmpml` | `src/lib/compile.ml` | 3 | 1 | 1 | 1 | – | 3 |
| `rntm` | `src/lib/runtime.ml` | 5 | 1 | 1 | 1 | – | 3 |
| `typmli` | `src/lib/types.mli` | 1 | 1 | 1 | 1 | 5 | 4 |
| `jitml` | `src/jit/jit.ml` | 5 | 3 | 3 | 1 | – | – |
| `fbrsmd` | `docs/book/fibers.md` | 1 | 1 | 1 | 1 | 5 | 6 |
| `prmsmd` | `docs/book/permissions.md` | 1 | 4 | 4 | 3 | 3 | – |
| `mirgenx86` | `src/sys/mir/mir-gen-x86_64.c` | 1 | 1 | 1 | 1 | 8 | 7 |
| `wrkrs` | `src/sys/workers.ml` | 2 | 2 | 2 | 1 | – | 3 |
| `liblists` | `src/lib/lists.ml` | 1 | 1 | 1 | 1 | 6 | 5 |
| `stdlist` | `src/std/list.ce` | 1 | 1 | 1 | 1 | 5 | 4 |
| `bookindex` | `docs/book/index.md` | 1 | 1 | 1 | 1 | 8 | 5 |
| `jitengine` | `src/jit/engine.ml` | 1 | 1 | 1 | 1 | 5 | 4 |
| `sysnet` | `src/sys/net.ml` | 1 | 1 | 1 | 1 | 6 | 4 |
| `toolstest` | `tools/test.sh` | 4 | 1 | 1 | 1 | – | 2 |
| `nvimlsp` | `tools/editors/nvim/lsp/cesia.lua` | 1 | 1 | 1 | 1 | 6 | 2 |
| `benchfibgo` | `bench/fib.go` | 1 | 1 | 1 | 1 | 9 | 9 |
| `ml messages` | `src/lib/messages.ml` | – | 1 | 1 | – | – | 5 |
| `toml lib` | `src/lib/toml.ml` | – | 1 | 1 | – | – | 3 |
| `go maps` | `bench/maps.go` | – | 1 | 1 | – | – | 4 |
| `py fib` | `bench/fib.py` | – | 1 | 1 | – | – | 4 |
| `md speed` | `docs/book/speed.md` | – | 1 | 1 | – | – | 5 |
| `ce http` | `src/std/http.ce` | – | 2 | 2 | – | – | – |
| `vim syntax` | `tools/editors/nvim/syntax/cesia.vim` | – | 1 | 1 | – | – | 5 |
| `mgx` | `src/sys/mir/mir-gen-x86_64.c` | 2 | 1 | 1 | 4 | – | 3 |
| `rlt` | `tools/reload-test.sh` | 207 | 24 | 24 | 38 | – | – |
| `htgt` | `tools/http-gate.sh` | 15 | 1 | 1 | 1 | – | 3 |
| `cmel` | `tools/editors/cesia-mode.el` | 48 | 1 | 1 | 18 | – | 4 |
| `ffic` | `src/sys/ffi.c` | 1 | 1 | 1 | 1 | 2 | 2 |
| `private-field.ce` | `tests/errors/private-field.ce` | 7 | 1 | 1 | 1 | – | 5 |

Par sorte : le mean reciprocal rank, puis entre parenthèses combien en premier et combien dans les cinq premières. La
colonne « Mots séparés » est le changement sans son classement : des mots dans n'importe quel ordre, les rangées gardées
dans leur ordre.

| Sorte | Requêtes | Avant | Mots séparés | Après | Vim 9.2, Neovim 0.12.6 | Emacs 31.1, `flex` |
|---|---|---|---|---|---|---|
| le début d'un nom | 10 | 0,825 (7 ; 10) | 0,825 (7 ; 10) | 1,000 (10 ; 10) | 1,000 (10 ; 10) | 1,000 (10 ; 10) |
| des lettres avec des trous | 10 | 0,723 (6 ; 10) | 0,723 (6 ; 10) | 0,728 (6 ; 10) | 0,728 (6 ; 10) | 0,933 (9 ; 10) |
| un dossier et un nom | 8 | 0,906 (7 ; 8) | 0,906 (7 ; 8) | 1,000 (8 ; 8) | 1,000 (8 ; 8) | 1,000 (8 ; 8) |
| des mots dans n'importe quel ordre | 7 | 0,000 (0 ; 0) | 0,905 (6 ; 7) | 0,929 (6 ; 7) | 0,929 (6 ; 7) | 0,000 (0 ; 0) |
| des initiales | 5 | 0,318 (1 ; 2) | 0,318 (1 ; 2) | 0,808 (4 ; 4) | 0,808 (4 ; 4) | 0,466 (2 ; 3) |
| un test | 1 | 0,143 (0 ; 0) | 0,143 (0 ; 0) | 1,000 (1 ; 1) | 1,000 (1 ; 1) | 1,000 (1 ; 1) |
| **toutes** | **41** | **0,597 (21 ; 30)** | **0,751 (27 ; 37)** | **0,898 (35 ; 40)** | **0,898 (35 ; 40)** | **0,748 (30 ; 32)** |

La propriété 2 tient donc sur ces requêtes : le fichier est premier pour 35 sur 41, plus de trois sur quatre, et dans les
cinq premières rangées pour 40 sur 41, plus de neuf sur dix. Le mean reciprocal rank passe de 0,597 à 0,898 : les mots
séparés le portent à 0,751, et le classement fait le reste. Le fichier est venu en premier dans les lettres de sa requête
pour 36 requêtes, contre 21 avant ; sur les 19 requêtes qui le mettaient en premier dans les deux versions, il a fallu
87 lettres en tout après le changement contre 104 avant, une médiane de 4 lettres contre 5.

**À côté des géants.** Vim 9.2 et Neovim 0.12.6 mettent chaque fichier au même rang que Cemacs, sur les 41 requêtes : le
même score, écrit trois fois, donne le même ordre. C'est un *differential test* (un test différentiel : un programme vérifié
contre un autre qui résout le même problème), et il attrape ce qu'aucun des deux tests n'attraperait seul. Le `flex`
d'Emacs gagne sur les lettres avec des trous, 0,933 contre 0,728 : son coût croît avec les lettres du nom que la requête
n'emploie pas, si bien qu'un nom court comme `src/lib/parser.ml` bat un long nom sous `tests/project/` dont les dossiers
contiennent les lettres. Il perd sur les initiales, 0,466, car une lettre au début d'un mot ne lui rapporte rien de plus ;
et il ne trouve rien pour les mots dans n'importe quel ordre, car son espace est une lettre. Sur les 41, il marque 0,748 ;
sur les 34 requêtes d'un seul mot, il marque 0,902, et Cemacs 0,892.

### La vitesse : chaque lettre répond tout de suite

**Comment c'est mesuré.** Les 41 requêtes tapées une lettre à la fois, 288 lettres, chacune depuis un filtre vide, dans une
liste des 1 933 fichiers : chaque lettre est l'événement de touche et l'événement de texte que la fenêtre envoie, à travers
[commands.Update], jusqu'au nouvel état, la liste filtrée, classée, et le curseur suivi. Trois versions ont tourné chacune à
son tour, chacune dans un processus à elle, quatre tours de cinq manches, 20 manches chacune : le code d'avant le
changement, à 3d6d8dc ; le code d'après avec les rangées gardées dans leur ordre, `ranked = false`, mots séparés ; et le
code d'après, classé. Puis la même chose avec la frame : après chaque lettre, [view.View] et [sdl.Frame] dessinent la liste
dans une fenêtre de 1920 sur 1080, par le dummy driver de SDL, comme dans [Vitesse](performance.md#comment-c-est-mesuré).
Tout cela seul sur la machine, sous le lock que partagent ses tâches lourdes. Chaque temps est la médiane de 20, avec son
intervalle à 95 %, du 6e au 15e temps triés.

| Lettres tapées dans une liste de 1 933 fichiers | Avant | Après, rangées gardées | Après, classé |
|---|---|---|---|
| les 288 lettres, une manche | 402 ms [393 ; 421] | 210 ms [208 ; 213] | 645 ms [637 ; 668] |
| la lettre médiane | 0,64 ms | 0,31 ms | 0,94 ms |
| la lettre la plus lente | 8,43 ms [7,41 ; 8,73], `cm` | 3,62 ms [1,96 ; 3,81], `c` | 15,3 ms [13,6 ; 15,8], `st` |
| `s`, la première lettre de `sysnet`, qui garde 1 897 rangées | 1,44 ms [1,37 ; 1,54] | 2,06 ms [1,97 ; 2,31] | 9,30 ms [8,97 ; 9,48] |
| `st`, sa deuxième, qui en garde 1 725 | 6,90 ms [6,80 ; 7,09] | 2,31 ms [2,22 ; 2,42] | 15,3 ms [13,6 ; 15,8] |
| avec la frame : les 288 lettres | 2 900 ms [2 887 ; 2 926] | 2 897 ms [2 883 ; 2 916] | 3 121 ms [3 116 ; 3 167] |
| avec la frame : la lettre médiane | 10,1 ms | 10,9 ms | 8,2 ms |
| avec la frame : la lettre la plus lente | 18,0 ms [17,1 ; 18,5], `cm` | 13,9 ms [13,7 ; 14,1], `pr` | 26,2 ms [25,9 ; 26,7], `st` |
| avec la frame : les lettres au-dessus de 16 ms | 16 sur 288 | 0 sur 288 | 66 sur 288 |

Chercher chaque lettre en code natif a rendu le filtre deux fois plus rapide : 210 ms contre 402 pour les 288 lettres.
Classer coûte trois fois cela, 645 ms, et tout se joue sur les premières lettres, où presque chaque fichier correspond et
où chacun doit recevoir un score : `s` garde 1 897 rangées, `st` 1 725. Dès la quatrième lettre, il reste quelques dizaines
de rangées, et une lettre coûte moins d'une milliseconde. Avec sa frame, une lettre coûte environ 10 ms en médiane quelle
que soit la version : dessiner la frame en est l'essentiel, et son coût dépend des rangées à l'écran, qui diffèrent une fois
classées.

La propriété 3 tient donc : la lettre la plus lente, dessinée, répond en 26 ms, sous les 100 ms de Miller et de Card,
Robertson et Mackinlay. L'objectif propre de Cemacs, une frame, 16 ms, ne tient pas pour une liste classée : 66 des 288
lettres le manquent, toutes parmi les deux ou trois premières lettres d'une requête, quand la plupart des fichiers sont
encore gardés et doivent recevoir un score. Avant le changement, 16 lettres le manquaient aussi, pour le filtre seul, lent
sur les deuxièmes lettres ; avec les rangées gardées et cherchées en code natif, aucune ne le manque.

**À côté des géants.** Les mêmes 288 préfixes, chacun classé parmi les 1 933 fichiers, par une fonction qu'a chaque
éditeur ; un processus chacun, 20 manches. Cemacs est chronométré ici de la même façon, avec [lists.Ranked] à partir de
toutes les rangées, pas à travers son éditeur :

| Chaque préfixe classé parmi les 1 933 fichiers | Les 288 | La médiane | Le plus lent |
|---|---|---|---|
| Cemacs, [lists.Ranked] | 1 544 ms [1 537 ; 1 554] | 4,84 ms | 13,5 ms [13,3 ; 13,8], `std` |
| Vim 9.2, `matchfuzzy()` | 180 ms [179 ; 181] | 0,50 ms | 1,65 ms [1,64 ; 1,67], `ce h` |
| Neovim 0.12.6, `matchfuzzy()` | 136 ms [135 ; 137] | 0,35 ms | 1,30 ms [1,30 ; 1,34], `ce h` |
| Emacs 31.1, `flex`, puis trié par son coût | 617 ms [604 ; 622] | 0,47 ms | 17,0 ms [16,9 ; 17,1], `st` |

Vim et Neovim classent avec le même score, en C, 8,6 et 11 fois plus vite que Cemacs en Cesia, et leur lettre la plus lente
prend moins de 2 ms. Le `flex` d'Emacs, son coût en C et son tri en Lisp, est 2,5 fois plus rapide que Cemacs en tout, mais
sa lettre la plus lente, 17,0 ms, est plus lente. L'éditeur de Cemacs a pris 645 ms pour les mêmes lettres, pas 1 544,
parce qu'il ne classe que les rangées que les lettres d'avant ont gardées, là où ceux-ci classent les 1 933 fichiers pour
chaque préfixe. C'est là que les géants gagnent, et nettement : le score est le même, et le C le fait tourner plus vite que
Cesia.

**L'ouverture de la liste.** `C-x p f` sur le dépôt de Cesia, les deux exécutions de Git et la liste de 1 933 rangées,
20 fois : 7,30 ms [6,85 ; 8,10]. Le `project-files` d'Emacs, le même `git ls-files` avec sa propre lecture de la sortie,
20 fois dans un seul processus : 5,80 ms [5,62 ; 6,10].

**La frappe dans un buffer** ne change pas : `bench/gate.ce`, trois exécutions de chaque version chacune à son tour, donne
un caractère tapé à la ligne 19 000 en 11,4, 11,4 et 11,4 ms avant, et 11,4, 11,4 et 11,4 ms après ; une ligne défilée en
18,0, 17,9 et 18,0 ms avant, et 18,1, 17,7 et 17,7 ms après.

### Les threats to validity

Une threat to validity (une menace pour la validité) est une raison pour laquelle la preuve pourrait être fausse alors même
que chaque nombre ci-dessus est vrai. Mytkowicz, Diwan, Hauswirth et Sweeney (2009) ont montré comment un changement aussi
innocent que la taille de l'environnement d'un programme déplace ses temps de plus que les effets mesurés. Chaque menace
ici, et ce qui a été fait :

- **Les requêtes ont été écrites par l'auteur du changement.** On pourrait choisir des requêtes que le nouveau classement
  favorise. Elles ont été écrites et enregistrées avant qu'existe une seule ligne du classement, et elles sont toutes ici,
  les échecs avec le reste. Les points du classement sont ceux de fzy, pris tels que publiés, et aucun n'a été ajusté sur ces
  requêtes ; Vim et Neovim, que personne ici n'a écrits, les classent de la même façon.
- **Un seul projet.** Les chemins de Cesia sont courts, en anglais, en ASCII, avec beaucoup de tests. Un projet aux dossiers
  Java profonds, ou aux noms dans une autre écriture, pourrait se classer autrement. Les tests prennent des noms avec `é`,
  mais la qualité a été mesurée sur un seul arbre.
- **Le fichier voulu est un jugement.** Pour `ce http`, `bench/http.ce` et `src/std/http.ce` sont deux réponses honnêtes ;
  la table ne compte que la seconde.
- **L'ordre d'avant.** La baseline est l'ordre de Git, qui trie les chemins. Tout autre ordre, par date ou au hasard,
  donnerait une autre baseline ; le classement d'après ne dépend pas de l'ordre, sauf pour les ex aequo.
- **Les temps.** Les tâches lourdes de la machine attendaient sur le lock pendant que ces mesures tournaient, mais un travail
  plus léger pouvait tourner à côté : la charge était de 2,9 sur 8 threads quand elles ont commencé. Les versions ont tourné
  chacune à son tour, dans les mêmes conditions, si bien qu'un tel bruit tombe sur toutes, et les intervalles restent
  étroits. Chaque version a tourné dans un processus à elle, lancé de la même façon, pour qu'une différence d'environnement,
  du genre que Mytkowicz et ses collègues ont mesuré, tombe sur toutes de la même façon ; et le JIT de Cesia (la partie qui
  compile une fonction en code machine une fois qu'elle tourne souvent) est à l'intérieur des 20 manches, pas avant elles.
  Le dummy driver de SDL dessine en mémoire : un vrai écran ajoute le travail de son driver et du compositor, le même pour
  chaque version. Une seule machine : un Intel Core i7-4720HQ, comme dans [Vitesse](performance.md#comment-c-est-mesuré).

## 7. Ce qui reste

- **Les lettres des dossiers comptent autant que les lettres du nom.** `rlt` met `tools/reload-test.sh` 24e, derrière
  `bench/RESULTS.md` et `src/std/result.ce` : dans `result`, le `l` et le `t` sont côte à côte, ce qui rapporte 1000, plus
  que les 800 du `t` au début de `test`. `prsml` et `prmsmd` perdent face à des fichiers sous `tests/project/` et
  `tests/programs/`, dont les noms de dossiers contiennent les lettres. Le `--scheme=path` de fzf classe une correspondance
  dans le nom propre du fichier au-dessus d'une correspondance dans ses dossiers, d'après son manuel, et le coût d'Emacs
  favorise les noms courts, ce qui lui fait gagner les lettres avec des trous. L'un ou l'autre pourrait aider ici ; il
  faudrait des requêtes qui n'ont pas servi à le choisir, ou il ne ferait que coller à celles-ci.
- **Les premières lettres manquent une frame.** Classer 1 900 rangées en Cesia prend jusqu'à 15 ms, et avec la frame 26 ms :
  sous le 0,1 seconde d'une réponse qui paraît immédiate, au-dessus des 16 ms d'une frame. Le score de Vim, en C, classe les
  mêmes rangées en moins de 2 ms. Un score écrit en code natif dans la bibliothèque standard de Cesia, comme l'est
  [text.ByteFind], comblerait l'essentiel de cet écart ; c'est un changement de Cesia, pas de Cemacs.
- **Seulement Git.** Un dossier qui n'est dans aucun dépôt Git n'a pas de liste de projet : la prompt line le dit. Emacs, par
  `project.el`, demande alors le projet à employer, par son `project-prompter`.
- **La liste est lue une fois.** Un fichier créé après `C-x p f` n'est pas dans la liste avant qu'elle s'ouvre à nouveau.
- **Les autres listes gardent leur ordre.** Les buffers, le gestionnaire de dossiers et les touches pourraient aussi être
  classés. La sortie d'un programme ne doit pas l'être : son ordre est son sens.
- **Une lettre mal tapée** ne trouve rien, comme dans chaque éditeur ici.
