# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le héros arrive : le mannequin du jeu d'origine, un corps qui marche selon les
commandes de l'étape 1, et une machine à états qui sépare la course de la chute.

Ce qu'on obtient : le mannequin sur une estrade, au milieu d'un grand sol. Il marche dans la direction
demandée, tourné vers sa marche, et la caméra le suit. Au bord de l'estrade, il tombe, puis repart au sol. Il
ne bouge pas encore les bras ni les jambes : l'animation vient à l'étape suivante.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. W, A, S, D ou le stick gauche : le mannequin marche. Pousser le stick à moitié : il marche à moitié
   vitesse. Sortir de l'estrade : il tombe.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un corps qui glisse : CharacterBody3D

`3_entities/player/player.tscn` a pour racine un `CharacterBody3D` : un corps que le code déplace lui-même,
sans subir la physique. On lui donne une vitesse (`velocity`), puis `move_and_slide()` le déplace en glissant
le long des murs et du sol, et met à jour `is_on_floor()`. La forme de collision est une capsule. Le modèle
(`Mannequin`, le fichier `.glb` du paquet KayKit) est posé 1 m plus bas : le centre de la capsule est à
hauteur de hanche, ses pieds touchent le sol.

La caméra est un enfant du joueur (`CameraRoot/Camera3D`) : elle le suit sans code. Seul le modèle tourne
vers la marche ; le corps et la caméra ne tournent pas.

### 2. Le joueur reçoit des commandes

`player.gd` ne lit jamais une touche. À chaque image physique, il demande ses commandes à son adaptateur
(`input.read()`, l'adaptateur de l'étape 1, enfant du joueur). Sans adaptateur (`input = null`), les
commandes restent celles qu'on écrit dans `player.commands` : c'est ainsi que les tests pilotent le joueur,
sans clavier ni manette.

Godot fait jouer l'image physique au parent avant ses enfants. Le joueur lit donc ses commandes avant que sa
machine à états, son enfant, ne s'en serve.

### 3. De l'écran au sol

Les commandes parlent de l'écran : « droite », « haut ». Le sol a ses propres axes, et la caméra le regarde
de biais. `to_ground()` tourne la direction de l'écran autour de la verticale, du même angle que la caméra :
`Vector3(x, 0, y).rotated(Vector3.UP, camera.global_rotation.y)`. « Droite » sur l'écran devient « droite »
au sol, vu par la caméra.

Le jeu d'origine ramenait toujours cette direction à une longueur de 1 (`normalized()`) : au clavier,
c'était sans effet ; à la manette, un stick à moitié poussé faisait courir à pleine vitesse. Ici, la
longueur est gardée : la vitesse suit le stick.

### 4. Se tourner en douceur, quelle que soit la cadence

`look_toward_direction()` tourne le modèle vers sa marche sans à-coup. On calcule l'orientation visée
(`looking_at`, avec `use_model_front` : le devant du modèle est son +Z), puis on en fait un bout à chaque
image : `interpolate_with(cible, 1 - exp(-turn_rate × delta))`. Avec `exp`, le résultat ne dépend pas de la
cadence : deux images de 1/120 s font le même chemin qu'une image de 1/60 s. Un simple « 20 % du chemin
par image » tournerait deux fois plus vite à 120 images par seconde.

### 5. La machine à états

Le joueur est soit en train de courir, soit en train de tomber, jamais les deux. Plutôt que des booléens
(`is_falling`…), une **machine à états** (règle SIM-05) :

- `1_core/state_machine/state_machine.gd` (`StateMachine`) : ses enfants sont des états, un seul est actif ;
  elle lui donne chaque image physique et change d'état quand il le demande ;
- `1_core/state_machine/state.gd` (`State`) : un état redéfinit `enter()`, `exit()`, `physics_update()`, et
  émet `finished` avec le nom de l'état suivant ;
- `3_entities/player/states/` : `PlayerRun` (marcher ; sans sol, passer à la chute) et `PlayerFall`
  (tomber ; au sol, reprendre la course). Leur base commune, `PlayerState`, porte `core_movement()`.

