class_name SavesScreen extends Control
## L'écran des sauvegardes, ouvert par « Jouer ». Il montre les emplacements : un emplacement libre lance tout de
## suite une partie neuve ; un emplacement occupé ouvre ses actions (continuer, effacer, retour). Effacer demande une
## confirmation, « Non » ayant le focus : on n'efface jamais par un appui de trop. B revient d'un cran : de la
## confirmation aux actions, des actions à la liste, de la liste au menu. Les entrées (`SavesInput`) demandent,
## l'écran décide, la vue (`SavesView`) montre, et `SaveSystem` lit et écrit les fichiers.

## L'écran a fini ; `next` nomme le suivant.
signal finished(next: StringName)
## Une partie vient d'être lancée dans l'emplacement `slot`, avec sa sauvegarde.
signal game_started(slot: int, save: Dictionary)

## Ce que montre l'écran.
enum Mode {
	LIST, ## les emplacements
	ACTIONS, ## les actions d'un emplacement occupé
	CONFIRM, ## la confirmation de l'effacement
	DONE, ## l'écran a fini
}

## Les réglages des sauvegardes.
@export var saves: SavesDef = null

## Ce que montre l'écran.
var mode: Mode = Mode.LIST
## L'emplacement choisi.
var selected_slot: int = 0
## La sauvegarde de la partie lancée (vide tant qu'aucune).
var started_save: Dictionary = {}

var _system: SaveSystem = null
var _rng: RandomNumberGenerator = null

@onready var _view: SavesView = $View
@onready var _input: SavesInput = $Input


## Donne le générateur du hasard de la partie (la graine d'une partie neuve en est tirée) ; à appeler avant l'entrée
## dans l'arbre. Sans lui, l'écran prend une source à la graine 0.
func use_rng(generator: RandomNumberGenerator) -> void:
	_rng = generator


func _ready() -> void:
	process_priority = ProcessOrder.FLOW
	for error: String in saves.validate():
		push_error(error)
	_system = SaveSystem.new(saves)
	if _rng == null:
		_rng = RngSource.new().instance()
	_view.setup(saves.title, saves.slot_count)
	_view.slot_chosen.connect(choose_slot)
	_view.action_chosen.connect(choose_action)
	_view.confirm_chosen.connect(confirm)
	_input.back_requested.connect(back)
	_show_list(0)


## Le générateur du hasard qu'utilise l'écran.
func rng() -> RandomNumberGenerator:
	return _rng


## Le système de sauvegarde de l'écran.
func system() -> SaveSystem:
	return _system


## Choisit l'emplacement `slot` : libre, une partie neuve commence ; occupé, ses actions s'ouvrent.
func choose_slot(slot: int) -> void:
	if mode != Mode.LIST:
		return
	selected_slot = slot
	if _system.state_of(slot) == SaveSystem.SlotState.EMPTY:
		_system.new_game(slot, _rng.randi())
		_start(slot)
	else:
		_open_actions()


## Fait l'action `action` sur l'emplacement choisi.
func choose_action(action: StringName) -> void:
	if mode != Mode.ACTIONS:
		return
	if action == &"continuer" and _system.state_of(selected_slot) == SaveSystem.SlotState.VALID:
		_start(selected_slot)
	elif action == &"effacer":
		mode = Mode.CONFIRM
		_view.show_confirm(saves.confirm_text, saves.yes_label, saves.no_label)
	elif action == &"retour":
		_show_list(selected_slot)


## Répond à la confirmation : `yes` efface l'emplacement et revient à la liste ; sinon, retour aux actions.
func confirm(yes: bool) -> void:
	if mode != Mode.CONFIRM:
		return
	if yes:
		_system.erase(selected_slot)
		_show_list(selected_slot)
	else:
		_open_actions()


## Revient d'un cran ; depuis la liste, revient à l'écran d'où l'on vient.
func back() -> void:
	if mode == Mode.LIST:
		mode = Mode.DONE
		finished.emit(saves.back_screen)
	elif mode == Mode.ACTIONS:
		_show_list(selected_slot)
	elif mode == Mode.CONFIRM:
		_open_actions()


## Le texte de l'emplacement `slot` : son nom, puis son état ou le résumé de sa sauvegarde.
func slot_text(slot: int) -> String:
	var name_text: String = saves.slot_label % (slot + 1)
	var state: SaveSystem.SlotState = _system.state_of(slot)
	var status: String = saves.empty_label
	if state == SaveSystem.SlotState.VALID:
		var data: Dictionary = _system.read(slot)
		status = saves.summary_format % [data["salle"], data["date"]]
	elif state == SaveSystem.SlotState.UNREADABLE:
		status = saves.unreadable_label
	elif state == SaveSystem.SlotState.OTHER_VERSION:
		status = saves.other_version_label
	return "%s — %s" % [name_text, status]


func _show_list(focus_slot: int) -> void:
	mode = Mode.LIST
	var texts: Array[String] = []
	for slot: int in saves.slot_count:
		texts.append(slot_text(slot))
	_view.show_slots(texts, focus_slot)


func _open_actions() -> void:
	mode = Mode.ACTIONS
	var actions: Array[StringName] = [&"effacer", &"retour"]
	if _system.state_of(selected_slot) == SaveSystem.SlotState.VALID:
		actions.push_front(&"continuer")
	_view.show_actions(actions, saves.action_labels)


func _start(slot: int) -> void:
	started_save = _system.read(slot)
	mode = Mode.DONE
	game_started.emit(slot, started_save)
	finished.emit(saves.start_screen)
