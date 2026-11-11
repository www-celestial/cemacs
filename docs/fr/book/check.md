# Les erreurs dans les lignes

Cemacs vérifie chaque fichier Cesia pendant que vous l'écrivez, sans l'exécuter, et montre les erreurs dans les lignes : ce
que fait Flymake dans Emacs, la vérification du code à la volée. Ce chapitre dit ce qu'elle montre, quand elle tourne, et
comment elle suit vos modifications. La vérification est une app de Cemacs, [src/check] : le core (le cœur de l'éditeur, le
dossier `core/`) n'en sait rien.

## Ce qu'elle montre

Chaque erreur ou warning est une marque sur un span d'une ligne (une plage de caractères), les caractères dont elle parle :

- un trait de deux pixels sous le span, rouge pour une erreur, ambre pour un warning ; un span prend au moins un caractère ;
- le numéro de la ligne dans la même couleur ;
- les mots de la première marque de la ligne, les erreurs d'abord, deux caractères après le bout de la ligne, dans un ton
  plus discret de la même couleur, avec `(+2)` quand la ligne en a deux de plus ; ils sont coupés au bord du pane, et
  laissés de côté quand moins de quatre colonnes sont libres ;
- le nombre des marques du buffer dans sa mode line, comme `2 errors, 1 warning`, en rouge quand il y a une erreur ;
- sur la prompt line, quand rien d'autre n'y est dit : la marque sous le curseur, du début de son span jusqu'à juste après
  lui, ou à défaut la première marque de la ligne du curseur, avec son hint, les mots qui disent comment la corriger.

Les mots au bout de la ligne sont dessinés, pas tapés : ils ne sont pas dans le texte, et le curseur n'y entre jamais.

## Ce qui tourne

La vérification est `cesia check`, la commande de Cesia qui lit du code et dit ce qui ne va pas sans rien en exécuter : la
syntaxe, les noms qui n'existent pas, les arguments d'une fonction connue, les valeurs qui ne vont sûrement pas avec un type,
et les résultats dont l'`Err` passerait inaperçu. Le livre de Cesia décrit chaque sorte. Cemacs la lance ainsi :

```bash
cesia check --json --stdin PATH
```

`--stdin` lui donne le texte du buffer sur son entrée : elle vérifie donc le texte tel que vous le voyez, enregistré ou non,
avec les autres fichiers de son package tels qu'ils sont sur le disque ; `--json` lui fait écrire un objet JSON par ligne,
que lit [check.Marks]. Cesia compte les colonnes à partir de 1, Cemacs à partir de 0, et Cemacs ne garde que les marques du
fichier du buffer lui-même :

```cesia
use src/check
check.Marks("{\"file\": \"a.ce\", \"line\": 2, \"column\": 3, \"end\": 7, \"severity\": \"error\", \"message\": \"m\", \"hint\": null}", "a.ce") --> [{Line: 2, Column: 2, End: 6, Severity: "error", Message: "m", Hint: missing}]
```

