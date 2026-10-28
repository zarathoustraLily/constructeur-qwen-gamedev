extends GdUnitTestSuite
## Règles des réglages enregistrés : volumes et boutons se relisent à l'identique ; un fichier absent donne des
## réglages vides ; un volume hors bornes est borné à la lecture ; le fichier porte sa version. (Un fichier abîmé donne
## aussi des réglages vides, mais ConfigFile écrit alors une ERROR dans la sortie : pas de cas pour lui ici.)

const PATH := "user://test_settings_store.cfg"


func after_test() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func test_volumes_et_boutons_se_relisent_a_l_identique() -> void:
	var store: SettingsStore = SettingsStore.new(PATH)
	var volumes: Dictionary[StringName, float] = {&"Music": 0.25, &"SFX": 0.8}
	var bindings: Dictionary[String, int] = {"move_jump": JOY_BUTTON_B, "move_dash": JOY_BUTTON_Y}
	assert_int(store.save(volumes, bindings)).is_equal(OK)
	var again: SettingsStore = SettingsStore.new(PATH)
	assert_dict(again.load_volumes()).is_equal(volumes)
	assert_dict(again.load_bindings()).is_equal(bindings)


func test_un_fichier_absent_donne_des_reglages_vides() -> void:
	var store: SettingsStore = SettingsStore.new("user://nulle_part.cfg")
	assert_dict(store.load_volumes()).is_empty()
	assert_dict(store.load_bindings()).is_empty()


func test_un_volume_hors_bornes_est_borne() -> void:
	var store: SettingsStore = SettingsStore.new(PATH)
	var volumes: Dictionary[StringName, float] = {&"Music": 4.0, &"SFX": -1.0}
	store.save(volumes, {})
	var loaded: Dictionary[StringName, float] = store.load_volumes()
	assert_float(loaded[&"Music"]).is_equal(1.0)
	assert_float(loaded[&"SFX"]).is_equal(0.0)


func test_le_fichier_porte_sa_version() -> void:
	SettingsStore.new(PATH).save({}, {})
	var config: ConfigFile = ConfigFile.new()
	assert_int(config.load(PATH)).is_equal(OK)
	assert_int(int(config.get_value("meta", "version", 0))).is_equal(SettingsStore.VERSION)
