# Maaack's Scene Loader (chargement de scènes, écran de chargement)

Version vérifiée : v1.7.0 (2026-09-09), GDScript, licence MIT, dépôt `Maaack/Godot-Scene-Loader` (72 étoiles au
2026-10-22). Du même auteur : un modèle de jeu complet (menus, pause, crédits, chargement de scènes). Exemple minimal vérifié
dans Godot 4.7.2 : `python -m usine.rag.plugins verifier maaack_scene_loader`.

## Ce qu'il résout

Passer d'une scène à l'autre sans figer le jeu : l'autoload `SceneLoader` lance le chargement sur un fil
(`ResourceLoader.load_threaded_request`), affiche au besoin un écran de chargement avec sa progression, puis change
de scène. En arrière-plan (`in_background = true`), il prépare le niveau suivant pendant qu'on joue.

## Le choisir, ou Godot seul ?

- **Godot seul** : `ResourceLoader.load_threaded_request`, `load_threaded_get_status` et `load_threaded_get`, puis
  `SceneTree.change_scene_to_packed`, suffisent ; c'est une vingtaine de lignes.
- **Le plugin** : un écran de chargement prêt (barre, astuces), des exemples, et la même logique dans tout le jeu.

## API (lue dans le code de la v1.7.0)

- `SceneLoader` (`SceneLoaderClass`) : `load_scene(chemin, in_background)`, `get_status()`, `get_progress()`,
  `get_resource()`, `change_scene_to_resource()`, `change_scene_to_loading_screen()`,
  `set_loading_screen_path(chemin)`, `has_loading_screen()`, `reload_current_scene()` ; signal `scene_loaded`.
- Écran de chargement fourni : `res://addons/maaacks_scene_loader/base/nodes/loading_screen/loading_screen.tscn`.

## Installation

1. Copier `addons/maaacks_scene_loader/`.
2. Activer le plugin : il ajoute l'autoload `SceneLoader`
   (`res://addons/maaacks_scene_loader/base/nodes/autoloads/scene_loader/scene_loader.tscn`) et règle des chemins
   dans les paramètres du projet.

## Exemple minimal (vérifié)

`exemple/exemple.gd` (et la petite scène `exemple/niveau_2.tscn`) : le niveau 2 se charge en arrière-plan ; au
signal `scene_loaded`, on récupère la scène et on l'instancie. Mesuré : prête en 1 image, racine `Niveau2`.

```gdscript
SceneLoader.set_loading_screen_path("res://addons/maaacks_scene_loader/base/nodes/loading_screen/loading_screen.tscn")
SceneLoader.scene_loaded.connect(_on_scene_loaded)
SceneLoader.load_scene(NIVEAU, true)
var scene := ResourceLoader.load_threaded_get(NIVEAU) as PackedScene
```

## Pièges (relevés par l'exemple)

- Sans écran de chargement déclaré, `load_scene` écrit « ERROR: loading screen is not set » **même en arrière-plan**
  (il vérifie l'écran avant de regarder `in_background`). Déclarer un écran avec `set_loading_screen_path`.
- `get_resource()` relit la scène par `ResourceLoader.load` quand elle est déjà en cache : la demande de chargement
  sur fil n'est alors jamais récupérée, et Godot 4.7.2 écrit à la sortie « 1 ObjectDB instance was leaked at
  exit ». C'est vrai sans le plugin aussi (mesuré : `load_threaded_request` suivi de `load` fuit, suivi de
  `load_threaded_get` non). Récupérer le résultat par `ResourceLoader.load_threaded_get`.
- Le chargeur ferme le jeu si l'on colle (`ui_paste`) un texte dont le hachage vaut 3295764423
  (`_unhandled_key_input` de `scene_loader.gd`) : un raccourci de l'auteur, à connaître.
