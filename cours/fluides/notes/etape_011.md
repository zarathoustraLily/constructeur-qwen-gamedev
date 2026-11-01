# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le processeur s'arrête à 64 × 64 cases. La carte graphique calcule des millions de cases en parallèle, mais rien
n'y marche comme dans un script. On commence par le plus petit calcul possible : multiplier les valeurs d'un tampon.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. L'appareil est dans `1_core/gpu/compute_device.gd`, la passe dans `1_core/gpu/compute_pass.gd`, le shader dans `1_core/gpu/shaders/scale_values.glsl`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur. Ils ouvrent une petite fenêtre : sans fenêtre, Godot n'ouvre aucune carte.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Ouvrir un appareil de calcul

`ComputeDevice.open` demande `RenderingServer.create_local_rendering_device()` : un appareil à soi, séparé du rendu de l'écran. En
`--headless`, cet appel rend null : un test de shader de calcul ne peut pas tourner sans fenêtre. Le code garde ce cas : `open` rend null, et
c'est à l'appelant de décider quoi faire.

### 2. Écrire le shader

`scale_values.glsl` commence par `#[compute]` et `#version 450`. `layout(local_size_x = 64)` dit que la carte lance les invocations par
groupes de 64. Le tampon se déclare en `std430`, sa taille se lit avec `.length()`. `gl_GlobalInvocationID.x` est le numéro de l'invocation.

Les groupes sont entiers : pour 70 valeurs, il en faut deux, soit 128 invocations. `main` n'écrit donc que si l'indice existe. `groups_for`
arrondit le nombre de groupes vers le haut.

### 3. Charger le shader

Godot importe un `.glsl` en `RDShaderFile`. `ComputePass._init` en tire le SPIR-V par `get_spirv()`, regarde `compile_error_compute`, en fait
un shader (`shader_create_from_spirv`), puis un pipeline (`compute_pipeline_create`).

L'import ne dit rien d'un shader faux : il passe sans erreur. La faute n'apparaît qu'en demandant le SPIR-V, ce que fait `7_tests/check_shaders.gd`,
sans carte ni fenêtre :

```
godot --headless --path . -s res://7_tests/check_shaders.gd
```

glslang compte les lignes à partir de `#version`, une fois `#[compute]` retiré : son `0:8` est la ligne 9 du fichier.

### 4. Lancer le calcul

`ComputePass.run` crée un jeu d'uniformes (`uniform_set_create`), ouvre une liste de calcul, y attache le pipeline, les données et les
constantes, puis lance les groupes (`compute_list_dispatch`). Rien n'est encore fait : `ComputeDevice.finish` envoie le travail
(`submit`) et attend la carte (`sync`).

Les constantes poussées doivent faire exactement la taille du bloc du shader. Un seul flottant pèse 4 octets : en envoyer 16 donne
`This compute pipeline requires (4) bytes of push constant data, supplied: (16)`, et le calcul ne se fait pas.

### 5. Tout rendre

La carte ne connaît pas la mémoire de Godot. `keep` note tout ce qui y est créé ; `release` le rend du dernier au premier, parce
qu'un pipeline dépend de son shader, puis ferme l'appareil par `rd.free()` : un appareil local n'est pas compté par références.

## Ce qu'il faut retenir

Un shader de calcul, c'est quatre objets : le fichier, le shader, le pipeline, le jeu d'uniformes. Et trois pièges : les groupes débordent, les constantes
ont une taille exacte, et l'import ne signale rien.
