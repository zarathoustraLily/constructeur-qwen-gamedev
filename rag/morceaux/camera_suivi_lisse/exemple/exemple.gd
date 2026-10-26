extends Node3D
## Exemple : caméra qui suit sa cible. La cible saute de 10 m ; on fait suivre deux caméras pendant 0,2 s, l'une à 30
## images par seconde (6 pas), l'autre à 120 (24 pas), en appelant follow() pas à pas. Elles arrivent au même endroit.
## Le lissage naïf (lerp par smoothing × delta), refait sur les mêmes pas, dépend de la cadence.

const SMOOTHING := 5.0  # dans un jeu, réglé dans la scène de la caméra
const DUREE := 0.2


func _ready() -> void:
	var cible := Node3D.new()
	add_child(cible)
	var a_30 := _camera(cible)
	var a_120 := _camera(cible)
	cible.position = Vector3(10.0, 0.0, 0.0)
	for _i: int in roundi(DUREE * 30.0):
		a_30.follow(1.0 / 30.0)
	for _i: int in roundi(DUREE * 120.0):
		a_120.follow(1.0 / 120.0)
	var ecart := a_30.global_position.distance_to(a_120.global_position)
	var reste := a_30.global_position.distance_to(cible.global_position)
	var attendu := 10.0 * exp(-SMOOTHING * DUREE)
	var naif_30 := _naif(30)
	var naif_120 := _naif(120)
	if ecart < 0.0001 and absf(reste - attendu) < 0.0001 and absf(naif_30 - naif_120) > 0.1:
		print(("EXEMPLE VERIFIE : après %.1f s, écart entre 30 et 120 images/s %.6f m, reste %.4f m (10 × e^-1 = %.4f) ; "
				+ "lissage naïf : reste %.3f m à 30 images/s, %.3f m à 120")
				% [DUREE, ecart, reste, attendu, naif_30, naif_120])
	else:
		push_error("écart %.6f, reste %.4f (attendu %.4f), naïf %.3f et %.3f" % [ecart, reste, attendu, naif_30, naif_120])
	get_tree().quit()


func _camera(cible: Node3D) -> FollowCamera3D:
	var camera := FollowCamera3D.new()
	camera.smoothing = SMOOTHING
	add_child(camera)
	camera.setup(cible)
	camera.set_process(false)  # l'exemple fait avancer la caméra lui-même, pas à pas
	return camera


## Distance restante après DUREE de lissage naïf (lerp par smoothing × delta) à `cadence` images par seconde.
func _naif(cadence: int) -> float:
	var x := 0.0
	for _i: int in roundi(DUREE * cadence):
		x = lerpf(x, 10.0, SMOOTHING / cadence)
	return 10.0 - x
