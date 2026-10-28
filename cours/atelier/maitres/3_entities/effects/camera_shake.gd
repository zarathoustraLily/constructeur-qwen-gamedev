class_name CameraShake extends Node
## Le tremblement de caméra, par « traumatisme » : chaque choc ajoute du traumatisme (de 0 à 1), qui retombe avec
## le temps ; la caméra est décalée de son carré (les petits chocs bougent à peine, les gros secouent) suivant un
## bruit continu (FastNoiseLite), pas un hasard qui saute d'une image à l'autre.

## La caméra secouée (son décalage h_offset et v_offset).
@export var camera: Camera3D
## Décalage maximal, retombée, fréquence.
@export var settings: VfxSettings

## Le traumatisme actuel, de 0 à 1.
var trauma: float = 0.0
## Le temps écoulé, qui fait avancer le bruit.
var time: float = 0.0

var _noise: FastNoiseLite = FastNoiseLite.new()


func _ready() -> void:
	process_priority = ProcessOrder.CAMERA
	_noise.seed = 1
	_noise.frequency = 1.0


func _process(delta: float) -> void:
	update(delta)


## Ajoute `amount` de traumatisme (borné à 1).
func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Fait passer `delta` secondes : le traumatisme retombe, et la caméra prend le décalage du moment.
func update(delta: float) -> void:
	time += delta
	trauma = maxf(trauma - settings.shake_decay * delta, 0.0)
	var shift: Vector2 = offset(time)
	camera.h_offset = shift.x
	camera.v_offset = shift.y


## La force du tremblement : le carré du traumatisme.
func intensity() -> float:
	return trauma * trauma


## Le décalage de la caméra au temps `at` : deux tirages du bruit (x et y, décalés), fois la force et le décalage
## maximal. Nul sans traumatisme.
func offset(at: float) -> Vector2:
	var amount: float = intensity() * settings.shake_max_offset
	var t: float = at * settings.shake_frequency
	return Vector2(_noise.get_noise_1d(t), _noise.get_noise_1d(t + 100.0)) * amount
