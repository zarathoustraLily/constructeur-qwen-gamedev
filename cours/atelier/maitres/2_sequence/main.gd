extends Node
#@ 1
## La scène principale de l'atelier : le menu principal, et les options par-dessus. Elle relie les menus au
## service audio : les menus disent ce que le joueur veut, elle le fait.
#@ 2+
## La scène principale de l'atelier : le menu principal, les options et les commandes par-dessus. Elle relie les
## menus au service audio et aux commandes : les menus disent ce que le joueur veut, elle le fait.
#@ all

#@ 9+
## Les réglages du son, donnés au service audio au démarrage.
@export var audio_settings: AudioSettings
#@ 12+
## Le fichier des réglages du joueur (volumes, boutons) : relu au démarrage, réécrit à chaque changement.
@export var settings_path: String = "user://reglages.cfg"

var _store: SettingsStore
#@ 9+

#@ all
@onready var _main_menu: MainMenu = $MainMenu
@onready var _options: OptionsMenu = $OptionsMenu
#@ 2+
@onready var _remap: RemapMenu = $RemapMenu
#@ all


func _ready() -> void:
#@ 9+
	AudioManager.setup(audio_settings)
#@ 12+
	_store = SettingsStore.new(settings_path)
	_restore_settings()
	AudioManager.volume_changed.connect(_on_settings_changed.unbind(2))
	_remap.rebound.connect(_on_settings_changed.unbind(2))
#@ all
	_main_menu.options_requested.connect(_open_options)
#@ 2+
	_main_menu.controls_requested.connect(_open_remap)
#@ all
	_main_menu.quit_requested.connect(func() -> void: get_tree().quit())
	_options.volume_changed.connect(AudioManager.set_volume)
	_options.closed.connect(_close_options)
	_options.hide()
#@ 2+
	_remap.closed.connect(_close_remap)
	_remap.hide()
#@ all
	_main_menu.open()


func _open_options() -> void:
	_main_menu.hide()
	_options.show_volumes(AudioManager.volume(AudioManager.MUSIC), AudioManager.volume(AudioManager.SFX))
	_options.open()


func _close_options() -> void:
	_options.hide()
	_main_menu.open()
#@ 2+


func _open_remap() -> void:
	_main_menu.hide()
	_remap.open()


func _close_remap() -> void:
	_remap.hide()
	_main_menu.open()
#@ all
#@ 12+


func _restore_settings() -> void:
	var volumes: Dictionary[StringName, float] = _store.load_volumes()
	for bus: StringName in volumes:
		AudioManager.set_volume(bus, volumes[bus])
	ActionRemap.from_config(_store.load_bindings())


func _on_settings_changed() -> void:
	var volumes: Dictionary[StringName, float] = {
		AudioManager.MUSIC: AudioManager.volume(AudioManager.MUSIC),
		AudioManager.SFX: AudioManager.volume(AudioManager.SFX),
	}
	_store.save(volumes, ActionRemap.to_config(_remap.settings.remappable_actions))
#@ all
