# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** C'est le cœur d'un fluide. Sans lui, on a de la matière qui glisse ; avec lui, de vrais tourbillons. L'air ne s'entasse pas :
ce qui entre dans une case doit en sortir.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. La projection est dans `1_core/fluid/fluid_projection.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Mesurer ce qui s'entasse

`FluidProjection.divergence` calcule, pour chaque case, ce qui en sort moins ce qui y entre : l'écart de `u` entre droite et gauche,
plus l'écart de `v` entre bas et haut. Un courant uniforme n'en a pas ; une source en a beaucoup.

### 2. Chercher la pression

La pression est le champ dont la pente annule la divergence. `solve_pressure` la cherche par passes rouge-noir : une case sur
deux, comme un damier, puis l'autre moitié. Chaque case vise `(somme des voisines - divergence) / 4`. `relaxation` va au-delà de
cette cible : à 1,7, la même précision demande bien moins de passes (surrelaxation). Le damier compte pour la suite : ses cases
ne se lisent pas entre elles, donc le calcul se transpose tel quel sur la carte graphique.

### 3. Retirer la pente

`subtract_gradient` retire à la vitesse la pente de la pression. Il reste un courant sans divergence : ce que le fluide perd d'un
côté, il le rend de l'autre, et c'est ce qui fait naître les tourbillons.

## Ce qu'il faut retenir

Divergence, pression, pente : trois fonctions, le même schéma dans tous les fluides. Les passes coûtent cher : c'est là que se joue le temps de calcul.
