# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un troisième ennemi rejoint la salle : sans arme, il erre, s'arrête, et lance des boules
de feu. La boule file droit, brûle ce qu'elle touche, et éclate en étincelles contre un mur ou une cible. Ses
flammes sont dessinées par un shader de particules.

Ce qu'on obtient : un ennemi qu'on ne peut plus ignorer à distance. Chaque boule retire 5 points et repousse ;
on l'évite en esquivant, ou en se mettant à l'abri d'un mur.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Repérer l'ennemi sans massue : il s'arrête, lève le bras, et la boule part. Esquiver (Espace) ou
   contourner un mur.
3. Ouvrir `3_entities/enemy/fireball/fireball.tscn` et sélectionner `Flames` : les particules jouent dans
   l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. L'ennemi à distance

`3_entities/enemy/ranged_enemy.tscn` hérite de l'ennemi de base, comme celui au corps à corps, avec son script
`ranged_enemy.gd` (`RangedEnemy`, qui étend `Enemy` : `super._ready()` garde le démarrage de l'ennemi). Il part
en errance (`EnemyMeander`) ; à portée (4 m) ou arrivé au but, il tire (`EnemyAttack`, animation
`RangedAttack`) ; puis il tire au sort : attendre (`EnemyWait`, 2 s, puis tirer encore) ou repartir en errance.
Ses réglages sont dans `5_data/enemies/ranged_enemy.tres`, avec sa propre graine.

### 2. C'est l'animation qui tire

L'animation `Melee_1H_Attack_Slice_Diagonal.res` contient une piste d'appel de méthode : à l'instant où le bras
s'abat, elle appelle `emit_signal("ranged_attack")` sur l'emplacement de l'arme (`WeaponSlot`, le signal
déclaré à l'étape 3 pour cela). `RangedEnemy` écoute ce signal et lance la boule : depuis l'arme, dans la
direction où regarde le modèle. L'état d'attaque ne sait pas qu'il tire : il joue l'animation.

### 3. Errer, de façon reproductible

L'errance choisit un but au hasard. Le jeu d'origine prenait un point au hasard sur toute la navigation
(`NavigationServer3D.map_get_random_point`), avec le hasard du moteur, qu'aucune graine ne règle. Ici, l'ennemi
tire un angle et une distance (au plus `meander_radius`, 8 m) avec **son** `RandomNumberGenerator`, puis prend
le point de la navigation le plus proche (`map_get_closest_point`). Même graine, même errance (règle SIM-09).

La carte de navigation ne répond pas avant sa première synchronisation : la toute première requête affichait
« navigation map query failed because it was made before first map synchronization ». L'errance attend que
`map_get_iteration_id()` ne vaille plus 0 avant de choisir son but.

### 4. La boule de feu

`3_entities/enemy/fireball/` (la boule fait partie de l'entité ennemi : une entité n'a pas le droit d'en
utiliser une autre) :

- `fireball.gd` (`Fireball`) : un `ShapeCast3D` sans portée (`target_position` nul), qui se teste là où il
  est. À chaque image physique, il avance vers son +Z (8 m/s), frappe avec son `AttackComponent` (5 points,
  15 m/s de recul) et, au premier choc, pose un impact et disparaît. Un `Timer` l'éteint au bout de 10 s.
  `ignore(lanceur)` exclut son lanceur, que la boule traverse au départ ;
- `top_level = true` : enfant de l'ennemi, la boule ne suit pas ses mouvements ;
- `fireball_impact.tscn` : des étincelles (`GPUParticles3D` en un seul jet, `one_shot`, `explosiveness = 1`) et
  un son ; son animation `hit` les lance et, au bout d'une seconde, libère la scène (piste d'appel de méthode
  vers `queue_free`).

La boule vise la couche 1 (son masque par défaut) : le joueur y est (couches 1 et 5), les murs aussi ; les
autres ennemis aussi, comme dans le jeu d'origine : une boule mal visée brûle un allié.

### 5. Le shader de feu

`6_assets/shaders/fire.gdshader` réécrit en code le VisualShader `fire.tres` du jeu d'origine, qui le fournissait
sans s'en servir (sa boule dessinait des sphères colorées). Il dessine les particules de la boule :

