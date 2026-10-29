class_name GolemDeadState extends State
## L'état Dead du golem : il est tombé ; plus rien ne frappe ni ne le touche ; il ne quitte plus cet état.

## Le golem piloté.
@export var golem: Golem


## Il tombe.
func enter(_previous: StringName) -> void:
	golem.velocity = Vector3.ZERO
	golem.fall()
