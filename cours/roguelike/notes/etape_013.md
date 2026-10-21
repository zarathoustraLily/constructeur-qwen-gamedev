# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Entre deux niveaux, une boutique : deux améliorations au choix parmi trois (dégâts, santé,
vitesse), sur un fond animé par un shader. Le choix s'applique au héros gardé de côté, qui l'emporte dans le
niveau suivant.

Ce qu'on obtient : une partie qui progresse. Chaque niveau franchi rend le héros plus fort, et la vague plus
nombreuse.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5, vaincre la vague, entrer dans la sortie : fondu au noir, la boutique. La première carte est éclairée.
3. À la manette, la croix passe d'une carte à l'autre, A choisit ; à la souris, un clic. Fondu, niveau suivant.
4. Ouvrir `2_sequence/menus/upgrade_shop/upgrade_shop.tscn` seule (F6) : sans héros gardé, les cartes montrent
   le seul bonus (« +50.0 »).

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. L'intermède, dans la séquence

`Sequence` gagne un champ `interlude` : la scène jouée après chaque niveau, avant le suivant. `sequence.tres`
y met la boutique. GameFlow, quand un niveau finit, charge l'intermède ; quand l'intermède finit, le niveau
suivant de l'ordre. Un « retry » ne passe pas par la boutique. La boutique est une étape (`Step`) comme un
niveau : elle appelle `finish()`, elle ne charge rien.

### 2. Une amélioration, c'est une donnée

`1_core/upgrades/upgrade.gd` (`Upgrade`, une `Resource`) dit quelle propriété du héros elle augmente (`stat`), de
combien (`bonus`), et comment se présenter (`title`, `description_template`, avec deux `%f` : la valeur actuelle,
puis la valeur après). Elle lit et écrit la propriété par son nom : elle ne connaît pas la classe `Player`.

