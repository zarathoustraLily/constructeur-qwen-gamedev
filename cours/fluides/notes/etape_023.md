# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un fluide se voit mieux avec ce qu'il emporte : étincelles, gouttes, poussière. Des dizaines de milliers de particules ne passent pas par le processeur : les relire et les renvoyer à chaque image coûterait plus cher que de les calculer. La carte les déplace, et la carte les dessine.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Lancer le projet : la scène principale est maintenant `2_sequence/gpu_sparks.tscn`. Les particules sont dans `1_core/gpu/gpu_tracers.gd` et `1_core/gpu/shaders/tracers.glsl`, leur juge dans `1_core/fluid/tracer.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Lire le courant à mi-chemin

La méthode la plus simple prend le courant au point de départ et trace une ligne droite. Dans un virage, une ligne droite sort du cercle, et la particule s'éloigne à chaque pas. `Tracer.moved` fait un demi-pas, y relit le courant, et part de là : c'est le point milieu. Les deux tests le mesurent dans un même tourbillon : 60 pas à 0,05 seconde gardent la particule à 0,05 case de son cercle, et la ligne droite l'en sort de plus d'une demi-case.

### 2. Des tampons, et un filtre

Une particule n'a pas de case : `positions` est un tampon de `vec2`, en `std430`, où deux flottants se suivent sans trou. `u` et `v` se lisent par le filtre de la carte, comme à l'étape 17 : `ComputePass` reçoit les `binding` 2 et 3. Il reste le décalage de l'étape 17 : le centre d'une case est à 0,5 dans une texture, et sur les entiers ici.

`layout(local_size_x = 64)` : une seule dimension. `positions.values.length()` donne le nombre de particules, et la vérification du début évite de lire au-delà : le dernier groupe n'est pas toujours plein. `test_toutes_les_particules_bougent_meme_apres_le_premier_groupe` en lance 65.

### 3. Une vie, sans âge

Une particule qui ne sort pas de la grille resterait pour toujours. Tenir un âge par particule demanderait un tampon de plus. À la place, à chaque pas, une particule sur `lifetime` retourne à son départ : celles dont l'indice tombe sur le tour courant. Chacune vit ainsi exactement `lifetime` pas, et aucune ne compte rien.

### 4. Écrire directement dans la MultiMesh

`RenderingServer.multimesh_get_buffer_rd_rid` donne le tampon d'une `MultiMesh` sur l'appareil du rendu. `tracer_instances.glsl` y écrit huit flottants par instance, dans l'ordre que donne `RenderingServer.multimesh_set_buffer` : deux lignes de quatre, avec la position en quatrième. Le moteur dessine, sans savoir qu'un shader a écrit à sa place.

Ce n'est possible que sur l'appareil du rendu : un appareil local ne voit pas ce tampon. C'est aussi pour cela que `_start` le demande sur le fil du rendu.

### 5. La boîte

Le moteur ne lit jamais ces positions : il ne sait donc pas où sont les particules. Sans `custom_aabb`, il peut juger l'objet hors de l'écran et ne rien dessiner. On lui donne la boîte de la grille.

### 6. Juger l'image

`test_une_particule_se_dessine_a_sa_place` pose une particule en (20, 44), rend l'image, et regarde le pixel. Le pixel symétrique (44, 20) reste vide : ce test tomberait si les deux lignes du rangement étaient inversées.

## Ce qu'il faut retenir

Ce que le moteur dessine n'a pas à passer par le processeur. Quand un calcul a un juge exact sur le processeur, on peut le confier à la carte sans perdre la preuve.
