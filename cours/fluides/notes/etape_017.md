# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un axe de plus, et le processeur ne peut plus suivre du tout : c'est le terrain de la carte. Deux choses sont nouvelles : le filtre matériel, et un juge pour un calcul qu'on ne sait plus faire à côté.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le volume est dans `1_core/gpu/gpu_volume.gd`, ses passes dans `gpu_volume_passes.gd`, ses shaders dans `1_core/gpu/shaders/*_3d.glsl`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un volume

`ComputeDevice.new_volume` crée une texture `TEXTURE_TYPE_3D`, d'un flottant par case pour un champ, de quatre pour la vitesse : `R32G32B32A32_SFLOAT`, et le
quatrième reste inutilisé. Dans un shader, c'est un `image3D`, et une case est un `ivec3`.

Comme une texture 2D, un volume neuf n'est pas vide. Ici, préparer ses zéros côté processeur coûterait trop à grande taille : `texture_clear` le vide sur la carte,
ce qui demande l'usage `CAN_COPY_TO`.

Les groupes passent à 4 × 4 × 4, soit 64 invocations : `layout(local_size_x = 4, local_size_y = 4, local_size_z = 4)`. `ComputePass.volume_groups` les compte sur les trois axes.

### 2. Le filtre de la carte

En 2D, le mélange entre quatre cases s'écrivait à la main. En 3D, il faudrait huit lectures. Un `sampler3D` les fait en une, par le matériel. C'est une autre sorte de
donnée : le `binding` reçoit un filtre et une texture, `UNIFORM_TYPE_SAMPLER_WITH_TEXTURE`. `ComputePass` prend la liste de ces `binding`, et `ComputeDevice.trilinear` crée le
filtre, une fois.

Deux pièges. Un filtre lit des coordonnées entre 0 et 1, pas des cases : on divise par la taille. Et le centre d'une case est à 0,5 : `origin = vec3(cell) + 0.5 - delta * speed`.
Sans ce 0,5, tout glisse d'une demi-case à chaque pas. `texelFetch` lit une case exacte, sans filtre : c'est ce qu'il faut pour la vitesse de la case.

Le filtre est plus rapide, pas plus exact : il travaille sur peu de bits. `test_le_transport_suit_le_processeur_par_le_filtre` accepte 0,01, là où le mélange écrit à la main tenait 0,0001.

### 3. Six voisines

`pressure_3d.glsl` lit six voisines et divise par 6. Le damier devient un jeu de cubes : `(cell.x + cell.y + cell.z + color) & 1`. Il reste vrai qu'aucune case ne lit
une case de sa couleur. `stop_at_box.glsl` remplace les murs par les six faces du volume.

### 4. La rotation devient un vecteur

En 2D, la rotation était un nombre. En 3D, c'est un vecteur : son axe est celui du tourbillon. `curl_3d.glsl` croise les écarts de vitesse, `confine_3d.glsl`
croise la direction où la rotation grandit avec la rotation (`cross`).

### 5. Un juge sans solveur 3D

Il n'y a pas de solveur 3D sur le processeur pour comparer. Mais un volume qui ne varie pas en profondeur doit se comporter comme le 2D : `VolumeCheck` fabrique ce volume, et chaque
passe doit rendre, sur la tranche du milieu, ce que rend `FluidProjection`, `Advection` ou `Vorticity`.

La pression ne se compare pas telle quelle : entre quatre murs, elle n'est définie qu'à une constante près, seule sa pente compte. `_centered` retire la moyenne, et la divergence du test doit
être de moyenne nulle, sinon la pression dérive à chaque passe. Elle demande aussi plus de passes qu'en 2D : deux de ses six voisines ne lui apportent rien sur ce volume.

Pour ce que le 2D ne dit pas, on mesure la physique : un courant uniforme déplace une boule d'autant, une fumée chaude monte droit, sans quitter son axe.

### 6. Un plantage qui ne vient pas du code

À cette étape, la suite complète plantait à chaque fois, à la première ouverture d'une carte, dans le pilote (`signal 11`, `nvoglv64.dll`), alors que chaque suite seule passait.
Aucune suite n'était en cause : en les retirant une à une, le plantage restait. La pile d'appels le disait : entre Vulkan et le pilote, `graphics-hook64.dll`, le crochet de
capture d'OBS Studio, qui entre dans chaque application Vulkan de la machine. `DISABLE_VULKAN_OBS_CAPTURE=1`, la variable que sa couche prévoit, le retire pour un seul lancement :
les 135 cas passent. `lancer_tests.bat` la pose. Une pile d'appels se lit jusqu'au bout : ce qui s'y trouve n'est pas toujours à vous.

## Ce qu'il faut retenir

Le filtre de la carte divise le travail par huit, contre un peu de précision. Quand on ne sait plus faire le calcul à côté, on cherche un cas où la réponse est connue.
