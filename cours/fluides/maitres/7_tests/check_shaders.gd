extends SceneTree
## Compile tous les shaders de calcul du projet et dit lesquels sont faux, sans carte ni fenêtre. L'import ne le signale pas :
## une erreur de `.glsl` n'apparaît qu'en demandant le SPIR-V.
##   godot --headless --path . -s res://7_tests/check_shaders.gd
## glslang compte les lignes à partir de `#version` : la ligne 0:8 d'une erreur est la ligne 9 du fichier.

const FOLDER := "res://1_core/gpu/shaders"


func _initialize() -> void:
	var failed: int = 0
	for file_name: String in DirAccess.get_files_at(FOLDER):
		if file_name.ends_with(".glsl") and not _compiles(FOLDER.path_join(file_name)):
			failed += 1
	print("%d shaders faux" % failed)
	quit(1 if failed > 0 else 0)


## Vrai si le shader `path` compile ; sinon, écrit son erreur.
func _compiles(path: String) -> bool:
	var file: RDShaderFile = load(path) as RDShaderFile
	if not file.base_error.is_empty():
		print("%s : %s" % [path, file.base_error])
		return false
	var error: String = file.get_spirv().compile_error_compute
	if not error.is_empty():
		print("%s : %s" % [path, error.get_slice("Stage 'compute'", 0)])
		return false
	return true
