class_name HealthBar extends Node3D
## Barre de santé au-dessus d'un personnage : une image de 128 × 16 pixels (une SubViewport et deux ProgressBar)
## affichée dans le monde par un Sprite3D toujours tourné vers la caméra. La barre de devant tombe d'un coup à la
## santé restante ; celle de derrière, claire, la rejoint en 0,2 s : on voit ce qu'on vient de perdre. Vaincu, le
## personnage voit sa barre s'effacer. Sans santé à suivre, elle reste éteinte.

## La santé suivie, posée avant d'entrer dans l'arbre.
@export var health_component: HealthComponent
## Couleur de la barre de devant.
@export var health_color: Color = Color.WHITE

@onready var _front: ProgressBar = $SubViewport/FrontProgressBar
@onready var _back: ProgressBar = $SubViewport/HealthProgressBar
@onready var _sprite: Sprite3D = $Sprite3D


func _ready() -> void:
	if health_component == null:
		return
	health_component.health_changed.connect(_on_health_changed)
	health_component.defeated.connect(_on_defeated)
	_front.value = _front.max_value
	_back.value = _back.max_value
	(_front.get_theme_stylebox(&"fill") as StyleBoxFlat).bg_color = health_color


## La part de santé restante montrée par la barre de devant, en % (de 0 à 100).
func shown_percentage() -> float:
	return _front.value


func _on_health_changed(value: float) -> void:
	var percentage := value / health_component.max_health * _front.max_value
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_back, "value", percentage, 0.2).from(_front.value)
	_front.value = percentage


func _on_defeated() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "transparency", 1.0, 0.2).from(0.0)
	tween.tween_callback(queue_free)
