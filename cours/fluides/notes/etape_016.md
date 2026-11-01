# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Jusqu'ici, on relisait les textures pour les regarder. C'est lent, et inutile : la carte peut montrer sa propre texture à l'écran.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`), et lancer la scène principale, `2_sequence/gpu_fire.tscn`. Il faut le renderer Forward+ ou Mobile : en Compatibilité, il n'y a pas d'appareil de calcul.
2. La scène est dans `2_sequence/gpu_fire.gd`, ses couleurs dans `1_core/gpu/shaders/fire_view.gdshader`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un autre appareil

Un appareil local (`create_local_rendering_device`) ne partage rien avec le rendu : ses textures ne peuvent pas aller à l'écran. `ComputeDevice.shared`
prend l'appareil du rendu de Godot, `RenderingServer.get_rendering_device()`. Trois choses changent : ses `RID` se montrent à l'écran ; il ne connaît ni `submit`
ni `sync`, son travail part avec l'image, donc `finish` ne fait rien ; et on ne le ferme pas, on rend seulement ce qu'on lui a pris. Il rend null sans fenêtre et
en Compatibilité : `gpu_fire.gd` s'arrête alors sans erreur.

### 2. Le fil du rendu

Tout ce qui touche à cet appareil passe par `RenderingServer.call_on_render_thread` : `_start`, `_advance`, `_device.release`.
`_exit_tree` vide d'abord `texture_rd_rid` : la texture ne doit plus désigner ce qu'on va rendre.

### 3. La texture montrée

`Texture2DRD` montre une texture de la carte. Il lui faut un usage de plus, `SAMPLING`, ajouté dans `new_texture`. Le solveur échange ses textures à
chaque pas : `_advance` redonne donc `_solver.temperature` à `texture_rd_rid` à chaque fois. Oublier cette ligne fige une image sur deux.

### 4. La couleur à l'écran

La texture ne contient qu'une température par case. `fire_view.gdshader` lit `TEXTURE`, puis un dégradé `ramp` : la couleur coûte une lecture par pixel,
et aucune case ne repasse par le processeur.

### 5. Ce que ça change

Mesuré sur la RTX 5090 du cours, machine occupée par ailleurs, feu complet avec 30 passes et MacCormack :

| Grille | Préparer le travail | Attendre la carte |
|---|---|---|
| 256 × 256 | 0,74 ms | 0,56 ms |
| 512 × 512 | 0,82 ms | 0,90 ms |
| 1 024 × 1 024 | 0,96 ms | 2,16 ms |
| 2 048 × 2 048 | 0,97 ms | 8,43 ms |

Préparer ne dépend pas de la taille : c'est le nombre de passes qui compte. Relire une texture de 2 048 × 2 048 coûte 5,88 ms de plus : c'est ce que `Texture2DRD` évite.
Sur le processeur, le même feu en plus simple (48 × 64 cases, 16 passes, transport simple) prenait environ 400 ms par pas.

`flame_gpu.tres` est une grille de 256 × 384 : les réglages sont en cases, donc une grille plus grande demande des forces plus grandes, d'où `fire_gpu.tres`.

## Ce qu'il faut retenir

Local pour calculer et relire, appareil du rendu pour montrer. La règle du fil du rendu ne se discute pas : tout passe par `call_on_render_thread`.
