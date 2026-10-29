@tool
class_name SpectreModel extends Node3D
## Le squelette spectral, monté : les pièces de SpectreBones posées sur des articulations que la vue fait bouger (la
## tête et sa mâchoire, deux épaules, deux coudes, deux poignets). Il se construit en entrant dans l'arbre, une fois,
## dans le jeu comme dans l'éditeur ; ses maillages sont partagés par tous les spectres. Il regarde vers -Z.

## La tête (pivot en haut du cou).
var head: Node3D
## La mâchoire (pivot à sa charnière).
var jaw: Node3D
## Les épaules, gauche puis droite.
var shoulders: Array[Node3D] = []
## Les coudes, gauche puis droite.
var elbows: Array[Node3D] = []
## Les poignets, gauche puis droite.
var wrists: Array[Node3D] = []


func _ready() -> void:
	if head != null:
		return
	_piece(self, &"Torso", &"torso")
	_piece(self, &"Shroud", &"shroud")
	head = _joint(self, &"Head", SpectreBones.SKULL_PIVOT)
	_piece(head, &"Skull", &"skull")
	jaw = _joint(head, &"JawHinge", SpectreBones.JAW_HINGE)
	_piece(jaw, &"Jaw", &"jaw")
	for side: String in ["Left", "Right"]:
		var x: float = SpectreBones.SHOULDER.x * (-1.0 if side == "Left" else 1.0)
		var shoulder: Node3D = _joint(self, side + "Shoulder", Vector3(x, SpectreBones.SHOULDER.y, SpectreBones.SHOULDER.z))
		_piece(shoulder, &"UpperArm", &"upper_arm")
		var elbow: Node3D = _joint(shoulder, side + "Elbow", Vector3(0.0, -SpectreBones.UPPER_ARM_LENGTH, 0.0))
		_piece(elbow, &"Forearm", &"forearm")
		var wrist: Node3D = _joint(elbow, side + "Wrist", Vector3(0.0, -SpectreBones.FOREARM_LENGTH, 0.0))
		_piece(wrist, &"Hand", StringName("hand_" + side.to_lower()))
		shoulders.append(shoulder)
		elbows.append(elbow)
		wrists.append(wrist)


func _joint(parent: Node3D, joint_name: String, at: Vector3) -> Node3D:
	var joint: Node3D = Node3D.new()
	joint.name = joint_name
	joint.position = at
	parent.add_child(joint)
	return joint


func _piece(parent: Node3D, piece_name: String, part: StringName) -> void:
	var piece: MeshInstance3D = MeshInstance3D.new()
	piece.name = piece_name
	piece.mesh = SpectreBones.mesh(part)
	parent.add_child(piece)
