# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La diffusion étale : l'encre dans l'eau, la viscosité du miel. Écrite naïvement, elle explose dès qu'elle devient forte.
C'est le premier calcul qu'on résout au lieu de l'appliquer.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. La diffusion est dans `1_core/fluid/diffusion.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Échanger avec ses voisines

Chaque case tend vers la moyenne de ses quatre voisines, au rythme `rate * delta`. Calculé en avant, ce rythme dépassant un quart,
une case donne plus qu'elle n'a, et le signe bascule d'une case à l'autre.

### 2. Résoudre l'état futur

`Diffusion.solve` cherche l'état futur qui, diffusé à l'envers, redonne `source` : pour chaque case,
`(source + exchange * autour) / (1 + 4 * exchange)`. Cette équation lie toutes les cases : on la résout par passes, en écrivant dans
`target` sur place (Gauss-Seidel) ; chaque passe rapproche de la solution. Le test vérifie qu'un taux énorme reste stable, et que
le total se conserve.

## Ce qu'il faut retenir

Quand un calcul explicite explose, on résout l'état futur par passes. Moins de passes donne un résultat moins exact, jamais une explosion.
