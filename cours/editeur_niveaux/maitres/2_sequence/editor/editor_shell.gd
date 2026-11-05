class_name EditorShell
extends Control
#@ 1-5
## La coquille de l'éditeur de niveaux : la fenêtre, son titre et sa barre d'état. À cette étape, elle s'ouvre vide (F5)
## et dit qu'aucune salle n'est ouverte ; la salle, la vue et les panneaux s'y logeront aux étapes suivantes.
#@ 6+
## La coquille de l'éditeur de niveaux : la fenêtre, son titre, la vue de dessus et la barre d'état. Au démarrage, elle
## ouvre la salle de départ (`start_room`), vérifiée face au catalogue, et la cadre dans la vue ; on la parcourt à la
## souris (molette : zoom autour du curseur ; bouton du milieu : déplacer la vue).
#@ 7+
## Le bouton gauche sélectionne (clic, Maj+clic, rectangle) et manipule la sélection par son cadre bleu : déplacer,
## agrandir par les poignées d'angle, tourner par la poignée ronde ; Page haut et Page bas règlent sa profondeur.
#@ 8+
## À gauche, la hiérarchie des calques et la palette (un double-clic pose l'asset au centre de la vue) ; à droite,
## l'inspecteur de la sélection ; au clavier, Ctrl+Z, Ctrl+Y, Suppr, Ctrl+D et les flèches.
#@ 9+
## En haut, la liste des salles du dossier des salles, « Enregistrer » (Ctrl+S) et « Abandonner les modifications ».
## Une salle s'enregistre seulement si elle est valide et ne cite que des calques et des assets du catalogue ; le titre
## porte un astérisque tant qu'elle a des modifications non enregistrées, et l'éditeur refuse alors d'ouvrir une autre
## salle sans qu'on ait choisi d'enregistrer ou d'abandonner.
#@ 10+
## Le mode, en haut, choisit ce que fait la souris : « Choses » (sélection et cadre bleu) ou « Collisions » (les formes
## infranchissables, montrées seulement dans ce mode).
#@ 11+
## Le mode « Apparitions » montre le départ du héros et les points d'apparition, et, à droite, la rencontre : les
## ennemis de la salle, choisis parmi les définitions du jeu. Une salle dont la rencontre cite un ennemi inconnu, ou un
## ennemi sans point d'apparition de son rôle, ne s'enregistre pas.
#@ 12+
## Le mode « Effets » montre les effets placés en aperçu animé, et, à droite, la liste des effets du jeu : Ctrl+clic place
## l'effet choisi. Une salle qui place un effet inconnu ne s'enregistre pas.
#@ 13+
## Le mode « Paramètres » montre, à droite, les définitions du jeu (ennemis, effets) et le formulaire de celle qu'on
## choisit : on règle le jeu lui-même, et une définition invalide ne s'écrit pas.
#@ all

## Le texte de la barre d'état vient de changer.
signal status_changed(text: String)

## Ce que dit la barre d'état quand rien n'est ouvert.
const NOTHING_OPEN: String = "Aucune salle ouverte"
#@ 9+
## Le nom de l'application, en tête du titre.
const APP_TITLE: String = "Éditeur de niveaux"
## Ce que dit la barre d'état quand on veut changer de salle avec des modifications non enregistrées.
const UNSAVED: String = "Modifications non enregistrées : « Enregistrer » (Ctrl+S) ou « Abandonner les modifications »"
#@ 10+
## Les modes de la souris, dans l'ordre de la liste.
#@ 10
const MODES: Array[StringName] = [&"choses", &"collisions"]
#@ 11
const MODES: Array[StringName] = [&"choses", &"collisions", &"apparitions"]
#@ 12
const MODES: Array[StringName] = [&"choses", &"collisions", &"apparitions", &"effets"]
#@ 13+
const MODES: Array[StringName] = [&"choses", &"collisions", &"apparitions", &"effets", &"parametres"]
#@ 10+
#@ 6+

