class_name Game extends Node
## Le jeu entier : une salle à la fois. Il écoute la salle présente, passe au noir, change de salle, rend l'image. Il garde
## l'arme de Bobine d'une salle à l'autre ; elle se perd à la chute, quand la scène principale recharge tout le jeu et ramène
## Bobine au Terrier.

## La salle du départ.
@export_file("*.tscn") var first_level: String = ""
## Le temps du passage au noir, puis du retour, en secondes.
@export_range(0.0, 3.0, 0.05) var fade_time: float = 0.35

## La salle présente.
var level: Node3D = null
## L'arme en main, ou null.
var weapon: WeaponKit = null
## Vrai pendant un passage : un second seuil franchi ne compte pas.
var changing: bool = false

@onready var _black: ColorRect = $Fade/Black


func _ready() -> void:
	_enter(first_level)


## Passe à la salle `path` : le noir, le changement, le retour de l'image.
func go_to(path: String) -> void:
	if changing:
		return
	changing = true
	await _fade_to(1.0)
	level.queue_free()
	_enter(path)
	await _fade_to(0.0)
	changing = false


## L'opacité du noir, de 0 à 1.
func fade_alpha() -> float:
	return _black.color.a


func _enter(path: String) -> void:
	level = (load(path) as PackedScene).instantiate() as Node3D
	add_child(level)
	var hero: Hero = level.get_node(^"Hero") as Hero
	hero.weapon_changed.connect(_on_weapon_changed)
	if weapon != null:
		hero.equip(weapon)
	if level is Level:
		(level as Level).left.connect(go_to)


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_black, ^"color:a", alpha, fade_time)
	await tween.finished


func _on_weapon_changed(kit: WeaponKit) -> void:
	weapon = kit
