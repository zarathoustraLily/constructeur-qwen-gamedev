class_name EncounterPanel
extends VBoxContainer
## Le panneau de la rencontre, en mode « Apparitions » : la profondeur de la salle dans la course, et les ennemis que la
## rencontre peut tirer, cochés parmi les définitions du jeu (`5_data/ennemis/`), chacun avec son rôle, sa santé et son
## poids. Sous la liste, ce qui manque : un ennemi sans point d'apparition de son rôle. Chaque changement est un pas
## d'annulation du document.

var _document: RoomDocument
var _enemies: Array[EnemyDef] = []
var _depth: SpinBox = SpinBox.new()
var _checks: Dictionary[StringName, CheckBox] = {}
var _warnings: Label = Label.new()
var _refreshing: bool = false


## Branche le panneau sur `document`, avec les définitions d'ennemis `enemies`.
func setup(document: RoomDocument, enemies: Array[EnemyDef]) -> void:
	_document = document
	_enemies = enemies
	var title: Label = Label.new()
	title.text = "Rencontre"
	add_child(title)
	var depth_row: HBoxContainer = HBoxContainer.new()
	var depth_label: Label = Label.new()
	depth_label.text = "Profondeur"
	_depth.min_value = 0.0
	_depth.max_value = 100.0
	_depth.step = 1.0
	_depth.value_changed.connect(func(value: float) -> void: _change(&"encounter_depth", roundi(value)))
	depth_row.add_child(depth_label)
	depth_row.add_child(_depth)
	add_child(depth_row)
	for enemy: EnemyDef in enemies:
		var check: CheckBox = CheckBox.new()
		check.text = "%s (%s, %d PV, poids %.1f)" % [enemy.display_name, enemy.role, roundi(enemy.max_health),
				enemy.weight]
		check.toggled.connect(func(_pressed: bool) -> void: _change(&"encounter_pool", chosen_pool()))
		_checks[enemy.id] = check
		add_child(check)
	_warnings.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_warnings)
	_document.changed.connect(refresh)
	refresh()


## Les identifiants des ennemis cochés, dans l'ordre des définitions.
func chosen_pool() -> PackedStringArray:
	var pool: PackedStringArray = PackedStringArray()
	for enemy: EnemyDef in _enemies:
		if _checks[enemy.id].button_pressed:
			pool.append(String(enemy.id))
	return pool


## La case de l'ennemi `enemy_id` (pour les tests).
func check_of(enemy_id: StringName) -> CheckBox:
	return _checks.get(enemy_id)


## Le texte de ce qui manque à la rencontre (vide si rien ne manque).
func warnings() -> String:
	return _warnings.text


## Montre la rencontre de la salle ouverte.
func refresh() -> void:
	if not _document.is_open():
		return
	_refreshing = true
	var pool: PackedStringArray = _document.room_value(&"encounter_pool")
	_depth.set_value_no_signal(float(_document.room_value(&"encounter_depth")))
	for enemy_id: StringName in _checks:
		_checks[enemy_id].set_pressed_no_signal(pool.has(String(enemy_id)))
	_warnings.text = "\n".join(EnemyDef.pool_errors(_document.snapshot(), _enemies))
	_refreshing = false


func _change(field: StringName, new_value: Variant) -> void:
	if not _refreshing:
		_document.set_room_fields({field: new_value})
