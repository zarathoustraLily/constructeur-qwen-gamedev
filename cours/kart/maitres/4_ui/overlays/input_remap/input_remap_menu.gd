class_name InputRemapMenu extends CanvasLayer

## Menu de re-mapping des contrôles (clavier/souris + manette).
## Instancier dans la scène principale ; ouvrir/fermer avec F1 ou Start (géré par pause_handler.gd).

## Fichier où les commandes personnalisées sont enregistrées.
const SAVE_PATH := "user://input_remap.cfg"
## À incrémenter si le format change : les sauvegardes d'un autre format sont ignorées.
## (La v1 enregistrait les axes sans leur direction et écrasait aussi les actions ui_*.)
const SAVE_VERSION := 2

## Un axe (stick / gâchette) doit dépasser ce seuil pour être capturé.
const AXIS_CAPTURE_THRESHOLD := 0.6
## Après une capture, l'axe est ignoré jusqu'à ce qu'il revienne sous ce seuil.
const AXIS_RELEASE_THRESHOLD := 0.3

## Actions proposées dans le menu, avec leur libellé.
const ACTION_LABELS := {
	"move_forward": "Avancer",
	"move_backward": "Reculer",
	"move_left": "Gauche",
	"move_right": "Droite",
	"move_jump": "Sauter / Drift",
	"move_brake": "Freiner",
	"use_item": "Utiliser un objet",
}

## Numérotation Godot 4 (standard SDL), libellés d'une manette Xbox.
const BUTTON_NAMES := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "View (Back)",
	JOY_BUTTON_GUIDE: "Bouton Xbox",
	JOY_BUTTON_START: "Menu (Start)",
	JOY_BUTTON_LEFT_STICK: "L3 (clic stick G)",
	JOY_BUTTON_RIGHT_STICK: "R3 (clic stick D)",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "Croix Haut",
	JOY_BUTTON_DPAD_DOWN: "Croix Bas",
	JOY_BUTTON_DPAD_LEFT: "Croix Gauche",
	JOY_BUTTON_DPAD_RIGHT: "Croix Droite",
	JOY_BUTTON_MISC1: "Share",
}

## Noms affichés en français pour certaines touches.
const KEY_NAMES_FR := {
	KEY_SPACE: "Espace",
	KEY_ENTER: "Entrée",
	KEY_KP_ENTER: "Entrée (pavé num.)",
	KEY_BACKSPACE: "Retour arrière",
	KEY_DELETE: "Suppr",
	KEY_INSERT: "Inser",
	KEY_ESCAPE: "Échap",
	KEY_UP: "Flèche Haut",
	KEY_DOWN: "Flèche Bas",
	KEY_LEFT: "Flèche Gauche",
	KEY_RIGHT: "Flèche Droite",
	KEY_HOME: "Début",
	KEY_END: "Fin",
	KEY_PAGEUP: "Page Haut",
	KEY_PAGEDOWN: "Page Bas",
	KEY_SHIFT: "Maj",
	KEY_CAPSLOCK: "Verr. Maj",
}

var _rows: Array[Dictionary] = []
var _status_label: Label
var _open: bool = false
var _pending_action: String = ""
var _background: ColorRect = null
var _buttons: Array[Button] = []
var _swallowed_axes: Dictionary = {}
var _dirty: bool = false
var _was_paused: bool = false
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	layer = 10
	# Le jeu est mis en pause pendant que le menu est ouvert : le menu, lui, doit continuer à tourner.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_gamepad_can_click()
	# Charger les bindings personnalisés dès le démarrage (pas seulement à l'ouverture)
	_load_bindings()

## Par défaut, Godot 4 n'associe aucun bouton manette à « ui_accept » :
## sans ça, A ne peut pas cliquer sur les boutons du menu.
func _ensure_gamepad_can_click() -> void:
	for e in InputMap.action_get_events("ui_accept"):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == JOY_BUTTON_A:
			return
	var a_button := InputEventJoypadButton.new()
	a_button.button_index = JOY_BUTTON_A
	InputMap.action_add_event("ui_accept", a_button)

