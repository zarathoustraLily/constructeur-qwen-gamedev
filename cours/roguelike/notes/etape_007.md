# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Deux ennemis armés d'une massue entrent dans la salle. Ils trouvent le chemin jusqu'au
héros en contournant le trou, frappent quand il est à portée, chancellent quand l'épée les touche, et,
vaincus, se couvrent d'un écho blanc avant de disparaître.

Ce qu'on obtient : un vrai combat. Les ennemis encaissent quatre coups environ (40 points de vie), le héros
supporte sept coups de massue (60 points, 8 par coup). Vaincu, il revient au départ, comme à l'étape 6.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Attendre les ennemis, frapper (clic gauche) quand ils approchent. Esquiver (Espace) leur massue.
3. Dans l'éditeur, cocher Débogage > Navigation visible : la surface où les ennemis peuvent marcher apparaît.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un ennemi, en trois scènes

- `3_entities/enemy/animated_enemy.tscn` : le modèle `Enemy_Medium` (paquet KayKit des ennemis), son
  `AnimationPlayer` et son arbre d'animation (`AnimationTreeView`, le même script que le joueur) : marche,
  coup reçu (`Stun`), défaite (`Defeat`), coup de massue (`MeleeAttack`). Ses emplacements d'arme et de pieds
  reprennent `WeaponSlot` et `FootBone` de `1_core/animation/` : c'est pour cela qu'ils y vivent depuis l'étape 3.
- `3_entities/enemy/enemy.tscn` : l'ennemi de base. Un `CharacterBody3D` sur les couches 1 et 2 (corps et
  ennemis, `collision_layer = 3`), les composants de santé (40) et de recul de l'étape 6, une machine à états,
  un `NavigationAgent3D`, et sa vue.
- `3_entities/enemy/melee_enemy.tscn` hérite de l'ennemi de base (`instance=` sur la racine) et ajoute la
  massue (une zone de coup qui vise la couche du joueur, `collision_mask = 16`), la poursuite et l'attaque.

Les ennemis vivent dans `3_entities/enemy/`, autour de `enemy.tscn`. Le juge des règles reconnaît une entité au
dossier qui porte une scène de son nom : sans `enemy.tscn` au bon endroit, le sous-dossier `states/` serait une
autre entité, et l'ennemi n'aurait pas le droit d'en dépendre.

### 2. Une cible, pas un joueur

L'ennemi cherche sa cible dans le groupe « player » (`get_first_node_in_group`) et la garde comme un simple
`Node3D`. Il ne connaît pas la classe `Player` : une entité n'en connaît pas une autre (règle des dossiers), et
les groupes restent permis (règle ARC-06). Tout ce qu'il lui faut, c'est une position.

### 3. Trouver son chemin : la navigation

La salle a maintenant une `NavigationRegion3D`, qui porte le maillage de navigation du niveau d'origine (les
surfaces où l'on peut marcher, calculées une fois pour toutes ; les deux grilles deviennent ses enfants). Chaque
ennemi a un `NavigationAgent3D`. À chaque image de poursuite, l'état donne la position de la cible
(`target_position`) et l'agent répond par le prochain point du chemin (`get_next_path_position()`) : l'ennemi
contourne le trou au lieu de foncer droit dedans.

### 4. La machine à états de l'ennemi

`3_entities/enemy/states/` : la même machine à états que le joueur (étape 2), d'autres états.

- `EnemyPursue` : court vers la cible par la navigation ; à portée (3 m), attaque.
- `EnemyAttack` : s'arrête et joue l'animation du coup. Sa massue frappe ce que sa zone touche, quand
  l'animation l'active (comme l'épée de l'étape 6). À la fin, il tire au sort l'état suivant parmi
  `next_states`, avec le `RandomNumberGenerator` de l'ennemi, à graine (règle SIM-09).
- `EnemyStun` : touché, joue le coup reçu et suit son recul, puis reprend.
- `EnemyDefeat` : vaincu, ne bouge plus.
- `EnemyWait` et `EnemyFall` : l'attente (pour l'ennemi à distance, à l'étape 8) et la chute.

Vitesse (3,5 m/s), portée (3 m) et attente (2 s) sont dans `5_data/enemies/melee_enemy.tres`
(`EnemySettings`) ; dégâts (8) et recul (20 m/s) du coup de massue, dans `melee_chop.tres` (le même
`AttackSettings` que les coups du joueur).

Dans le jeu d'origine, chaque état vérifiait le sol **avant** de bouger. Or `is_on_floor()` ne sait rien tant
que `move_and_slide()` n'a pas tourné : à sa première image, l'ennemi se croyait en l'air, tombait d'une image,
« atterrissait » et jouait l'animation du coup reçu. Ici, `move_enemy()` bouge d'abord et regarde le sol ensuite.

