# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le kart dérape, gagne des turbos et fait des figures. Ses effets suivent : fumée et
étincelles de dérapage, flammes du turbo, traînée fantôme, marques de pneus, gerbes d'eau et traînées des
roues.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (Forward+).
2. F5 : rouler gaz ouverts, braquer, puis appuyer sur Espace et le garder. Le kart saute, puis glisse en
   fumant. Les étincelles deviennent bleues, puis orange. Relâcher Espace : turbo, et une traînée de fantômes
   arc-en-ciel.
3. En l'air (après une rampe), Espace : le kart fait un tour complet, puis prend un turbo à l'atterrissage.
4. Rouler dans le sable, puis dans la mer : les pneus marquent le sable, les roues éclaboussent.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Dérapage, turbo et figures : de la logique

Dans `3_entities/kart/kart.gd`, `update_drift()` suit le dérapage. Un saut en braquant, gaz ouverts, le lance
dans le sens du braquage : c'est le petit bond du départ. Au sol, il passe par quatre niveaux
(`enum DriftStage`) : aucun, glissade, étincelles après 0,8 s, étincelles chaudes après 3 s. Relâcher le saut,
ou les gaz, l'arrête. Relâché aux étincelles, il donne 0,5 s de turbo ; aux étincelles chaudes, 1 s ; en
glissade, rien. En dérapage, le braquage penche vers le sens du dérapage (60 %), que le stick module (40 %), et
s'élargit (× 1,5).

Pendant un turbo, `apply_engine()` pousse le kart à 50 m/s² jusqu'à 25 m/s, au-delà de sa vitesse de pointe.
En l'air, un saut fait une figure. Après un saut depuis le sol, la figure attend 0,4 s, et l'atterrissage qui
suit une figure donne 1 s de turbo.

Les niveaux sont une énumération, pas des chiffres : la règle DAT-01 ne laisse que 0 et 1 dans la logique.
Toutes les durées et vitesses sont dans le groupe « Dérapage, turbo et figures » de `kart_settings.tres`. Les
commandes `jump_held` et `jump_released`, prévues à l'étape 001, servent enfin.

### 2. Le kart signale, ses effets écoutent

Le kart émet `drift_stage_changed`, `boost_changed` et `tricked`. Il ne connaît aucun de ses effets :

- `3_entities/kart/effects/kart_particles_view.gd` (`KartParticlesView`) allume la fumée de glissade, les
  étincelles, dont il change la couleur, les flammes du turbo et la gerbe d'une figure ;
- `kart_view.gd` joue l'animation « trick » du modèle (un tour complet en 0,5 s). Pendant ce temps, il cesse de
  l'aligner sur le sol ;
- `ghost_trail.gd` lance la traînée fantôme à chaque turbo.

Les particules sont des `GPUParticles3D` sous le modèle : elles penchent et tournent avec lui. Le shader des
flammes (`boost_particle.gdshader`) tourne chaque particule face à la caméra et passe du violet à l'orange au
fil de sa vie.

### 3. Les marques de pneus

