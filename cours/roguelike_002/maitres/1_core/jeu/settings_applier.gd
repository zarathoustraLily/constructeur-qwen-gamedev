class_name SettingsApplier extends RefCounted
## Applique les réglages au jeu : le volume de chaque bus audio (`AudioServer`), puis le mode de la fenêtre et sa
## définition (`DisplayServer`). Un bus qui n'existe pas est ignoré. Sans fenêtre (tests, serveur), l'écran n'a ni
## mode ni taille : on n'y touche pas.


## Applique `settings`.
static func apply(settings: GameSettings) -> void:
	for bus: StringName in settings.volumes:
		var index: int = AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.set_bus_volume_linear(index, settings.volumes[bus])
	if DisplayServer.get_name() == "headless":
		return
	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(settings.resolution)
