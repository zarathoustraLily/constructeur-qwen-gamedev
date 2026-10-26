extends Node
## Exemple : réglages sauvegardés dans user://. On enregistre, on relit dans un nouvel objet : mêmes valeurs. Un
## fichier absent rend ERR_FILE_NOT_FOUND et garde les valeurs par défaut ; un fichier abîmé rend une erreur de lecture
## et les garde aussi. Les fichiers d'essai sont effacés à la fin.

const FICHIER := "user://exemple_reglages.cfg"
const ABIME := "user://exemple_reglages_abime.cfg"


func _ready() -> void:
	var reglages := SettingsStore.new()
	reglages.music_volume = 0.35
	reglages.sensitivity = 1.8
	var ecrit := reglages.save_to(FICHIER)
	var relus := SettingsStore.new()
	var lu := relus.load_from(FICHIER)
	var absent := SettingsStore.new()
	var code_absent := absent.load_from("user://exemple_absent.cfg")
	var fichier := FileAccess.open(ABIME, FileAccess.WRITE)
	fichier.store_string("[reglages\nmusic_volume = ")
	fichier.close()
	var abime := SettingsStore.new()
	var code_abime := abime.load_from(ABIME)
	DirAccess.remove_absolute(FICHIER)
	DirAccess.remove_absolute(ABIME)
	var memes := is_equal_approx(relus.music_volume, 0.35) and is_equal_approx(relus.sensitivity, 1.8)
	var defauts := absent.music_volume == 1.0 and abime.music_volume == 1.0
	if ecrit == OK and lu == OK and memes and code_absent == ERR_FILE_NOT_FOUND and code_abime != OK and defauts:
		print("EXEMPLE VERIFIE : enregistré puis relu (volume %.2f, sensibilité %.2f) ; fichier absent : %s, défauts gardés ; fichier abîmé : %s, défauts gardés"
				% [relus.music_volume, relus.sensitivity, error_string(code_absent), error_string(code_abime)])
	else:
		push_error("écrit %s, lu %s, mêmes %s, absent %s, abîmé %s, défauts %s"
				% [ecrit, lu, memes, error_string(code_absent), error_string(code_abime), defauts])
	get_tree().quit()