## La salle ouverte au démarrage.
@export_file("*.tres") var start_room: String = ""
## Le catalogue des assets du jeu.
@export var catalog: AssetCatalogDef
## Les réglages de l'éditeur.
@export var settings: EditorSettingsDef
#@ 9+
## Le dossier des salles : la liste en haut de la fenêtre, et là où l'on enregistre.
@export_dir var rooms_dir: String = RoomStore.DEFAULT_ROOT
#@ 11+
## Le dossier des définitions d'ennemis du jeu.
@export_dir var enemies_dir: String = "res://5_data/ennemis"
#@ 12+
## Le dossier des définitions d'effets du jeu.
@export_dir var effects_dir: String = "res://5_data/effets"
#@ 6+

var _store: RoomStore = RoomStore.new()
var _document: RoomDocument = RoomDocument.new()
var _transform: ViewTransform = ViewTransform.new()
#@ 7+
var _selection: SelectionModel = SelectionModel.new()
var _actions: EditorActions = EditorActions.new()
#@ 9+
var _current_file: String = ""
#@ 11+
var _enemies: Array[EnemyDef] = []
#@ 12+
var _effects: Array[FxDef] = []
#@ all

@onready var _status: Label = $Layout/Status
#@ 6+
@onready var _view: RoomView = $Layout/Body/RoomView
@onready var _view_input: RoomViewInput = $Layout/Body/RoomViewInput
#@ 7+
@onready var _overlay: SelectionOverlay = $Layout/Body/SelectionOverlay
@onready var _selection_input: SelectionInput = $Layout/Body/SelectionInput
#@ 8+
@onready var _hierarchy: HierarchyPanel = $Layout/Body/Left/HierarchyPanel
@onready var _palette: PalettePanel = $Layout/Body/Left/PalettePanel
@onready var _inspector: InspectorPanel = $Layout/Body/InspectorPanel
@onready var _shortcuts: EditorShortcutsInput = $Layout/Body/EditorShortcutsInput
#@ 9+
@onready var _title: Label = $Layout/TopBar/Title
@onready var _picker: OptionButton = $Layout/TopBar/RoomPicker
@onready var _save_button: Button = $Layout/TopBar/SaveButton
@onready var _discard_button: Button = $Layout/TopBar/DiscardButton
#@ 10+
@onready var _mode_picker: OptionButton = $Layout/TopBar/ModePicker
@onready var _collision_view: CollisionView = $Layout/Body/CollisionView
@onready var _collision_input: CollisionInput = $Layout/Body/CollisionInput
#@ 11+
@onready var _spawn_view: SpawnView = $Layout/Body/SpawnView
@onready var _spawn_input: SpawnInput = $Layout/Body/SpawnInput
@onready var _encounter: EncounterPanel = $Layout/Body/EncounterPanel
#@ 12+
@onready var _effect_view: EffectView = $Layout/Body/EffectView
@onready var _effect_input: EffectInput = $Layout/Body/EffectInput
@onready var _effect_panel: EffectPanel = $Layout/Body/EffectPanel
#@ 13+
@onready var _definitions: DefinitionPanel = $Layout/Body/DefinitionPanel
#@ all


func _ready() -> void:
#@ 1-5
	show_status(NOTHING_OPEN)
#@ 6+
	_transform.setup(settings)
	_view.setup(_document, catalog, _transform)
	_view_input.setup(_view, _transform, settings)
#@ 7+
	_actions.setup(_document, catalog, settings)
	_selection_input.setup(_view, _document, _selection, _actions, settings)
	_overlay.setup(_selection_input, settings)
	_document.changed.connect(_forget_removed)
#@ 8+
	_hierarchy.setup(_document, _selection, catalog)
	_palette.setup(catalog)
	_palette.asset_chosen.connect(place_asset)
	_inspector.setup(_document, _selection, _actions, catalog)
	_shortcuts.setup(_document, _selection, _actions, settings)
#@ 9+
	_store.setup(rooms_dir)
	_document.dirty_changed.connect(_on_dirty_changed)
	_shortcuts.save_requested.connect(save_room)
	_save_button.pressed.connect(save_room)
	_discard_button.pressed.connect(discard_changes)
	_picker.item_selected.connect(_on_room_picked)
	refresh_rooms()
