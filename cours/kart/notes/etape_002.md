# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le kart arrive : il reçoit les commandes de l'étape 001 et roule sur une aire d'essai,
un sol plat et une rampe. La caméra est encore fixe ; elle suivra le kart à l'étape 003.

Ce qu'on obtient : le kart et son pilote (le personnage Gobot), qui accélère, recule, tourne, freine, tourne
sur place en freinant à l'arrêt, et saute. Sur la rampe, il décolle.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Gâchette droite ou W : le kart part vers la rampe. Stick gauche ou A et D : il tourne. Bouton A ou
   Espace : il saute, et la manette vibre.
3. Les réglages de conduite : ouvrir `5_data/kart/kart_settings.tres` dans l'inspecteur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un seul corps, des commandes

Le kart est un `CharacterBody3D` (`3_entities/kart/kart.gd`, classe `Kart`) : un seul corps qui glisse sur
le sol, sans physique de roues. À chaque image physique, il prend ses commandes : son adaptateur
d'entrées (`KartInput`, enfant du kart) les lit, ou bien, sans adaptateur, on les écrit dans `commands`.
C'est ainsi que les tests pilotent le kart, et qu'un pilote automatique le pourrait. Le kart ne lit jamais
`Input` (règle ARC-04).

### 2. Les réglages dans une ressource

Vitesse de pointe, accélération, angles de braquage, saut, gravité : tout est dans
`5_data/kart/kart_settings.tres`, de type `KartSettings` (`1_core/vehicles/kart_settings.gd`). Le script ne
contient aucun chiffre de réglage (règle DAT-01). Les seuls nombres permis dans la logique sont 0 et 1.

Les amortissements le montrent. Le kart d'origine écrivait `pow(0.5, 0.6 * delta)` (résistance au roulement
de 0,6, réglée sur le joueur) : la vitesse est divisée par deux toutes les 1,67 s. Ici, on écrit
`exp(-rolling_decay * delta)`, avec `rolling_decay = 0,416` dans la ressource. C'est la même chose, car 0,416
vaut 0,6 × ln 2. Le test `test_en_roue_libre_la_vitesse_est_divisee_par_deux_en_ln2_sur_l_amortissement` le
vérifie.

### 3. Le moteur, au sol

`apply_engine(delta)`, dans l'ordre :

1. la résistance au roulement freine un peu, toujours ;
2. la vitesse est ramenée sur l'axe du kart : la composante de côté disparaît, le kart ne glisse pas ;
3. si on freine, la vitesse fond plus vite (`braking_decay`) ;
4. sinon, les gaz ajoutent `throttle × acceleration × delta` jusqu'à la vitesse de pointe, en avant, ou
   jusqu'à `top_reverse_speed`, en arrière. Une gâchette à moitié accélère donc deux fois moins.

### 4. La direction : comme une voiture

`apply_steering(delta)`. Le braquage effectif rejoint en douceur celui demandé (`steering_response`). Au sol,
le kart tourne comme une voiture : vitesse de rotation = vitesse × tan(angle) / empattement. Il en découle :

- à l'arrêt, il ne tourne pas ;
- l'angle maximal diminue avec la vitesse (16° à l'arrêt, 6° à la vitesse de pointe), donc le virage est
  plus serré à basse vitesse ;
- frein tenu presque à l'arrêt : il tourne sur place (`handbrake_steering_velocity`) ;
- en l'air, il tourne à vitesse fixe (`air_steering_velocity`).

### 5. Le saut et la gravité

Au sol, un saut ajoute `jump_velocity` vers le haut et émet le signal `jumped`. En l'air, `apply_air`
ajoute la gravité, et la vitesse reste sur l'axe du kart. Au sol, `move_and_slide()` et l'accrochage au sol
de `CharacterBody3D` gardent le kart collé à la pente : pas besoin de gravité.

Le kart ne heurte que les couches de son masque de collision (`collision_mask = 63` : les couches 1 à 6,
Karts, Items, ItemBoxes, Terrain, Circuit, BoostPanels, comme dans le jeu d'origine) : le sol et la rampe sont
sur la couche Terrain. `floor_max_angle` (60°) dit jusqu'à quelle pente le sol compte comme un sol.

### 6. La présentation, à part

Le kart ne s'occupe pas de son apparence. `kart_view.gd` (le nœud `Visual`) lit son état à chaque image
et anime le modèle :

- il l'aligne sur le sol, ou, en l'air, le fait piquer du nez selon la vitesse verticale ;
- il fait tourner les roues, et braquer les directrices ;
- il tourne le volant et fait pencher la caisse.

`wheel_view.gd` cherche le sol sous chaque roue par un rayon et y descend le maillage : c'est la suspension,
qu'on voit sans qu'elle porte le kart. `steering_wheel_view.gd` accroche les mains du pilote au volant.

Les scripts `_view` ont le droit d'écrire leurs chiffres d'affichage : ils ne changent pas la conduite.

### 7. La scène fait les liens

`2_sequence/main.gd` montre les commandes reçues par le kart dans l'affichage de l'étape 001, et branche
le signal `jumped` du kart sur la vibration. Le kart ne connaît ni l'affichage ni la vibration.

## Les tests

- `3_entities/kart/test_kart.gd` : une règle de conduite par test. Le kart est posé sur un vrai sol, puis
  piloté pas à pas, ses méthodes appelées directement.
- `3_entities/kart/test_kart_view.gd` : les roues reçoivent la vitesse, seules les directrices braquent, le
  modèle reste droit.
- `2_sequence/test_main.gd` : le kart se pose sur le sol ; en fonçant sur la rampe, il décolle.

C'est ce dernier test qui a montré, en écrivant l'étape, que la rampe était posée à l'envers : un mur au
lieu d'une pente.

## Ce qu'il faut retenir

- La logique reçoit des commandes ; les tests et les pilotes automatiques s'en servent autant que la manette.
- Chiffres de réglage dans une ressource, amortissements écrits en `exp(-taux × delta)`.
- La conduite d'un kart d'arcade : vitesse ramenée sur l'axe, rotation proportionnelle à la vitesse.
- La présentation lit l'état sans le changer.

## À essayer

- Dans `kart_settings.tres`, passer `max_steering_angle_fast` à 16 : à pleine vitesse, le kart devient
  nerveux.
- Mettre `rolling_decay` à 0 : en roue libre, le kart ne s'arrête plus.
- Doubler `gravity` : les sauts deviennent courts et secs.

## Source

- Référence de la classe `CharacterBody3D` (API de Godot 4.7.2) : `move_and_slide()`, `is_on_floor()`,
  `get_floor_normal()`, `get_slide_collision()`.
- Le kart d'origine : GDWaterKart (JorisAR, licence MIT), `3_entities/kart/kart.gd` du projet rangé, dont
  les formules de conduite sont reprises.

## Étape suivante

Étape 003 : la caméra qui suit le kart, à la souris et au stick droit.
