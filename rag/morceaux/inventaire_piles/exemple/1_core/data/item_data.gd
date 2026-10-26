class_name ItemData
extends Resource
## Définition d'un objet, immuable pendant la partie : ses valeurs vivent dans un .tres de 5_data/items/.

## Identifiant stable, en snake_case, jamais renommé : deux objets de même id s'empilent.
@export var id: StringName
@export var display_name: String = ""
## Nombre d'exemplaires par emplacement (1 : ne s'empile pas).
@export var max_stack: int = 1


## Erreurs de la définition ; vide si elle est valide.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : id « %s » vide ou hors snake_case" % [resource_path, id])
	if max_stack < 1:
		errors.append("%s : max_stack %d (attendu >= 1)" % [resource_path, max_stack])
	return errors
