# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Avant de dessiner quoi que ce soit, on fixe ce que l'éditeur écrit et que le jeu lit : la salle.
C'est le contrat entre les deux. S'il est flou, l'éditeur produira des salles que le jeu chargera mal ; s'il est
précis et vérifié, tout le reste de l'éditeur n'est qu'une façon de le modifier sans le casser.

Ce qu'on obtient : trois salles d'exemple (`5_data/salles/hangar.tres`, `soute.tres`, `pont.tres`), une classe qui
dit si une salle est valide, phrase par phrase, et un magasin qui lit une copie privée et écrit sans jamais laisser un
fichier à moitié écrit.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. Double-cliquer sur `5_data/salles/hangar.tres` : l'Inspecteur montre la salle, ses groupes Choses, Collisions,
   Apparitions, Rencontre et Effets.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une salle en tableaux compacts

Une salle pose des centaines de choses : dalles de sol, détails, obstacles, avant-plan. Une sous-ressource par chose
ferait un fichier énorme, long à charger, et autant d'objets en mémoire. `1_core/data/room_data.gd` range plutôt les
choses **en colonnes** : un tableau compact par champ (`PackedInt32Array` pour les identifiants,
`PackedVector3Array` pour les positions, `PackedFloat32Array` pour les rotations…), tous de la même longueur. La chose
n° i, c'est `thing_ids[i]`, `thing_positions[i]`, `thing_assets[i]`… Un tableau compact est un seul bloc de mémoire :
le hangar et ses 203 choses se chargent d'un coup.

Chaque chose a un **identifiant stable** (`thing_ids`) : l'indice change quand on supprime une chose, l'identifiant
jamais. La sélection, l'annulation et les attaches (`thing_parents`) s'appuieront dessus.

La salle porte aussi ce que le jeu en attend : les formes de collision (`collisions`), le départ du héros et les points
d'apparition avec leur rôle (`spawn_positions`, `spawn_roles`), les ennemis que la rencontre peut tirer
(`encounter_pool`) et sa profondeur, les effets placés. Les groupes d'export (`@export_group`) rangent l'Inspecteur.

### 2. Les champs inconnus, gardés tels quels

Un autre outil peut ajouter des champs à une chose, que l'éditeur ne connaît pas. `thing_extras` les garde, par
identifiant de chose, sous forme d'un objet JSON en texte. L'éditeur ne les réécrit jamais : ce qu'il ne comprend pas,
il ne le touche pas. Le hangar en contient deux, pour que les tests le vérifient.

### 3. Valider, phrase par phrase

`validate()` rend la liste des erreurs, une phrase par erreur, vide si la salle est valide :
- une colonne qui n'a pas la longueur de `thing_ids` : « thing_names : 202 valeurs pour 203 choses ». Les autres
  contrôles lisent les colonnes par indice : on s'arrête là, sinon ils sortiraient des tableaux ;
- un identifiant nul ou en double, un calque absent de `layers`, une échelle nulle, une rotation hors de [0, 360[, un
  parent introuvable, une forme de moins de 3 sommets, un rôle d'apparition inconnu, des champs inconnus illisibles.

Chaque phrase nomme la chose par son identifiant : c'est ce que l'éditeur montrera à l'utilisateur.

### 4. Lire une copie privée

Godot garde en cache chaque ressource chargée : deux `load()` du même chemin rendent **le même objet**. Si l'éditeur
modifiait ce qu'il a chargé ainsi, le jeu et toute autre partie du projet verraient la salle changer avant même qu'on
l'enregistre. `RoomStore.load_room` charge avec `ResourceLoader.CACHE_MODE_IGNORE` : une copie à lui, qu'il peut
modifier librement. Le test `test_la_lecture_rend_une_copie_privee` le vérifie.

Un piège voisin : un tableau compact se lit **par copie**. `room.thing_names.remove_at(0)` ne modifie que la copie ;
il faut lire le tableau, le modifier, puis le réaffecter (`room.thing_names = names`). Les tests le font ainsi.

### 5. Écrire sans jamais laisser un fichier à moitié écrit

`RoomStore.save_room` :
1. valide la salle : une salle invalide n'est jamais écrite ;
2. n'accepte qu'un nom simple en `.tres`, dans le dossier des salles : pas de `../`, pas de sous-dossier ;
3. confie l'écriture à `StableSaver` : la salle s'enregistre dans un fichier voisin (`.hangar.enregistrement.tres`, qui
   garde l'extension `.tres`, car `ResourceSaver` choisit son format d'après l'extension), et ce voisin ne remplace
   l'ancien fichier (`DirAccess.rename_absolute`) qu'une fois complet ; en cas d'échec, le voisin est effacé et
   l'ancien fichier reste intact.

### 6. L'aller-retour à l'octet

Enregistrer deux fois la même salle doit donner exactement les mêmes octets : sinon chaque enregistrement changerait
le fichier, et l'historique des versions (étape 17) se remplirait de différences sans objet.

Le premier essai a échoué : `test_deux_enregistrements_donnent_les_memes_octets` trouvait deux fichiers différents.
En comparant leurs lignes, une seule différence : l'identifiant de la ressource externe (le script de la salle),
`id="1_8umkc"` dans l'un, `id="1_8qlov"` dans l'autre. `ResourceSaver` le tire au hasard, et la méthode qui le garderait,
`Resource.set_id_for_path`, « n'est implémentée que dans le contexte de l'éditeur » (référence de la classe Resource,
4.7.2) : l'éditeur de niveaux, lancé comme un jeu, n'y a pas droit. `StableSaver` renomme donc ces identifiants dans leur
ordre d'apparition (`1_ext`, `2_ext`…), dans la déclaration `[ext_resource … id="…"]` et dans chaque `ExtResource("…")`,
avant de remplacer le fichier. Ses tests vérifient le renommage, qu'un texte déjà stable ne change plus, et que deux
enregistrements, même vers deux fichiers, donnent les mêmes octets.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent ;
- l'Inspecteur montre les trois salles d'exemple.
