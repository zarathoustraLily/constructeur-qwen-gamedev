# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La demande : un éditeur pour le roguelike, qui permette d'éditer les niveaux, les collisions, les
apparitions, les effets, les animations, et de choisir les ennemis, avec un cadre bleu autour du sprite pour le
déplacer, le tourner, le mettre à l'échelle et choisir sa profondeur. Avant la première poignée, on construit un projet
qui tient debout : des dossiers qu'on ne remettra pas en cause, des réglages qui refusent le code approximatif, un
ordre d'exécution écrit, et une fenêtre qui s'ouvre.

Ce qu'on obtient : F5 ouvre une fenêtre vide, « Éditeur de niveaux », dont la barre d'état dit « Aucune salle
ouverte » ; les tests passent.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5 : la fenêtre de l'éditeur, vide.
3. Les tests : `7_tests/lancer_tests.bat` (adapter le chemin de Godot), ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Mettre l'éditeur dans le projet du jeu

Un éditeur de niveaux à part, dans son propre projet, ne pourrait pas lire les données du jeu : un `.tres` de Godot
désigne son script par un chemin `res://`, valable seulement dans son projet. Pour éditer les ennemis, les effets ou
les animations du jeu, l'éditeur doit donc vivre **dans** le projet du jeu, et ranger ses fichiers dans les mêmes
dossiers :
- `1_core/editor/` : le document, la sélection, l'annulation, la validation (aucun nœud d'affichage) ;
- `4_ui/editor/` : la vue de dessus, le cadre de sélection, les panneaux ;
- `2_sequence/editor/` : la coquille qui assemble le tout.

Il se lance comme une scène à part ; il ne fera pas partie du jeu distribué (étape 18). Ici, le projet ne contient
encore que l'éditeur : c'est sa scène principale.

### 2. Des avertissements qui sont des erreurs

Dans `project.godot`, section `[debug]`, chaque avertissement de GDScript passe au niveau 2 (erreur) : une variable
sans type (`untyped_declaration`), une division entière silencieuse (`integer_division`), un paramètre inutilisé
(`unused_parameter`), un nom qui en masque un autre (`shadowed_variable`)… Un script qui en contient un ne se charge
plus. Un éditeur manipule des données qu'on ne veut pas abîmer : on préfère qu'il refuse de démarrer plutôt qu'il
écrive une salle fausse.

### 3. Le moteur de rendu Compatibilité

L'éditeur dessine des sprites à plat et une vue de dessus : le rendu Compatibilité (`gl_compatibility`) suffit, il
démarre vite et tourne sur une petite carte. Le banc d'essai 3D (étape 15) s'en contente aussi.

### 4. Un ordre d'exécution écrit

`1_core/process_order.gd` nomme les priorités : les entrées (souris, raccourcis) d'abord, puis le document qui applique
les actions, puis les vues qui redessinent, et le cadre de sélection en dernier, par-dessus. Un nœud qui en dépend
prend sa priorité ici, jamais un nombre écrit sur place : l'ordre se lit d'un coup d'œil, et se change en un endroit.

### 5. La coquille

`2_sequence/editor/editor_shell.tscn` : un `Control` plein écran, avec une colonne (`VBoxContainer`) : le titre, un
corps vide qui accueillera la vue et les panneaux, et la barre d'état. `editor_shell.gd` écrit dans la barre d'état
par `show_status` et émet `status_changed` : les tests, et plus tard les autres parties de l'éditeur, apprennent ce
qui s'affiche sans aller lire le `Label`.

### 6. La documentation, vérifiée

Chaque script commence par sa description, en commentaires `##`, et chaque membre public a la sienne : c'est l'aide
intégrée de Godot (F1). `7_tests/1_core/test_documentation.gd` le vérifie sur tous les scripts du projet : un oubli fait
échouer les tests.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent ;
- F5 : la fenêtre s'ouvre, la barre d'état dit « Aucune salle ouverte ».
