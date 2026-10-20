class_name Impact
extends CPUParticles3D
## Gerbe d'étincelles à l'endroit d'un coup ; se détruit une fois jouée.


func _ready() -> void:
	emitting = true
	finished.connect(queue_free)
