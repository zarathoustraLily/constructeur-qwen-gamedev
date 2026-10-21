extends GdUnitTestSuite
## Règles de la scène de démarrage, côté contrôles : elle porte les réglages des liaisons du jeu, et remet au
## démarrage les liaisons sauvegardées par le menu des contrôles.

const BOOT := preload("res://2_sequence/boot.tscn")
const BINDINGS := preload("res://5_data/input/bindings.tres")
const SAVE_PATH := "user://test_boot_bindings.cfg"


func after_test() -> void:
	InputBindings.reset(SAVE_PATH)


func test_elle_porte_les_reglages_des_liaisons_du_jeu() -> void:
	var boot: Node = auto_free(BOOT.instantiate())
	assert_object(boot.get("bindings")).is_same(BINDINGS)


func test_elle_remet_les_liaisons_sauvegardees() -> void:
	var settings := BINDINGS.duplicate() as BindingSettings
	settings.save_path = SAVE_PATH
	InputBindings.bind(&"dash", InputBindings.event_from_code("physical %d" % KEY_K))
	InputBindings.save_to(SAVE_PATH, settings.actions())
	InputMap.load_from_project_settings()
	var boot: Node = auto_free(BOOT.instantiate())
	boot.set("bindings", settings)
	boot.call(&"apply_saved_bindings")
	var keyboard := InputBindings.events_for(&"dash", InputBindings.Device.KEYBOARD)
	assert_str(InputBindings.code_of(keyboard[0])).is_equal("physical %d" % KEY_K)
