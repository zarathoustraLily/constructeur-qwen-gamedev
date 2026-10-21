class_name InputBindings extends RefCounted
## Les liaisons des commandes : les touches, boutons et axes qui déclenchent chaque action de l'InputMap. Une
## liaison se fait par appareil, le clavier et la souris d'un côté, la manette de l'autre : lier une entrée remplace
## celles du même appareil et garde celles de l'autre. Les liaisons des actions demandées se sauvegardent dans un
## fichier (ConfigFile), avec un numéro de version et en codes lisibles (« physical 87 », « axis 3 - »), jamais en
## objets. Ce script ne lit pas les entrées : on lui donne des événements.

## Les appareils d'une liaison ; NONE : un événement qui ne se lie pas (mouvement de souris, écran tactile…).
enum Device { NONE, KEYBOARD, PAD }

## Numéro du format de sauvegarde : une sauvegarde d'un autre numéro est ignorée.
const VERSION: int = 1
## Un axe (stick, gâchette) se lie quand on le pousse au-delà de ce seuil.
const AXIS_THRESHOLD: float = 0.6
## Un axe qu'on vient de lier est revenu au repos sous ce seuil.
const AXIS_RELEASE: float = 0.3
## Appareil des liaisons créées : tous (-1), comme les actions de project.godot ; une liaison faite avec la
## première manette marche aussi avec la deuxième.
const ALL_DEVICES: int = -1


## L'appareil de `event`.
static func device_of(event: InputEvent) -> Device:
	if event is InputEventKey or event is InputEventMouseButton:
		return Device.KEYBOARD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Device.PAD
	return Device.NONE


## La liaison que `event` demande pour `device`, ou null : une touche appuyée (par sa place sur le clavier : sur un
## AZERTY comme sur un QWERTY, la même touche), un bouton de souris ou de manette appuyé, un axe poussé au-delà
## d'AXIS_THRESHOLD, avec son sens. Un relâchement, une répétition, un petit mouvement ou un autre appareil ne
## demandent rien.
static func binding_from(event: InputEvent, device: Device) -> InputEvent:
	if device_of(event) != device:
		return null
	var motion := event as InputEventJoypadMotion
	if motion != null:
		if absf(motion.axis_value) < AXIS_THRESHOLD:
			return null
	elif not event.is_pressed() or event.is_echo():
		return null
	# Le code ne garde que la touche, le bouton ou l'axe et son sens : ni modificateurs, ni position, ni appareil.
	return event_from_code(code_of(event))


## Lie `binding` à `action` : elle remplace les entrées du même appareil ; celles de l'autre restent.
static func bind(action: StringName, binding: InputEvent) -> void:
	var device := device_of(binding)
	for event: InputEvent in InputMap.action_get_events(action):
		if device_of(event) == device:
			InputMap.action_erase_event(action, event)
	InputMap.action_add_event(action, binding)


## Les liaisons de `action` pour `device`.
static func events_for(action: StringName, device: Device) -> Array[InputEvent]:
	var found: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if device_of(event) == device:
			found.append(event)
	return found


## Le code de sauvegarde de `event` : « physical 87 » (une touche par sa place), « key 32 » (une touche par son
## nom), « mouse 1 », « button 0 », « axis 3 - » ; vide pour un autre événement.
static func code_of(event: InputEvent) -> String:
	var key := event as InputEventKey
	if key != null:
		if key.physical_keycode != KEY_NONE:
			return "physical %d" % key.physical_keycode
		return "key %d" % key.keycode
	var mouse := event as InputEventMouseButton
	if mouse != null:
		return "mouse %d" % mouse.button_index
	var button := event as InputEventJoypadButton
	if button != null:
		return "button %d" % button.button_index
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return "axis %d %s" % [motion.axis, "+" if motion.axis_value > 0.0 else "-"]
	return ""


## L'événement d'un code de sauvegarde (voir code_of), pour tous les appareils ; null pour un code inconnu.
static func event_from_code(code: String) -> InputEvent:
	var parts := code.split(" ")
	if parts.size() < 2:
		return null
	var number := parts[1].to_int()
	var event: InputEvent = null
	match parts[0]:
		"physical":
			var physical := InputEventKey.new()
			physical.physical_keycode = number as Key
			event = physical
		"key":
			var key := InputEventKey.new()
			key.keycode = number as Key
			event = key
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = number as MouseButton
			event = mouse
		"button":
			var button := InputEventJoypadButton.new()
			button.button_index = number as JoyButton
			event = button
		"axis":
			if parts.size() < 3:
				return null
			var motion := InputEventJoypadMotion.new()
			motion.axis = number as JoyAxis
			motion.axis_value = 1.0 if parts[2] == "+" else -1.0
			event = motion
		_:
			return null
	event.device = ALL_DEVICES
	return event


## Sauvegarde dans `path` les liaisons de `actions`, avec VERSION.
static func save_to(path: String, actions: Array[StringName]) -> Error:
	var file := ConfigFile.new()
	file.set_value("meta", "version", VERSION)
	for action: StringName in actions:
		var codes := PackedStringArray()
		for event: InputEvent in InputMap.action_get_events(action):
			var code := code_of(event)
			if not code.is_empty():
				codes.append(code)
		file.set_value("bindings", action, codes)
	return file.save(path)


## Remet aux actions de `actions` les liaisons sauvegardées dans `path`. Faux, sans rien changer, si le fichier
## manque ou n'est pas de cette VERSION. Une action absente du fichier, ou inconnue de l'InputMap, garde les
## siennes.
static func load_from(path: String, actions: Array[StringName]) -> bool:
	var file := ConfigFile.new()
	if file.load(path) != OK or file.get_value("meta", "version", 0) != VERSION:
		return false
	for action: StringName in actions:
		if not InputMap.has_action(action) or not file.has_section_key("bindings", action):
			continue
		InputMap.action_erase_events(action)
		for code: String in file.get_value("bindings", action) as PackedStringArray:
			var event := event_from_code(code)
			if event != null:
				InputMap.action_add_event(action, event)
	return true


## Revient aux liaisons du projet (project.godot) et efface la sauvegarde `path`.
static func reset(path: String) -> void:
	InputMap.load_from_project_settings()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
