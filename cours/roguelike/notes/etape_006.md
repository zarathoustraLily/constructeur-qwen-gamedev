# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le héros apprend à se battre : trois coups qui s'enchaînent (taille, estoc,
tourbillon), une épée qui blesse et repousse, une santé, un recul. La lame laisse un éclat de feu, et la
caméra tremble quand elle touche.

Ce qu'on obtient : clic gauche (ou X, ou la gâchette droite) lance une taille, avec un éclat rouge et jaune ;
un second clic pendant la taille enchaîne l'estoc, un troisième le tourbillon. Tomber du niveau vide la santé :
le héros, vaincu, revient au départ avec toute sa santé.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Clic gauche : taille. Clic, clic, clic en rythme : taille, estoc, tourbillon. Pendant la taille,
   Espace esquive ; pendant le tourbillon, non.
3. Il n'y a encore personne à frapper : les ennemis arrivent à l'étape 7. Les tests posent une cible.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Trois composants, réutilisables

Le combat se construit avec des **composants** : des nœuds sans contenu de jeu, dans `1_core/components/`, que
l'on pose sous un personnage. Le joueur les a dès cette étape, les ennemis les prendront à la suivante.

- `HealthComponent` : une santé (`max_health`, 60 pour le joueur) ; `take_damage()` émet `damage_taken`, puis
  `health_changed`, puis `defeated` à 0 ou moins ; `restore()` rend toute la santé.
- `KnockbackComponent` : un recul qui s'amortit (`1 - exp(-decay × delta)`, le même lissage qu'à l'étape 2).
  Tant qu'il dépasse 1 m/s, le personnage le suit au lieu de sa marche (`PlayerState.core_movement`).
- `AttackComponent` : enfant d'un `ShapeCast3D`, la zone du coup. `deal_damage()` inflige dégâts et recul à
  chaque cible dans la zone, et l'exclut jusqu'à `reset_exceptions()` : un coup ne touche qu'une fois. Il
  émet `struck` pour chaque cible touchée.

Les attaques trouvent les composants de la cible **par leur nom** (`HealthComponent`, `KnockbackComponent`,
enfants directs). Dans le jeu d'origine, le composant de santé jouait lui-même le son du coup reçu : un son dans
la logique (règle ARC-03). Il ne fait plus que signaler.

### 2. Des coups décrits par des données

Chaque coup a ses réglages dans un `.tres` de `5_data/player/attacks/` (`slash`, `stab`, `spin`), de type
`AttackSettings` (`1_core/combat/attack_settings.gd`) : l'animation, les dégâts (10, 14, 10), le recul
(15 m/s), la vitesse de marche pendant le coup, si l'esquive peut l'interrompre, et le délai d'enchaînement
(0,5 s). Dans le jeu d'origine, ces valeurs étaient écrites dans chaque nœud d'état ; ici, changer un coup,
c'est changer son fichier.

Les dégâts passent par `Damage.scaled(base, pourcentage)` (`1_core/combat/damage.gd`), une fonction pure,
testable sans scène (règle SIM-10). La statistique de dégâts du joueur (`damage_stat`, 100 %) part de ses
réglages ; la boutique l'augmentera (étape 13).

### 3. Un état, trois nœuds : l'enchaînement

`3_entities/player/states/player_attack.gd` sert aux trois nœuds `PlayerAttack`, `PlayerAttack2`,
`PlayerAttack3`, chacun avec son `AttackSettings` et son coup suivant (`next_attack`). En entrant, l'état lance
l'animation du coup et un minuteur (`QueueTimer`). Un coup demandé pendant le coup est noté ; quand le minuteur
sonne, s'il y a un coup noté et un coup suivant, on y passe. Sinon, à la fin de l'animation
(`animation_finished`), la course reprend.

Le jeu d'origine lançait ce délai avec `get_tree().create_timer()` sans jamais l'arrêter : un coup interrompu
par une esquive pouvait encore, une demi-seconde plus tard, faire sauter la machine à états au coup suivant,
depuis l'esquive. Ici le délai est un `Timer` que l'état arrête en sortant (`exit()`), avec l'écoute de
l'animation.

La visée vient de `get_aim_direction()` : la visée des commandes (souris ou stick droit) ; à défaut, la marche ;
à défaut, le devant du modèle. C'est le choix fait à l'étape 1 pour la manette.

### 4. C'est l'animation qui frappe

Les animations d'attaque (`Melee_1H_Attack_Slice_Horizontal`, `Melee_1H_Attack_Stab`, `Melee_2H_Attack_Spin`)
écrivent, image par image, trois propriétés de l'emplacement de l'arme (`WeaponSlot`) : `attack_mode`,
`vfx_threshold` et `enabled`. Quand `enabled` passe à vrai, la zone de coup s'active (`shapecast.enabled`) et le
signal `slash` fait jouer le son du coup. L'état d'attaque appelle `deal_damage()` à chaque image ; la zone
ne touche que pendant la partie du coup que l'animation active. Elle est éteinte au départ
(`enabled = false` sur le `ShapeCast3D`).

