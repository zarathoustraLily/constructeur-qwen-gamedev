# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le mannequin s'anime : il sort du sol au départ, respire au repos, court quand il
marche. Ses pieds font entendre ses pas, et il tient son épée laser dans la main droite.

Ce qu'on obtient : la même estrade, mais un héros vivant. Le passage du repos à la course est progressif, et
chaque pas qui touche le sol joue un son choisi au hasard parmi quatre.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Le mannequin sort du sol, puis attend. Marcher : il court ; s'arrêter : il revient au repos. Avec un
   casque, on entend ses pas.
3. Dans l'éditeur, ouvrir `3_entities/player/animated_player.tscn`, sélectionner `AnimationTree` : le
   panneau du bas montre la machine à états d'animation.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Le modèle animé : une scène à lui

`3_entities/player/animated_player.tscn` reprend le modèle `.glb` et lui ajoute :

- un `AnimationPlayer` et ses bibliothèques d'animations : `PlayerAnimations` (repos, course, sortie du
  sol, des fichiers `.res` du paquet d'animations KayKit) et une animation `RESET`, qui remet l'arme au repos ;
- un `AnimationTree`, qui décide quelle animation joue ;
- des `BoneAttachment3D`, des nœuds accrochés à un os du squelette : l'épée à l'os `hand.r`, et un nœud par
  pied (`foot.r`, `foot.l`).

Les animations désignent leurs cibles par un chemin depuis le modèle (`Rig_Medium/Skeleton3D/WeaponSlot`…) :
les noms de ces nœuds font partie du contrat avec les fichiers `.res`.

### 2. L'arbre d'animation : une machine à états

L'`AnimationTree` a pour racine une machine à états d'animation (`AnimationNodeStateMachine`), à ne pas
confondre avec la machine à états du gameplay de l'étape 2 :

- `Start → Spawn` : au lancement, le mannequin sort du sol (`Spawn_Ground`) ;
- `Spawn → WalkSpace` : à la fin de cette animation (*switch mode* « At End », valeur 2), on passe au
  mélange repos-course, en 0,1 s de fondu ;
- les deux transitions sont automatiques (*advance mode* « Auto », valeur 2) : personne ne les déclenche.

`WalkSpace` est un `AnimationNodeBlendSpace1D` : deux animations posées sur une ligne, le repos (`Idle_A`) à
−1 et la course (`Running_B`) à 1. Entre les deux, Godot les mêle. La position sur la ligne est un paramètre
de l'arbre : `parameters/WalkSpace/blend_position`.

### 3. Mêler en douceur : AnimationTreeView

`1_core/animation/animation_tree_view.gd` (`AnimationTreeView`) étend `AnimationTree`. Le personnage donne
une cible (`blend_target` : −1 ou 1) et l'arbre s'en approche à `blend_speed` par seconde
(`move_toward`), à chaque image : d'un bout à l'autre en un tiers de seconde. C'est de la présentation : le
fichier finit par `_view.gd`, et peut donc se servir de `_process` (règle SIM-01).

C'est l'état `PlayerRun` qui donne la cible : 1 quand le joueur marche, −1 à l'arrêt. Dans ce jeu, les états
du gameplay choisissent l'animation, parce que la durée d'un coup ou d'une esquive sera celle de son
animation (étapes 5 et 6).

`change_immediate()` lance un état d'animation tout de suite, sans transition (`playback.start()`) ; il
servira pour les coups et l'esquive.

### 4. Les pas : une piste de méthode et un signal

L'animation `Running_B.res` contient, en plus des os, une **piste d'appel de méthode** : au moment où un pied
touche le sol, elle appelle `emit_signal("footstep")` sur `RightFootBone` ou `LeftFootBone`. Ces nœuds
portent `1_core/animation/foot_bone.gd` (`FootBone`), qui déclare le signal `footstep`. La scène branche ce
signal sur la fonction `play()` de l'`AudioStreamPlayer3D` du pied (les lignes `[connection]` en bas du
`.tscn`).

