# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le premier élément de gameplay : le héros, en maquette grise (une capsule et un nez orange pour
voir où il regarde), qui court là où pousse le stick. On commence par lui parce que tout le reste (caméra, tir,
roulade, boss) se règle par rapport à lui ; et en maquette grise parce que le gameplay se juge avant l'habillage :
on ne colle pas un modèle animé sur des déplacements qu'on n'a pas encore réglés.

Ce qu'on obtient : F5, le stick gauche (ou W A S D) fait courir la capsule ; le haut du stick l'emmène là où regarde
la caméra ; le corps pivote vers sa marche ; en visant (gâchette gauche, clic droit), il ralentit.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5, puis le stick gauche ou W A S D.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Trois scripts, trois rôles

On sépare dès le départ ce qui lit les appareils, ce qui décide et ce qui calcule :
- `3_entities/hero/hero_input.gd` lit les actions (`Input.get_vector`, `Input.is_action_pressed`) et les pose sur le
  héros. C'est le seul endroit qui connaît l'existence d'une manette : un rejeu automatique (tests, captures) pilote le
  héros en posant `stick` et `aiming` lui-même, sans passer par les appareils ;
- `3_entities/hero/hero.gd` décide : à quelle vitesse aller, vers où se tourner, quand tomber ;
- `1_core/physics/motion.gd` calcule, en fonctions pures (sans nœud, sans état) : elles se testent en une ligne et se
  réutiliseront pour le boss.
Les valeurs (vitesses, accélérations, virage, gravité) vivent dans `5_data/hero/hero_settings.tres` (classe
`1_core/data/hero_settings.gd`) : on règle le ressenti sans toucher au code.

### 2. Se déplacer par rapport à la caméra

Le joueur pense « vers le haut de l'écran », pas « vers -Z du monde ». La direction du stick `(x, 0, y)` est tournée
du lacet de la caméra autour de l'axe vertical (`Vector3.rotated(Vector3.UP, lacet)`) : le haut du stick (y = -1)
devient l'avant de la caméra. Bornée à une longueur de 1 (`limit_length`), elle garde la finesse d'un stick à moitié
poussé (marcher doucement) sans permettre d'aller plus vite en diagonale.

### 3. Accélérer et freiner, sans saut de vitesse

La vitesse horizontale rejoint sa cible avec `Vector2.move_toward(cible, taux × delta)` : elle avance d'un pas fixe
par seconde (l'accélération), puis s'arrête pile sur la cible. Le freinage a son propre taux, plus fort : un héros qui
glisse en s'arrêtant paraît mou. `move_toward` plutôt que `lerp` : `lerp` n'arrive jamais tout à fait et dépend du
nombre d'images. La vitesse verticale (la gravité) n'est pas touchée par ce calcul.

### 4. Tourner le corps vers sa marche

Dans Godot, l'avant d'un nœud est son axe **-Z**. Le lacet qui le fait regarder vers une direction (x, z) est donc
`atan2(-x, -z)` : écrire `atan2(x, z)` ferait avancer un modèle à reculons (piège classique, invisible sur une
capsule : c'est pour ça qu'on lui a mis un nez). Le corps rejoint ce lacet par le plus court chemin
(`angle_difference`, qui rend un écart entre -PI et PI : de 170° à -170°, on tourne de 20°, pas de 340°), au plus de
la vitesse de virage par seconde.

### 5. Le corps, sa couche, sa gravité

`Hero` est un `CharacterBody3D` : on règle sa vitesse et `move_and_slide()` le fait glisser le long des obstacles. Il
est sur la couche du héros et regarde le monde et le boss, pas les projectiles (les siens ne doivent pas le toucher).
Hors du sol, la gravité tire sa vitesse vers le bas. Il passe dans l'ordre des acteurs ; son entrée, avant lui.

### 6. Les tests d'abord, sur un vrai sol

Les fonctions de `Motion` se testent seules. Le héros, lui, se teste dans une vraie simulation : le test construit un
sol (`StaticBody3D` et sa forme), une « caméra » (un `Node3D` qu'on tourne), retire l'entrée du héros et pose `stick`
lui-même, puis attend des images de physique (`await get_tree().physics_frame`). On vérifie : il se pose ; il avance
vers l'avant de la caméra, puis vers sa gauche quand elle a tourné d'un quart de tour ; il atteint sa vitesse de
course, moins en visant ; il s'arrête stick lâché ; son corps regarde sa marche.