#@ 10+
	_collision_input.setup(_view, _document, settings)
	_collision_view.setup(_document, _transform, _collision_input)
	_collision_input.refused.connect(show_status)
#@ 11+
	var folder: DefinitionFolder = DefinitionFolder.new()
	_enemies.assign(folder.load_all(enemies_dir, EnemyDef))
	_spawn_input.setup(_view, _document, settings)
	_spawn_view.setup(_document, _transform, _spawn_input)
	_spawn_input.refused.connect(show_status)
	_encounter.setup(_document, _enemies)
#@ 12+
	_effects.assign(folder.load_all(effects_dir, FxDef))
	_effect_input.setup(_view, _document, settings)
	_effect_view.setup(_document, _transform, _effect_input, _effects)
	_effect_input.refused.connect(show_status)
	_effect_panel.setup(_effects)
	_effect_panel.effect_chosen.connect(func(effect_id: StringName) -> void: _effect_input.current_fx = effect_id)
#@ 13+
	_definitions.setup({"Ennemis": enemies_dir, "Effets": effects_dir})
	_definitions.definition_saved.connect(func(path: String) -> void: show_status("%s enregistré" % path.get_file()))
#@ 10+
	for mode: StringName in MODES:
		_mode_picker.add_item(String(mode).capitalize())
	_mode_picker.item_selected.connect(func(index: int) -> void: set_mode(MODES[index]))
	set_mode(MODES.front())
#@ 6+
	_view.resized.connect(frame_room)
	if start_room.is_empty():
		show_status(NOTHING_OPEN)
	else:
		open_room(start_room)
#@ all


## Écrit `text` dans la barre d'état et le signale.
func show_status(text: String) -> void:
	_status.text = text
	status_changed.emit(text)


## Le texte affiché dans la barre d'état.
func status() -> String:
	return _status.text
#@ 6+


## Le document de la salle ouverte.
func document() -> RoomDocument:
	return _document
#@ 7+


## La sélection de l'éditeur.
func selection() -> SelectionModel:
	return _selection
#@ 8+


## Pose l'asset `asset_id` au centre de la vue et le sélectionne ; rend l'identifiant de la nouvelle chose, ou 0.
func place_asset(asset_id: StringName) -> int:
	var center: Vector3 = _transform.screen_to_world(Rect2(Vector2.ZERO, _view.size).get_center())
	var created: int = _actions.add_asset(asset_id, center)
	if created == 0:
		show_status("Pose impossible : " + "; ".join(_actions.errors))
		return created
	_selection.replace([created])
	show_status("%s posé" % asset_id)
	return created
#@ 6+


#@ 6-8
## Ouvre la salle `path` : elle doit être valide, et ne citer que des calques et des assets du catalogue.
func open_room(path: String) -> bool:
#@ 9+
## Ouvre la salle `path` : elle doit être valide, et ne citer que des calques et des assets du catalogue. Refusé si la
## salle ouverte a des modifications non enregistrées, sauf si `discard` demande de les abandonner.
func open_room(path: String, discard: bool = false) -> bool:
	if _document.is_dirty() and not discard:
		show_status(UNSAVED)
		_select_current()
		return false
#@ 6+
	var room: RoomData = _store.load_room(path)
	var errors: Array[String] = _store.errors.duplicate()
	if room != null:
		errors.append_array(catalog.room_errors(room))
	if not errors.is_empty() or not _document.open(room):
		errors.append_array(_document.errors)
		show_status("Ouverture impossible : " + "; ".join(errors))
		return false
	frame_room()
#@ 9+
	_current_file = path.get_file()
	_update_title()
	_select_current()
#@ 6+
	show_status("%s : %d choses" % [room.display_name, room.thing_count()])
	return true


## Cadre la salle ouverte dans la vue (au démarrage, puis chaque fois que la vue change de taille).
func frame_room() -> void:
	var room: RoomData = _document.snapshot()
	if room != null and _view.size.x > 0.0 and _view.size.y > 0.0:
		_transform.frame(room.size_m, _view.size)
#@ 7+


# Après une suppression ou une annulation, la sélection ne garde que les choses qui existent encore.
func _forget_removed() -> void:
	_selection.retain(_document.ids())
