# Visualiseur d'animations · étape {STEP} · {TITLE}

**Piste : {TRACK}.** On montre enfin l'asset choisi : son modèle 3D ou son animation 2D, avec la liste de ses
animations à droite. Tout se lit à l'exécution, sans l'import de Godot, pour que le visualiseur ouvre les fichiers où
qu'ils soient.

Ce qu'on obtient : choisir « heros » le montre dans la scène, en « pause » ; la liste de droite donne ses onze
animations, et en choisir une la joue. « flamme » montre l'atlas de l'optimiseur, « etincelle » le dossier d'images.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5, puis choisir un asset dans la liste.
3. Les tests : `7_tests/lancer_tests.bat`.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un modèle glTF, chargé à l'exécution

`1_core/viewer/model_loader.gd` passe par `GLTFDocument` : `append_from_file`, puis `generate_scene`, qui rend la scène
du modèle avec son `Skeleton3D` et son `AnimationPlayer`. Le dernier argument de `generate_scene`,
`remove_immutable_tracks`, vaut `true` par défaut. On le met à `false`, sinon le coffre resterait ouvert :

- l'animation « ferme » tient une seule valeur, le couvercle à 0°, sur toute sa durée ;
- avec le réglage par défaut, Godot retire cette piste constante, et « ferme » n'a plus aucune piste ;
- jouée après « ouverture », elle ne remet donc rien en place.

`test_model_view.gd` vérifie que « ferme » referme le coffre.

`LoadedModel` tient la scène hors de l'arbre. Qui la reçoit la pose sous un nœud, ou la libère (`free_scene`) ; un
modèle refusé ne laisse aucun nœud orphelin.

### 2. Ce que glTF ne dit pas : le fichier d'accompagnement

glTF ne dit pas si une animation boucle. C'est le fichier d'accompagnement, posé à côté de l'asset, qui le dit
(`heros.glb` → `heros.visu.json`, `visu.json` dans un dossier d'images) :

```json
{"boucles": ["course", "pause"]}
```

Il porte aussi la cadence d'un dossier d'images (`"ips": 16`). Absent, rien ne boucle et la cadence est de 24 images par
seconde, sans erreur. `1_core/viewer/asset_sidecar.gd` le lit ; le visualiseur l'écrira à l'étape 5, quand on cochera
« en boucle ».

### 3. Les animations 2D, sous leurs deux formes

`1_core/viewer/sprite_loader.gd` lit :

- **l'atlas de l'optimiseur** (format `atlas_animation`, version 1). Il donne des pages et, pour chaque image, sa zone
  dans la page (`zone`), son coin dans le cadre (`decalage`) et sa taille d'origine (`taille`). Une image réduite par
  l'optimiseur a une zone plus petite que sa taille ; une image vide a la page -1 ;
- **un dossier d'images** : une page par image, dans l'ordre de leurs numéros (tri naturel : `2` avant `10`).

Les PNG se lisent octet par octet : `FileAccess`, puis `Image.load_png_from_buffer`. `Image.load_from_file` sur un
chemin `res://` avertit que cela ne marchera plus une fois le projet exporté.

Toutes les valeurs du JSON passent par `1_core/viewer/json_values.gd`. Un objet devient un
`Dictionary[String, Variant]`, une liste un `Array[Variant]` : les conteneurs restent typés (règle COD-02), et une
valeur d'une mauvaise sorte donne un conteneur vide au lieu d'une erreur à l'exécution.

### 4. Les sujets

`3_entities/subject/subject.gd` donne la même façon de jouer aux deux formes : la liste des clips, `play`, `advance`,
`position_s`. Deux formes en héritent :

- `model_view.gd` pose la scène du modèle et règle la boucle de chaque animation ;
- `sprite_view.gd` montre l'image du moment par un `Sprite3D` tourné vers la caméra autour de la verticale.

Une image 2D se place dans le cadre là où l'optimiseur l'a prise. Le cadre est posé par le milieu de son bord bas, comme
un personnage par ses pieds. `Sprite3D.offset` est en pixels de la page et son y monte : pour une image réduite de
moitié, la taille du pixel double et le décalage se divise par deux, si bien que l'image ne bouge pas à l'écran.

Une animation « additif » (une lumière sur fond noir) prend un matériau qui s'ajoute à ce qui est derrière elle.

Les deux noms finissent par `_view` parce que ce sont des scripts de présentation : un `Sprite3D` dans un script de
logique est refusé (règle ARC-03), et leurs nombres de mise en page ne sont pas des chiffres d'équilibrage.

### 5. La scène et la coquille

`2_sequence/viewer/viewer_stage.tscn` réunit un sol, un soleil, la caméra et les deux sujets. Leurs places sont dans la
scène, pas dans le code (règle DAT-01). Elle charge l'asset choisi avec son accompagnement et lance « pause » s'il en a
une, sinon sa première animation.

La coquille montre la scène dans un `SubViewportContainer`, et la liste des animations à droite
(`4_ui/viewer/clip_list.gd`).

En test, la lecture avance à la main (`manual`) : un `AnimationPlayer` en `ANIMATION_CALLBACK_MODE_PROCESS_MANUAL` ne
bouge que par `advance`, d'autant de secondes qu'on veut.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent ;
- F5, « heros » : le pantin respire en « pause » ; « course » court en boucle, « attaque » s'arrête à la fin ;
- « coffre », « ouverture » puis « ferme » : le coffre se referme ;
- « flamme » : la flamme danse en boucle, sans sauter d'une image à l'autre.
