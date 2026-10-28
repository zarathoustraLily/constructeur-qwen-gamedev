# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Dans un combat de boss, la caméra est la moitié du jeu : si elle traverse un mur, cache la cible
ou se laisse semer, le joueur meurt sans avoir compris pourquoi. On la construit maintenant, juste après le héros,
parce que tout ce qui suit se règle à travers elle (viser, rouler autour du boss, lire ses attaques).

Ce qu'on obtient : une caméra à la troisième personne au-dessus de l'épaule droite ; le stick droit ou la souris la
tourne autour du héros ; elle ne passe jamais sous le sol ni par-dessus la tête ; elle se rapproche en visant ; un mur
derrière le héros la rapproche aussi ; le clic du stick droit verrouille la cible rouge, et la caméra la garde au
centre jusqu'au prochain clic.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : la souris est capturée (Échap ne la rend pas encore : la pause viendra avec l'interface). Stick droit ou
   souris : la caméra tourne. Clic du stick droit ou de la molette : verrouillage sur le bloc rouge.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un pivot, un bras, une caméra

`1_core/camera/orbit_camera.tscn` : un `Node3D` (le pivot) porte le **lacet** (tourner autour du héros) ; son enfant
`SpringArm3D` (le bras) porte l'**inclinaison** ; la `Camera3D` est au bout du bras. Séparer les deux rotations sur
deux nœuds évite le roulis parasite qu'on obtient en combinant lacet et inclinaison sur un seul.

Le bras à ressort lance un rayon le long de sa longueur (`spring_length`) sur les couches de son masque (le monde) :
si un mur coupe le rayon, la caméra s'arrête devant, à `margin` près. `get_hit_length()` dit la longueur tenue.

### 2. Au-dessus de l'épaule, comme un jeu de tir

La caméra est décalée sur le côté (`position.x` = `shoulder`) : le héros est à gauche de l'écran et ne cache pas ce
qu'on vise au centre. En visant, le bras raccourcit (`aim_distance`) : on voit la cible de plus près.

### 3. Suivre sans à-coups, en dernier

Le pivot rejoint le point visé (les pieds du héros, relevés de `height`) par un amortissement exponentiel :
`lerp(position, but, 1 - exp(-vitesse × delta))`, le même mouvement à 30 ou à 144 images par seconde. La caméra passe
en dernier (`ProcessOrder.CAMERA`) : elle suit le héros déjà déplacé, sans image de retard.

### 4. Tourner au stick et à la souris

Le stick donne une vitesse : on la multiplie par le temps (`degrés par seconde × delta`). La souris donne un
déplacement : on le multiplie par une sensibilité (`degrés par pixel`), **sans** le temps (le multiplier par delta
rendrait la souris plus lente quand le jeu va plus vite). Le mouvement de la souris arrive dans `_unhandled_input`
(`InputEventMouseMotion.relative`), seulement quand elle est capturée (`Input.mouse_mode`). L'inclinaison est bornée
(`clampf`) pour ne pas passer sous le sol ni basculer ; le lacet reste entre -PI et PI (`wrapf`).

### 5. Verrouiller la cible

Une cible se déclare en entrant dans le groupe `lockable` : la caméra ne connaît pas le boss, elle cherche ce qui
s'est déclaré (`get_tree().get_nodes_in_group`). `LockOn.pick` garde la plus proche à portée et **devant** la caméra
(produit scalaire positif entre l'avant et la direction de la cible) : verrouiller quelque chose derrière soi
désorienterait. Verrouillée, la caméra calcule les angles qui regardent la cible (`look_angles` : lacet de l'axe -Z
avec `atan2`, inclinaison selon la hauteur) et s'y tourne en douceur (`lerp_angle` pour le lacet, qui prend le plus
court chemin). Le stick ne la tourne plus. Une cible détruite déverrouille d'elle-même (`is_instance_valid`).

### 6. Le héros suit la caméra

Le héros reçoit maintenant le pivot de la caméra (`camera` de `hero.gd`) : son déplacement relatif (étape 2) prend le
lacet du pivot. La scène principale capture la souris au démarrage.

### 7. Les tests d'abord

- `LockOn` : la plus proche devant à portée ; derrière ou trop loin, rien ; les angles exacts (un quart de tour, 45°).
- La caméra, sans son entrée, pilotée par le test : bornes de l'inclinaison, lacet qui boucle ; verrouillée, elle
  ignore le stick et finit face à la cible ; elle rejoint le héros en douceur ; le bras raccourcit en visant et devant
  un mur (un vrai `StaticBody3D`, et quelques images de physique pour que le bras lance son rayon) ; l'épaule ; une
  cible libérée déverrouille.
