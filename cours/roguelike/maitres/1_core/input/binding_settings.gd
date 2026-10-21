class_name BindingSettings extends Resource
## Réglages du menu des contrôles : les actions qu'on peut lier, dans l'ordre du menu et avec leur nom montré, et le
## fichier où leurs liaisons se sauvegardent. Un .tres dans 5_data/input/ ; la scène de démarrage le lit pour
## remettre les liaisons sauvegardées, le menu pour les montrer et les changer.

## Les actions qu'on peut lier, dans l'ordre du menu, et leur nom montré.
@export var titles: Dictionary[StringName, String] = {}
## Le fichier des liaisons sauvegardées.
@export var save_path: String = "user://input_bindings.cfg"


## Les actions qu'on peut lier, dans l'ordre du menu.
func actions() -> Array[StringName]:
	var listed: Array[StringName] = []
	listed.assign(titles.keys())
	return listed
