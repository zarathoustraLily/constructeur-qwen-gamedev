# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un jeu a plus de trois salles. Il faut en créer, et pouvoir les renommer sans rien casser. Le
piège classique : ranger une salle sous son nom affiché. Le jour où l'on renomme « Le hangar » en « Le grand hangar »,
le fichier change de nom, et tout ce qui le citait (la chaîne des salles du jeu, l'historique des versions) le perd.

Ce qu'on obtient : en haut, un champ de nom, « Nouvelle salle » et « Renommer ». Une salle neuve reçoit un identifiant
tiré de son nom, unique dans le projet, qui devient le nom de son fichier et ne change plus ; renommer ne change que le
nom affiché.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 ; taper « Salle des machines », « Nouvelle salle » : `5_data/salles/salle_des_machines.tres` apparaît, et s'ouvre.
3. Taper « La salle du moteur », « Renommer », Ctrl+S : le fichier garde son nom.
4. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un identifiant tiré du nom, une fois pour toutes

`1_core/editor/room_factory.gd` tire l'identifiant du nom : minuscules et sans accents (la même normalisation que la
recherche de la palette), puis tout ce qui n'est ni une lettre ni un chiffre devient un tiret bas
(`RegEx.sub`, sur toutes les occurrences), sans tiret bas au début ni à la fin. « Pont supérieur ! » donne
`pont_superieur`. Si l'identifiant existe déjà, on ajoute `_2`, `_3`… ; un nom qui ne donne rien (« ?! ») donne
`salle`. L'identifiant est le nom du fichier ; après la création, plus rien ne le change.

### 2. Une salle neuve, déjà valide

Une salle neuve a sa taille (`new_room_size_m`, dans les réglages), les calques du catalogue, son contour de collision
(un rectangle de la taille de la salle), et le départ du héros au milieu, un peu au-dessus du bord bas. Elle passe donc
la validation dès sa création, et s'enregistre par le magasin comme toute autre salle.

### 3. Renommer, c'est changer un champ

Le nom affiché devient un champ de salle modifiable (`display_name` dans `ROOM_FIELDS`) : renommer est un pas
d'annulation comme un autre, la salle devient modifiée, et le titre suit. Le test
`test_renommer_ne_change_que_le_nom_affiche` enregistre la salle renommée et vérifie que son fichier et son identifiant
n'ont pas bougé. Le test de l'étape 10 qui refusait `display_name` vaut jusqu'à l'étape 15 ; il vérifie maintenant le
refus d'un autre champ, `size_m`.

### 4. Ne rien perdre en créant

Créer une salle ouvre la salle neuve. Comme pour changer de salle (étape 9), c'est refusé si la salle ouverte a des
modifications non enregistrées, et la barre d'état dit quoi faire.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5 : créer une salle, la renommer, l'enregistrer ; son fichier garde le nom de sa création.