Trois fichiers dans `5_data/upgrades/` : `damage.tres` (+50 % de `damage_stat`), `speed.tres` (+1,5 m/s de
`movement_speed`), `health.tres`. La santé ne se range pas dans une propriété du héros : `HealthUpgrade` (hérite
d'`Upgrade`) passe par son `HealthComponent`, dont `raise_max_health()` monte le maximum et la santé actuelle
d'autant, puis prévient la barre de santé par `health_changed`.

Le jeu d'origine en faisait trois scènes de bouton qui portaient le calcul et écrivaient dans le joueur : ici, la
donnée (`1_core`, `5_data`), la carte qui la montre (`4_ui`) et la boutique qui l'applique (`2_sequence`) sont
séparées.

### 3. L'état du héros, pas ses réglages

La vitesse de course était lue dans `settings.movement_speed`, une ressource partagée : y écrire changerait la
vitesse de tout ce qui la partage, et pour la suite de la partie, même après une défaite (règle DAT-04). Le héros
a désormais un état `movement_speed`, copié de ses réglages à son entrée en jeu, comme `damage_stat` à l'étape 6 ;
les états course et chute le lisent. L'amélioration écrit dans cet état. Un test le vérifie : après
l'amélioration, les réglages n'ont pas bougé.

### 4. La carte : elle montre, elle ne modifie rien

`4_ui/components/upgrade_icon/` (`UpgradeIcon`) montre le titre et la description, calculée pour le héros, et
couvre la carte d'un `TextureButton`. Un clic émet `chosen(upgrade)`. Une carte de `4_ui` ne connaît pas les
acteurs (règle des dossiers) : elle reçoit le héros comme un simple `Node`, et ne lui écrit rien.

À la manette, il faut voir où l'on est : quand son bouton a le focus, la carte s'éclaire (`modulate` à 1,4) ; la
boutique donne le focus à la première carte (`grab_focus`, à la fin de l'image : les cartes viennent d'entrer
dans l'arbre). Le jeu d'origine ne donnait le focus à rien : à la manette, on ne pouvait pas choisir.

La croix déplace le focus : les actions `ui_left` et `ui_right` de Godot 4.7.2 ont déjà la croix et le stick
gauche. Mais `ui_accept`, l'action qui appuie sur le bouton qui a le focus, n'a par défaut que des touches
(Entrée, Entrée du pavé, Espace : lu dans l'`InputMap` d'un projet lancé). Le projet la redéfinit dans
`project.godot` avec ces trois touches et le bouton A. A sert aussi au dash, sans conflit : pendant la boutique,
le héros est hors de l'arbre.

### 5. La boutique : un tirage à graine, un seul choix

`2_sequence/menus/upgrade_shop/upgrade_shop.gd` tire `offer_count` (2) améliorations différentes parmi
`upgrades`, avec un `RandomNumberGenerator` dont la graine est `random_seed` plus le rang du niveau : une même
partie, une même boutique. Le jeu d'origine mélangeait sur place la liste de GameState, sans graine.

Le héros, c'est celui que GameFlow garde de côté pendant le changement de scène (`GameFlow.carried_player()`,
sans le prendre : le niveau suivant le reprendra). Le jeu d'origine le cherchait par son groupe : il le gardait
dans l'arbre, sous GameFlow. Ici, il est **hors** de l'arbre, et `get_first_node_in_group()` ne trouve que des
nœuds dans l'arbre.

Le premier choix applique l'amélioration et finit l'étape ; un second clic, pendant le fondu, ne fait plus rien.

### 6. Le fond : un shader de canvas_item

`6_assets/shaders/background_material.gdshader` colore le `ColorRect` du fond. Il lit un bruit cellulaire en
coordonnées polaires (distance au centre, angle en tours) avec un zoom qui va et vient (`sin(TIME * 0.2)`), le
renforce vers les bords et selon un second échantillon du bruit qui défile avec le temps, puis passe l'intensité
dans un dégradé (`GradientTexture1D`), du bleu nuit au bleu clair.

C'est la réécriture en code du VisualShader du jeu d'origine, même suite de calculs. Comparé à l'original, image
par image (rendus de la même scène, l'un avec l'original), l'écart est de **0 pixel** à 0,5 s, 2 s, 5 s, 10 s,
15 s et 20 s. Le fond « respire » : vers 2 s, le bruit lu au temps courant est presque nul, et le fond est
presque uni ; c'est le comportement de l'original.

## Les tests

- `1_core/upgrades/test_upgrade.gd`, avec une cible témoin (`cible_temoin.gd`) : l'amélioration augmente la
  propriété nommée ; la description montre la valeur actuelle puis la valeur après, et sans cible le seul
  bonus ; la santé monte le maximum et la santé actuelle ; la vitesse monte l'état du héros, pas ses réglages ;
- `4_ui/components/upgrade_icon/test_upgrade_icon.gd` : titre et description ; un clic émet `chosen` sans rien
  modifier ; avec le focus, la carte s'éclaire ;
- `2_sequence/menus/upgrade_shop/test_upgrade_shop.gd` : deux améliorations différentes ; même graine et même
  rang, les mêmes ; la première carte a le focus ; à la manette (de vrais événements de manette poussés dans
  l'interface), la croix change de carte et A choisit ; le choix s'applique au héros gardé et l'étape finit une
  seule fois ;
- `0_autoload/test_game_flow.gd` : après un niveau, l'intermède avec le héros gardé, puis le niveau suivant ; la
  séquence du jeu a pour intermède la boutique.

## Ce qu'il faut retenir

- Une amélioration est une donnée ; la montrer, l'appliquer : deux autres endroits.
- On n'écrit jamais dans une ressource de réglages partagée : on copie dans l'état, et on écrit dans l'état.
- Un menu jouable à la manette donne le focus à un bouton, montre lequel, et met un bouton de manette dans
  `ui_accept` : par défaut, il n'y en a aucun.
- Un nœud hors de l'arbre n'est dans aucun groupe que l'arbre connaisse : on le demande à celui qui le garde.
- Un shader réécrit se compare à l'original au pixel près, à plusieurs instants.

## À essayer

- Passer `offer_count` à 3 sur `upgrade_shop.tscn` : les trois cartes.
- Changer `bonus` dans `speed.tres` à 5 : un héros qui file.
- Vider `interlude` dans `sequence.tres` : les niveaux s'enchaînent sans boutique.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : la boutique entre deux niveaux, ses trois
  améliorations et leurs valeurs, la carte (titre ondulant, description en BBCode), le fond en VisualShader
  (`background_material.tres`).
- Documentation de Godot 4.7, *Keyboard/Controller Navigation and Focus* (`tutorials/ui/gui_navigation.rst`) ;
  *CanvasItem shaders* (`tutorials/shaders/shader_reference/canvas_item_shader.rst`) ; *Resources*
  (`tutorials/scripting/resources.rst`).
- Références des classes `Control` (`grab_focus`, `focus_entered`), `RandomNumberGenerator`,
  `NoiseTexture2D`, `GradientTexture1D`, `SceneTree` (`get_first_node_in_group`) : API de Godot 4.7.2.

## Étape suivante

Étape 014 : la pause et la réaffectation des commandes. Mettre le jeu en pause, au clavier comme à la manette, et
choisir ses touches et ses boutons.
