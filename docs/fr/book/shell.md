# Le shell

`C-c o t` ouvre un buffer (un texte ouvert dans Cemacs) nommé `*shell*`, où vous tapez des commandes pour votre shell,
l'interpréteur de commandes, comme bash ou zsh, que nomme `$SHELL`, ou `/bin/sh` sans lui : chaque ligne tapée après le
prompt `$ ` (l'invite qui attend votre commande) tourne à Enter, et ce qu'écrit le shell, ses erreurs aussi, vient
au-dessus du prompt. C'est le `M-x shell` d'Emacs, pas un terminal emulator (un émulateur de terminal, le programme qui
imite l'écran d'un terminal) : le shell lit ses commandes dans un pipe (un tuyau par lequel un programme passe du texte à
un autre), si bien qu'un programme qui dessine un écran entier, comme `vim` ou `top`, ou qui attend un mot de passe tapé
sur un terminal, n'y a pas d'écran. Les couleurs qu'un programme écrit pour un terminal sont enlevées. Le shell est la
touche `t` du groupe `o`, open (ouvrir), de `C-c`, comme `SPC o t` dans Doom Emacs. Un second `C-c o t` revient au buffer.

| Touches | Commande | Ce qu'elle fait |
|---|---|---|
| `C-c o t` | [ide.Terminal] | ouvre le buffer du shell, le shell démarré dans le dossier du fichier courant, ou y va |
| Enter, dans le buffer du shell | [ide.Enter] | lance la commande de la dernière ligne |

Le shell garde son état d'une commande à la suivante : `cd ../shop` une fois, et les commandes suivantes tournent là. Ce
qu'il écrit s'affiche à mesure que cela vient, pendant qu'il écrit et trois secondes après ; ce qu'une commande écrit plus
tard, comme un serveur, s'affiche à la touche suivante. Le buffer est un buffer de texte : les déplacements, la recherche et
la copie y marchent, et ses lignes ne sont jamais enregistrées. Le fermer, `C-x k`, termine le shell ; il ne demande
d'abord que lorsqu'une commande est tapée et pas lancée.

## Sécurité

- Le shell ne tourne que lorsque vous appuyez sur `C-c o t`, et une commande que lorsque vous appuyez sur Enter dans son
  buffer : rien d'autre dans Cemacs ne lui envoie de ligne.
- Cemacs lui-même ne peut pas démarrer le shell : ses permissions ne nomment que `cesia` et `git`. `C-c o t` lance
  `cesia run --allow exec=SHELL tools/shell.ce SHELL FOLDER`, un programme dont la seule permission est de démarrer ce
  shell, et qui lui passe les commandes et rend ce qu'il écrit, en lignes de JSON, chacune un texte. Cemacs lit `$SHELL`
  pour lui, avec la permission `env=SHELL` ; une valeur qui n'est pas un chemin depuis la racine, ou qui contient une
  virgule, donne `/bin/sh`.
- Le shell a ensuite vos droits, comme dans n'importe quel terminal : ce que vous tapez tourne en votre nom. C'est son
  usage, et la raison pour laquelle il ne démarre que par une touche à vous.
- Fermer le buffer termine le relais, et le shell avec lui ; quand Cemacs se termine, l'entrée du shell se ferme, et il se
  termine aussi.