# ---------------------------------------------------------------------------
# Ouverture / Fermeture
# ---------------------------------------------------------------------------

## Vrai si le menu est ouvert.
func is_open() -> bool:
	return _open

## Vrai si le menu attend la nouvelle touche ou le nouveau bouton d'une action.
func is_capturing() -> bool:
	return _open and _pending_action != ""

## Ouvre le menu s'il est fermé, sinon le ferme.
func toggle() -> void:
	if _open:
		close()
	else:
		open()

## Ouvre le menu et met le jeu en pause.
func open() -> void:
	if _open:
		return
	_open = true

	_background = ColorRect.new()
	_background.color = Color(0.04, 0.06, 0.11, 0.82)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(860, 640)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.12, 0.19, 0.96)
	sb.border_color = Color(0.25, 0.45, 0.85, 1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "RÉGLAGES DES CONTRÔLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "F1 / Start = ouvrir / fermer  •  B = fermer  •  Échap / Start pendant une capture = annuler"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(0.6, 0.7, 0.9)
	vbox.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	# En-tête du tableau
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	var h_action := Label.new()
	h_action.text = "ACTION"
	h_action.custom_minimum_size.x = 200
	var h_key := Label.new()
	h_key.text = "CLAVIER / SOURIS"
	h_key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h_pad := Label.new()
	h_pad.text = "MANETTE"
	h_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h_btn := Label.new()
	h_btn.custom_minimum_size.x = 140
	header.add_child(h_action)
	header.add_child(h_key)
	header.add_child(h_pad)
	header.add_child(h_btn)
	list.add_child(header)

	list.add_child(HSeparator.new())

	# Une ligne par action
	for action: String in ACTION_LABELS:
		list.add_child(_build_row(action, ACTION_LABELS[action]))

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 17)
	_status_label.modulate = Color(1, 0.85, 0.4)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size.x = 780
	vbox.add_child(_status_label)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	vbox.add_child(bottom)

	var reset_btn := Button.new()
	reset_btn.text = "Réinitialiser par défaut"
	reset_btn.custom_minimum_size.y = 46
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.pressed.connect(_reset_to_defaults)
	bottom.add_child(reset_btn)
	_buttons.append(reset_btn)

	var close_btn := Button.new()
	close_btn.text = "Fermer le menu  (F1 / Start / B)"
	close_btn.custom_minimum_size.y = 46
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.pressed.connect(close)
	bottom.add_child(close_btn)
	_buttons.append(close_btn)

	_background.add_child(panel)

	_refresh_labels()
	_status_label.text = "Choisissez « Assigner » (souris, ou croix + A à la manette) puis appuyez sur la touche, le bouton ou l'axe souhaité."
	visible = true

	# Pause du jeu : tout ce qui n'est pas en PROCESS_MODE_ALWAYS s'arrête (kart, caméra…)
	_was_paused = get_tree().paused
	get_tree().paused = true
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Focus sur la première ligne pour pouvoir naviguer à la manette / au clavier
	(_rows[0].btn as Button).grab_focus()

## Ferme le menu, enregistre les changements et remet le jeu dans l'état d'avant (en pause ou non).
func close() -> void:
	if not _open:
		return
	_open = false

	get_tree().paused = _was_paused
	Input.mouse_mode = _previous_mouse_mode
	if _dirty:
		_save_bindings()
		_dirty = false
	visible = false

	# Libérer les nodes UI (le panneau est un enfant du fond)
	if _background and is_instance_valid(_background):
		_background.queue_free()
	_background = null
	_status_label = null
	_buttons.clear()
	_rows.clear()
	_pending_action = ""

# ---------------------------------------------------------------------------
# Construction des lignes
# ---------------------------------------------------------------------------

