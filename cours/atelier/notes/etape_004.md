# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le joueur prend corps : il marche, freine, saute à une hauteur voulue et retombe, sur un
vrai sol que le moteur physique simule.

Ce qu'on obtient : un `CharacterBody3D` qui obéit au stick filtré de l'étape 2, accélère et freine au sol, garde
de l'élan en l'air, saute exactement de la hauteur des réglages, pardonne un saut un peu tardif au bord d'un vide
et un appui un peu trop tôt avant l'atterrissage.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Ouvrir `3_entities/player/player.tscn` : le corps, sa forme de collision, son entrée.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les couches de collision, nommées

`project.godot` nomme les couches (`[layer_names]`) : monde, joueur, ennemis, coups. Un corps est sur une couche
(`collision_layer`) et regarde des couches (`collision_mask`). Le masque est un entier où la couche n donne le
bit n - 1 : `1_core/physics/layers.gd` fait ce calcul une fois pour toutes (`bit`, `mask`, `has`). Le joueur est
sur sa couche et regarde le monde et les ennemis, pas les autres joueurs.

### 2. Le mouvement, en calculs purs

`1_core/physics/motion.gd` ne connaît aucun nœud. `horizontal` fait rejoindre à la vitesse celle voulue avec
`Vector2.move_toward`, au rythme de l'accélération au sol ou, plus faible, en l'air ; stick lâché, au sol, elle
freine ; en l'air, l'élan reste. `fall` applique la gravité, bornée par la vitesse de chute maximale.
`jump_speed` donne la vitesse de départ d'un saut de hauteur h sous la gravité g : racine de 2 g h.

### 3. Deux tolérances qui rendent le saut agréable

Sauter juste après avoir quitté un bord reste permis un court instant (`can_jump`, le « coyote time ») ; un
appui sur saut fait un peu avant de toucher le sol est gardé (`jump_buffered`) et part à l'atterrissage.

### 4. Le joueur et son entrée

`3_entities/player/player.gd` tient la vitesse, compte le temps depuis le sol et depuis le dernier appui, saute
quand c'est permis et demandé, puis laisse `move_and_slide` gérer les collisions. Il ne lit jamais la manette :
`player_input.gd` lit les actions (stick filtré, saut par `is_action_just_pressed`) et les lui donne. L'entrée
passe avant le joueur (`ProcessOrder.INPUT`), le joueur avec les entités.
