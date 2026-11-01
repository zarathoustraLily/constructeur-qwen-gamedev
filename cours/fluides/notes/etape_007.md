# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le transport simple floute : à chaque pas, la lecture bilinéaire moyenne. Une fumée perd ses détails en quelques images.
MacCormack retire la moitié de cette erreur, à peine plus cher.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le transport est dans `1_core/fluid/advection.gd`, le choix dans `FluidSettings.sharp_transport`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Mesurer sa propre erreur

`Advection.mac_cormack` transporte en avant dans `forward`, puis revient en arrière dans `backward`. Sans erreur, on retrouverait
`source` : l'écart est l'erreur commise. La moitié de cet écart, ajoutée au résultat, l'efface presque. L'erreur vit là où la matière
était : elle se lit à l'endroit d'où vient le courant (`from_x`, `from_y`), pas dans la case d'arrivée. Lue à l'arrivée, comme dans la
formule des petits pas, elle ne corrige rien à grande vitesse : le premier essai rendait exactement le transport simple.

### 2. Borner la correction

Cette correction peut inventer des valeurs au bord d'une tache, et le calcul s'emballe. `_limited` ramène chaque valeur entre la plus
petite et la plus grande des quatre cases d'où elle vient. Le test vérifie que le plus haut de départ n'est jamais dépassé.

### 3. Un réglage

`FluidSettings.sharp_transport` choisit. `FluidSolver._transport` passe les deux champs de travail (`_forward`, `_backward`) : un
transport coûte trois lectures au lieu d'une.

## Ce qu'il faut retenir

Une correction sans borne n'est pas stable. Mesurer son erreur en faisant l'aller et le retour est un procédé qui resservira.
