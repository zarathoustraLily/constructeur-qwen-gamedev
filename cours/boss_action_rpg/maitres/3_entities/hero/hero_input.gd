class_name HeroInput extends Node
## L'entrée du héros : elle lit les actions et les donne au héros. Changer de manette ou de touches ne touche que les
## actions de project.godot ; le héros ne sait rien des appareils.

## Le héros piloté.
@export var hero: Hero


func _ready() -> void:
	process_physics_priority = ProcessOrder.INPUT


func _physics_process(_delta: float) -> void:
	hero.stick = Input.get_vector(Actions.MOVE_LEFT, Actions.MOVE_RIGHT, Actions.MOVE_FORWARD, Actions.MOVE_BACK)
	hero.aiming = Input.is_action_pressed(Actions.AIM)
#@ 4+
	hero.dodge_held = Input.is_action_pressed(Actions.DODGE)
	if Input.is_action_just_pressed(Actions.DODGE):
		hero.roll_buffer.press()
#@ 16+
	if Input.is_action_just_pressed(Actions.JUMP):
		hero.jump_buffer.press()
#@ all
#@ 5+
	hero.trigger = Input.is_action_pressed(Actions.SHOOT)
#@ 6+
	if Input.is_action_just_pressed(Actions.HEAL):
		hero.heal_buffer.press()
#@ all
