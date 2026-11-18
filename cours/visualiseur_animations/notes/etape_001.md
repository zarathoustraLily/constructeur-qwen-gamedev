# Visualiseur d'animations · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La demande : un visualiseur des assets du jeu (héros, ennemis, boss, props), qui montre leurs
animations sous tous les angles en 3D, ou en 2D, avec leur contour noir et leur ombre, qu'on enchaîne à la manette ou
qu'on choisit une par une. Avant de montrer quoi que ce soit, il faut savoir où sont les assets et lesquels existent.

Ce qu'on obtient : F5 ouvre « Visualiseur d'animations » ; la liste de gauche range les cinq assets d'exemple par
catégorie (Héros, Ennemis, Props, Effets), et la barre d'état dit « 5 assets ».

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5 : la fenêtre du visualiseur, la liste à gauche.
3. Les tests : `7_tests/lancer_tests.bat` (adapter le chemin de Godot), ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une application à part, des assets hors du projet

Comme l'éditeur de cartes, le visualiseur est une application à part. Il ne copie rien dans son projet : il lit les
fichiers tels que Blender et l'optimiseur d'atlas les écrivent, dans les dossiers qu'on lui donne. On peut ainsi
réexporter un ennemi depuis Blender et le revoir aussitôt, sans import.

Les assets d'exemple sont dans `6_assets/exemple/`, un dossier qui contient un `.gdignore` : Godot ne les importe pas,
le visualiseur les lit comme il lira ceux du jeu.

### 2. Des réglages qu'on modifie à la main

`5_data/visualiseur/config.json` liste les dossiers, chacun avec sa catégorie :

```json
{"sources": [{"dossier": "D:/GODOT/PROJETS_DEMOS/PROJET_ROGUE_LIKE_002/SOURCE02/ENNEMIS", "categorie": "ennemi"}]}
```

Les catégories sont celles de `ViewerConfig.CATEGORIES` : `heros`, `ennemi`, `boss`, `prop`, `effet`. Un visualiseur
exporté lit d'abord le `config.json` posé à côté de son exécutable.

`1_core/viewer/viewer_config.gd` lit le fichier et ne s'arrête pas au premier problème. Un JSON invalide (avec sa ligne),
une catégorie inconnue ou un dossier manquant vont chacun dans `errors`, en une phrase, et le reste du fichier est lu
quand même. La barre d'état montre le premier problème.

### 3. Chercher, sans rien deviner

`1_core/viewer/asset_scanner.gd` fouille chaque dossier et ses sous-dossiers. Trois formes comptent comme un asset :

- un modèle 3D (`.glb`, `.gltf`) ;
- un atlas d'animation (`.atlas.json`, celui de l'optimiseur) ;
- un dossier d'au moins deux PNG numérotés au même nom (`feu_01.png`, `feu_02.png`…).

Les pages d'un atlas (`flamme_0.png`) ne comptent pas comme un dossier d'images : l'atlas les désigne déjà. Des PNG sans
numéro, ou numérotés à des noms différents, ne font pas une animation. Les dossiers cachés (`.cache`) sont ignorés.

Chaque asset reçoit un identifiant stable : sa catégorie, puis son chemin dans le dossier source, sans extension
(`ennemi/golem`). Deux sources qui donneraient le même identifiant sont signalées, et le premier asset reste. La liste
est triée par catégorie, puis par identifiant : deux recherches sur les mêmes dossiers donnent la même liste.

### 4. La liste

`4_ui/viewer/asset_list.gd` montre une branche par catégorie, avec son nombre d'assets, puis une ligne par asset, avec sa
forme (3D ou 2D) et son chemin en info-bulle. Choisir une ligne émet `asset_chosen` ; la scène qui le montre arrive à
l'étape suivante.

### 5. Le socle

Le socle est le même que celui de l'éditeur de niveaux :

- les avertissements de GDScript sont des erreurs (bloc `[debug]` de `project.godot`) ;
- l'ordre d'exécution est nommé (`1_core/process_order.gd` : les entrées, la lecture, la caméra, puis l'interface) ;
- chaque membre public est documenté (`test_documentation.gd`).

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent ;
- F5 : cinq assets dans la liste, « 5 assets » dans la barre d'état ;
- dans `config.json`, un dossier qui n'existe pas : la barre d'état le dit.
