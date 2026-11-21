class_name MenuScreen extends Control
## Le menu principal. Il décide : l'entrée (le titre puis les choix arrivent ; on ne peut rien choisir avant la fin),
## le choix mis en avant, ce que fait un choix (mener à un écran, quitter le jeu, ou trembler s'il n'est pas encore
## disponible), puis le départ. Sa vue (`MenuView`) calcule tout le mouvement à partir de ce qu'il lui donne : le temps
## écoulé et l'âge de chaque événement. Le même temps redonne donc toujours la même image.

## L'écran a fini ; `next` nomme le suivant.
signal finished(next: StringName)
## Le joueur a choisi de quitter le jeu.
signal quit_requested
## Le joueur a choisi un choix qui ne mène encore nulle part.
signal unavailable(item: StringName)

## Les moments de l'écran.
enum Phase {
	INTRO, ## le titre et les choix entrent
	READY, ## on peut choisir
	LEAVING, ## un choix est fait, l'écran part
	DONE, ## l'écran a fini
}

## Les réglages du menu.
@export var menu: MenuDef = null
## Vrai : le choix qui quitte ferme vraiment le jeu (les tests le coupent).
@export var quits_game: bool = true

## Le moment où en est l'écran.
var phase: Phase = Phase.INTRO
## Le choix mis en avant.
var focused: StringName = &""
## Le choix fait (vide tant qu'aucun).
var chosen: StringName = &""

var _time: float = 0.0
var _focused_at: float = 0.0
var _refused: StringName = &""
var _refused_at: float = 0.0
var _left_at: float = 0.0
var _target: StringName = &""

@onready var _view: MenuView = $View


func _ready() -> void:
	process_priority = ProcessOrder.FLOW
	for error: String in menu.validate():
		push_error(error)
	_view.setup(menu)
	_view.item_focused.connect(focus)
	_view.item_chosen.connect(choose)
	_render()


func _process(delta: float) -> void:
	advance(delta)


## Avance l'écran de `delta` secondes.
func advance(delta: float) -> void:
	if phase == Phase.DONE:
		return
	_time += delta
	if phase == Phase.INTRO and _time >= menu.intro_s():
		phase = Phase.READY
		_view.set_interactive(true)
	elif phase == Phase.LEAVING and _time - _left_at >= menu.leave_s:
		phase = Phase.DONE
	_render()
	if phase == Phase.DONE:
		finished.emit(_target)


## Met `item` en avant.
func focus(item: StringName) -> void:
	if item != focused:
		focused = item
		_focused_at = _time


## Fait le choix `item` : seulement quand on peut choisir.
func choose(item: StringName) -> void:
	if phase != Phase.READY:
		return
	if item == menu.quit_item:
		quit_requested.emit()
		if quits_game:
			get_tree().quit()
		return
	var target: StringName = menu.targets.get(item, &"")
	if target == &"":
		_refused = item
		_refused_at = _time
		unavailable.emit(item)
		return
	chosen = item
	_target = target
	phase = Phase.LEAVING
	_left_at = _time
	_view.set_interactive(false)


## Le temps écoulé depuis l'ouverture de l'écran, en secondes.
func elapsed() -> float:
	return _time


func _render() -> void:
	var leave: float = 0.0
	if phase == Phase.LEAVING or phase == Phase.DONE:
		leave = 1.0 if menu.leave_s <= 0.0 else clampf((_time - _left_at) / menu.leave_s, 0.0, 1.0)
	_view.render(_time, focused, _time - _focused_at, _refused, _time - _refused_at, leave)
