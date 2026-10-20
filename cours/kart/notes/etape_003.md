# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La caméra fixe de l'étape 002 laisse la place à une caméra qui suit le kart, derrière
lui, au bout d'un bras à ressort. La souris et le stick droit la font tourner autour du kart ; quand on les
lâche, elle revient dans son dos.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Conduire : la caméra suit. Stick droit : regarder autour du kart. Cliquer dans la fenêtre : la
   souris est capturée et pilote la caméra ; Échap la rend.
3. Les réglages : `5_data/camera/follow_camera.tres`.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une caméra qui ne connaît pas le kart

La caméra est un mécanisme réutilisable, dans `1_core/camera/` : elle suit une **cible**, n'importe quel
`Node3D`. Elle ne sait pas que c'est un kart. Une entité ne doit pas dépendre d'une autre entité (règle
DOSSIERS), et `1_core` ne connaît rien du jeu. C'est la scène principale qui lui donne sa cible
(`target = ../Kart`) et le point à suivre (`anchor = ../Kart/Visual`, le modèle, qui suit les pentes). Elle
lui donne aussi ses réglages, puisque `1_core` n'a pas le droit de désigner `5_data`.

### 2. Un pivot, un bras à ressort, une caméra

`follow_camera.tscn` :

- `FollowCamera` (le pivot, script `follow_camera_view.gd`) se place à chaque image au-dessus du modèle
  du kart (`height` = 1 m) ;
- `SpringArm` (`SpringArm3D`), penché de 30° vers le bas, porte la caméra à 4 m. Si un obstacle de son
  masque (`collision_mask = 30`) passe entre le pivot et la caméra, le bras se raccourcit : la caméra ne
  traverse pas les murs ;
- `Camera3D`, avec un champ de 85°.

Faire tourner la caméra, c'est faire tourner le pivot : `turn(montant)` change le cap (`rotation.y`) et
l'inclinaison (`rotation.x`), bornée à ±0,4 π.

### 3. La souris et le stick droit : une seule porte d'entrée

`camera_input.gd` (classe `CameraInput`) est l'adaptateur d'entrées de la caméra, le seul de ses scripts à
lire `Input` (règle ARC-04) :

- la souris : chaque mouvement (`InputEventMouseMotion.relative`, en pixels) est cumulé, et la caméra le
  lit une fois par image (`take_mouse_motion()`), ce qui remet le cumul à zéro ;
- le stick droit : quatre nouvelles actions, `look_left`, `look_right`, `look_up`, `look_down`, sur les
  axes `JOY_AXIS_RIGHT_X` et `JOY_AXIS_RIGHT_Y`, avec leur zone morte. `get_vector()` les lit comme à
  l'étape 001.

La souris et la manette demandent deux chemins différents : la souris donne un **déplacement** (des
pixels, quand elle bouge), le stick une **position** (tenue tant qu'on le pousse). On multiplie donc le
premier par une sensibilité (radians par pixel) et le second par une vitesse et par `delta` (radians par
seconde). La documentation de Godot le signale pour la vue à la première personne, qui pose le même
problème.

### 4. Capturer la souris, et la rendre

`Input.mouse_mode = Input.MOUSE_MODE_CAPTURED` cache la souris et la garde dans la fenêtre : ses mouvements
ne s'arrêtent plus au bord de l'écran. Le kart d'origine la capturait dès le démarrage. Ici, elle ne l'est
qu'après un clic dans la fenêtre, et Échap (l'action `ui_cancel`, prédéfinie par Godot) la rend : on ne
prend pas la souris de celui qui n'a pas encore commencé à jouer.

### 5. Revenir derrière le kart

Après `reset_delay` (1,25 s) sans souris ni stick, si la cible avance (plus de 1 m/s), le pivot tourne en
douceur vers l'orientation du kart : `global_basis.slerp(cible, 1 − exp(−reset_rate × delta))`. `slerp`
interpole entre deux rotations sans déformer la base ; `orthonormalized()` corrige les petites erreurs qui
s'accumulent image après image. À l'arrêt, la caméra reste où on l'a tournée : on peut regarder le kart de
face.

La vitesse de la cible se mesure par son déplacement entre deux images : la caméra n'a pas besoin de savoir
que la cible est un `CharacterBody3D`.

### 6. Présentation, donc `_process`

Le gameplay tourne dans `_physics_process` (règle SIM-01). La caméra, elle, est de la présentation : son
script s'appelle `follow_camera_view.gd` et tourne dans `_process`, à chaque image affichée.

## Les tests

- `1_core/camera/test_follow_camera_view.gd` : la caméra se place au-dessus du point suivi ; le stick et la
  souris capturée la font tourner, la souris libre non ; l'inclinaison est bornée ; elle revient derrière
  une cible qui avance, pas derrière une cible arrêtée, et pas pendant le délai.
- `1_core/camera/test_camera_input.gd` : la souris libre au démarrage, le clic, Échap, le cumul des
  mouvements, les axes du stick droit.
- `2_sequence/test_main.gd` : la caméra suit le kart qui roule.

## Ce qu'il faut retenir

- Un mécanisme générique reçoit ses dépendances de la scène : la cible, le point suivi, les réglages.
- Souris : un déplacement, à multiplier par une sensibilité. Stick : une position, à multiplier par une
  vitesse et par `delta`.
- `SpringArm3D` empêche la caméra de traverser le décor.
- `slerp` sur des bases orthonormées pour tourner en douceur.

## À essayer

- Passer `reset_delay` à 0 : la caméra ne se laisse plus tourner pendant que le kart roule.
- Passer `max_pitch` à 0,2 : on ne peut presque plus regarder vers le haut ou le bas.
- Ajouter un cube au milieu de l'aire, en `StaticBody3D` sur la couche Terrain : en passant derrière, le bras
  se raccourcit.

## Source

- Documentation de Godot 4.7, *Controllers, gamepads, and joysticks*
  (`tutorials/inputs/controllers_gamepads_joysticks.rst`, révision `9adca4c`) : la souris et la manette
  demandent des chemins de code différents pour regarder autour de soi.
- Référence des classes `SpringArm3D`, `Input` (`mouse_mode`) et `Basis` (`slerp`, `orthonormalized`), API de
  Godot 4.7.2.
- La caméra du kart d'origine (`3_entities/player/camera_controller.gd` du kart rangé), dont les réglages
  sont repris : sensibilité, vitesse au stick, délai, retour, bras de 4 m.

## Étape suivante

Étape 004 : l'île. Un vrai terrain, un circuit, et le shader triplanaire qui habille le sol.
