extends SceneTree
## Fait réécrire des scènes par Godot lui-même : chargement puis ResourceSaver.save au même chemin.
## Sert à éprouver le lecteur sur le format exact que produit l'éditeur (unique_id, uid…).
## Usage : godot --headless --path <projet> -s resauver_scene.gd -- res://a.tscn res://b.tscn
## Sortie : une ligne « @@RESAUVER@@{"chemin": …, "code": …} » par scène (code 0 = OK).

const MARQUEUR := "@@RESAUVER@@"


# À la première image et non dans _init : les autoloads sont alors enregistrés.
func _process(_delta: float) -> bool:
	for chemin in OS.get_cmdline_user_args():
		var uid := ResourceLoader.get_resource_uid(chemin)
		var scene: PackedScene = load(chemin)
		var code := ERR_CANT_OPEN if scene == null else ResourceSaver.save(scene, chemin)
		# ResourceSaver.save hors éditeur oublie l'uid de la scène ; l'éditeur, lui, le garde.
		if code == OK and uid != ResourceUID.INVALID_ID:
			code = ResourceSaver.set_uid(chemin, uid)
		print(MARQUEUR + JSON.stringify({"chemin": chemin, "code": code}))
	quit()
	return true
