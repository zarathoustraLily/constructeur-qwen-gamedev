# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le héros apprend à esquiver : un bond très rapide dans la direction de sa marche,
qui laisse derrière lui une traînée turquoise dessinée par un shader, avec un son. Une recharge empêche
d'esquiver en boucle.

Ce qu'on obtient : en marchant, Espace (ou A, ou la gâchette gauche) fait bondir le mannequin de 5 m en un
dixième de seconde. Une traînée de bruit coloré apparaît derrière lui et s'efface en une demi-seconde.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Marcher, puis Espace : esquive. À l'arrêt, Espace ne fait rien. Deux appuis très rapprochés : la
   seconde esquive attend la recharge (0,3 s).
3. Ouvrir `6_assets/shaders/dash.gdshader` : le shader de la traînée, en code.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un nouvel état : l'esquive

`3_entities/player/states/player_dash.gd` (`PlayerDash`) rejoint la course et la chute. En entrant, il appelle
`player.start_dash()` avec la direction de la marche **ramenée à une longueur de 1** : à la manette, un stick
poussé à moitié fait marcher à moitié vitesse (étape 2), mais esquive aussi loin. Il lance aussi l'animation
`DodgeForward` (`change_immediate`), puis laisse le joueur filer (`move_and_slide`) jusqu'à la fin de son
minuteur `DashDuration`, et rend la main à la course.

C'est la course qui décide d'esquiver : si la commande `dash` vient d'être donnée et que `can_dash()` le
permet (le joueur marche, la recharge est finie), elle passe à l'esquive.

### 2. Durées en nœuds Timer, valeurs en données

La durée (0,1 s), la recharge (0,3 s) et la vitesse (50 m/s) vivent dans `player_settings.tres`. Deux nœuds
`Timer` les comptent : `DashDuration` (dans l'état) et `DashCooldown` (dans le joueur). Le joueur règle la
recharge au démarrage (`wait_time = settings.dash_cooldown`) ; l'état donne sa durée en le lançant
(`start(settings.dash_duration)`).

Un `Timer` s'arrête quand le jeu est en pause : une recharge ne s'écoule pas pendant le menu (règle SIM-08).

### 3. Ce qui se voit et s'entend : la vue du joueur

L'esquive se voit (une traînée) et s'entend (un son). Le jeu d'origine jouait les deux depuis l'état
d'esquive. Ici, la logique ne connaît ni son ni effet (règle ARC-03). Le joueur **signale** l'esquive :
`signal dashed(direction)`. Un nœud de présentation, `View` (`3_entities/player/player_view.gd`,
`PlayerView`), écoute ce signal et :

- tourne le support de la traînée (`DashRoot`) vers la direction de l'esquive (`look_at`) ;
- rejoue l'animation `dash`, qui fait passer le paramètre `threshold` du shader de 0 à 1 en 0,5 s ;
- joue le son `dash.ogg`.

Godot avertit d'un signal « jamais employé » s'il n'est pas émis dans la classe qui le déclare : c'est donc
`start_dash()`, une fonction du joueur, qui émet `dashed`, et non l'état.

### 4. Le shader de la traînée, en code

Le jeu d'origine dessinait la traînée avec un **VisualShader** (`Dash.tres`), un graphe de nœuds. L'éditeur de
Godot montre le code qu'il en tire (le dernier bouton de sa barre d'outils) ; on l'a réécrit à la main, avec
des noms parlants, dans `6_assets/shaders/dash.gdshader`. Ligne à ligne :

- `shader_type spatial` : un shader pour une surface 3D ; `cull_disabled` : les deux faces du quad se voient ;
- les paramètres (`uniform`) : `speed`, la texture de bruit, la texture de dégradé, `threshold`. Le guide de
  style des shaders les nomme en snake_case : le graphe d'origine disait `Speed`, `NoiseTexture`,
  `GradientParameter`, `Threshold`.
- `UV.x` va de 0 (contre le joueur) à 1 (au bout de la traînée). Le bruit est lu à `UV + (UV.x − TIME ×
  speed, 0)` : il défile le long du quad avec le temps.
- `trail = bruit − UV.x` : plus on s'éloigne du joueur, plus la traînée s'amincit.
- `glow = (1 − UV.x)^5 + trail` : de l'éclat en plus tout contre le joueur ; `smoothstep(0, 2, glow)` choisit
  la couleur dans le dégradé (`gradient_texture`, du turquoise clair au foncé). Cette couleur sert de base
  (`ALBEDO`) et de lumière propre (`EMISSION`).
- `ALPHA = step(threshold, trail)` : ne reste que le bruit au-dessus du seuil. Quand l'animation monte
  `threshold` de 0 à 1, la traînée s'effrite puis disparaît.

Les deux quads (`VerticalTrail`, debout, et `GroundTrail`, à plat) partagent le même matériau : une seule
piste d'animation efface les deux.

### 5. Vérifié au pixel près

Le shader réécrit doit dessiner exactement ce que dessinait le graphe. La fabrication du cours a rendu les
mêmes images d'une esquive deux fois, l'une avec `dash.gdshader`, l'autre avec le `Dash.tres` d'origine
(paramètres renommés en conséquence) : 0 pixel différent sur quatre images où la traînée se voit. Une image en
rendu Compatibilité confirme que le shader s'y compile aussi.

## Les tests

- `3_entities/player/test_player.gd` : à l'arrêt, pas d'esquive ; l'esquive lance vite dans la direction de
  la marche, puis la course reprend ; elle est signalée avec une direction de longueur 1, même stick à moitié ;
  la recharge empêche une seconde esquive aussitôt, puis la permet ;
- `3_entities/player/test_player_view.gd` : sans esquive, la traînée est effacée ; une esquive tourne la
  traînée, joue l'animation et le son, et la traînée s'efface en une demi-seconde.

## Ce qu'il faut retenir

- Un état par comportement : l'esquive a le sien, et la course décide d'y entrer.
- Les durées de jeu dans des `Timer`, leurs valeurs dans les données.
- La logique signale, la vue joue les effets et les sons.
- Un VisualShader est du code de shader : on peut le lire, le réécrire, et vérifier la réécriture au pixel.
- `step(seuil, valeur)` dans `ALPHA` : un effacement progressif, piloté par un seul paramètre.

## À essayer

- Dans `dash.gdshader`, remplacer `pow(1.0 - UV.x, 5.0)` par `pow(1.0 - UV.x, 1.0)` : toute la traînée devient
  claire.
- Passer `speed` à 0 sur le matériau : le bruit ne défile plus, la traînée est figée.
- Passer `dash_cooldown` à 0 dans `player_settings.tres` : on esquive en rafale.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : esquive (50 m/s, 0,1 s, recharge 0,3 s), traînée
  (deux quads, bruit, dégradé, animation de 0,5 s), son `dash.ogg`, animation `Dodge_Forward` (KayKit).
- Documentation de Godot 4.7 : *Using VisualShaders* (`tutorials/shaders/visual_shaders.rst`), qui montre où
  lire le code d'un graphe ; *Shaders style guide* (`tutorials/shaders/shaders_style_guide.rst`), snake_case
  des variables ; *Spatial shaders* (`tutorials/shaders/shader_reference/spatial_shader.rst`) pour `UV`,
  `TIME`, `ALBEDO`, `EMISSION`, `ALPHA`.
- Références des classes `Timer`, `AnimationPlayer`, `Node3D` (`look_at`) : API de Godot 4.7.2.

## Étape suivante

Étape 006 : le combat. Trois coups enchaînés, une santé, le recul, et l'effet de lame de l'épée.
