# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un ennemi joue un clip selon son état : il respire au repos, court, frappe, encaisse, tombe,
apparaît. Le jeu doit savoir quel clip jouer dans chaque état, à quelle vitesse, et en combien de temps passer de l'un à
l'autre. Ces réglages sont des données ; l'éditeur doit les modifier, et refuser de citer un clip que le modèle n'a pas.

Ce qu'on obtient : deux modèles d'exemple (un bipède, un volant, faits de primitives, avec un `AnimationPlayer` et six
clips), une définition d'animation par ennemi, et un mode « Animations » : pour chaque état, le clip choisi dans une liste
qui ne propose que les clips du modèle, et sa vitesse. Une définition qui cite un clip absent ne s'écrit pas.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. `6_assets/exemple/modeles/bipede.tscn` : le modèle ; son `AnimationPlayer` joue « repos », « course »…
3. F5 ; mode « Animations » ; « brute » ; changer le clip de l'attaque ; « Enregistrer ».
4. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Des modèles fictifs, avec de vrais clips

Les modèles d'exemple sont des scènes simples : un `MeshInstance3D` (une capsule ou une sphère) et un `AnimationPlayer`
dont la bibliothèque (`AnimationLibrary`) porte six clips. Chaque clip anime une propriété du corps (`Corps:scale`,
`Corps:rotation`, `Corps:position`) par trois clés ; « repos » et « course » bouclent. Ils sont fictifs, mais un vrai
modèle importé aura la même forme : un `AnimationPlayer` et des clips nommés. Le générateur des données d'exemple les
écrit au format texte de Godot.

### 2. La définition, vérifiée sur le modèle

`1_core/data/animation_def.gd` relie chaque état du jeu (`STATES`) à un clip et à une vitesse. Sa validation va plus loin
que les champs : elle instancie le modèle, trouve son `AnimationPlayer` (`find_children`), lit ses clips
(`get_animation_list`), puis libère l'instance (`free`) ; chaque clip cité doit y être. Un état sans clip, un état
inconnu ou une vitesse nulle sont signalés aussi. Comme cette règle est dans `validate()`, l'éditeur des définitions de
l'étape 13 la respecte sans rien changer : il refusera lui aussi d'écrire une animation qui cite un clip absent.

### 3. Le panneau des animations

`4_ui/editor/animation_panel.gd` construit une ligne par état : un `OptionButton` rempli des clips du modèle (on ne peut
pas y choisir un clip qui n'existe pas) et un `SpinBox` pour la vitesse. Un changement passe par l'éditeur des
définitions : il copie le dictionnaire des clips, change l'état, et le donne d'un bloc (`set_value(&"clips", …)`), en
gardant son type (`Dictionary[StringName, StringName]`). Sous les lignes, ce que la validation refuse ; « Enregistrer »
n'écrit qu'une définition valide.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5, mode « Animations » : changer un clip, enregistrer, rouvrir : le changement est là.
