# GLoot (inventaires)

Version vérifiée : v3.0.2 (2026-07-05), GDScript pur, licence MIT, dépôt `peter-kish/gloot` (985 étoiles au
2026-10-22). La v3 n'est pas compatible avec la v2. Exemple minimal vérifié dans Godot 4.7.2 :
`python -m usine.rag.plugins verifier gloot`.

## Ce qu'il résout

Un inventaire (`Inventory`, un nœud) d'objets (`InventoryItem`) créés d'après des prototypes décrits dans une
ressource JSON (`protoset`). Des contraintes, nœuds enfants de l'inventaire, le limitent : `WeightConstraint`
(poids total, propriété `weight` de chaque objet), `GridConstraint` (place dans une grille), `ItemCountConstraint`
(nombre d'objets). `ItemSlot` tient un seul objet (équipement). Le plugin fournit aussi des contrôles d'interface
pour afficher et manipuler l'inventaire.

## Le choisir, ou Godot seul ?

- **Godot seul** : un tableau typé de ressources (`Array[ItemData]`, des `.tres` de `5_data`) suffit pour un petit
  inventaire sans règles.
- **GLoot** : dès qu'il y a des piles, un poids ou une grille, des transferts entre inventaires, de l'équipement et
  une interface toute faite.

## API (lue dans le code de la v3.0.2)

- `Inventory` : `protoset` (JSON), `create_item(prototype_id)`, `create_and_add_item(prototype_id)`,
  `add_item(item)`, `can_add_item(item)`, `remove_item(item)`, `get_items()`, `get_item_count()`,
  `get_item_with_prototype_id(id)`, `has_item_with_prototype_id(id)`, `move_item(from, to)` ; signaux
  `item_added`, `item_removed`, `item_property_changed`, `item_moved`.
- `InventoryItem` : `get_property(nom, defaut)`, `set_property(nom, valeur)`, `get_title()`, `get_stack_size()`,
  `split(taille)`, `merge_into(cible)`, `get_prototype()`.
- `WeightConstraint` : `capacity`, `get_occupied_space()`, `get_free_space()`, `has_space_for(item)`.

## Installation

Copier `addons/gloot/`. Aucun autoload.

## Exemple minimal (vérifié)

`exemple/exemple.gd` : un inventaire limité à 5 de poids accepte une potion (1) et une épée (4), puis refuse une
seconde épée. Résultat : 2 objets, poids 5,0 sur 5,0.

```gdscript
var prototypes := JSON.new()
prototypes.data = {"potion": {"name": "Potion", "weight": 1.0}, "epee": {"name": "Épée", "weight": 4.0}}
sac.protoset = prototypes
var poids := WeightConstraint.new()
poids.capacity = 5.0
sac.add_child(poids)
```

## Pièges (relevés par l'exemple)

- À la sortie du programme, Godot écrit « WARNING: 5 ObjectDB instances were leaked at exit » et « ERROR: 1
  resources still in use at exit » : le cache statique des prototypes (`core/prototree/proto_tree_cache.gd`,
  `static var _cache`) garde les `Prototype` jusqu'au bout. Le jeu n'en souffre pas, mais un test qui lit chaque
  ligne de sortie doit savoir que ces deux lignes viennent du plugin.
- Libérer l'inventaire (`queue_free()`) avant de quitter ne supprime pas ces lignes : elles ne viennent pas du jeu.
- Dans un projet aux avertissements stricts, les prototypes vont dans un fichier `.json` de `5_data/` (règle
  DAT-01), pas dans un dictionnaire écrit dans le code comme dans cet exemple minimal.
