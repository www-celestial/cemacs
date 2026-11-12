# Cemacs

Cemacs est un éditeur de texte pour Cesia, écrit en Cesia. Il a les touches d'Emacs et les couleurs du code de Cesia. Une
bande montre à quoi une touche peut mener : vous n'avez donc pas besoin d'apprendre les touches avant de commencer. Les
erreurs s'affichent dans les lignes pendant que vous tapez, et un programme tourne dans la fenêtre, où il s'arrête à ses
breakpoints. Vous modifiez Cemacs en Cesia, et il se recharge pendant qu'il tourne.

```cesia
use src/emacs
use std/dict
use std/value
value.Len(dict.Keys(emacs.Keys())) -->
```

Ce nombre est celui des touches que contient aujourd'hui la table des touches d'Emacs dans `src/emacs/emacs.ce`, compté au
moment où cette page a été construite : les touches de Cemacs sont une valeur de son propre code, que tout programme Cesia
peut lire.

## Comment le lire

- Lisez d'abord [Premiers pas](first-steps.md) : en dix minutes, ce chapitre vous mène de rien jusqu'à modifier, exécuter et
  déboguer un fichier Cesia. Les chapitres suivants couvrent chacun une partie en entier, et se lisent dans n'importe quel
  ordre.
- Chaque mot du domaine est expliqué là où un chapitre l'emploie pour la première fois, et de nouveau dans le
  [Glossaire](glossary.md). Les mots techniques restent en anglais, comme Cemacs et Emacs les écrivent. Cemacs emploie les
  mots d'Emacs là où ils sont vrais pour lui, et le dit là où son propre nom diffère.
- Un nom dans le texte mène à sa page dans la référence : [commands.Save], par exemple, la commande qui enregistre.
- Chaque exemple de code Cesia de ces pages a tourné quand le site a été construit, et le texte en dessous est ce qu'il a
  affiché ; une ligne avec `-->` et une valeur est vérifiée, et un résultat différent arrête la construction. Les pages ne
  peuvent donc pas s'écarter du code.

## Comment les touches sont écrites

| Écrit | Signifie |
|---|---|
| `C-x` | maintenir Control et appuyer sur `x` |
| `M-x` | maintenir Alt et appuyer sur `x` (M veut dire Meta, l'ancien nom de cette touche) |
| `S-right` | maintenir Shift et appuyer sur la flèche droite |
| `C-x C-s` | `C-x`, puis `C-s` : une key sequence de deux touches |
| `C-c f f` | `C-c`, puis `f`, puis `f`, sans Control sur les deux dernières |
| `enter`, `tab`, `backspace`, `delete`, `home`, `end`, `pageup`, `pagedown`, `space` | les touches de ces noms |

## Sommaire

1. [Installation](install.md) : Cesia, SDL3 et SDL3_ttf, le code, et la commande `bin/cemacs`.
2. [Premiers pas](first-steps.md) : une visite, de l'ouverture d'un fichier jusqu'à son exécution, son débogage et la
   modification de Cemacs.
3. [Édition](editing.md) : le curseur, la mark et la sélection, les déplacements, la frappe, l'indentation du code Cesia,
   la completion, couper et coller, annuler, la souris.
4. [Fichiers et buffers](files.md) : ouvrir, enregistrer sans risque, quels fichiers s'ouvrent, les fins de ligne, la liste
   des buffers, le gestionnaire de dossiers.
5. [Fenêtre et panes](windows.md) : la fenêtre, ses panes, la mode line, la prompt line et la bande des hints.
6. [Recherche](search.md) : l'incremental search dans un buffer, `C-s` et `C-r`, et ce que Cemacs trouve d'autre : des
   rangées de listes, des touches, des erreurs, des endroits.
7. [Touches](keys.md) : chaque touche, générée à partir du code, et comment une touche devient une commande.
8. [Exécuter et déboguer](running.md) : exécuter un fichier avec ses permissions, sa sortie, les breakpoints, le pas à pas,
   fix and continue.
9. [Les erreurs dans les lignes](check.md) : ce que montre la vérification, quand elle tourne, et comment aller d'une erreur
   à la suivante.
10. [Modifier Cemacs](customising.md) : votre dossier `user/`, les réglages, vos propres touches et commandes, une app à
    vous, et le rechargement pendant qu'il tourne.
11. [Recettes](recipes.md) : de petites tâches faites dans `user/`, chacune avec son code, sa touche et ce qu'elle montre :
    vos réglages, des fichiers au démarrage, un nouveau buffer, un groupe de touches, une question, une liste, un hook,
    une app.
12. [À l'intérieur de Cemacs](internals.md) : l'état et sa mise à jour, la rope, l'historique, les couleurs,
    l'indentation, la frame, la boucle des événements, l'enregistrement.
13. [Vitesse](performance.md) : ce qui a été mesuré, comment, et les chiffres.
14. [Cemacs et les autres éditeurs](comparison.md) : à côté de GNU Emacs, Neovim, Vim et VS Code, en chiffres et en
    fonctions.
15. [Un cas : trouver un fichier à partir de quelques lettres](finding.md) : un vrai problème, de son énoncé jusqu'à la
    preuve qu'il est résolu, par les méthodes de la recherche scientifique : une base de comparaison, une hypothèse, les
    articles, le plus petit changement, des tests et des mesures.
16. [Dépannage](troubleshooting.md) : chaque message de Cemacs, ce qu'il veut dire et que faire.
17. [Glossaire](glossary.md) : les mots des éditeurs, tels que Cemacs les emploie.
18. [Références](references.md) : les travaux et les normes que suit Cemacs.

La référence, sous [Reference](ref/index.html), liste chaque package de Cemacs et chaque nom public, à partir de son code.

Cesia a un livre à elle, qui enseigne le langage : https://www-celestial.github.io/cesia-lang/.