func _build_row(action: String, label_text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.custom_minimum_size.y = 42

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 200
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var key_label := Label.new()
	key_label.text = "—"
	key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var pad_label := Label.new()
	pad_label.text = "—"
	pad_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pad_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var bind_btn := Button.new()
	bind_btn.text = "Assigner"
	bind_btn.custom_minimum_size.x = 140
	bind_btn.pressed.connect(_start_binding.bind(action))

	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	row.add_child(label)
	row.add_child(key_label)
	row.add_child(pad_label)
	row.add_child(bind_btn)

	_rows.append({
		"action": action,
		"key_label": key_label,
		"pad_label": pad_label,
		"btn": bind_btn,
	})
	_buttons.append(bind_btn)
	return row

func _get_row(action: String) -> Dictionary:
	for row in _rows:
		if row.action == action:
			return row
	return {}

# ---------------------------------------------------------------------------
# Logique de binding
# ---------------------------------------------------------------------------

func _start_binding(action: String) -> void:
	if _pending_action != "":
		_cancel_binding()
	_pending_action = action
	var row := _get_row(action)
	(row.key_label as Label).text = "En attente… appuyez sur une touche"
	(row.key_label as Label).modulate = Color(1, 0.85, 0.4)
	(row.pad_label as Label).text = "…ou sur un bouton / un axe manette"
	(row.pad_label as Label).modulate = Color(1, 0.85, 0.4)
	(row.btn as Button).disabled = true
	_status_label.text = "Capture en cours pour « %s »… (Échap ou Start = annuler)" % ACTION_LABELS[action]

func _input(event: InputEvent) -> void:
	if not _open:
		return

	# Un stick qui vient d'être capturé envoie encore des événements en revenant au centre :
	# on les absorbe pour qu'ils ne déplacent pas le focus du menu.
	if event is InputEventJoypadMotion and _swallowed_axes.has(event.axis):
		if absf(event.axis_value) < AXIS_RELEASE_THRESHOLD:
			_swallowed_axes.erase(event.axis)
		get_viewport().set_input_as_handled()
		return

	if _pending_action == "":
		return

	# --- Clavier (F1 / Échap sont gérés par pause_handler.gd : ouvrir/fermer/annuler) ---
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var kc := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		if kc == KEY_ESCAPE or kc == KEY_F1:
			return
		if kc != KEY_NONE:
			# Touche enregistrée par position physique : W reste W sur QWERTY comme Z sur AZERTY
			var key_event := InputEventKey.new()
			if key.physical_keycode != KEY_NONE:
				key_event.physical_keycode = key.physical_keycode
			else:
				key_event.keycode = key.keycode
			_apply_event(_pending_action, key_event)
		get_viewport().set_input_as_handled()
		return

	# --- Souris ---
	if event is InputEventMouseButton and event.pressed:
		# Clic sur un bouton du menu (Fermer, Assigner…) : on laisse le bouton réagir
		var mp: Vector2 = get_viewport().get_mouse_position()
		for b in _buttons:
			if is_instance_valid(b) and not b.disabled and b.get_global_rect().has_point(mp):
				return
		var mb_event := InputEventMouseButton.new()
		mb_event.button_index = event.button_index
		_apply_event(_pending_action, mb_event)
		get_viewport().set_input_as_handled()
		return

	# --- Bouton manette (Start est réservé à l'ouverture/fermeture du menu) ---
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_START:
			return
		var jp_event := InputEventJoypadButton.new()
		jp_event.button_index = event.button_index
		_apply_event(_pending_action, jp_event)
		get_viewport().set_input_as_handled()
		return

	# --- Axe manette (sticks, gâchettes LT/RT) : on garde la DIRECTION de l'axe ---
	if event is InputEventJoypadMotion:
		if absf(event.axis_value) >= AXIS_CAPTURE_THRESHOLD:
			var jm_event := InputEventJoypadMotion.new()
			jm_event.axis = event.axis
			jm_event.axis_value = signf(event.axis_value)
			_swallowed_axes[event.axis] = true
			_apply_event(_pending_action, jm_event)
		# Pendant la capture, les petits mouvements de stick ne doivent pas naviguer dans le menu
		get_viewport().set_input_as_handled()

func _is_gamepad_event(e: InputEvent) -> bool:
	return e is InputEventJoypadButton or e is InputEventJoypadMotion

func _apply_event(action: String, new_event: InputEvent) -> void:
	# Une colonne = un appareil : la nouvelle entrée remplace celles du même appareil
	# (clavier/souris d'un côté, manette de l'autre).
	var replace_gamepad := _is_gamepad_event(new_event)
	for e in InputMap.action_get_events(action):
		if _is_gamepad_event(e) == replace_gamepad:
			InputMap.action_erase_event(action, e)
	InputMap.action_add_event(action, new_event)

	_pending_action = ""
	_dirty = true

	var row := _get_row(action)
	var btn := row.btn as Button
	btn.disabled = false
	btn.grab_focus()

	_refresh_labels()

	var others: Array[String] = []
	for other: String in ACTION_LABELS:
		if other != action and InputMap.action_has_event(other, new_event):
			others.append(ACTION_LABELS[other])
	if others.is_empty():
		_status_label.text = "✔ %s — assigné avec succès" % ACTION_LABELS[action]
	else:
		_status_label.text = "✔ %s — assigné. Attention : aussi utilisé par %s" % [ACTION_LABELS[action], ", ".join(others)]

func _cancel_binding() -> void:
	var row := _get_row(_pending_action)
	_pending_action = ""
	_refresh_labels()
	if not row.is_empty():
		var btn := row.btn as Button
		btn.disabled = false
		btn.grab_focus()
	_status_label.text = "Annulé — choisissez « Assigner » pour essayer à nouveau."

func _reset_to_defaults() -> void:
	if _pending_action != "":
		_cancel_binding()
	# Recharge le mappage défini dans project.godot et supprime la sauvegarde
	InputMap.load_from_project_settings()
	_ensure_gamepad_can_click()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_dirty = false
	_refresh_labels()
	_status_label.text = "Contrôles par défaut restaurés."

# ---------------------------------------------------------------------------
# Rafraîchissement des labels
# ---------------------------------------------------------------------------

func _refresh_labels() -> void:
	for row in _rows:
		var key_strs: Array[String] = []
		var pad_strs: Array[String] = []
		for e in InputMap.action_get_events(row.action):
			if e is InputEventKey:
				key_strs.append(_describe_key(e))
			elif e is InputEventMouseButton:
				key_strs.append(_describe_mouse(e))
			elif e is InputEventJoypadButton:
				var bi: int = (e as InputEventJoypadButton).button_index
				pad_strs.append(BUTTON_NAMES.get(bi, "Bouton %d" % bi))
			elif e is InputEventJoypadMotion:
				pad_strs.append(_describe_axis(e))
		(row.key_label as Label).text = ", ".join(key_strs) if key_strs.size() > 0 else "Aucun"
		(row.pad_label as Label).text = ("🎮 " + ", ".join(pad_strs)) if pad_strs.size() > 0 else "Aucun"
		(row.key_label as Label).modulate = Color.WHITE
		(row.pad_label as Label).modulate = Color.WHITE

# ---------------------------------------------------------------------------
# Sauvegarde / Chargement (uniquement les actions du jeu, jamais les ui_*)
# ---------------------------------------------------------------------------

func _save_bindings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", SAVE_VERSION)
	for action: String in ACTION_LABELS:
		var arr: Array = []
		for e in InputMap.action_get_events(action):
			var d: Dictionary = _event_to_dict(e)
			if not d.is_empty():
				arr.append(d)
		cfg.set_value("bindings", action, arr)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Impossible d'enregistrer %s (erreur %d)" % [SAVE_PATH, err])

func _load_bindings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	if cfg.get_value("meta", "version", 0) != SAVE_VERSION:
		# Ancien format : on garde le mappage de project.godot (la sauvegarde sera réécrite)
		return
	if not cfg.has_section("bindings"):
		return
	for action in cfg.get_section_keys("bindings"):
		if not ACTION_LABELS.has(action) or not InputMap.has_action(action):
			continue
		var events: Array[InputEvent] = []
		for d: Variant in cfg.get_value("bindings", action, []):
			var e: InputEvent = _dict_to_event(d)
			if e != null:
				events.append(e)
		if events.size() > 0:
			InputMap.action_erase_events(action)
			for e in events:
				InputMap.action_add_event(action, e)

func _event_to_dict(e: InputEvent) -> Dictionary:
	if e is InputEventKey:
		var k := e as InputEventKey
		return {"type": "key", "physical": k.physical_keycode, "keycode": k.keycode}
	elif e is InputEventMouseButton:
		var m := e as InputEventMouseButton
		return {"type": "mouse", "button": m.button_index}
	elif e is InputEventJoypadButton:
		var j := e as InputEventJoypadButton
		return {"type": "pad_btn", "button": j.button_index}
	elif e is InputEventJoypadMotion:
		var j := e as InputEventJoypadMotion
		return {"type": "pad_axis", "axis": j.axis, "value": signf(j.axis_value)}
	return {}

func _dict_to_event(d: Variant) -> InputEvent:
	if d is Dictionary:
		var dict: Dictionary = d
		match dict.get("type", ""):
			"key":
				var k := InputEventKey.new()
				k.physical_keycode = dict.get("physical", 0)
				k.keycode = dict.get("keycode", 0)
				return k
			"mouse":
				var m := InputEventMouseButton.new()
				m.button_index = dict.get("button", MOUSE_BUTTON_LEFT)
				return m
			"pad_btn":
				var j := InputEventJoypadButton.new()
				j.button_index = dict.get("button", 0)
				return j
			"pad_axis":
				var value: float = dict.get("value", 0.0)
				if value == 0.0:
					return null  # Un axe sans direction déclencherait les deux sens à la fois
				var j := InputEventJoypadMotion.new()
				j.axis = dict.get("axis", 0)
				j.axis_value = value
				return j
	return null

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _describe_key(e: InputEventKey) -> String:
	var kc := e.keycode
	if e.physical_keycode != KEY_NONE:
		# Nom selon la disposition du clavier (AZERTY : la touche physique W s'affiche « Z »)
		kc = DisplayServer.keyboard_get_keycode_from_physical(e.physical_keycode)
	if KEY_NAMES_FR.has(kc):
		return KEY_NAMES_FR[kc]
	var s := OS.get_keycode_string(kc)
	return s if s != "" else "Touche %d" % kc

func _describe_mouse(e: InputEventMouseButton) -> String:
	match e.button_index:
		MOUSE_BUTTON_LEFT:
			return "Clic gauche"
		MOUSE_BUTTON_RIGHT:
			return "Clic droit"
		MOUSE_BUTTON_MIDDLE:
			return "Clic molette"
		MOUSE_BUTTON_WHEEL_UP:
			return "Molette haut"
		MOUSE_BUTTON_WHEEL_DOWN:
			return "Molette bas"
		_:
			return "Bouton souris %d" % e.button_index

func _describe_axis(e: InputEventJoypadMotion) -> String:
	var positive := e.axis_value > 0.0
	match e.axis:
		JOY_AXIS_LEFT_X:
			return "Stick G Droite" if positive else "Stick G Gauche"
		JOY_AXIS_LEFT_Y:
			return "Stick G Bas" if positive else "Stick G Haut"
		JOY_AXIS_RIGHT_X:
			return "Stick D Droite" if positive else "Stick D Gauche"
		JOY_AXIS_RIGHT_Y:
			return "Stick D Bas" if positive else "Stick D Haut"
		JOY_AXIS_TRIGGER_LEFT:
			return "LT"
		JOY_AXIS_TRIGGER_RIGHT:
			return "RT"
	return "Axe %d %s" % [e.axis, "+" if positive else "-"]