Dans l'arbre d'animation, chaque coup est un petit `AnimationNodeBlendTree` : l'animation, puis un
`TimeScale` réglé à 1,5. Les coups sont joués une fois et demie plus vite que l'animation d'origine.

### 5. L'éclat de la lame

`3_entities/player/effects/slash_effect.gd` règle un quad posé le long de l'épée, dessiné avec le shader de la
traînée de l'étape 5 (`dash.gdshader`), mais un autre dégradé (rouge, jaune, blanc) et un défilement plus rapide.
Il n'est visible que pendant la taille (`attack_mode` vaut `SLASH`), et son effacement suit `vfx_threshold`,
que l'animation fait varier. Un même shader, deux effets : seuls les paramètres changent. Le script est marqué
`@tool` : dans l'éditeur, jouer l'animation montre l'éclat.

### 6. Toucher se sent

Quand l'épée touche (`struck`), la vue du joueur fait trembler la caméra (`hit_shake`, 0,75). La vue choisit,
la logique ne fait que signaler.

### 7. Tomber coûte la vie

La limite du monde vide désormais la santé de qui y tombe, et le cache. Elle le cache **avant** de vider sa
santé : la scène principale écoute la défaite du joueur et le fait aussitôt réapparaître au départ, visible et
soigné (`restore()`). Dans l'autre ordre, la limite le cacherait juste après sa réapparition.

Pourquoi ne pas recharger le niveau, comme le jeu d'origine ? Parce qu'un seul nœud a le droit de charger des
scènes : le chef d'orchestre, l'autoload `GameFlow`, qui arrive à l'étape 12. D'ici là, la scène remet le joueur
en place.

### 8. Les couches de collision ont un nom

`project.godot` nomme les couches (`[layer_names]`) : 1 « corps » (tout ce qui bute), 2 « ennemis » (ce que
vise l'épée, `collision_mask = 2`), 5 « joueur » (ce que viseront les ennemis). Le joueur est sur les couches 1
et 5 (`collision_layer = 17`, soit 1 + 16).

## Les tests

- `1_core/components/` : santé (départ, ordre des signaux, défaite à 0, `restore`), recul (somme, borne,
  amortissement, seuil), attaque (une seule touche par coup, `reset_exceptions`, zone éteinte) ;
- `1_core/combat/test_damage.gd` : 100 %, 150 %, 0 % ;
- `1_core/zones/test_world_boundary.gd` : un personnage tombé perd toute sa santé et disparaît ;
- `3_entities/player/test_player.gd` : la taille puis la course ; l'enchaînement taille, estoc, tourbillon ;
  l'esquive interrompt la taille, pas le tourbillon ; l'épée blesse une cible devant le joueur ; la visée ; le
  recul ;
- `3_entities/player/effects/test_slash_effect.gd` : visible pendant la taille seulement, effacement suivi ;
- `3_entities/player/test_player_view.gd` : l'épée touche, la caméra tremble ;
- `2_sequence/test_main.gd` : vaincu, le joueur revient au départ, visible, soigné.

## Ce qu'il faut retenir

- Des composants (santé, recul, attaque) que tous les personnages partagent.
- Les réglages d'un coup dans un `.tres` ; un même état pour trois coups.
- Un minuteur d'enchaînement s'arrête quand l'état se termine.
- L'animation pilote la zone de coup ; l'état frappe à chaque image, la zone décide.
- L'ordre des effets compte quand un signal déclenche une réaction aussitôt.

## À essayer

- Dans `stab.tres`, passer `damage` à 40 : l'estoc devient le coup fort.
- Mettre `next_attack` de `PlayerAttack2` à vide : l'enchaînement s'arrête à l'estoc.
- Dans `animated_player.tscn`, passer `parameters/SpinAttack/TimeScale/scale` à 3 : le tourbillon est deux fois
  plus rapide.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : composants de santé, recul et attaque ; trois
  coups (dégâts 10, 14, 10 ; recul 15 ; délai 0,5 s ; vitesse 1, 0, 2 ; vitesse d'animation 1,5) ; santé du
  joueur 60 ; éclat de la lame ; son `fire-slash.ogg` ; couches de collision ; animations KayKit.
- Documentation de Godot 4.7 : *Physics introduction* (`tutorials/physics/physics_introduction.rst`), couches et
  masques de collision ; *Using AnimationTree* (`tutorials/animation/animation_tree.rst`), `BlendTree` et
  `TimeScale`.
- Références des classes `ShapeCast3D` (`force_shapecast_update`, `add_exception`), `AnimationMixer`
  (`animation_finished`), `Timer` (API de Godot 4.7.2).

## Étape suivante

Étape 007 : les ennemis au corps à corps. Ils attendent, poursuivent le joueur en suivant la navigation,
frappent, et laissent un écho en disparaissant.
