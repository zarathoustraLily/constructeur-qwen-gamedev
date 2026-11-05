# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Jusqu'ici, l'éditeur lisait les définitions du jeu (ennemis, effets) sans les modifier. On veut
maintenant régler le jeu lui-même depuis l'éditeur : la santé d'une brute, la cadence d'un tireur, le débit d'une
fumée. Sans écrire un formulaire par classe : un seul éditeur, qui lit les champs de n'importe quelle définition.

Ce qu'on obtient : un mode « Paramètres ». À droite, une famille (Ennemis, Effets), la liste de ses définitions, et le
formulaire de celle qu'on choisit : un champ par variable exportée de son script. « Enregistrer » n'écrit que si la
définition est valide ; sinon, les erreurs s'affichent, et rien n'est écrit. « Annuler » défait le dernier changement.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 ; mode « Paramètres » ; « Ennemis », puis « brute » ; changer `max_health` ; « Enregistrer ».
3. Mettre `weight` à 0 : le formulaire le signale ; « Enregistrer » est refusé.
4. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les champs d'une définition, lus du script

`1_core/editor/definition_editor.gd` ne connaît ni `EnemyDef` ni `FxDef`. Il demande à la définition ses propriétés
(`get_property_list()`) et garde celles qui portent à la fois `PROPERTY_USAGE_SCRIPT_VARIABLE` (une variable du script,
pas une propriété de Godot comme `resource_name`) et `PROPERTY_USAGE_EDITOR` (exportée, visible dans l'Inspecteur).
`id` est exclu : une définition ne se renomme jamais, les salles la citent. Ajouter un champ à `EnemyDef`, c'est le
voir apparaître dans le formulaire, sans toucher à l'éditeur.

Chaque changement vérifie le type attendu (un entier vaut pour un nombre à virgule ; un texte devient un `StringName`
pour un champ de ce type) et garde une copie de l'état d'avant, pour l'annulation.

### 2. Valider, écrire, puis mettre à jour ce qui est chargé

`save()` appelle la validation de la définition elle-même (`validate()`, celle que le jeu applique) ; une définition
invalide ne s'écrit pas. Sinon, l'enregistreur stable de l'étape 2 l'écrit. Reste un piège : le reste du projet a déjà
chargé cette définition (la rencontre de la salle, par exemple), et Godot lui a rendu l'objet de son cache. Écrire le
fichier ne change pas cet objet. Un dernier `ResourceLoader.load(chemin, "", CACHE_MODE_REPLACE)` relit le fichier
**dans l'objet déjà en cache** (« leurs données sont rafraîchies depuis le stockage dans les instances existantes »,
référence de ResourceLoader, 4.7.2) : tous ceux qui le tiennent voient la nouvelle valeur. Le test
`test_une_definition_valide_s_ecrit_et_le_projet_la_voit` le vérifie sur un objet chargé avant l'enregistrement.

### 3. Le formulaire, construit d'après les champs

`4_ui/editor/definition_panel.gd` construit une ligne par champ selon son type : un `SpinBox` pour un nombre (au pas
fin de l'inspecteur, pour la même raison qu'à l'étape 8), une case pour un booléen, un sélecteur pour une couleur, une
ligne de texte pour le reste. Après chaque changement, il affiche ce que la validation refuserait, avant même qu'on
enregistre. L'annulation reconstruit le formulaire depuis la définition.

### 4. Des tests qui ne réécrivent pas le jeu

Les tests copient les définitions dans `user://` et travaillent sur la copie : un passage des tests ne change jamais
la santé d'un ennemi du jeu.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5, mode « Paramètres » : modifier un ennemi, l'enregistrer ; passer en mode « Apparitions » : la rencontre voit la
  nouvelle valeur dans les contrôles.
