class_name DisclaimerScreen extends Control
## L'écran d'avertissement : le texte apparaît, se lit, puis disparaît. Le joueur ne peut le passer qu'après le temps
## de lecture minimal (une demande trop tôt est ignorée) ; s'il ne fait rien, l'écran passe seul au bout de sa durée
## d'affichage. Ses entrées (`DisclaimerInput`) demandent, l'écran décide, sa vue (`DisclaimerView`) montre.

## L'écran a fini ; `next` nomme le suivant.
signal finished(next: StringName)

## Les moments de l'écran.
enum Phase {
	FADE_IN, ## le texte apparaît
	SHOW, ## il se lit
	FADE_OUT, ## il disparaît
	DONE, ## l'écran a fini
}

## Les réglages de l'écran.
@export var disclaimer: DisclaimerDef = null

## Le moment où en est l'écran.
var phase: Phase = Phase.FADE_IN

var _elapsed: float = 0.0
var _shown_for: float = 0.0

@onready var _view: DisclaimerView = $View
@onready var _input: DisclaimerInput = $Input


func _ready() -> void:
	process_priority = ProcessOrder.FLOW
	for error: String in disclaimer.validate():
		push_error(error)
	_input.skip_requested.connect(request_skip)
	_view.show_texts(disclaimer.title, disclaimer.body, disclaimer.hint, disclaimer.hint_pulse_s,
			disclaimer.hint_low_alpha)
	_view.render(opacity(), can_skip())


func _process(delta: float) -> void:
	advance(delta)


## Avance l'écran de `delta` secondes.
func advance(delta: float) -> void:
	if phase == Phase.DONE:
		return
	_elapsed += delta
	_shown_for += delta
	if phase == Phase.FADE_IN and _elapsed >= disclaimer.fade_s:
		_enter(Phase.SHOW)
	elif phase == Phase.SHOW and disclaimer.auto_next_s > 0.0 and _shown_for >= disclaimer.auto_next_s:
		_enter(Phase.FADE_OUT)
	elif phase == Phase.FADE_OUT and _elapsed >= disclaimer.fade_s:
		_enter(Phase.DONE)
	_view.render(opacity(), can_skip())
	if phase == Phase.DONE:
		finished.emit(disclaimer.next_screen)


## Vrai quand le temps de lecture minimal est passé et que l'écran n'est pas déjà en train de partir.
func can_skip() -> bool:
	return phase != Phase.FADE_OUT and phase != Phase.DONE and _shown_for >= disclaimer.skip_after_s


## Le joueur demande à passer l'écran : accepté seulement quand `can_skip()`.
func request_skip() -> void:
	if can_skip():
		_enter(Phase.FADE_OUT)


## L'opacité du texte, de 0 à 1.
func opacity() -> float:
	if phase == Phase.FADE_IN:
		return _ratio()
	if phase == Phase.SHOW:
		return 1.0
	if phase == Phase.FADE_OUT:
		return 1.0 - _ratio()
	return 0.0


func _ratio() -> float:
	if disclaimer.fade_s <= 0.0:
		return 1.0
	return clampf(_elapsed / disclaimer.fade_s, 0.0, 1.0)


func _enter(next_phase: Phase) -> void:
	phase = next_phase
	_elapsed = 0.0
