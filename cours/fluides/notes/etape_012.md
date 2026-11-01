# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un champ devient une texture, et le transport devient un shader. Le code du processeur reste : c'est lui qui juge la carte, case par case.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Les shaders sont `1_core/gpu/shaders/advect.glsl` et `mac_cormack.glsl`, leur appel `1_core/gpu/gpu_advection.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un champ devient une image

`ComputeDevice.new_texture` crée une texture `DATA_FORMAT_R32_SFLOAT` : un flottant de 32 bits par case. Ses `usage_bits` disent tout ce
qu'on lui fera : `STORAGE` pour la lire et l'écrire dans un shader, `CAN_UPDATE` pour y déposer un champ, `CAN_COPY_FROM` pour le relire.
`upload` et `download` passent d'un `FluidField` à la texture sans rien convertir : les deux rangent les cases ligne par ligne.

Dans le shader, elle s'appelle `layout(r32f) uniform image2D`. `readonly` et `writeonly` disent à Godot ce que la passe en fait : c'est ce
qui lui permet d'ordonner les passes. `ComputePass` reconnaît une texture par `texture_is_valid` et l'attache comme image.

### 2. Lire entre quatre cases

`imageLoad` lit une case entière, sans filtrage : le mélange bilinéaire s'écrit à la main, dans `source_sample`. `source_at` borne les
coordonnées avec `clamp`, comme `FluidField.at`.

On voudrait une seule fonction qui reçoive l'image à lire. GLSL le refuse : `cannot use layout qualifiers on a function parameter`, et
une image lue doit dire son format. Chaque image lue entre deux cases a donc ses propres fonctions : `mac_cormack.glsl` a les siennes pour `source` et pour `backward`.

### 3. Ne pas sortir de la grille

Les groupes font 8 × 8 cases. Une grille de 30 × 22 demande 4 × 3 groupes, soit 32 × 24 invocations : `main` s'arrête au-delà de `imageSize`.
La grille des tests n'est pas un multiple de 8, exprès : `test_la_derniere_case_est_calculee` le vérifie.

### 4. Enchaîner les passes de MacCormack

`GpuAdvection.mac_cormack` lance trois passes : l'aller, le retour, la correction bornée. Chaque `run` est une liste de calcul à part,
qui lit ce que la précédente a écrit. `finish` n'est pas appelé entre elles : Godot les met dans l'ordre, d'après les images que chacune lit et écrit.

### 5. Le processeur pour juge

Les suites construisent le même champ des deux côtés, font le même transport, et comparent toutes les cases (`GridCheck.largest_gap`).
L'écart doit rester sous un dix-millième. Un test qui ne regarderait que quelques cases laisserait passer un décalage d'une case.

## Ce qu'il faut retenir

Une image se lit case par case, sans filtre. Le code du processeur n'est pas jeté : c'est le meilleur test du code de la carte.
