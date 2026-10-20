class_name ParticlesManager extends Node3D
## Particules du kart : glissade et étincelles de dérapage, flammes de boost, gerbes d'eau et étincelles
## de figure. Le kart lui demande d'allumer ou d'éteindre chaque effet.

## Couleur des étincelles au niveau de dérapage 2.
@export var drift_stage_1_color : Color 
## Couleur des étincelles au niveau de dérapage 3.
@export var drift_stage_2_color : Color 
## Matériau des étincelles ; son émission prend la couleur du niveau de dérapage.
@export var sparks_material : StandardMaterial3D
@onready var drift_sparks_parent: Node3D = $"../Visual/Kart/Particles/DriftSparks"
## Étincelles de dérapage, trouvées au démarrage.
var drift_spark_particles : Array[GPUParticles3D]

@onready var drifting_sliding_particles_parent: Node3D = $"../Visual/Kart/Particles/SlidingParticles"
## Particules de glissade (niveau de dérapage 1).
var drifting_sliding_particles : Array[GPUParticles3D]

@onready var boost_particles_parent: Node3D = $"../Visual/Kart/Particles/Boost"
## Particules de boost.
var boost_particles : Array[GPUParticles3D]

@onready var trick_particle_sparks : GPUParticles3D = $"Trick/Sparks"

@onready var water_spray_particles_parent: Node3D = $"../Visual/Kart/Particles/WaterParticles"
## Gerbes d'eau.
var water_spray_particles : Array[GPUParticles3D]



func _ready() -> void:
	for child in drift_sparks_parent.get_children(true):
		if child is GPUParticles3D:
			drift_spark_particles.append(child)
			
	for child in drifting_sliding_particles_parent.get_children(true):
		if child is GPUParticles3D:
			drifting_sliding_particles.append(child)
	
	for child in boost_particles_parent.get_children(true):
		if child is GPUParticles3D:
			boost_particles.append(child)
			
	for child in water_spray_particles_parent.get_children(true):
		if child is GPUParticles3D:
			water_spray_particles.append(child)
			
	set_boost(false)
	set_water_spray(false)
	set_sliding_particles(false)

# 0 : no drift
# 1 : sliding drift
# 2 : blue
# 3 : orange
## Affiche l'effet du niveau de dérapage `stage` : 0 aucun, 1 glissade, 2 et 3 étincelles colorées.
func set_drifing_stage(stage : int) -> void:	
	match stage:
		0:
			set_sliding_particles(false)
			drift_sparks_parent.visible = false
		1:
			set_sliding_particles(true)
			drift_sparks_parent.visible = false
		2:
			set_sliding_particles(false)
			sparks_material.emission = drift_stage_1_color
			drift_sparks_parent.visible = true
		3:
			set_sliding_particles(false)
			sparks_material.emission = drift_stage_2_color
			drift_sparks_parent.visible = true

## Allume ou éteint les particules de glissade.
func set_sliding_particles(enabled: bool) -> void:
	for particle in drifting_sliding_particles:
		particle.emitting = enabled

## Allume ou éteint les particules de boost.
func set_boost(enabled: bool) -> void:
	for particle in boost_particles:
		particle.emitting = enabled

## Allume ou éteint les gerbes d'eau.
func set_water_spray(enabled: bool) -> void:
	for particle in water_spray_particles:
		particle.emitting = enabled
		
## Lance la gerbe d'étincelles d'une figure.
func play_trick_particles() -> void:
	trick_particle_sparks.emitting = true
