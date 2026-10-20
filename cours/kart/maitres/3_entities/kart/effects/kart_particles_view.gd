class_name KartParticlesView extends Node3D
## Particules du kart : fumée de glissade et étincelles de dérapage, flammes de turbo, gerbe d'étincelles des
## figures. Elle écoute les signaux du kart (drift_stage_changed, boost_changed, tricked) et allume ou
## éteint chaque effet ; elle ne change jamais l'état du kart. Les étincelles prennent la couleur du niveau de
## dérapage : bleues, puis orange.

## Le kart écouté.
@export var kart: Kart
## Les particules de glissade (niveau « glissade »).
@export var sliding_particles: Node3D
## Les étincelles de dérapage (niveaux « étincelles » et « étincelles chaudes »).
@export var drift_sparks: Node3D
## Les flammes de turbo.
@export var boost_particles: Node3D
## La gerbe d'étincelles d'une figure.
@export var trick_sparks: GPUParticles3D
## Matériau des étincelles : son émission prend la couleur du niveau.
@export var sparks_material: StandardMaterial3D
## Couleur des étincelles.
@export var sparks_color: Color
## Couleur des étincelles chaudes.
@export var hot_sparks_color: Color


func _ready() -> void:
	if kart == null:
		push_error("Particules du kart : kart absent")
		return
	kart.drift_stage_changed.connect(set_drift_stage)
	kart.boost_changed.connect(set_boost)
	kart.tricked.connect(play_trick)
	set_drift_stage(Kart.DriftStage.NONE)
	set_boost(false)


## Montre l'effet du niveau de dérapage `stage`.
func set_drift_stage(stage: Kart.DriftStage) -> void:
	_set_emitting(sliding_particles, stage == Kart.DriftStage.SLIDING)
	drift_sparks.visible = stage == Kart.DriftStage.SPARKS or stage == Kart.DriftStage.HOT_SPARKS
	if stage == Kart.DriftStage.SPARKS:
		sparks_material.emission = sparks_color
	elif stage == Kart.DriftStage.HOT_SPARKS:
		sparks_material.emission = hot_sparks_color


## Allume (`active`) ou éteint les flammes de turbo.
func set_boost(active: bool) -> void:
	_set_emitting(boost_particles, active)


## Lance la gerbe d'étincelles d'une figure.
func play_trick() -> void:
	trick_sparks.restart()


# Allume ou éteint toutes les particules enfants de `parent`.
func _set_emitting(parent: Node3D, active: bool) -> void:
	for particles: Node in parent.find_children("*", "GPUParticles3D", true, false):
		(particles as GPUParticles3D).emitting = active