- **vertex()** : un *billboard*. La matrice du modèle est remplacée par les axes de la caméra
  (`INV_VIEW_MATRIX`), tournée de l'angle de la particule (`INSTANCE_CUSTOM.x`, que le matériau de particules
  remplit grâce à `angle_min` et `angle_max`) et gardée à son échelle ; le quad fait toujours face à la caméra ;
- un `varying flat int` passe le numéro de la particule (`INSTANCE_ID`) au fragment, sans interpolation ;
- **fragment()** : un bruit qui monte avec le temps, décalé selon le numéro de la particule
  (`sin(id / 100)`), multiplié par `(1 - distance au centre)^5` : la flamme s'éteint vers les bords ; un
  dégradé du rouge au jaune la colore ;
- `threshold` (0,1 ici) coupe ce qui est trop faible : à 0, chaque quad se verrait en entier, comme un carré
  rouge.

Vérifié contre l'original : 0 pixel différent sur trois quads portant le matériau, à trois instants.

### 6. Les particules ne se rejouent pas au pixel

Pour l'A/B, la première scène de test utilisait les particules elles-mêmes. Deux rendus de la **même** version
différaient déjà de 30 000 pixels environ : les particules GPU ne se rejouent pas au pixel près dans les rendus
du cours, même avec `use_fixed_seed`, et même avec `fixed_fps` à 60 sans interpolation. Sans particules, les
mêmes images se rejouent à l'identique. Pour comparer un shader, on le pose donc sur des maillages fixes ; un juge
qui compare des images doit masquer les particules ou choisir des vues sans elles.

## Les tests

- `3_entities/enemy/fireball/test_fireball.gd` : la boule file à la vitesse de ses réglages ; elle blesse une
  cible, laisse un impact, disparaît ; elle épargne son lanceur ; sans rien toucher, elle s'éteint ;
- `3_entities/enemy/test_ranged_enemy.gd` : le signal de l'animation lance une boule depuis l'arme, vers où
  l'ennemi regarde, sans le blesser ; à portée, il tire ; même graine, même but d'errance ;
- `2_sequence/test_main.gd` : dans la salle, l'ennemi à distance finit par tirer.

## Ce qu'il faut retenir

- Une scène qui hérite, un script qui étend : `RangedEnemy` ajoute le tir à `Enemy`, `super._ready()` garde le
  reste.
- Une piste d'appel de méthode choisit l'instant d'un tir, au milieu d'une animation.
- Un hasard qui compte passe par une graine, même pour choisir un point de navigation.
- Un billboard dans un shader : les axes de la caméra à la place de ceux du modèle.
- Les particules GPU ne se comparent pas au pixel.

## À essayer

- Passer `speed` à 3 dans `fireball.tres` : les boules deviennent lentes et faciles à esquiver.
- Passer `threshold` à 0 sur le matériau des flammes : chaque particule devient un carré.
- Passer `random_seed` à 2 dans `ranged_enemy.tres` : l'ennemi erre ailleurs ; deux parties avec cette
  graine restent identiques entre elles.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : ennemi à distance, errance (portée 4), attente
  (2 s), boule de feu (8 m/s, 5 points, recul 15, 10 s) et son impact, sons `fire.ogg` et `fireball-hit.ogg`,
  shader `fire.tres` (fourni, non employé) ; animation KayKit `Melee_1H_Attack_Slice_Diagonal`.
- Documentation de Godot 4.7 : *Spatial shaders* (`tutorials/shaders/shader_reference/spatial_shader.rst`),
  `INSTANCE_CUSTOM`, `INSTANCE_ID`, `MODELVIEW_MATRIX` ; *Using NavigationServer*
  (`tutorials/navigation/navigation_using_navigationservers.rst`).
- Références des classes `GPUParticles3D` (`use_fixed_seed`, `seed`), `NavigationServer3D`
  (`map_get_closest_point`, `map_get_iteration_id`), `ShapeCast3D` (API de Godot 4.7.2).

## Étape suivante

Étape 009 : le retour des coups. Des chiffres de dégâts à l'écran, une barre de santé au-dessus de chaque
personnage, l'écran qui rougit quand le héros est touché.