`cesia check` est la même vérification que celle que `cesia lsp`, le language server de Cesia (le serveur qui donne aux
éditeurs les erreurs et les noms d'un langage), donne aux autres éditeurs. Cemacs lance la commande, pas le serveur : un
processus pour chaque vérification, qui lit les fichiers dont il a besoin et se termine.

## Quand elle tourne

Un buffer est à vérifier quand le nom de son fichier finit par `.ce` et que son texte a changé depuis sa dernière
vérification :

```cesia
use core/text
check.IsDue(text.Of("", "a.ce")) --> true
check.IsDue(text.Of("", "notes.md")) --> false
```

Une fois qu'aucune touche, aucun texte et aucun clic n'est arrivé pendant [emacs.CheckDelay] secondes, une demi-seconde,
Cemacs vérifie le buffer courant s'il est à vérifier, ou à défaut le premier buffer qui l'est. La frappe ne lance donc jamais
une vérification : c'est une pause qui la lance.

- Une seule vérification tourne à la fois, dans un processus lancé depuis une fiber, une tâche de Cesia qui attend à côté de
  l'éditeur sans le retenir, si bien que l'éditeur ne l'attend jamais : vous continuez de taper pendant qu'elle tourne, et
  son résultat arrive à un tour suivant de la boucle.
- Un résultat pour un texte qui a changé pendant qu'elle tournait est jeté, et la pause suivante redemande.
- Après un enregistrement, chaque buffer Cesia est de nouveau à vérifier, puisqu'un autre fichier peut employer celui qu'on
  vient d'enregistrer.
- Une vérification qui ne peut pas tourner, parce que `cesia` n'est pas dans le `PATH` par exemple, dit une fois
  `cesia check can't run: REASON` (cesia check ne peut pas tourner : la raison), et le buffer compte comme vérifié : il
  n'est donc pas redemandé avant de changer.
- Un buffer de plus de [check.CheckLimit] octets, 1 000 000, n'est pas vérifié : il compte comme vérifié, sans marque, et sa
  mode line dit `not checked: over 1 MB` (pas vérifié : plus de 1 MB) là où serait le nombre de marques. `cesia check` d'un
  fichier de 15,9 MB a grandi jusqu'à 320 MB et a occupé un cœur du processeur pendant plus de 12 s, pour des marques que
  personne ne lit dans un fichier de cette taille, souvent un fichier généré ; l'éditeur reste aussi léger au repos avec un
  tel fichier que les autres éditeurs, qui ne vérifient rien si on ne le leur demande pas. Les mots viennent avec les
  marques, [text.WithMarks] avec une `note`, et une modification qui ramène le buffer sous la limite le fait vérifier à
  nouveau à la pause suivante.

Pendant qu'une vérification tourne ou qu'un buffer est à vérifier, Cemacs compte le temps avec des ticks, des événements
qu'il fait lui-même à chaque tour de sa boucle, et dessine une frame à chacun ; un éditeur immobile sans rien à vérifier ne
dessine rien. Voir [À l'intérieur de Cemacs](internals.md#la-boucle-des-événements).

## Comment les marques suivent vos modifications

Une vérification prend un moment, et le texte change pendant ce temps. Une modification enlève les marques des lignes
qu'elle change, pour qu'une correction que vous êtes en train de taper perde sa marque tout de suite, et elle déplace les
marques en dessous avec leurs lignes ; annuler et rétablir font de même. Les marques des autres lignes restent jusqu'à ce que
la vérification suivante donne les nouvelles.

```cesia
use core/press
use core/view
use src/emacs
use src/ui
use std/value
mark = {Line: 3, Column: 0, End: 1, Severity: "error", Message: "m", Hint: missing}
b = text.WithMarks([mark], text.Of("a\nb\nc", "a.ce"))
s = view.Start([b], ui.Look(ui.Dark, (w, f) -> 8 * value.Len(w), 19), {Width: 8, Height: 19}, 800, 600)
s.Config = () -> emacs.Config(emacs.Keys)
[m.Line for m in text.MarksOf(press.Press(["enter"], s).Buffers[1])] --> [4]
[m.Line for m in text.MarksOf(press.Press(["C-n", "C-n", "x"], s).Buffers[1])] --> []
```

Enter sur la ligne 1 déplace la marque de la ligne 3 à la ligne 4 ; taper sur la ligne 3 l'enlève.

## Aller d'une erreur à la suivante

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `M-g n`, `C-c c n` | [check.NextError] | le curseur au début de la marque suivante, et ses mots sur la prompt line |
| `M-g p`, `C-c c p` | [check.PreviousError] | le curseur au début de la marque d'avant |

Les deux font le tour par les bouts du buffer, et un buffer sans marque dit `No error here.` `M-g n` et `M-g p` sont les
touches du `next-error` et du `previous-error` d'Emacs ; `M-g` seul est un groupe, `errors` (erreurs) : la bande des hints
les montre donc.

## Les hooks de la vérification

La vérification a besoin d'apprendre que le temps passe et que des enregistrements ont lieu, ce que seul le core voit. Elle
les demande par trois hooks (des fonctions que le core appelle à des moments donnés), que [check.Hooked] ajoute à la config
de l'éditeur : `Idle(state)` à chaque tick, `Saved(state)` après chaque enregistrement, et `Moving(state)`, qui dit si elle a
besoin de ticks. [Modifier Cemacs](customising.md#les-hooks) dit comment une app à vous peut les employer.
