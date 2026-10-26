extends Node3D
## Exemple : couches et masques. Une pièce surveille la couche « joueur ». Un ennemi (couche 3) entre dans sa zone : rien.
## Le joueur (couche 2) y entre : la pièce émet collected et disparaît. On compte aussi les images de physique avant la
## détection : la zone ne voit un corps qu'après une image de physique.

const COIN: PackedScene = preload("res://3_entities/pickups/coin/coin.tscn")
const COUCHE_JOUEUR := 2
const COUCHE_ENNEMIS := 3

var _ramassee := 0


func _ready() -> void:
	var piece := COIN.instantiate() as Coin
	add_child(piece)
	piece.collected.connect(func() -> void: _ramassee += 1)
	var ennemi := _corps(COUCHE_ENNEMIS, Vector3(0.0, 0.0, 0.3))
	add_child(ennemi)
	for _i: int in 3:
		await get_tree().physics_frame
	var apres_ennemi := _ramassee
	var joueur := _corps(COUCHE_JOUEUR, Vector3(10.0, 0.0, 0.0))
	add_child(joueur)
	await get_tree().physics_frame
	joueur.position = Vector3.ZERO
	var images := 0
	var tout_de_suite := _ramassee
	while _ramassee == 0 and images < 10:
		await get_tree().physics_frame
		images += 1
	await get_tree().process_frame  # queue_free libère la pièce à la fin de l'image
	if apres_ennemi == 0 and tout_de_suite == 0 and _ramassee == 1 and not is_instance_valid(piece):
		print("EXEMPLE VERIFIE : ennemi (couche %d) dans la zone, 0 ramassage ; joueur (couche %d) : ramassée après %d image(s) de physique, pièce libérée"
				% [COUCHE_ENNEMIS, COUCHE_JOUEUR, images])
	else:
		push_error("après l'ennemi %d, tout de suite %d, ramassée %d en %d images, pièce encore là %s"
				% [apres_ennemi, tout_de_suite, _ramassee, images, is_instance_valid(piece)])
	get_tree().quit()


## Un corps sur une seule couche, de 0,5 m de rayon.
func _corps(couche: int, ou: Vector3) -> CharacterBody3D:
	var forme := SphereShape3D.new()
	forme.radius = 0.5
	var collision := CollisionShape3D.new()
	collision.shape = forme
	var corps := CharacterBody3D.new()
	corps.collision_layer = 0
	corps.set_collision_layer_value(couche, true)
	corps.position = ou
	corps.add_child(collision)
	return corps
