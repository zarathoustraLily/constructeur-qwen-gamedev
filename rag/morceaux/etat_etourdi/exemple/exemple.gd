extends Node
## Exemple : un état « étourdi » ajouté au robot. On pose la scène du robot, on le frappe au début d'une image de
## physique et on compte les images jusqu'à son retour au repos : stun_duration × 60. Puis on le frappe encore et on
## met l'arbre en pause pendant 60 images : le décompte s'arrête, l'étourdissement dure 60 images de plus en temps
## réel. Enfin, le même décompte refait en GDScript, avec et sans is_zero_approx.

const ROBOT: PackedScene = preload("res://3_entities/robot/robot.tscn")
const PAUSE := 60

var _robot: Robot
var _au_repos := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # l'exemple compte aussi pendant la pause
	_robot = ROBOT.instantiate() as Robot
	_robot.process_mode = Node.PROCESS_MODE_PAUSABLE  # sinon il hériterait d'ALWAYS et ignorerait la pause
	add_child(_robot)
	_robot.state_machine.state_changed.connect(_on_state_changed)
	var attendu := roundi(_robot.stats.stun_duration * Engine.physics_ticks_per_second)
	var sans_pause := await _frapper_et_compter(0)
	var avec_pause := await _frapper_et_compter(PAUSE)
	var decomptes := _decomptes(_robot.stats.stun_duration)
	var ok := sans_pause == attendu and avec_pause == attendu + PAUSE and decomptes.y == attendu
	if ok and _robot.state_machine.current_name() == &"idle":
		print(("EXEMPLE VERIFIE : étourdi %d images de physique (attendu %d) ; avec %d images de pause au milieu, %d ; "
				+ "décompte de %.1f s par pas de 1/%d : %d images avec <= 0 seul, %d avec is_zero_approx")
				% [sans_pause, attendu, PAUSE, avec_pause, _robot.stats.stun_duration, Engine.physics_ticks_per_second,
				decomptes.x, decomptes.y])
	else:
		push_error("étourdi %d images (attendu %d), avec pause %d (attendu %d), décomptes %s"
				% [sans_pause, attendu, avec_pause, attendu + PAUSE, decomptes])
	get_tree().quit()


## Frappe le robot au début d'une image de physique, met l'arbre en pause `pause` images au milieu de
## l'étourdissement, et rend le nombre d'images de physique écoulées jusqu'à son retour au repos.
func _frapper_et_compter(pause: int) -> int:
	await get_tree().physics_frame
	_au_repos = false
	_robot.take_hit()
	var images := 0
	while not _au_repos:
		await get_tree().physics_frame
		images += 1
		if pause > 0 and images == 10:
			get_tree().paused = true
		if pause > 0 and images == 10 + pause:
			get_tree().paused = false
	return images


## Nombre de pas de 1/60 pour épuiser `duree` : avec la seule comparaison à 0 (x), puis avec is_zero_approx (y).
func _decomptes(duree: float) -> Vector2i:
	var pas := 1.0 / Engine.physics_ticks_per_second
	var resultat := Vector2i.ZERO
	var reste := duree
	while reste > 0.0:
		reste -= pas
		resultat.x += 1
	reste = duree
	while reste > 0.0 and not is_zero_approx(reste):
		reste -= pas
		resultat.y += 1
	return resultat


func _on_state_changed(_from: StringName, to: StringName) -> void:
	if to == &"idle":
		_au_repos = true