`1_core/effects/tire_marks/tire_marks_manager.gd` (`TireMarksManager`, sur le terrain de l'île) fait vivre une
texture de 128 m centrée sur le kart, 32 pixels par mètre. Chaque image, le shader de calcul
`tire_marks_shader.glsl` recopie la texture de la veille, décalée du chemin parcouru, puis y imprime les
quatre marques reçues. Le shader de l'île mêle au sable une couleur de sable tassé, et à l'herbe un peu de
terre. Celui de l'herbe la couche le long des traces. `KartTireMarksView`, dans le kart, envoie chaque roue :
une marque pleine au sol, une marque nulle en l'air.

Deux corrections du kart d'origine, trouvées en regardant :

- **Les noms inversés.** `add_tire(position, radius, strength)` rangeait le rayon là où le shader de calcul lit
  la force, et inversement ; le jeu passait 1 et 9 dans le désordre, et ça tombait juste. L'appel est
  maintenant `add_tire(position, strength, radius_px)`, dans l'ordre que lit le shader.
- **Les roues se croyaient en l'air.** Dans le kart d'origine, aucune marque ne se voyait. En peignant les
  traces en rouge vif dans le shader de l'île, la texture se montrait bien lue, mais vide dès que le kart
  roulait. Les rayons des roues mesuraient 0,5 m, la longueur de la suspension ; kart posé, le sol est à 0,53
  à 0,60 m sous eux (mesuré en roulant sur l'île), et presque toujours à plus de 0,75 m en l'air. Ce cours
  donne donc au rayon, dès l'étape 002, sa propre portée : `ground_probe_length`, 0,7 m.

### 4. Gerbes et traînées des roues

`3_entities/kart/effects/wheel_splash_effects.gd` (`WheelSplashEffects`) duplique, pour chaque roue, des
émetteurs modèles :

- sur la mer, des gouttelettes autour de chaque roue, des embruns et une traînée derrière les roues arrière ;
- sur une route mouillée, de petites gouttelettes et une traînée. La route reste sèche jusqu'à la pluie, à
  l'étape 011 (`road_wetness` à 0).

La force suit la vitesse. Les émetteurs se placent en coordonnées du monde (`top_level`), orientés vers
l'extérieur du kart.

La traînée (`trail/wheel_trail.gd`, `WheelTrail`) est un ruban reconstruit à chaque image avec un
`ImmediateMesh`, à partir des derniers points de la roue. Chaque point vieillit, s'élargit et s'efface. Son
shader (`wheel_trail.gdshader`) ronge le ruban avec du bruit fixé dans le monde : l'écume ne glisse pas avec le
kart.

### 5. La traînée fantôme

`ghost_trail/ghost_trail.gd` (`GhostTrail`) laisse, pendant un turbo, des copies figées du kart et du pilote :
une tous les 0,4 m. Le squelette du pilote est copié dans sa pose du moment. Chaque copie vit 0,6 s. Son
contour brille (Fresnel, `ghost.gdshader`), son halo s'ajoute en seconde passe (`ghost_halo.gdshader`), et sa
teinte défile en arc-en-ciel. 40 copies sont préparées au chargement, puis recyclées.

Le fantôme d'origine passait sa couleur par des paramètres d'instance. Avec une quinzaine de maillages par
copie, 40 copies dépasseraient la réserve de ces paramètres en rendu de compatibilité, comme les carrés de
l'océan à l'étape 008. Chaque copie a maintenant son matériau.

## Les tests

- `3_entities/kart/test_kart_drift.gd` : le dérapage se lance, monte de niveau, donne le bon turbo selon le
  niveau ; il tourne plus serré ; le turbo dépasse la vitesse de pointe puis s'éteint ; figure, puis turbo à
  l'atterrissage ; pas de figure juste après un saut.
- `3_entities/kart/effects/test_kart_particles_view.gd` : chaque signal allume le bon effet, à la bonne
  couleur, et la figure joue son animation.
- `1_core/effects/tire_marks/test_tire_marks_manager.gd` et `3_entities/kart/effects/test_kart_tire_marks_view.gd` :
  une marque tombe au bon pixel ; les traces suivent le kart ; roue au sol, marque pleine ; en l'air, nulle.
- `3_entities/kart/effects/test_wheel_effects.gd` : gerbes et traînées sur l'eau en roulant, rien à l'arrêt ;
  rien sur route sèche, gouttelettes et traînées sur route mouillée.
- `3_entities/kart/effects/test_ghost_trail.gd` : un turbo lance la traînée, le kart y laisse des copies, puis
  elle s'arrête.
- `3_entities/kart/test_kart_view.gd` : kart posé, chaque roue se sait au sol ; en l'air, aucune.

## Ce qu'il faut retenir

- La logique signale, les effets écoutent : le kart ne connaît ni ses particules ni son fantôme.
- Un état à quelques valeurs est une énumération, pas une suite de chiffres.
- Pour voir ce qu'un shader lit, peindre ce qu'il lit d'une couleur criarde.
- Mesurer avant de régler : la portée des rayons vient de distances relevées en roulant.
- Une réserve du moteur de rendu se dépasse vite avec des paramètres par instance : un matériau par objet,
  quand ils sont peu nombreux.

## À essayer

- Dans `kart_settings.tres`, passer `drift_sparks_time` à 0,3 : les étincelles arrivent presque tout de suite.
- Dans `kart.tscn`, nœud `KartTireMarks`, passer `mark_strength` à 0 : le sable ne garde plus aucune trace
  des roues.

## Source

- La conduite, les particules, les traces, les gerbes et le fantôme viennent du kart d'origine (GDWaterKart,
  JorisAR, licence MIT) ; le fantôme, du tutoriel « Ghost Trail - Godot 4.4 » de Pixezy.
- Références des classes (API de Godot 4.7.2) : `GPUParticles3D`, `ParticleProcessMaterial`, `ImmediateMesh`,
  `AnimationPlayer`, `RayCast3D`, `Skeleton3D`.
- Documentation de Godot 4.7 : *Using compute shaders* (`tutorials/shaders/compute_shaders.rst`), *Particle
  systems (3D)* (`tutorials/3d/particles/`).

## Étape suivante

Étape 011 : la pluie et l'éclair. La route se mouille, les gouttes font des anneaux sur l'eau, le ciel
s'éclaire.
