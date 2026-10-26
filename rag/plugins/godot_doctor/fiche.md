# Godot Doctor (valider scènes et ressources avant de jouer)

Version vérifiée : 2.2.0 (2026-07-23), GDScript (et C#), licence MIT, dépôt `codevogel/godot_doctor` (170 étoiles
au 2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 : `python -m usine.rag.plugins verifier godot_doctor`.

## Ce qu'il résout

Attraper avant l'exécution les erreurs de réglage : un `@export` oublié, une chaîne vide, une valeur hors bornes, un
enfant manquant, une scène du mauvais type. Chaque script déclare ses conditions dans
`_get_validation_conditions()` ; le plugin les évalue dans l'éditeur (sans `@tool` pour les nœuds) et signale les
problèmes. Par défaut, il vérifie aussi seul que les `@export` d'objets sont assignés et les chaînes non vides. Il
tourne aussi en ligne de commande, avec un code de sortie non nul et un rapport JUnit (pour une intégration
continue).

## Le choisir, ou Godot seul ?

- **Godot seul** : `_get_configuration_warnings()` sur un script `@tool` affiche des avertissements dans l'éditeur ;
  `assert` vérifie au lancement.
- **Godot Doctor** : des conditions déclaratives sans `@tool`, des vérifications par défaut sur tous les `@export`,
  et une validation de tout le projet en ligne de commande avant un commit.

## API (lue dans le code de la 2.2.0)

- Dans un script : `func _get_validation_conditions() -> Array[ValidationCondition]`.
- `ValidationCondition` : `new(callable, message, severity)`, `simple(resultat, message)`, `is_instance_valid(objet,
  nom)`, `is_string_not_empty`, `is_in_range_int`, `is_in_range_float`, `has_child_count`,
  `has_minimum_child_count`, `has_node_path`, `is_scene_of_type(scene, type)`.
- `GodotDoctorValidator` : `validate_scene_root(racine)`, `validate_resource(ressource)`,
  `evaluate_conditions(conditions)` (statique) ; signaux `validated_node`, `validated_resource`.
- Ligne de commande : `godot --headless --editor --quit-after 100 -- --run-godot-doctor`, avec une
  `GodotDoctorValidationSuite` déclarée dans `addons/godot_doctor/settings/godot_doctor_settings.tres` (d'après son
  README).

## Installation

Copier `addons/godot_doctor/` et activer le plugin. Sans C# dans le projet, ses dossiers `core/csharp` et
`examples/csharp` peuvent être retirés (d'après son README).

## Exemple minimal (vérifié)

`exemple/exemple.gd` : un ennemi à santé nulle et sans cible. Mesuré : 2 problèmes, « La santé doit être
positive » et « cible is not a valid instance. ».

```gdscript
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		ValidationCondition.simple(sante > 0, "La santé doit être positive"),
		ValidationCondition.is_instance_valid(cible, "cible"),
	]
```

## Pièges

- Un script de **ressource** doit porter `@tool` pour être validé (limite du moteur, d'après le README) ; un script
  de nœud, non.
- `ValidationCondition.simple` évalue son résultat tout de suite : pour une condition qui doit se réévaluer, passer
  une fonction à `ValidationCondition.new`.
- Hors de l'éditeur, le plugin n'est pas actif : l'exemple appelle directement `evaluate_conditions`.
- Son module de mise à jour interroge GitHub ; hors ligne, il ne trouve rien.
