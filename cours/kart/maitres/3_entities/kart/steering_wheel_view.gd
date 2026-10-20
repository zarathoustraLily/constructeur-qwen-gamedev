extends MeshInstance3D
## Volant du kart : au démarrage, les mains du pilote (les cibles de cinématique inverse IKTargetLeftArm et
## IKTargetRightArm du personnage Gobot) sont accrochées à ses deux poignées ; elles suivent alors le volant.

## Le pilote (gobot_skin.tscn, de l'extension gdquest_gobot).
@export var character: Node3D

@onready var _left_grip: Node3D = $LeftHandGrip
@onready var _right_grip: Node3D = $RightHandGrip


func _ready() -> void:
	if character == null:
		push_error("Volant : le pilote (character) manque")
		return
	_attach(character.get("IKTargetLeftArm"), _left_grip)
	_attach(character.get("IKTargetRightArm"), _right_grip)


func _attach(target: Node3D, grip: Node3D) -> void:
	target.reparent(grip)
	target.position = Vector3.ZERO