### 5. Deux scripts qui se citent : une fuite

`Enemy` désigne ses états d'étourdissement et de défaite. Typés `EnemyState`, ils faisaient de `Enemy` et
`EnemyState` deux scripts qui se citent l'un l'autre, et Godot les gardait en mémoire jusqu'à sa sortie :
l'import du projet finissait par « 110 resources still in use at exit ». Il a fallu chercher : retirer les
fichiers un par un d'une copie, jusqu'à trouver le couple. L'ennemi n'a besoin que du nom de ces états : ils sont
typés `State`, la classe de base de `1_core`, et la fuite a disparu.

### 6. L'écho de défaite

`6_assets/shaders/defeat_echo.gdshader` réécrit en code le VisualShader `defeat_echo.tres` du jeu d'origine.
Ce dernier le fournissait sans s'en servir ; le cours lui donne un usage. Une silhouette blanche sans éclairage
(`unshaded`, `ALBEDO = vec3(1.0)`) dont l'`ALPHA` vaut `step(1 - dissolve_amount, bruit)` : à 0, rien ; à 1,
tout le corps.

La vue de l'ennemi (`enemy_view.gd`) le pose à la défaite en **surcouche** (`material_overlay`) sur chaque maillage
du modèle : la surcouche se dessine par-dessus le matériau d'origine, sans le remplacer. Chaque ennemi reçoit
sa copie du matériau (`duplicate()`) : un matériau partagé ferait blanchir tous les ennemis à la fois. Un
`Tween` monte l'écho de 0 à 1 en 0,8 s, puis le modèle disparaît.

Comme pour la traînée, la réécriture a été vérifiée contre l'original : 0 pixel différent sur une sphère
couverte de l'écho à mi-chemin.

La vue joue aussi le son du coup reçu : le composant de santé n'en joue plus (étape 6).

### 7. Une vue qui attend son ennemi

La vue est un enfant de l'ennemi : Godot la rend prête avant lui (les enfants d'abord). À cet instant, les
champs `@onready` de l'ennemi, dont `health_component`, sont encore vides. La vue attend donc l'ennemi
(`await enemy.ready`) avant de se brancher sur sa santé.

## Les tests

- `3_entities/enemy/test_enemy.gd`, dans une arène posée en code (un sol, une cible du groupe « player ») :
  la cible est trouvée ; à portée, la massue blesse la cible ; touché, l'ennemi chancelle puis reprend la
  poursuite ; vaincu, il le signale, ne bloque plus et ne bouge plus ; réglages et graine viennent des données ;
- `3_entities/enemy/test_enemy_view.gd` : le son du coup reçu ; l'écho monte puis le modèle disparaît ;
- `2_sequence/test_main.gd` : dans la salle, les ennemis se rapprochent du joueur.

Deux rendus d'un même combat (mêmes touches, mêmes images) sont identiques au pixel près.

## Ce qu'il faut retenir

- Une scène de base et des scènes qui en héritent : l'ennemi au corps à corps ajoute son arme et ses états.
- La navigation : une région, un maillage précalculé, un agent qui donne le prochain point du chemin.
- Une entité trouve une autre par un groupe, sans connaître sa classe.
- `material_overlay` ajoute un effet par-dessus un modèle sans toucher à ses matériaux.
- Deux scripts qui se citent mutuellement restent en mémoire : typer par la classe de base.

## À essayer

- Passer `speed` à 7 dans `melee_enemy.tres` : les ennemis rattrapent le héros en course.
- Retirer la `NavigationRegion3D` (ses grilles restent) : les ennemis ne savent plus où aller.
- Dans `defeat_echo.gdshader`, remplacer `vec3(1.0)` par `vec3(1.0, 0.2, 0.2)` : l'écho devient rouge.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : ennemi de base et au corps à corps (santé 40,
  vitesse 3,5, portée 3, massue : dégâts 8, recul 20), états, maillage de navigation du niveau, shader
  `defeat_echo.tres` (fourni, non employé) ; modèle et animations KayKit (GameDev.tv Enemies Character Pack).
- Documentation de Godot 4.7 : *Using NavigationAgents* (`tutorials/navigation/navigation_using_navigationagents.rst`) ;
  *Spatial shaders* (`tutorials/shaders/shader_reference/spatial_shader.rst`), mode `unshaded`.
- Références des classes `NavigationAgent3D`, `NavigationRegion3D`, `GeometryInstance3D` (`material_overlay`),
  `RandomNumberGenerator` (API de Godot 4.7.2).

## Étape suivante

Étape 008 : les ennemis à distance. Ils errent, s'arrêtent, et lancent des boules de feu, dessinées par le
shader de feu.
