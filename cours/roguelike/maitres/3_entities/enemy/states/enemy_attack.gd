extends EnemyState
## Attaque : l'ennemi s'arrête et joue l'animation de son attaque ; s'il a une arme, elle frappe ce que sa zone
## touche, quand l'animation l'active. À la fin de l'animation, il tire au sort l'état suivant parmi
## next_states, avec son RandomNumberGenerator.

## Les réglages de l'attaque.
@export var attack: AttackSettings
## La zone de coup de l'arme ; vide pour une attaque sans arme (le tir d'une boule de feu).
@export var attack_component: AttackComponent
## Les états possibles après l'attaque, tirés au sort.
@export var next_states: Array[EnemyState] = []


## Rend l'arme à nouveau capable de toucher, lance l'animation et écoute sa fin.
func enter(_previous_state: StringName) -> void:
	if attack_component != null:
		attack_component.reset_exceptions()
	enemy.animation_tree.change_immediate(attack.animation)
	enemy.animation_tree.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Reste sur place et frappe.
func physics_update(_delta: float) -> void:
	if attack_component != null:
		attack_component.deal_damage(attack.damage, enemy.mesh_mount.global_basis.z * attack.knockback)
	enemy.velocity = Vector3.ZERO
	enemy.move_and_slide()


## Une attaque interrompue n'écoute plus la fin de son animation.
func exit() -> void:
	if enemy.animation_tree.animation_finished.is_connected(_on_animation_finished):
		enemy.animation_tree.animation_finished.disconnect(_on_animation_finished)


func _on_animation_finished(_animation_name: StringName) -> void:
	finished.emit(next_states[enemy.rng.randi_range(0, next_states.size() - 1)].name)
