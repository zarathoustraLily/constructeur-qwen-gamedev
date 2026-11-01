# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La matière suit le courant. C'est le premier geste d'un fluide, et le premier piège : pousser les valeurs vers l'avant
laisse des trous et explose dès que la vitesse dépasse une case par pas.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le transport est dans `1_core/fluid/advection.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Remonter le courant

`Advection.semi_lagrangian` prend le problème à l'envers. Pour chaque case de `target`, elle se demande d'où vient ce qui arrive
ici : elle remonte le courant de `delta` secondes, de `x - delta * u.at(x, y)` à `y - delta * v.at(x, y)`, et lit `source` à cet
endroit par `sample`. Il faut deux champs : on lit dans `source`, on écrit dans `target`.

### 2. Pourquoi c'est stable

Une valeur lue est un mélange de valeurs existantes : elle ne peut pas dépasser la plus haute. Quelle que soit la vitesse, rien ne
s'emballe. Le test le vérifie avec une vitesse de 300 cases par seconde. Le prix à payer est un léger flou : on verra à l'étape 7
comment le réduire.

## Ce qu'il faut retenir

Transporter, c'est lire en remontant le courant, jamais écrire en le descendant. La vitesse est en cases par seconde.
