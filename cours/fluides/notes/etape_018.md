# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un volume ne se montre pas comme une image : il n'a pas de surface. On lance un rayon par pixel, on le fait avancer à petits pas dans la fumée, et on additionne. C'est le raymarching.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Lancer le projet : la scène principale est maintenant `2_sequence/gpu_smoke.tscn`. Le shader est `1_core/gpu/shaders/smoke_view.gdshader`, et son juge `1_core/fluid/ray_march.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Le volume arrive au shader sans repasser par le processeur

C'est le même chemin qu'à l'étape 16, avec un axe de plus : `Texture3DRD` donne au moteur une texture créée sur l'appareil du rendu. `GpuVolume` échange ses textures à chaque pas : on redonne donc `density` après chaque pas, sur le fil du rendu.

### 2. Une boîte, et son dos

La boîte n'est qu'une silhouette : elle dit quels pixels lancent un rayon. `cull_front` dessine son dos plutôt que sa face. Avec la face, le volume disparaîtrait dès que la caméra y entre, puisqu'on ne verrait plus aucune face. `depth_draw_never` : une fumée n'écrit pas la profondeur, ce qui passe derrière doit rester visible.

Tout se calcule dans le repère de la boîte, qui va de -0,5 à 0,5 : ajouter 0,5 donne directement les coordonnées de la texture, et la taille de la boîte ne change rien au shader.

### 3. Où le rayon entre, où il sort

Une boîte est trois paires de plans. Le long d'un axe, le rayon passe deux plans : l'un d'entrée, l'autre de sortie. Il est dans la boîte après le dernier plan d'entrée et jusqu'au premier plan de sortie. S'il part de l'intérieur, l'entrée vaut 0 : c'est ce `max(…, 0.0)` qui laisse la caméra entrer dans le volume.

### 4. La loi de Beer-Lambert

Chaque longueur de matière retire la même part de ce qui reste : la lumière suit une exponentielle, pas une droite. `taken = 1.0 - exp(-absorption * matter * spacing)` est la part retirée à un pas. On ne peut pas additionner les opacités : deux fumées à moitié opaques ne font pas une fumée pleine, elles laissent encore passer un quart de la lumière.

### 5. La fumée dans sa propre ombre

Sans lumière, la fumée est une tache plate. À chaque pas, un petit rayon part vers la lumière et compte la fumée qui la cache. C'est cher : 48 pas fois 6 lectures par pixel. `if (matter > 0.0)` saute ce coût dans le vide, qui occupe la plus grande partie de la boîte.

### 6. Juger une image par le calcul

Une image ne se juge pas à l'œil dans un test. Mais à travers un volume uniforme, on connaît la réponse : `RayMarch.transmittance` la calcule sur le processeur. Le test rend cette boîte dans un `SubViewport` à fond transparent, et compare l'alpha du pixel central à la loi. Le même test avec une caméra dans le volume vérifie le trajet raccourci.

`ALPHA` s'écrit, mais ne se relit pas : d'où la variable `opacity`.

## Ce qu'il faut retenir

Un pixel, un rayon, de petits pas : le coût se mesure en lectures de texture par pixel. Une opacité ne s'additionne pas : la lumière s'en va en exponentielle.
