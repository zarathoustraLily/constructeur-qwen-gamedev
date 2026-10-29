class_name GolemApproachState extends State
## L'état Approach du golem : il se tourne vers le héros ; quand il le regarde à peu près en face, il choisit une
## attaque permise à cette distance (Attack) ; s'il n'en a aucune, il marche vers lui. La seconde phase, si elle est
## due, passe d'abord (PhaseShift).

## Le golem piloté.
@export var golem: Golem


## Il s'arrête en entrant.
func enter(_previous: StringName) -> void:
	golem.velocity = Vector3.ZERO


## Il choisit un coup, ou marche.
func physics_update(delta: float) -> void:
	if golem.phase_two_due:
		finish(&"PhaseShift")
		return
	golem.face_target(delta)
	var facing: bool = golem.angle_to_target() <= golem.settings.walk_cone
	var chosen: GolemAttack = golem.choose_attack(golem.distance_to_target()) if facing else null
	if chosen != null:
		golem.attack = chosen
		finish(&"Attack")
		return
	golem.velocity = Motion.forward_of(golem.rotation.y) * golem.settings.walk_speed if facing else Vector3.ZERO
	golem.move_and_slide()


## Il s'arrête en sortant.
func exit() -> void:
	golem.velocity = Vector3.ZERO
