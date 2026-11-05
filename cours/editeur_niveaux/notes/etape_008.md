# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Autour de la vue, les trois panneaux d'un éditeur : la palette pour poser, la hiérarchie pour
trouver, l'inspecteur pour régler au chiffre près ; et les raccourcis qu'on attend sous les doigts. Aucun ne modifie
la salle lui-même : chacun appelle les gestes de l'étape 5, et lit le document et la sélection de l'étape 3.

Ce qu'on obtient : F5, à gauche la hiérarchie des calques et la palette ; à droite l'inspecteur ; un double-clic dans la
palette pose l'asset au centre de la vue ; Ctrl+Z, Ctrl+Y, Suppr, Ctrl+D et les flèches marchent.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 ; chercher « caisse » dans la palette, double-cliquer ; changer son échelle dans l'inspecteur ; Ctrl+Z.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. La palette

`4_ui/editor/palette_panel.gd` : une zone de recherche (`LineEdit`) et une liste (`ItemList`). Chaque frappe relance la
recherche de l'étape 4 ; chaque asset montré a sa vignette, une `AtlasTexture` qui ne garde de la planche que sa région :
aucune image n'est recopiée. Un double-clic, ou Entrée (`item_activated`), émet `asset_chosen` ; la coquille pose
l'asset au centre de la vue, dans son calque par défaut, et le sélectionne.

### 2. La hiérarchie

`4_ui/editor/hierarchy_panel.gd` : un `Tree` où chaque calque porte ses choses, dans l'ordre de dessin, chacune avec son
nom et son identifiant (gardé en métadonnée de la ligne). Un clic sélectionne la chose, y compris une dalle du sol, que
la vue ne laisse pas prendre ; la sélection faite dans la vue se reflète ici. Reconstruire l'arbre sélectionne des
lignes, ce qui émet `item_selected` : sans le garde `_refreshing`, la hiérarchie se renverrait la sélection à elle-même.

### 3. L'inspecteur

`4_ui/editor/inspector_panel.gd` construit une ligne par champ : un `SpinBox` pour les nombres, un `LineEdit` pour le
nom, un `OptionButton` pour le calque, une `CheckBox` pour l'actif, un `ColorPickerButton` pour la couleur. Chaque
changement appelle `edit(champ, valeur)`, qui passe par `EditorActions` : un pas d'annulation, et la même validation
que partout. Le rang (`sort`) est entier : la valeur du `SpinBox` est arrondie (`roundi`) avant de partir, sinon le
document la refuserait (« sort : int attendu »).

L'affichage d'une valeur ne doit pas renvoyer une modification. On écrit donc sans émettre de signal :
`set_value_no_signal`, `set_pressed_no_signal`, `select` (l'`OptionButton` n'émet pas `item_selected` quand on le
change en code). Pour plusieurs choses sélectionnées, seuls les champs qu'on peut leur donner ensemble restent
visibles (calque, actif, parallaxe, hauteur, couleur) : donner la même position à trois caisses les empilerait. Les
champs inconnus de la chose s'affichent tels quels, « Non édité : … », en lecture seule.

### 4. Les raccourcis

`4_ui/editor/editor_shortcuts_input.gd` reçoit les touches que personne d'autre n'a prises
(`_unhandled_key_input`) : quand on tape un nom dans l'inspecteur, Suppr efface une lettre, pas la sélection.
Ctrl+Z annule, Ctrl+Y ou Ctrl+Maj+Z refait, Suppr supprime, Ctrl+D duplique et sélectionne les doubles, les flèches
déplacent d'un pas de grille (quatre avec Maj). Ses tests lui envoient des `InputEventKey` fabriqués.

### 5. La place de chacun

La coquille range les panneaux dans le même corps que la vue : la colonne de gauche ancrée à gauche, l'inspecteur
ancré à droite, et la vue entre les deux (marges `offset_left` et `offset_right`). Les chemins des nœuds de la vue ne
changent pas, et les étapes précédentes restent valables.

Pour poser au centre de la vue, la coquille prend le centre du rectangle de la vue
(`Rect2(Vector2.ZERO, _view.size).get_center()`) plutôt que `_view.size / 2.0` : dans `2_sequence`, la règle du
projet refuse tout nombre écrit dans le code, et ce 2 en serait un.

### 6. Deux échecs au premier passage

**L'inspecteur affichait 1,26 pour une échelle de 1,25.** Le premier jet donnait au `SpinBox` de l'échelle un minimum
de 0,01 et un pas de 0,05. Or un `Range` « arrondit toujours sa valeur à un multiple de son pas, compté depuis
`min_value` » (référence de la classe Range, 4.7.2) : 0,01 + 0,05 × k, soit 1,21, 1,26… jamais 1,25. L'affichage
trahissait la donnée, et une modification d'un autre champ aurait pu la recopier fausse. Les champs ont maintenant un
pas fin (`PRECISION`, 0,001) et un pas de flèches à part (`custom_arrow_step`). Seul le rang garde un pas de 1 : il est
entier.

**Suppr ne supprimait pas.** Le test prenait le premier obstacle du pont ; or une lampe y était attachée, et le
document refuse de supprimer un parent tant qu'une chose qui reste lui est attachée (étape 3). Le comportement était
juste, le test faux : il prend maintenant un obstacle sans rien d'attaché. Avant de corriger le code, on vérifie ce
que le test suppose.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5 : poser une caisse par la palette, la régler dans l'inspecteur, la retrouver dans la hiérarchie, Ctrl+Z.
