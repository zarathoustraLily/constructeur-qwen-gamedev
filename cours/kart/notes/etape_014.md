# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Dernière étape : le jeu complet. Un chef d'orchestre, l'autoload `GameFlow`, charge
maintenant les scènes du jeu ; la scène principale devient une étape de son déroulé. F1 ou Start ouvrent le
menu des contrôles, qui met le jeu en pause et permet de changer chaque touche, clavier comme manette.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (Forward+).
2. F5 : le jeu démarre par `2_sequence/boot.tscn`, qui remet la séquence à GameFlow ; GameFlow charge l'île.
3. F1 (ou Start) : le menu des contrôles ; cliquer une action, puis appuyer sur la nouvelle touche ou le
   nouveau bouton. Échap annule une capture, ferme le menu, ou, menu fermé, quitte le jeu.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. L'autoload charge les scènes

`0_autoload/game_flow.gd` (le singleton GameFlow) est le seul à charger des scènes. Il garde la séquence du jeu
(`2_sequence/sequence.tres`, une liste de scènes) et charge ses étapes dans l'ordre. Charger une étape, c'est
l'instancier, retirer de l'arbre la scène courante, poser la nouvelle et écouter son signal `finished`. Selon
la suite reçue, il charge l'étape suivante (`done`), la même (`retry`) ou la première (`restart`) ; après la
dernière, il revient à la première. `quit()` quitte le jeu.

Le contrat d'une étape est `1_core/step/step.gd` (`Step`) : une étape ne charge jamais une autre scène, elle
appelle `finish()`. La scène principale (`main.gd`) en hérite désormais : c'est la première, et pour l'instant
la seule, étape du déroulé. Un menu titre ou une cinématique s'ajouteraient dans `sequence.tres`, sans toucher
au reste.

### 2. Qui donne la séquence au chef d'orchestre

Un autoload ne connaît que 1_core (règle des dossiers) : GameFlow ne peut pas précharger `sequence.tres`, qui
vit dans 2_sequence. Le kart d'origine le faisait ; le juge des règles l'a refusé. La scène de démarrage,
`2_sequence/boot.tscn` (la scène principale du projet), porte la séquence et la remet à GameFlow
(`GameFlow.start`). Elle ne charge rien elle-même : c'est GameFlow qui charge la première étape, en remplaçant
la scène de démarrage. C'est le schéma du socle (`godot/socle_jeu/2_sequence/boot.gd`).

Au passage, une correction : une étape rejouée était posée avant que l'ancienne ne soit libérée, et Godot la
renommait (`@StepA@9`, vu dans les tests). L'ancienne scène quitte maintenant l'arbre d'abord.

### 3. La pause et le menu des contrôles

`4_ui/overlays/pause_handler.gd` reste actif pendant la pause (`PROCESS_MODE_ALWAYS`) et lit F1, Start, B et
Échap. `4_ui/overlays/input_remap/input_remap_menu.gd` (`InputRemapMenu`) liste les actions du jeu, leurs
touches et leurs boutons. Ouvert, il met le jeu en pause et libère la souris ; une capture attend la nouvelle
touche, le nouveau bouton ou le nouvel axe (au-delà de 0,6), puis le menu enregistre les commandes dans
`user://input_remap.cfg` et les recharge au lancement.

Ce sont des scripts d'interface : ils lisent les entrées, ce que la logique ne fait pas (règle ARC-04). Les
lignes du menu sont des objets typés (`Row`), et ses tables (libellés, noms des boutons et des touches), des
dictionnaires typés (règle COD-02). L'annulation d'une capture, appelée par le gestionnaire de pause, devient
publique (`cancel_binding()`).

## Les tests

- `0_autoload/test_game_flow.gd`, avec deux étapes minuscules (`step_a.tscn`, `step_b.tscn`) :
  - GameFlow charge la première étape, puis la suivante quand elle finit ;
  - après la dernière, il revient à la première ; `retry` recharge l'étape, `restart` la première ;
  - une séquence vide ne charge rien ;
  - la séquence du jeu commence par la scène principale, que la scène de démarrage remet.
- `1_core/step/test_step.gd` : finir l'étape le signale, avec la suite demandée.
- `4_ui/overlays/test_pause_handler.gd` : F1 et Start ouvrent et ferment le menu, B et Échap le ferment,
  une capture s'annule sans fermer le menu, le gestionnaire reste actif en pause.
- La vérification rend le jeu lancé par `boot.tscn` : GameFlow a bien chargé l'île.

## Ce qu'il faut retenir

- Un seul chargeur de scènes, l'autoload ; les étapes signalent, elles ne changent pas de scène.
- Ce que l'autoload ne peut pas connaître, on le lui remet au démarrage.
- L'interface lit les entrées et met en pause ; la logique ne lit que des commandes.

## À essayer

- Ajouter une deuxième étape à `sequence.tres` (une scène dont la racine porte `step.gd`), puis appeler
  `finish()` à la fin du niveau : GameFlow l'enchaîne.
- F1, puis réassigner « Sauter / Drift » à une autre touche : relancer le jeu, la touche est gardée.

## Source

- La pause, le menu des contrôles et le chef d'orchestre viennent du kart d'origine (GDWaterKart, JorisAR,
  licence MIT, avec les ajouts du kart rangé) ; le chef d'orchestre suit le socle de ce dépôt
  (`godot/socle_jeu/0_autoload/game_flow.gd`).
- Documentation de Godot 4.7, *Singletons (Autoload)* (`tutorials/scripting/singletons_autoload.rst`) et
  *Pausing games* (`tutorials/scripting/pausing_games.rst`).
- Références des classes (API de Godot 4.7.2) : `SceneTree.current_scene`, `Node.process_mode`, `InputMap`,
  `ConfigFile`.

## Fin du cours

Les quatorze étapes ont construit le kart entier : des commandes au remappage, en passant par l'île, l'eau,
la houle, les effets, la météo, les poissons et les objets.
