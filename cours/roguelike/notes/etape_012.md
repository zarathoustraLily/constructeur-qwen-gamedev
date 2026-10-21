# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Les niveaux s'enchaînent : un chef d'orchestre, l'autoload `GameFlow`, tire l'ordre des
trois niveaux, charge le premier, et à chaque sortie atteinte charge le suivant, avec un fondu au noir. Le
héros passe d'un niveau à l'autre en gardant ce qu'il a gagné. Vaincu, il recommence le niveau, au premier
rang.

Ce qu'on obtient : une partie. Trois niveaux dans un ordre tiré au sort, une vague plus nombreuse à chaque
niveau franchi.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : le jeu démarre par `2_sequence/boot.tscn`, qui remet la séquence à GameFlow ; l'image revient du noir
   sur le premier niveau de l'ordre.
3. Vaincre la vague, entrer dans la sortie : fondu au noir, niveau suivant.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un seul chargeur de scènes : l'autoload

`0_autoload/game_flow.gd` (singleton `GameFlow`, une scène autoload : `game_flow.tscn`, un `CanvasLayer` qui
porte le voile noir) est le **seul** à charger des scènes. Charger une étape, c'est l'instancier, retirer de
l'arbre la scène courante, poser la nouvelle et écouter son signal `finished`. Les niveaux ne chargent jamais
rien : ils finissent.

Le contrat d'une étape est `1_core/step/step.gd` (`Step`), le même que dans le cours du kart : une étape appelle
`finish()` (« done ») ou `finish(&"retry")`. Le modèle de niveau en hérite désormais.

### 2. Qui remet la séquence au chef d'orchestre

Un autoload ne connaît que `1_core` (règle des dossiers) : GameFlow ne peut pas précharger la séquence, qui vit
dans `2_sequence`. Le jeu d'origine le faisait ; ici, la scène de démarrage `2_sequence/boot.tscn` (la scène
principale du projet) porte la séquence et la remet à GameFlow (`GameFlow.start`, à la fin de l'image : la
scène de démarrage est encore en train d'entrer dans l'arbre). Elle ne charge rien elle-même.

### 3. L'ordre des niveaux, et le premier

`2_sequence/sequence.tres` (`Sequence`) liste les trois niveaux, avec `shuffle` et une graine. GameFlow tire
l'ordre (mélange de Fisher et Yates avec un `RandomNumberGenerator` à graine : même graine, même ordre), puis
charge **le premier niveau de cet ordre**.

Le jeu d'origine démarrait toujours sur `level_2`, sa scène principale, hors de l'ordre tiré : après la première
boutique, le niveau 2 pouvait revenir aussitôt. Le cours démarre sur le premier niveau tiré, comme laurent l'a
choisi.

### 4. Le fondu, et le héros gardé de côté

Chaque changement passe par un `Tween` : le voile (`Veil`) devient noir en `fade_time` (1 s), la scène change,
une pause (`pause_time`, 0,5 s), puis l'image revient. Pendant ce temps, le héros (le nœud du groupe « player »)
est figé (`PROCESS_MODE_DISABLED`) puis retiré de l'arbre : il survit à la libération du niveau quitté.
GameFlow ne connaît pas sa classe (un autoload ne connaît pas les acteurs) : pour lui, c'est un `Node3D`.

Le niveau suivant le reprend (`GameFlow.take_player()`) et le pose à la place du sien, au même endroit : le héros
garde sa santé, sa barre et, à l'étape suivante, ses améliorations. Sur un « retry », GameFlow ne garde pas le
héros : le niveau repart à neuf.

Le joueur du niveau, remplacé, est libéré tout de suite (`free()`) : hors de l'arbre, rien ne l'empêche, et un
`queue_free()` l'aurait laissé orphelin jusqu'à la fin de l'image ; GdUnit, qui compte les nœuds orphelins à la
fin de chaque test, l'a signalé.

### 5. Des connexions qui partent avec le niveau

Le niveau branche les dégâts du héros sur sa couche de chiffres. Avec une fonction anonyme, cette connexion
appartiendrait à la fonction ; avec une **méthode du niveau** (`_show_damage.bind(personnage)`), Godot la coupe
quand le niveau est libéré : le héros repris dans le niveau suivant ne parle plus à l'ancien.

### 6. L'état qui dure : GameState

`0_autoload/game_state.gd` (singleton `GameState`) garde le rang du niveau en cours. La sortie atteinte, le
niveau le monte (`finish_level()`) ; le héros vaincu le ramène à 1 (`reset()`). La vague en tire sa taille. Le
jeu d'origine y mettait aussi la courbe de difficulté et la liste des améliorations : la courbe est dans les
réglages de la vague (`5_data`), et un autoload ne peut pas connaître les améliorations de `2_sequence`.

## Les tests

- `0_autoload/test_game_flow.gd`, avec deux étapes minuscules (`step_a.tscn`, `step_b.tscn`) et des fondus
  raccourcis : premier niveau de l'ordre ; étape suivante après le fondu ; après la dernière, la première ;
  « retry » recharge ; le héros gardé est repris, mais pas sur un « retry » ; même graine, même ordre ; séquence
  vide ; la séquence du jeu et la scène de démarrage ;
- `0_autoload/test_game_state.gd` : le rang monte et revient à 1 ;
- `1_core/step/test_step.gd` : finir l'étape le signale, avec la suite demandée ;
- `2_sequence/levels/test_levels.gd` : chaque niveau est une étape ; la sortie atteinte, le rang monte et
  l'étape finit ; vaincu, le rang revient à 1 et le niveau demande à être rejoué ; la vague suit le rang ; le
  héros gardé remplace celui du niveau, avec son amélioration.

## Ce qu'il faut retenir

- Un seul chargeur de scènes, l'autoload ; les étapes signalent, elles ne changent pas de scène.
- Ce que l'autoload ne peut pas connaître, on le lui remet au démarrage.
- Un ordre tiré au hasard passe par une graine.
- Garder un nœud d'une scène à l'autre : le retirer de l'arbre avant que sa scène ne parte.
- Une connexion à une méthode part avec son objet.

## À essayer

- Passer `shuffle` à faux dans `sequence.tres` : les niveaux viennent dans l'ordre de la liste.
- Changer `random_seed` : un autre ordre, toujours le même pour cette graine.
- Passer `fade_time` à 3 sur `game_flow.tscn` : des transitions de cinéma.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : GameFlow (fondus de 1 s, pause de 0,5 s, joueur gardé
  de côté), GameState (rang du niveau), ordre mélangé des niveaux ; le contrat d'étape et la scène de démarrage
  suivent le socle de ce dépôt (`godot/socle_jeu`) et le cours du kart.
- Documentation de Godot 4.7, *Singletons (Autoload)* (`tutorials/scripting/singletons_autoload.rst`) ;
  *Change scenes manually* (`tutorials/scripting/change_scenes_manually.rst`).
- Références des classes `SceneTree` (`current_scene`), `Tween`, `RandomNumberGenerator`, `Node`
  (`process_mode`, `remove_child`) : API de Godot 4.7.2.

## Étape suivante

Étape 013 : la boutique d'améliorations. Entre deux niveaux, deux améliorations au choix (santé, dégâts,
vitesse), sur un fond animé par un shader.
