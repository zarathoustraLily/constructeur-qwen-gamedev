# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Les effets qui donnent du poids aux coups : des gerbes de particules, une caméra qui
tremble, un éclair blanc sur ce qui est touché. Tout est construit en code, réglé par un `.tres`.

Ce qu'on obtient : des étincelles qui jaillissent et retombent, une poussière qui s'étale au sol, un tremblement
de caméra proportionné au choc et qui s'apaise, et un voile blanc qui s'efface en un dixième de seconde.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Les recettes sont dans `3_entities/effects/`, leurs réglages dans `5_data/vfx/vfx.tres`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Des particules construites en code

`3_entities/effects/particle_recipes.gd` construit un `ParticleProcessMaterial` : la direction de départ et
l'ouverture du cône (`direction`, `spread`), la vitesse tirée entre deux bornes (`initial_velocity_min`,
`initial_velocity_max`), la gravité, la taille au fil de la vie (`scale_curve`, une `CurveTexture` qui va de 1 à
0 : la particule rétrécit) et la couleur au fil de la vie (`color_ramp`, une `GradientTexture1D` : elle fond
jusqu'à la transparence). La poussière s'étale à plat (`flatness` à 1, cône complet) et ralentit (`damping`).

### 2. Une gerbe, d'un coup

`burst` fait un `GPUParticles3D` qui lâche toutes ses particules d'un coup (`explosiveness` à 1) une seule fois
(`one_shot`), avec un petit quad à dessiner (`draw_pass_1`). Il attend qu'on le lance (`emitting = true`).

### 3. Le tremblement par traumatisme

`3_entities/effects/camera_shake.gd` : chaque choc ajoute du traumatisme, borné à 1, qui retombe chaque seconde.
La force est le carré du traumatisme : un petit choc bouge à peine, un gros secoue. Le décalage suit un bruit
continu (`FastNoiseLite.get_noise_1d`), pas un hasard qui saute d'une image à l'autre ; il se pose sur
`h_offset` et `v_offset` de la caméra, sans toucher à sa position.

### 4. L'éclair d'un coup

`3_entities/effects/hit_flash.gd` pose un voile (`material_overlay`) non éclairé et transparent sur le maillage,
puis un `Tween` efface son alpha (`"albedo_color:a"`) et retire le voile. Un nouveau coup tue le Tween en cours et
relance l'éclair.
