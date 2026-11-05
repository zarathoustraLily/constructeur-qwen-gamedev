class_name BenchPanel
extends VBoxContainer
## Le panneau du banc d'essai : l'animation à poser sur le banc, un bouton par état pour jouer son clip (avec le fondu de
## la définition), et une case par effet du jeu pour l'ajouter ou le retirer en aperçu.

var _bench: BenchView
var _animations: Array[AnimationDef] = []
var _effects: Array[FxDef] = []
var _picker: OptionButton = OptionButton.new()
var _effect_checks: Dictionary[StringName, CheckBox] = {}


## Construit le panneau pour le banc `bench`, avec les animations et les effets du jeu.
func setup(bench: BenchView, animations: Array[AnimationDef], effects: Array[FxDef]) -> void:
	_bench = bench
	_animations = animations
	_effects = effects
	var title: Label = Label.new()
	title.text = "Banc d'essai"
	add_child(title)
	for definition: AnimationDef in animations:
		_picker.add_item(definition.display_name)
	_picker.item_selected.connect(choose)
	add_child(_picker)
	var states: HFlowContainer = HFlowContainer.new()
	for state: StringName in AnimationDef.STATES:
		var button: Button = Button.new()
		button.text = String(state)
		button.pressed.connect(func() -> void: _bench.play_state(state))
		states.add_child(button)
	add_child(states)
	for effect: FxDef in effects:
		var check: CheckBox = CheckBox.new()
		check.text = effect.display_name
		check.toggled.connect(func(_pressed: bool) -> void: _apply_effects())
		_effect_checks[effect.id] = check
		add_child(check)
	if not animations.is_empty():
		choose(0)


## Pose sur le banc l'animation de la ligne `index`.
func choose(index: int) -> void:
	if index < 0 or index >= _animations.size():
		return
	_picker.select(index)
	_bench.show_animation(_animations[index])
	_apply_effects()


## La case de l'effet `effect_id` (pour les tests).
func effect_check(effect_id: StringName) -> CheckBox:
	return _effect_checks.get(effect_id)


func _apply_effects() -> void:
	_bench.clear_effects()
	for effect: FxDef in _effects:
		if _effect_checks[effect.id].button_pressed:
			_bench.add_effect(effect)
