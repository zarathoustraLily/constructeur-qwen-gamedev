class_name Main extends Node
## La coquille du jeu : elle ouvre le premier écran de l'enchaînement (`SequenceDef`), puis, chaque fois qu'un écran
## dit qu'il a fini, ouvre celui qu'il nomme. Un écran est une scène dont la racine émet `finished(next)` ; il ne
## connaît pas la coquille, et la coquille ne sait rien de ce qu'il montre.

## Un écran vient de s'ouvrir.
signal screen_changed(screen: StringName)
## Un écran a demandé un écran qui n'existe pas.
signal screen_missing(screen: StringName)

## L'enchaînement des écrans.
@export var sequence: SequenceDef = null
#@ 5+
## Les options du jeu : leurs réglages enregistrés s'appliquent dès l'ouverture.
@export var options: OptionsDef = null
#@ all

## Le nom de l'écran ouvert (vide : aucun).
var current_name: StringName = &""

var _current: Node = null
var _rng_source: RngSource = null


func _ready() -> void:
	process_priority = ProcessOrder.FLOW
	var errors: Array[String] = ["main : pas d'enchaînement"]
	if sequence != null:
		errors = sequence.validate()
	for error: String in errors:
		push_error(error)
	if not errors.is_empty():
		return
	_rng_source = RngSource.new(sequence.rng_seed)
#@ 5+
	if options != null:
		SettingsApplier.apply(GameSettings.load_from(options))
#@ all
	if sequence.first_screen != &"":
		show_screen(sequence.first_screen)


## Le générateur du hasard de la partie, tiré de la graine de l'enchaînement.
func rng() -> RandomNumberGenerator:
	return _rng_source.instance()


## L'écran ouvert, ou null.
func current_screen() -> Node:
	return _current


## Ouvre l'écran `screen` à la place de celui qui était ouvert.
func show_screen(screen: StringName) -> void:
	if not sequence.screens.has(screen):
		screen_missing.emit(screen)
		return
	var scene: PackedScene = load(sequence.screens[screen])
	var node: Node = scene.instantiate()
	if _current != null:
		remove_child(_current)
		_current.queue_free()
	_current = node
	current_name = screen
	node.connect(&"finished", _on_screen_finished)
#@ 6+
	if node.has_method(&"use_rng"):
		node.call(&"use_rng", rng())
#@ all
	add_child(node)
	screen_changed.emit(screen)


func _on_screen_finished(next: StringName) -> void:
#@ 2+
	if next == &"":
		return
#@ all
	show_screen(next)
