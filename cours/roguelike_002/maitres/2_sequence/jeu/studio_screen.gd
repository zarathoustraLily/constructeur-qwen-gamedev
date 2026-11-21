class_name StudioScreen extends Control
## L'écran du studio : la marque et le nom de la boîte apparaissent, tiennent, puis disparaissent, pendant que le
## jeu charge en fond ce dont le menu aura besoin. Il ne part qu'une fois la tenue minimale finie ET le chargement
## fini ; la barre suit le vrai chargement. Il décide seul de son déroulé ; sa vue (`StudioView`) ne fait que montrer.

## L'écran a fini ; `next` nomme le suivant.
signal finished(next: StringName)

## Les moments de l'écran.
enum Phase {
	FADE_IN, ## la marque apparaît
	HOLD, ## elle tient, le temps du chargement
	FADE_OUT, ## elle disparaît
	DONE, ## l'écran a fini
}

## Les réglages de l'écran.
@export var studio: StudioDef = null

## Le moment où en est l'écran.
var phase: Phase = Phase.FADE_IN

var _elapsed: float = 0.0
var _loader: BackgroundLoader = null

@onready var _view: StudioView = $View


## Donne le chargeur à utiliser (sinon l'écran en crée un) ; à appeler avant l'entrée dans l'arbre.
func setup(loader: BackgroundLoader) -> void:
	_loader = loader


func _ready() -> void:
	process_priority = ProcessOrder.FLOW
	for error: String in studio.validate():
		push_error(error)
	if _loader == null:
		_loader = BackgroundLoader.new()
	_loader.start(studio.preload_paths)
	_view.show_name(studio.studio_name)
	_view.render(opacity(), _loader.progress())


func _process(delta: float) -> void:
	advance(delta)


func _exit_tree() -> void:
	_loader.release()


## Avance l'écran de `delta` secondes.
func advance(delta: float) -> void:
	if phase == Phase.DONE:
		return
	_loader.poll()
	_elapsed += delta
	if phase == Phase.FADE_IN and _elapsed >= studio.fade_in_s:
		_enter(Phase.HOLD)
	elif phase == Phase.HOLD and _elapsed >= studio.min_hold_s and _loader.is_done():
		_enter(Phase.FADE_OUT)
	elif phase == Phase.FADE_OUT and _elapsed >= studio.fade_out_s:
		_enter(Phase.DONE)
	_view.render(opacity(), _loader.progress())
	if phase == Phase.DONE:
		finished.emit(studio.next_screen)


## L'opacité de la marque et du nom, de 0 à 1.
func opacity() -> float:
	if phase == Phase.FADE_IN:
		return _ratio(studio.fade_in_s)
	if phase == Phase.HOLD:
		return 1.0
	if phase == Phase.FADE_OUT:
		return 1.0 - _ratio(studio.fade_out_s)
	return 0.0


## Où en est le chargement en fond, de 0 à 1.
func load_progress() -> float:
	return _loader.progress()


func _ratio(duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	return clampf(_elapsed / duration, 0.0, 1.0)


func _enter(next_phase: Phase) -> void:
	phase = next_phase
	_elapsed = 0.0
