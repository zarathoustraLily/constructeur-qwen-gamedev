class_name DefinitionFolder
extends RefCounted
## Les définitions d'une famille, rangées une par fichier dans un dossier de `5_data` (`5_data/ennemis/`,
## `5_data/effets/`…) : on les charge toutes, triées par identifiant. Un fichier qui n'est pas de la bonne classe est
## signalé, pas ignoré en silence. Les fichiers commençant par un point (une écriture en cours) sont laissés de côté.

## Les erreurs du dernier chargement, une phrase par erreur.
var errors: Array[String] = []


## Les définitions du dossier `folder` qui ont le script `script` (par exemple `EnemyDef`), triées par identifiant.
func load_all(folder: String, script: Script) -> Array[Resource]:
	errors.clear()
	var found: Array[Resource] = []
	if not DirAccess.dir_exists_absolute(folder):
		errors.append("Dossier introuvable : " + folder)
		return found
	for file: String in DirAccess.get_files_at(folder):
		if file.get_extension() != "tres" or file.begins_with("."):
			continue
		var definition: Resource = ResourceLoader.load(folder.path_join(file))
		if definition == null or definition.get_script() != script:
			errors.append("%s : pas une définition de cette famille" % file)
			continue
		found.append(definition)
	found.sort_custom(func(a: Resource, b: Resource) -> bool: return String(a.get(&"id")) < String(b.get(&"id")))
	return found
