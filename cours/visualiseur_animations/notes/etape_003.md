# Visualiseur d'animations · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Voir un asset sous tous les angles, puis tel qu'il sera en partie. Et puisque les animations
seront refaites pour chaque angle de caméra, le visualiseur choisit lui-même la bonne.

Ce qu'on obtient :

- glisser sur la vue (ou le stick droit) tourne autour de l'asset, la molette (ou les gâchettes hautes) rapproche ;
- « Vue du jeu » (Y, ou G au clavier) prend la caméra du jeu, à 30° et 45° ;
- « salut » tient une seule ligne, « salut · 4 angles », et change de variante quand on tourne autour du héros.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5, choisir « heros », glisser sur la vue.
3. Les tests : `7_tests/lancer_tests.bat`.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. La caméra en quatre nombres

`1_core/viewer/orbit_rig.gd` tient quatre nombres :

- un lacet, autour de la verticale ;
- un tangage, en hauteur ;
- une distance ;
- un point visé.

Le sujet regarde +Z, l'avant de glTF et celui d'un export de Blender :

- au lacet 0, la caméra est devant lui ;
- à 90, de son côté gauche (+X) ;
- à 180, derrière lui.

La place de la caméra est `point visé + direction × distance`, et `Basis.looking_at` la tourne vers le point visé.

Deux bornes évitent les cas qui cassent :

- le tangage s'arrête à 85°, parce qu'à 90° la caméra regarderait droit en bas et n'aurait plus de « haut » pour
  `looking_at` ;
- la distance reste entre 0,5 et 60 mètres.

Cadrer un asset vise le milieu de son pavé et recule jusqu'à voir la sphère qui l'entoure dans le champ de vision.

### 2. La vue du jeu

La vue du jeu est orthographique, à l'inclinaison, à la rotation et à la taille de `config.json` (`vue_jeu`) : l'asset
s'y voit à l'échelle du jeu. Elle ne se rapproche pas, sinon elle ne serait plus la vue du jeu. Tourner la quitte en
partant de son angle : la caméra ne saute pas.

Les valeurs 30° et 45° attendent celles de la caméra du jeu.

### 3. Les commandes

`4_ui/viewer/orbit_input.gd` traduit les commandes en mouvements de caméra :

| Commande | Souris ou clavier | Manette |
|---|---|---|
| Tourner | glisser sur la vue (bouton gauche ou droit) ; J L I K | stick droit |
| Rapprocher, éloigner | molette ; E et Q | gâchettes hautes |
| Vue du jeu | G | Y |

Les actions sont dans `project.godot`. Le stick se lit par `Input.get_vector` : la zone morte de l'action (0,2) évite
qu'un stick au repos fasse tourner la caméra.

### 4. Une animation par angle

Une animation faite pour un angle se nomme `<base>_angle_<degrés>` dans Blender : `salut_angle_0`, `salut_angle_90`,
`salut_angle_180`, `salut_angle_270`. `1_core/viewer/angle_clips.gd` prend la variante dont l'angle est le plus proche
de la caméra :

- l'écart se compte sur le cercle, si bien que 350° est près de 0° ;
- à égalité, le plus petit angle gagne ;
- une animation sans `_angle_` sert sous tous les angles.

Le premier nom prévu était `salut@90`. Les tests l'ont refusé : l'import glTF de Godot 4.7.2 remplace « @ » par « _ »
dans les noms d'animations, et `salut@90` arrivait en `salut_90`, qu'on ne distinguerait plus d'un deuxième coup
(`attaque_2`). `_angle_` survit à l'import et ne se confond avec rien.

Le sujet garde le nom de base qu'on lui a demandé. Quand la caméra tourne, `set_view_angle` passe à la nouvelle
variante au même instant de l'animation : un salut commencé de face continue de profil, sans repartir du début.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent ;
- F5, « heros », « salut » : de face, il lève le bras droit ; on tourne d'un quart de tour, il lève le gauche ;
- « Vue du jeu » : le héros, petit, vu de haut et de trois quarts, comme en partie ; glisser repasse en vue libre.
