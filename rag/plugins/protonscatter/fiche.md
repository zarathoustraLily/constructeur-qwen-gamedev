# ProtonScatter (dispersion procédurale d'objets en 3D)

Version vérifiée : branche `main`, commit `7198cc00078ebde61307578137c3f35223c6e438` (mise à jour le 2026-09-27),
GDScript, licence MIT, dépôt `HungryProton/scatter` (3 017 étoiles au 2026-10-22). Exemple minimal vérifié dans
Godot 4.7.2 : `python -m usine.rag.plugins verifier protonscatter`.

## Ce qu'il résout

Poser automatiquement des centaines d'objets (arbres, rochers, herbe, débris) dans des zones : un nœud
`ProtonScatter` contient des `ProtonScatterItem` (quoi poser : une scène, avec une proportion) et des
`ProtonScatterShape` (où : boîte, sphère, chemin ; une forme peut être négative pour creuser). Une pile de
modificateurs (`ProtonScatterModifierStack`) décrit le placement, étape par étape : créer au hasard, en grille, en
Poisson ou le long des bords ; décaler, tourner, mettre à l'échelle au hasard ; projeter sur le sol ; écarter
(`relax`) ; retirer au hasard ou hors des formes. La sortie utilise l'instanciation (`MultiMeshInstance3D`), donc
des milliers d'objets coûtent peu.

## Le choisir, ou Godot seul ?

- **Godot seul** : un `MultiMeshInstance3D` rempli par un script, avec un `RandomNumberGenerator` à graine fixe,
  suffit pour un placement simple (le `MultiMesh` est aussi la technique des cours de nos bâtiments pour les
  éléments répétés).
- **ProtonScatter** : un placement réglable dans l'éditeur, projeté sur le terrain, mélangé (plusieurs objets en
  proportions), avec exclusion de zones, sans écrire le code de placement.

## API (lue dans le code de la branche main)

- `ProtonScatter` : `enabled`, `global_seed`, `render_mode` (0 : instanciation, 1 : copies de nœuds, 2 : particules GPU), `keep_static_colliders`,
  `force_rebuild_on_load`, `enable_updates_in_game`, `modifier_stack`, `dbg_disable_thread` ; `rebuild()`,
  `full_rebuild()`, `clear_output()`, `is_thread_running()` ; signal `build_completed`.
- `ProtonScatterItem` : `path` (la scène à poser), `source` (scène courante ou disque), `proportion`,
  `override_material`, réglages de visibilité.
- `ProtonScatterShape` : `shape` (`ProtonScatterBoxShape.size`, `ProtonScatterSphereShape`,
  `ProtonScatterPathShape`), `negative`.
- `ProtonScatterModifierStack` : `add(modifier)`, `remove(modifier)`, `move(ancien, nouveau)`. Les modificateurs
  sont des scripts sans `class_name` (`src/modifiers/create_inside_random.gd`, `amount`…).

## Installation

Copier `addons/proton_scatter/` **sans le dossier `demos/`** si Blender n'est pas configuré dans l'éditeur.

## Exemple minimal (vérifié)

`exemple/exemple.gd` (et la petite scène `exemple/caillou.tscn`) : 20 cailloux au hasard dans une boîte de
10 × 1 × 10 m, graine 7 ; mesuré : 20 instances dans les `MultiMeshInstance3D` produits.

```gdscript
var pile := ProtonScatterModifierStack.new()
var au_hasard: ScatterBaseModifier = CREER_AU_HASARD.new()
au_hasard.set(&"amount", 20)
pile.add(au_hasard)
_dispersion.modifier_stack = pile
objet.path = "res://exemple/caillou.tscn"
```

## Pièges (relevés en le testant)

- La version publiée 4.0 (2023-10-23) ne compile plus dans Godot 4.7.2 : « Parse Error: Not all code paths return
  a value » (`src/scatter.gd:240`). Prendre la branche `main`, qui compile.
- Le dossier `demos/` contient `assets/source.blend` : sans chemin vers Blender, l'import du projet écrit « Blender
  path is invalid or not set » et n'importe pas les icônes du plugin (« Failed loading resource:
  res://addons/proton_scatter/icons/scatter.svg »). Sans ce dossier, l'import est propre (vérifié).
- Les modificateurs n'ont pas de `class_name` : on les charge par leur chemin, et on règle leurs propriétés par
  `set()` quand les avertissements sont des erreurs.
- Le calcul tourne par défaut sur un fil séparé ; attendre `build_completed` avant de compter le résultat.
