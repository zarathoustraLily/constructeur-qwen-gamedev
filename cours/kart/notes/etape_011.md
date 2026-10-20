# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Il pleut sur l'île. La route se mouille, brille et éclabousse sous les roues ; les gouttes
dessinent des anneaux sur la mer ; le soleil faiblit, le brouillard s'épaissit. Pendant l'averse, la foudre
frappe le kart de temps en temps.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (Forward+).
2. F5 : il pleut dès le départ. Rouler sur la piste : des gouttelettes jaillissent derrière les roues.
3. Attendre : entre 6 et 14 secondes plus tard, un éclair frappe le kart.
4. La météo : `5_data/weather/storm.tres`.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. La météo est de la logique

`1_core/weather/weather.gd` (`Weather`) tient l'état du ciel. Sa force de pluie vient des réglages. Le
mouillage de la route la rejoint à 0,15 par seconde : la route sèche ou se mouille avec retard. S'il pleut au
départ, la route part mouillée. `update(delta)` fait avancer tout cela et dit si un éclair tombe. Sous une
averse (force 0,5 ou plus), les éclairs tombent à des délais pris entre 6 et 14 s, avec un
`RandomNumberGenerator` à graine : un même orage, éclair pour éclair.

La météo n'est pas un nœud : c'est un objet que la scène principale possède et fait avancer à chaque pas
de physique.

### 2. La scène principale distribue la météo

Dans `2_sequence/main.gd`, à chaque pas :

- `GameState.rain_intensity` et `GameState.rain_wetness` reçoivent la pluie et le mouillage : GameState les
  passe aux paramètres globaux de shader du même nom (`project.godot`) ;
- la pluie dessinée (`Rain`) reçoit la force de la pluie ;
- les roues du kart (`WheelEffects`) reçoivent le mouillage : la route mouillée de l'étape 010 éclabousse
  enfin ;
- quand l'orage le décide, un éclair (`LightningStrike`) est lancé sur le kart.

La pluie et les roues sont des entités : elles ne peuvent pas lire GameState (règle des dossiers). La scène
leur donne ce qu'il faut savoir.

### 3. Les shaders lisent la pluie

Les paramètres globaux `rain_intensity` et `rain_wetness` arrivent dans trois shaders, par
`rain_ripples.gdshaderinc` :

- la piste (`stylized_shader.gdshader`, matériaux à `rain_receiver` 1), là où elle est à plat : mouillée,
  elle s'assombrit et brille ; des flaques plates s'y forment, et les gouttes y dessinent leurs anneaux ;
- la mer (`water_surface.gdshader`) se couvre d'anneaux d'impact, qui changent ses normales et blanchissent
  un peu sa couleur ;
- les traits de pluie (`rain_drop.gdshader`).

### 4. La pluie dessinée

`3_entities/effects/rain/rain_view.gd` (`RainView`) émet 9 000 traits de pluie au-dessus de la caméra
(`GPUParticles3D`). Elle se place un peu en avant du déplacement de la caméra : il pleut devant le kart lancé.
Sous l'averse, elle retire jusqu'à 35 % de l'énergie du soleil et épaissit le brouillard. En partant, elle
rend leur valeur au soleil et au brouillard. Le soleil et l'environnement lui sont donnés par la scène ; le
script d'origine les cherchait dans tout l'arbre.

### 5. L'éclair

`3_entities/effects/lightning/lightning_strike.gd` (`LightningStrike`) dessine un éclair procédural :

- un zigzag par déplacement de points médians : chaque génération coupe les segments en deux et décale le
  milieu, d'une amplitude divisée par deux ;
- cinq ramifications, puis des arcs électriques autour du kart ;
- le tout redessiné toutes les 0,05 s, d'où le scintillement.

Les rubans font face à la caméra (`ImmediateMesh`, `lightning.gdshader`). À l'impact, une lumière flashe, un
éclat grandit et une gerbe d'étincelles part. Le bas de l'éclair suit le kart, même lancé. L'éclair se
supprime une fois éteint. Sa forme vient d'une graine, comme l'orage.

## Les tests

- `1_core/weather/test_weather.gd` : la route part mouillée s'il pleut ; le mouillage rejoint la pluie ; les
  éclairs tombent entre les deux délais ; sous une pluie faible, aucun ; une même graine, le même orage.
- `3_entities/effects/rain/test_rain_view.gd` : la pluie tombe quand on lui donne une force ; le soleil faiblit
  et le brouillard s'épaissit, puis tout revient ; elle suit la caméra.
- `3_entities/effects/lightning/test_lightning_strike.gd` : l'éclair frappe sa cible et la suit, flashe, puis
  se supprime.
- `2_sequence/test_main.gd` : la météo arrive aux shaders, à la pluie et aux roues ; l'orage lance des éclairs
  sur le kart.
- `0_autoload/test_game_state.gd` : la pluie et le mouillage ont leur paramètre global.

## Ce qu'il faut retenir

- Un état du jeu (la météo) vit dans la logique ; la scène le distribue à ceux qui le montrent.
- Une entité ne cherche rien dans tout l'arbre : ce dont elle dépend lui est donné.
- Un hasard à graine rend un orage et un éclair rejouables, donc comparables image par image.
- Une valeur qui en suit une autre avec retard : `move_toward`, à vitesse fixe.

## À essayer

- Dans `storm.tres`, passer `intensity` à 0 : plus de pluie, de route mouillée ni d'éclairs.
- Passer `lightning_interval_min` et `lightning_interval_max` à 1 et 2 : un orage déchaîné.

## Source

- La pluie, les anneaux et l'éclair viennent du kart d'origine (GDWaterKart, JorisAR, licence MIT) ; l'éclair,
  du tutoriel « Godot 4 - 3D Electric Lightning Shader for beginners ».
- Références des classes (API de Godot 4.7.2) : `RandomNumberGenerator`, `GPUParticles3D`, `ImmediateMesh`,
  `OmniLight3D`, `Environment.fog_density`.
- Documentation de Godot 4.7, *Shading language* (`tutorials/shaders/shader_reference/shading_language.rst`) :
  les `global uniform`.

## Étape suivante

Étape 012 : les poissons. Des bancs de poissons procéduraux nagent autour de l'île.
