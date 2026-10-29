# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Dans un combat exigeant, le joueur décide en lisant ses jauges : il reste combien de vie, assez
d'endurance pour rouler, l'arme va-t-elle surchauffer, combien de fioles, et où en est le boss. La référence de laurent
(Dark Souls 1) range ces informations à des places que l'œil trouve sans chercher : le héros en haut à gauche, les
objets en bas à gauche, le boss en bas, au centre. On reprend ces places, avec une interface à nous.

Ce qu'on obtient : en haut à gauche, trois jauges empilées (vie rouge sombre, endurance verte, chaleur de l'arme
orange) ; quand on perd de la vie, une traîne claire montre un instant ce que le coup a enlevé, puis rejoint la
valeur ; en bas à gauche, une fiole dessinée et le nombre qui reste ; en bas, le nom du Gardien et sa longue jauge ; à
la chute, un voile sombre et le mot « TERRASSÉ », en fondu, pendant que le niveau attend de recommencer.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : tirer sur le golem fait descendre sa jauge ; rouler et sprinter vident l'endurance ; tirer longtemps remplit la
   chaleur ; boire une fiole (X) en retire une.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. La règle des dossiers décide de l'architecture

Le plan du projet dit ce dont chaque dossier peut dépendre : `4_ui/` peut connaître `0_autoload/`, `1_core/` et
`6_assets/`, **pas** `3_entities/` ni `5_data/`. L'interface ne connaît donc ni le héros ni le golem : elle connaît
leurs **composants** (`HealthComponent`, `StaminaComponent`, `HeatComponent`, `FlaskComponent`, dans `1_core/`), qui
annoncent leurs changements par des signaux. C'est la scène principale (`2_sequence/`, qui peut dépendre de tout) qui
branche l'interface sur les composants du héros et du golem (`bind_health`, `bind_stamina`, `bind_heat`,
`bind_flasks`, `bind_boss`) et qui lui donne ses réglages (`5_data/ui/hud.tres`). Changer de héros ou de boss ne
touche pas l'interface.

### 2. Une jauge ne sait rien de ce qu'elle mesure

`StatBar` (`4_ui/hud/stat_bar/`) reçoit une valeur et son maximum (`set_values`), et dessine fond, traîne, remplissage
et cadre (`_draw`). Elle sert quatre fois : vie, endurance, chaleur, vie du boss ; seules les couleurs changent (dans
la scène). Les signaux des composants ont déjà la forme qu'il faut : `changed(current, maximum)` se branche
directement sur `set_values`. Pour la santé, qui annonce `damaged(montant, reste)`, une petite fonction anonyme passe
le reste et le maximum.

**La traîne** : après une perte, elle reste à l'ancienne valeur pendant `trail_delay`, puis la rejoint à
`trail_speed` ; un gain la remonte avec la valeur. Le temps qui reste dans l'image une fois le délai fini sert à
avancer (comme l'endurance et la chaleur des étapes 4 et 5) : la traîne ne dépend pas de la cadence.

### 3. Les autres morceaux

- `FlaskCounter` : une fiole dessinée (corps rond, col, liquide ambré) et le nombre ; sans fiole, le tout s'éteint à
  moitié.
- `BossBar` : le nom et la jauge du boss, cachés jusqu'à `reveal` ; à cette étape, le golem se montre dès le début (son
  réveil viendra avec son combat).
- `DefeatScreen` (`4_ui/overlays/`) : voile et mot, en fondu sur `defeat_fade_time` ; la scène principale le montre
  quand le héros tombe, pendant le délai avant de recommencer.
- `Hud` : un `CanvasLayer` qui place tout (jauges ancrées en haut à gauche, fioles en bas à gauche, boss en bas au
  centre, écran de chute plein écran) et pose la traîne de ses réglages sur ses quatre jauges.

Les textes et les délais sont des réglages (`HudSettings`, `5_data/ui/hud.tres`), jamais écrits dans un script.

### 4. Ce que la capture a appris

La première capture (960 × 540) montrait deux défauts que les tests ne voyaient pas :
- **l'interface ne suivait pas la fenêtre** : placée en pixels pour 1920 × 1080, elle débordait (le nom du boss coupé
  et posé sur les fioles). Le projet n'étirait rien (`window/stretch/mode` valait « disabled »). La documentation
  (guide « Multiple resolutions ») recommande, pour une vue 3D en haute résolution, le mode `canvas_items` : réglé avec
  l'aspect `expand`, l'interface s'étire et la 3D garde la résolution de la fenêtre ;
- **une traîne au démarrage** sur la jauge de chaleur : les jauges partent pleines, et le premier branchement (chaleur
  à 0) passait pour une perte. Le premier branchement pose la valeur d'un coup (`snap`), traîne comprise.

La capture se fait en Compatibilité (le moteur le plus léger, la carte graphique étant occupée par un autre travail) :
ce moteur ne gère pas la brume volumétrique (« shader type fog not supported in OpenGL renderer ») ; le jeu, lui,
tourne en Forward+.

### 5. Les tests

- La jauge : bornes, traîne qui attend puis rejoint, gain qui remonte la traîne, maximum nul, pose d'un coup.
- Les fioles, la jauge du boss (cachée, montrée à son nom), l'écran de chute (caché, fondu, fondu nul).
- L'interface branchée sur de vrais composants : chaque jauge part de leur valeur et suit leurs changements.
- La scène principale : un coup au héros, un tir qui chauffe, une fiole bue, un coup au golem se lisent dans
  l'interface ; la chute montre l'écran de chute.

Chaque widget se teste sans fenêtre : on lit les valeurs (`ratio`, `trail_ratio`, le texte, `modulate.a`) au lieu de
regarder des pixels ; l'image se juge à part, sur une capture.

Avec les cas des étapes précédentes : 161 cas verts.