Les états se désignent par des références (`@export var fall_state`), pas par des noms écrits à la main :
renommer un nœud ne casse rien.

Dans le jeu d'origine, la machine transmettait aussi les événements d'entrée aux états
(`_unhandled_input`, `handle_input`). Elle ne le fait plus : seul l'adaptateur lit les entrées (règle
ARC-04), et les états lisent les commandes du joueur.

### 6. Une chute à vitesse constante

`PlayerFall` ajoute `get_gravity()` (9,8 m/s², une accélération) à la vitesse, sans la multiplier par la
durée de l'image, et `core_movement()` remet la vitesse à zéro à chaque image. Le joueur tombe donc à
9,8 m/s dès le départ, sans accélérer. C'est le comportement du jeu d'origine, gardé tel quel et écrit en
commentaire. Pour une vraie chute accélérée, il faudrait garder la vitesse verticale d'une image à l'autre et
lui ajouter `get_gravity() * delta`.

### 7. Les réglages hors du code

Vitesse de course (8 m/s) et vivacité du virage (12 par seconde) vivent dans
`5_data/player/player_settings.tres`, de type `PlayerSettings` (`1_core/characters/player_settings.gd`) :
règles DAT-01 et DAT-02. Les scripts de `3_entities` n'écrivent aucun chiffre de réglage.

## Les tests

- `1_core/state_machine/test_state_machine.gd`, avec un état témoin (`etat_temoin.gd`) qui note ses appels :
  état de départ, premier enfant à défaut, seul l'état actif joue, passage à l'état nommé, nom inconnu
  refusé ;
- `3_entities/player/test_player.gd` : sans commande, le joueur reste sur place ; il marche dans la
  direction voulue, tournée comme la caméra, à la vitesse des réglages ; un stick à moitié, moitié vitesse ;
  le modèle se tourne vers sa marche ; sans sol, il tombe, puis reprend sa course ;
- `2_sequence/test_main.gd` : le joueur se tient sur l'estrade.

Les tests du joueur posent un sol en code (`StaticBody3D` et `BoxShape3D`), retirent l'adaptateur et
écrivent les commandes : `_player.commands.move = Vector2.RIGHT`.

## Ce qu'il faut retenir

- `CharacterBody3D` : on donne une vitesse, `move_and_slide()` déplace et dit si l'on touche le sol.
- Une direction de l'écran se tourne comme la caméra pour devenir une direction du sol.
- `1 - exp(-taux × delta)` : un lissage qui ne dépend pas de la cadence.
- Des états exclusifs : une machine à états, des états qui se désignent par référence.

## À essayer

- Passer `turn_rate` à 2 dans `player_settings.tres` : le mannequin se tourne lentement, en arc.
- Remplacer `player.velocity += player.get_gravity()` par une chute accélérée (garder `velocity.y` d'une
  image à l'autre, ajouter `get_gravity().y * delta`) : sauter de l'estrade devient plus doux au départ.
- Retirer le `return` après `finished.emit(...)` dans `player_run.gd` : à l'image du changement, l'état
  quitté joue encore sa fin.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : joueur, états de course et de chute, machine à
  états, réglages (vitesse 8, virage 12), angle de la caméra ; modèle KayKit (GameDev.tv Free Sample Pack).
- Documentation de Godot 4.7, *Using CharacterBody2D/3D*
  (`tutorials/physics/using_character_body_2d.rst`) : `move_and_slide()`, `is_on_floor()`.
- Références des classes `CharacterBody3D`, `Transform3D` (`looking_at`, `interpolate_with`) et `Node`
  (`owner`, `is_node_ready`, signal `ready`) : API de Godot 4.7.2.

## Étape suivante

Étape 003 : l'animation. Un arbre d'animation fait passer le mannequin du repos à la course ; ses pieds
font entendre ses pas, et l'arme vient dans sa main.