Personne n'émet `footstep` dans un script : Godot avertirait d'un signal jamais employé, et cet avertissement
est une erreur dans ce projet. `@warning_ignore("unused_signal")` le dit au-dessus du signal.

Le son est un `AudioStreamRandomizer` : à chaque `play()`, il tire un des quatre `footstep-0N.ogg`. Les pas
ne se répètent pas à l'identique.

### 5. L'épée en main

`WeaponSlot` (`1_core/animation/weapon_slot.gd`) est accroché à `hand.r`. Il porte la lame (`LazerSword`, un
cylindre dont le matériau brille par émission) et la poignée. Il a trois propriétés que les animations
d'attaque écriront image par image : la forme du coup (`attack_mode`, une énumération `Mode`), l'effacement
de l'effet de lame (`vfx_threshold`) et la partie du coup qui frappe (`enabled`). L'animation `RESET` les
remet au repos. Elles serviront à l'étape 6.

Ces trois scripts (`WeaponSlot`, `FootBone`, `AnimationTreeView`) vivent dans `1_core/animation/` : les
ennemis s'en serviront aussi, et une entité n'a pas le droit d'en connaître une autre (règle des dossiers).
Dans le jeu d'origine, ils étaient dans `3_entities/mannequin/`.

### 6. Le bus audio des bruitages

Les sons jouent sur le bus `SFX`, déclaré dans `5_data/audio/default_bus_layout.tres`. Godot cherche ce
fichier à la racine du projet par défaut ; le réglage `audio/buses/default_bus_layout` (section `[audio]` de
`project.godot`) lui donne sa place dans `5_data`, parmi les réglages.

## Les tests

`3_entities/player/test_player.gd` gagne quatre règles :

- il apparaît en sortant du sol (état d'animation `Spawn`) ;
- en marche, le mélange passe à la course, puis revient au repos à l'arrêt ;
- ses pieds font entendre ses pas : chaque `FootBone` est branché à son son, et la course émet `footstep`
  sur les deux pieds ;
- il tient son épée dans la main droite (`hand.r`).

## Ce qu'il faut retenir

- `AnimationPlayer` garde les animations ; `AnimationTree` décide laquelle joue.
- Une machine à états d'animation : transitions « Auto » et « At End » pour enchaîner sans code.
- `BlendSpace1D` mêle deux animations selon un paramètre, qu'on approche en douceur.
- Une piste d'appel de méthode fait émettre un signal à l'instant voulu de l'animation.
- `BoneAttachment3D` accroche un objet à un os.

## À essayer

- Passer `blend_speed` à 1 sur l'`AnimationTree` : le mannequin met deux secondes à se mettre à courir.
- Remplacer l'`AudioStreamRandomizer` du pied droit par `footstep-01.ogg` seul : un pied sur deux sonne
  toujours pareil.
- Dans la transition `Spawn → WalkSpace`, passer *switch mode* à « Immediate » : la sortie du sol est coupée.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : modèle animé, arbre d'animation, pas, épée laser,
  bus `SFX` ; modèle et animations KayKit (GameDev.tv Free Sample Pack, Character Animations).
- Documentation de Godot 4.7 : *Using AnimationTree* (`tutorials/animation/animation_tree.rst`) pour les
  machines à états, les types de transition et `BlendSpace1D` ; *Animation track types*
  (`tutorials/animation/animation_track_types.rst`) pour les pistes d'appel de méthode ; *Audio buses*
  (`tutorials/audio/audio_buses.rst`) ; référence de `ProjectSettings` pour `audio/buses/default_bus_layout`.
- Références des classes `AnimationTree`, `AnimationNodeStateMachinePlayback`, `BoneAttachment3D`,
  `AudioStreamRandomizer` (API de Godot 4.7.2).

## Étape suivante

Étape 004 : le niveau de test. Un sol et des murs en tuiles (GridMap), un trou, la limite du monde sous le
niveau.
