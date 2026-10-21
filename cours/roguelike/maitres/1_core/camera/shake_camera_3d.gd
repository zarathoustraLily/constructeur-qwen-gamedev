class_name ShakeCamera3D extends Camera3D
## Caméra qui tremble : un bruit (FastNoiseLite) décale l'image à l'écran (h_offset, v_offset), d'autant plus
## que le « trauma » est grand. quick_shake() le fait monter d'un coup, puis il retombe à zéro en
## shake_duration. Le bruit est lu le long du temps de jeu, pas de l'horloge : deux parties jouées à
## l'identique tremblent à l'identique.

## Le bruit qui donne la forme du tremblement.
@export var noise: FastNoiseLite
## Force actuelle du tremblement : 0, immobile.
@export var trauma: float = 0.0
## Décalage de l'image (en mètres, à la distance de la caméra) pour un trauma de 1 et un bruit de 1.
@export var offset_scale: float = 1.0
## Durée du retour au calme après quick_shake(), en secondes.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var shake_duration: float = 0.3
## Défilement du bruit, en unités de bruit par seconde de jeu (le jeu d'origine lisait l'horloge en
## millisecondes : 1000 par seconde).
@export var noise_speed: float = 1000.0

var _time: float = 0.0


func _physics_process(delta: float) -> void:
	_time += delta * noise_speed
	if noise == null:
		return
	h_offset = noise.get_noise_2d(_time, 0.0) * trauma * offset_scale
	v_offset = noise.get_noise_2d(0.0, _time) * trauma * offset_scale


## Fait trembler la caméra : le trauma part de `magnitude`, puis retombe à zéro en shake_duration.
func quick_shake(magnitude: float) -> void:
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "trauma", 0.0, shake_duration).from(magnitude)
