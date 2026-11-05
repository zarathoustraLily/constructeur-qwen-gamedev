# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le jeu ne voit pas les sprites : il voit des formes. Un mur, un conteneur, le bord de la salle
sont, pour lui, des polygones infranchissables. L'éditeur doit les montrer et les modifier, et refuser une forme que le
moteur ne saurait pas utiliser.

Ce qu'on obtient : un mode « Collisions » dans la barre du haut. Les formes apparaissent en rouge ; un clic en choisit
une ; on tire ses sommets ; un double-clic sur un côté ajoute un sommet ; Suppr retire le sommet choisi, puis la forme ;
Ctrl+clic crée une forme carrée. Une forme dont deux côtés se croiseraient est refusée, et la barre d'état dit pourquoi.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 ; choisir le mode « Collisions » ; cliquer dans un rectangle rouge, tirer un de ses coins.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une forme doit être simple

Un polygone dont deux côtés se croisent (un « nœud papillon ») n'a pas d'intérieur clair : le moteur de physique ne
sait pas dire de quel côté on est. `1_core/editor/collision_tools.gd` le détecte (`is_simple`) : chaque côté est
comparé à chaque autre côté non voisin par `Geometry2D.segment_intersects_segment`, qui rend le point de croisement,
ou `null`. Deux côtés voisins se touchent toujours en leur sommet commun : on ne les compare pas. `RoomData.validate()`
s'en sert désormais : « collision 3 : des côtés se croisent ». La règle est donc la même pour le document, pour
l'enregistrement, et pour toute salle chargée.

Les autres fonctions de `CollisionTools` rendent un **nouveau** polygone (sommet déplacé, ajouté, retiré ; forme
carrée) sans toucher à l'original : c'est le document qui décide, après validation, si le nouveau polygone remplace
l'ancien.

### 2. Les champs de la salle elle-même

Jusqu'ici, le document ne modifiait que les choses. Les collisions, les apparitions, la rencontre et les effets sont des
champs de la salle : `RoomDocument.set_room_fields` les change d'un coup (un seul pas d'annulation), après avoir
vérifié que le champ est modifiable (`ROOM_FIELDS`) et du bon type. Les collisions sont un `Array[PackedVector2Array]`,
un tableau **typé** : on le remplit par `assign`, car un tableau sans type lui serait refusé.

### 3. Les modes de la souris

Un même clic ne peut pas à la fois choisir une chose et un sommet. La coquille a donc des modes (`MODES`), choisis
dans la barre du haut : en mode « Choses », la sélection et le cadre bleu ; en mode « Collisions », les formes. Chaque
script d'entrée a un drapeau `active`, et laisse passer tous les événements quand il ne l'est pas. Les formes ne se
montrent que dans leur mode : elles cacheraient les sprites.

### 4. La souris des collisions

`4_ui/editor/collision_input.gd` convertit la souris en mètres (`screen_to_world`), et ses rayons de prise en mètres
aussi : 8 pixels font 0,27 m au zoom de départ, mais 0,07 m au zoom fort. Il garde la forme choisie et le sommet
choisi. Tirer un sommet montre un aperçu (`shown_polygons`), puis confie un seul changement au document au
relâchement. Quand il traite une touche, il le dit à la vue (`accept_event`) : sinon les raccourcis de l'étape 8
recevraient aussi Suppr, et supprimeraient la sélection de choses en plus du sommet. Le contour de la salle (la forme
0) ne se supprime pas.

### 5. Le calque des collisions

`4_ui/editor/collision_view.gd` dessine chaque forme : un fond rouge transparent (sauf le contour, qui couvrirait
toute la salle), un contour, et les sommets de la forme choisie. Il redessine quand le document, le cadrage ou la forme
choisie changent.

### 6. Un nom qui en masque un autre

Le premier jet donnait à la coquille une méthode `mode()`, qui rendait le mode courant. Godot a refusé de charger le
script : « The local function parameter "mode" is shadowing an already-declared function », pour `set_mode(mode)` et
pour la boucle `for mode in MODES`. Avec `shadowed_variable` traité en erreur, un paramètre ou une variable qui porte
le nom d'une méthode de la classe ne passe pas : on ne saurait plus, en lisant `mode`, lequel des deux est visé. La
méthode s'appelle maintenant `current_mode()`. Comme le script de la coquille ne se chargeait plus, la sortie se
terminait aussi par des fuites de textures et de polices : elles en étaient la conséquence, pas une autre cause. On
corrige la première erreur, puis on relit la sortie.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5, mode « Collisions » : tirer un coin d'une forme ; essayer de le faire passer de l'autre côté de la forme : refusé.
