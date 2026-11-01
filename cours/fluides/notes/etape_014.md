# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** On réunit les passes dans un solveur complet, le même pas que `FluidSolver`. Et on vérifie le tout : pas après pas, la carte doit suivre le processeur.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le solveur est dans `1_core/gpu/gpu_solver.gd`, les petites passes dans `gpu_field_ops.gd`, la diffusion et les tourbillons dans `gpu_diffusion.gd` et `gpu_vorticity.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les petites passes

Une boucle de deux lignes sur le processeur devient un shader : `scale_image.glsl` pour ce qu'un champ perd, `add_disc.glsl` pour une source,
`clear_walls.glsl` et `stop_at_walls.glsl` pour les murs. `add_disc` tourne sur toute la grille : une invocation ne sait pas d'avance si sa case compte.

### 2. La diffusion change de chemin

`Diffusion` parcourt les cases dans l'ordre : chacune lit celles qui viennent d'être calculées. Une carte ne peut pas le faire, puisque
tout tourne en même temps. `diffuse.glsl` passe en rouge-noir : le chemin est autre, l'équation est la même. Les deux ne sont donc égaux
qu'à la fin : `test_a_force_de_passes_il_arrive_ou_arrive_le_processeur` donne 80 passes aux deux.

`target` doit d'abord recevoir `source`. `ComputeDevice.copy` le fait sur la carte (`texture_copy`), ce qui demande un usage de plus, `CAN_COPY_TO`.

### 3. Les tourbillons

`curl.glsl` écrit la rotation dans son image, `confine.glsl` la lit et pousse la vitesse sur place. Le test de `length_squared` devient
`dot(toward, toward)` : même calcul, sans racine.

### 4. Le pas complet

`GpuSolver` reprend `FluidSolver` ligne par ligne : mêmes réglages, mêmes passes, même ordre. Il ne garde que des `RID`. Échanger un champ et
son double revient à échanger deux `RID` : aucune donnée ne bouge.

`step` ne calcule rien : il prépare le travail, et la carte l'exécute à `finish` ou à une lecture.

### 5. Le juge

`test_gpu_solver.gd` fait avancer les deux solveurs ensemble, source, force et mur compris, puis compare chaque champ. L'écart reste sous 0,002
après six pas, transport simple, MacCormack et tourbillons compris. Un écart ici ne se trouve qu'en découpant le pas et en comparant après chaque sous-étape.

## Ce qu'il faut retenir

Ce qui marche sur le processeur se transpose passe par passe. Seul ce qui lit des cases déjà calculées doit changer de méthode.
