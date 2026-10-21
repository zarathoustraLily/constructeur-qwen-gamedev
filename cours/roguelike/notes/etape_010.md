# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Les ennemis ne sont plus posés à la main : une vague les fait apparaître un à un, autant
que la courbe de difficulté le dit pour le rang du niveau. Quand le dernier tombe, la sortie s'ouvre : une
sphère noire au contour lumineux, surmontée d'une colonne de lumière. L'atteindre lance la vague suivante, plus
nombreuse.

Ce qu'on obtient : une boucle de jeu. Trois ennemis au premier rang, quatre ou plus au suivant…

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Deux secondes et demie plus tard, le premier ennemi apparaît ; puis un par seconde. Les vaincre tous :
   la sortie apparaît au fond de la salle. Y entrer : retour au départ, vague suivante.
3. Ouvrir `5_data/levels/wave.tres` et cliquer sur sa courbe `difficulty` : on la redessine à la souris.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. La vague : un objectif du niveau

`2_sequence/levels/wave_objective.gd` (`WaveObjective`) vit dans `2_sequence` : c'est un objectif du déroulé,
pas un acteur. `start(rang)` prépare la vague :

- le nombre d'ennemis vient de la courbe (`WaveSettings.enemy_count(rang)`, la partie entière de
  `difficulty.sample(rang)` : 3 au rang 1) ;
- la sorte de chaque ennemi est tirée parmi `enemy_scenes`. Ces scènes sont données par la scène du niveau :
  une donnée de `5_data` n'a pas le droit de connaître les acteurs ;
- un `Timer` (`SpawnTimer`) les fait apparaître : `first_delay` (2,5 s), puis un tous les `interval` (1 s). Un
  `Timer` s'arrête en pause (règle SIM-08).

Chaque ennemi apparu est signalé (`enemy_spawned`) : la scène lui pose sa barre et branche ses dégâts sur les
chiffres, comme à l'étape 9. Quand le dernier est vaincu, la vague l'est aussi (`cleared`).

### 2. Où apparaître, de façon reproductible

Le jeu d'origine faisait apparaître chaque ennemi à un point au hasard de la navigation, choisi par l'ennemi
lui-même avec le hasard du moteur. Ici, c'est la vague qui choisit, avec sa graine : une place dans un carré
de 7 m de demi-côté autour d'elle, posée sur la navigation (`map_get_closest_point`), à 1 m au-dessus du sol
(le centre de la capsule). La vague donne aussi à chaque ennemi sa propre graine (`rng.randi()`) : deux ennemis
de la même sorte n'errent pas pareil, et une partie rejouée refait la même vague.

Les ennemis pas encore apparus n'ont pas de parent : si la vague disparaît avant la fin (le niveau quitté),
elle les libère elle-même (`NOTIFICATION_PREDELETE`). Le jeu d'origine avait cette fuite ; son rangement l'avait
déjà corrigée.

### 3. La sortie

`3_entities/interactables/exit_point/` (`ExitPoint`) : cachée et fermée au départ ; `unlock()` l'ouvre. Le
joueur qui y entre la signale (`reached`), une seule fois : il est reconnu à son groupe « player », la sortie ne
connaît pas sa classe. Son animation `Exit` remplit la colonne de lumière et lâche un anneau, puis la sortie se
cache. Le jeu d'origine passait le niveau suivant depuis la sortie elle-même (`GameState.finish_level()`) ; ici
la sortie ne fait que signaler, et c'est la scène qui décide.

La sphère est noire, avec un contour blanc obtenu par le **stencil** : son matériau est en mode `Outline`
(`stencil_mode = 1`, `stencil_outline_thickness`), et Godot lui ajoute lui-même un second passage (`next_pass`),
un peu gonflé (`grow`), qui ne se dessine que là où la sphère n'a pas marqué le stencil : un contour net, sans
shader. La référence prévient : ce second passage est refait par Godot, on ne le modifie pas à la main.

### 4. Le shader de la colonne

`6_assets/shaders/spawn_point.gdshader` réécrit le VisualShader `spawn_point.tres` du jeu d'origine : un dégradé
de haut en bas plus un bruit qui monte (`TIME`), et ne reste que ce qui dépasse `cutoff`. L'animation `Exit`
descend `cutoff` de 0,41 à 0 : la colonne se remplit de lumière. Le paramètre s'appelait « Cuttoff » ; il
s'écrit maintenant `cutoff`. `unshaded` et `depth_prepass_alpha` : une lumière pure, bien triée avec la
profondeur malgré sa transparence.

Vérifié contre l'original : 0 pixel différent sur la colonne seule, à mi-remplissage, à deux instants.

### 5. La boucle, en attendant le chef d'orchestre

Sortie atteinte : `main.gd` remet le joueur au départ, monte le rang (`level_rank`) et relance la vague. Il ne
charge pas d'autre scène : ce sera le rôle du chef d'orchestre, l'autoload `GameFlow`, à l'étape 12.

## Les tests

- `2_sequence/levels/test_wave_objective.gd` : trois ennemis au premier rang ; personne avant le premier délai,
  puis un par intervalle ; tous vaincus, la vague l'est ; même graine, même vague (sortes et places) ; les
  ennemis pas encore apparus partent avec elle (GdUnit signale les nœuds orphelins) ;
- `3_entities/interactables/exit_point/test_exit_point.gd` : cachée et fermée ; `unlock()` ; le joueur la
  signale une fois ; un autre corps, ou une sortie fermée, rien ;
- `2_sequence/test_main.gd` : la vague fait apparaître ses ennemis, chacun avec sa barre ; vaincue, elle ouvre
  la sortie ; la sortie atteinte, une vague plus nombreuse commence.

## Ce qu'il faut retenir

- Un objectif de niveau dans `2_sequence` ; ses acteurs lui sont donnés par la scène.
- Une `Curve` dans une ressource : la difficulté se dessine, elle ne s'écrit pas.
- Le hasard de la vague a une graine, et il la transmet aux ennemis.
- La sortie signale ; la scène décide de la suite.
- Le stencil en mode `Outline` : un contour sans shader.

## À essayer

- Redessiner la courbe de `wave.tres` pour qu'elle monte à 10 dès le rang 2.
- Passer `interval` à 0,1 : la vague tombe d'un coup.
- Dans `spawn_point.gdshader`, remplacer `TIME` par `-TIME` : le bruit de la colonne descend.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : vague (délais 2,5 s et 1 s, sortes tirées parmi
  deux), courbe de difficulté (3 à 20), libération des ennemis non apparus, sortie (sphère au contour par
  stencil, colonne, anneau, animation `Exit`), shader `spawn_point.tres`.
- Documentation de Godot 4.7 : référence de `Curve` (`sample`) ; référence de `BaseMaterial3D`
  (`STENCIL_MODE_OUTLINE` et sa note sur `next_pass`, `stencil_outline_thickness`).
- Références des classes `Timer`, `NavigationServer3D` (`map_get_closest_point`), `Area3D` : API de Godot 4.7.2.

## Étape suivante

Étape 011 : les trois niveaux. Un modèle commun, trois salles qui en héritent, chacune avec son éclairage
global précalculé (VoxelGI).