#@ 9+


## Enregistre la salle ouverte dans le dossier des salles, si elle est valide et ne cite que ce que le catalogue connaît.
func save_room() -> bool:
	var room: RoomData = _document.snapshot()
	if room == null:
		show_status(NOTHING_OPEN)
		return false
	var errors: Array[String] = catalog.room_errors(room)
#@ 11+
	errors.append_array(EnemyDef.pool_errors(room, _enemies))
#@ 12+
	errors.append_array(FxDef.placement_errors(room, _effects))
#@ 9+
	if errors.is_empty() and _store.save_room(room, _current_file):
		_document.mark_saved()
		show_status("%s enregistré" % room.display_name)
		refresh_rooms()
		return true
	errors.append_array(_store.errors)
	show_status("Enregistrement impossible : " + "; ".join(errors))
	return false


## Abandonne les modifications non enregistrées : rouvre la salle telle qu'elle est sur le disque.
func discard_changes() -> bool:
	return not _current_file.is_empty() and open_room(_store.path_of(_current_file), true)


## Relit la liste des salles du dossier des salles.
func refresh_rooms() -> void:
	_picker.clear()
	if DirAccess.dir_exists_absolute(rooms_dir):
		for file: String in DirAccess.get_files_at(rooms_dir):
			if file.get_extension() == "tres" and not file.begins_with("."):
				_picker.add_item(file)
	_select_current()


## Les fichiers de la liste des salles, dans l'ordre.
func room_files() -> PackedStringArray:
	var files: PackedStringArray = PackedStringArray()
	for index: int in _picker.item_count:
		files.append(_picker.get_item_text(index))
	return files


## Le titre de la fenêtre.
func title() -> String:
	return _title.text


func _on_room_picked(index: int) -> void:
	var file: String = _picker.get_item_text(index)
	if file != _current_file:
		open_room(_store.path_of(file))


func _on_dirty_changed(_dirty: bool) -> void:
	_update_title()


func _update_title() -> void:
	var room: RoomData = _document.snapshot()
	var marker: String = " *" if _document.is_dirty() else ""
	_title.text = APP_TITLE if room == null else "%s · %s%s" % [APP_TITLE, room.display_name, marker]


func _select_current() -> void:
	for index: int in _picker.item_count:
		if _picker.get_item_text(index) == _current_file:
			_picker.select(index)
#@ 10+


## Passe la souris dans le mode `mode` (un nom de `MODES`) ; seules les formes du mode « Collisions » s'y montrent.
func set_mode(mode: StringName) -> void:
	_selection_input.active = mode == &"choses"
	_collision_input.active = mode == &"collisions"
	_collision_view.visible = mode == &"collisions"
#@ 11+
	_spawn_input.active = mode == &"apparitions"
	_spawn_view.visible = mode == &"apparitions"
	_encounter.visible = mode == &"apparitions"
#@ 11
	_inspector.visible = mode != &"apparitions"
#@ 12+
	_effect_input.active = mode == &"effets"
	_effect_view.visible = mode == &"effets"
	_effect_panel.visible = mode == &"effets"
	_inspector.visible = mode == &"choses" or mode == &"collisions"
#@ 13+
	_definitions.visible = mode == &"parametres"
#@ 10+
	_mode_picker.select(MODES.find(mode))
	if mode != &"choses":
		_selection.clear()


## Le mode courant de la souris (pas `mode()` : ce nom masquerait les paramètres `mode`, une erreur ici).
func current_mode() -> StringName:
	return MODES[_mode_picker.selected]


## La souris des collisions (pour les tests).
func collision_input() -> CollisionInput:
	return _collision_input
#@ 11+


## Le panneau de la rencontre (pour les tests).
func encounter_panel() -> EncounterPanel:
	return _encounter
#@ 12+


## La souris des effets (pour les tests).
func effect_input() -> EffectInput:
	return _effect_input
#@ 13+


## Le panneau des paramètres du jeu (pour les tests).
func definition_panel() -> DefinitionPanel:
	return _definitions
#@ 10+
#@ all
