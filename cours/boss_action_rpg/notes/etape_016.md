# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent, en jouant : « le joueur ne peut pas sauter » ; « le canon et le tir ne pointent pas dans
la même direction, et pire parfois le joueur tire en bas ». Cette étape ajoute le saut et répare la visée.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Le tir qui part vers le sol

`Hero.aim_point()` lançait toujours le rayon du centre de l'écran. La caméra regarde le héros d'en haut : elle part
inclinée de 15° vers le bas (`OrbitCamera.pitch`). Au-delà du héros, ce rayon touche le plancher quelques mètres
devant lui, et le tir partait du fusil vers ce point du sol.

Le point visé dépend maintenant de la situation :
- **verrouillé sur une cible** : la cible elle-même ;
- **en visée** (gâchette gauche tenue) : le rayon du centre de l'écran, comme avant, compté à partir de la profondeur
  du héros ;
- **sinon (tir de hanche)** : droit devant le corps, à l'horizontale, à la hauteur de l'arme.

### 2. Le canon qui suit le tir

Le clip de visée tient le fusil à l'horizontale. Quand le tir monte vers la poitrine du golem, le canon ne le suivait
pas. `HeroAimModifier` est un `SkeletonModifier3D` : il passe après l'animation et incline l'os `Chest` de l'angle
vertical du tir (`_process_modification_with_delta`). La vue l'ajoute au squelette, avant l'IK de la main gauche.

Le héros épaule dès qu'il tire, pas seulement quand il vise : le fusil pointe alors là où part le tir de hanche.

### 3. Le saut

- Une action `jump` : A à la manette, Espace au clavier. La roulade passe sur B et Maj.
- `HeroJumpState` dépense de l'endurance (`jump_cost`, 15) et donne la vitesse verticale qui monte de `jump_height`
  (1 m) sous la gravité du héros : `sqrt(2 × gravité × hauteur)`. En l'air, le héros garde une part de contrôle
  (`air_control`, 0,35). Il peut tirer. Il revient à la course quand il retouche le sol.
- Un appui est gardé 0,15 s (`InputBuffer`) : un saut demandé juste avant de toucher le sol part à l'atterrissage.
- Sans endurance, pas de saut.

Le jeu n'a pas de clip de saut. La vue tient une foulée de course : le clip `run` part de 30 % de sa durée
(`AnimationNodeAnimation.start_offset`) et passe presque arrêté (`AnimationNodeTimeScale`, 0,15). L'entrée du saut
repart de zéro à chaque saut (`AnimationNodeTransition.set_input_reset`).

### 4. Les tests

- Le héros monte de la hauteur voulue (à 0,1 m près), dépense l'endurance du saut, puis retombe en course.
- Sans endurance, il reste en course.
- Il épaule dès qu'il tire ; le saut a sa pose.
- Le tir de hanche part à l'horizontale, à la hauteur de l'arme. Verrouillé, il vise la cible. Le buste s'incline de
  l'angle du tir (à 0,05 rad près), et le canon pointe à moins de 12° de la cible.

Avec les cas des étapes précédentes : 220 cas verts. À l'image, vue de côté, le héros verrouillé sur le golem tire
puis saute en tirant. Il monte, retombe, et le fusil reste tourné vers le golem.
