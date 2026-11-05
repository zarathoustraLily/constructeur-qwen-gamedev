# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Toutes les modifications de l'éditeur (déplacer, tourner, mettre à l'échelle, ajouter,
supprimer) vont passer par un seul objet : le document. C'est lui qui garantit qu'une salle invalide n'apparaît
jamais, que chaque geste s'annule, et qu'on sait si la salle a changé depuis le dernier enregistrement. On le construit
avant la moindre vue : il se teste sans fenêtre, et tout ce qui suivra s'y branchera.

Ce qu'on obtient : un document qui ouvre une salle, la modifie champ par champ ou plusieurs choses d'un coup, refuse
ce qui la rendrait invalide, annule et refait ; un historique peu coûteux ; une sélection par identifiants.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. Rien de nouveau à l'écran : le document n'a pas de vue. Ses tests le montrent à l'œuvre.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Modifier une copie, valider, puis seulement adopter

`1_core/editor/room_document.gd` ne modifie jamais la salle courante directement. Chaque opération :
1. copie la salle (`duplicate(true)`) ;
2. applique le changement à la copie ;
3. valide la copie (`RoomData.validate()`, celle de l'étape 2) ;
4. si elle est valide, l'adopte comme état courant et la pousse dans l'historique ; sinon, rend `false` et laisse ses
   raisons dans `errors`, sans rien changer.

Une échelle nulle, un calque inconnu, une chose attachée à un parent supprimé : tout est arrêté au même endroit, par
les mêmes règles que celles de l'enregistrement.

### 2. Des champs courts, reliés aux colonnes

Les vues et les panneaux parlent de `position`, `scale`, `layer`… `COLUMNS` relie chaque nom court à la colonne de
`RoomData` (`thing_positions`, `thing_scales`, `thing_layers`…), et `TYPES` dit le type attendu. Une valeur du mauvais
type est refusée avec une phrase claire (« position : Vector3 attendu ») avant de toucher au tableau, où elle aurait
provoqué une erreur de Godot. Un entier passe pour un nombre à virgule, un booléen pour l'actif (0 ou 1) : c'est ce
que donneront naturellement les panneaux.

### 3. Un seul pas pour un geste

Déplacer trois choses sélectionnées, c'est un geste : il doit s'annuler en une fois. `apply` reçoit tous les changements
d'un coup (`{identifiant: {champ: valeur}}`) et n'en fait qu'un pas d'annulation, ou rien si une seule valeur est
refusée. `add_thing` donne à la nouvelle chose l'identifiant libre suivant et les valeurs par défaut de `DEFAULTS`, mais
exige `asset` et `layer`. `remove_things` refuse de supprimer un parent tant qu'une chose qui reste lui est attachée,
et emporte les champs inconnus des choses supprimées.

### 4. Un historique qui coûte peu

`1_core/editor/undo_stack.gd` garde des instantanés entiers de la salle. Ça paraît cher ; ça ne l'est pas : un tableau
compact de Godot se copie **à l'écriture**. Tant qu'une colonne n'a pas changé, l'instantané et la salle partagent le
même bloc de mémoire ; un déplacement ne recopie que la colonne des positions. Au-delà de `MAX_STATES` instantanés,
les plus anciens sont oubliés.

### 5. « Modifiée », par révision

Comparer la salle courante à celle qu'on a enregistrée serait long. Chaque instantané porte plutôt un numéro de
révision ; `mark_saved()` retient celui de l'état enregistré, et la salle est modifiée dès que la révision courante
diffère. Une annulation qui ramène à l'état enregistré rend la salle non modifiée ; une annulation au-delà la rend
modifiée de nouveau. `dirty_changed` n'est émis qu'au changement.

### 6. Pas de modification pendant une notification

Un abonné à `changed` qui modifierait la salle pendant qu'on le prévient lancerait une modification au milieu d'une
autre. Le document le refuse (« Modification refusée pendant une notification ») ; le test
`test_un_abonne_ne_modifie_pas_la_salle_pendant_la_notification` le vérifie.

### 7. La sélection, un modèle

`1_core/editor/selection_model.gd` garde des **identifiants** : un indice change dès qu'on supprime une chose, un nœud
disparaît quand la vue se redessine, l'identifiant reste. `changed` n'est émis que si la sélection change vraiment ;
`retain` retire ce qui n'existe plus après une suppression ou une annulation. Les vues et les panneaux s'y abonneront.

### 8. Une fuite, trouvée en lisant toute la sortie

Au premier passage, les 50 tests étaient verts et GdUnit4 rendait le code 0, mais la sortie finissait par deux
lignes : « 13 ObjectDB instances were leaked at exit » et « 5 resources still in use at exit ». Un test vert ne suffit
pas : on lit chaque ligne. La cause était dans le test de la notification : la fonction anonyme branchée sur `changed`
utilisait `document`, donc le gardait ; et le document gardait la fonction, par son signal. Deux objets à comptage de
références qui se tiennent l'un l'autre ne sont jamais libérés, ni eux, ni les salles de leur historique. Le test
débranche maintenant la fonction (`changed.disconnect(handler)`) avant de finir ; la sortie est propre.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, et la sortie ne signale aucune fuite à la fin.
