extends Node2D
## Exemple : traînée derrière un objet qui se déplace. Un point traverse l'écran de gauche à droite ; à chaque image, la
## Line2D reçoit sa position et perd ses points les plus anciens au-delà d'une longueur. Un dégradé l'efface vers
## l'arrière. On lit la ligne de l'image où passe le point : la traînée couvre une longueur bornée derrière lui,
## pleine près du point, pâle à l'arrière, et rien au point de départ.

# Dans un jeu, ces réglages viennent d'un .tres de 5_data (principe 2 du plan).
const LONGUEUR := 30
const VITESSE := 6.0

var _trainee: Line2D
var _point := Vector2(20.0, 0.0)


func _ready() -> void:
	_point.y = get_viewport_rect().size.y * 0.5
	_trainee = Line2D.new()
	_trainee.width = 12.0
	_trainee.top_level = true  # les points sont des positions du monde : la ligne ne suit pas son parent
	var degrade := Gradient.new()
	degrade.set_color(0, Color(1.0, 1.0, 1.0, 0.0))  # premier point : le plus ancien, transparent
	degrade.set_color(1, Color(1.0, 1.0, 1.0, 1.0))  # dernier point : le plus récent, plein
	_trainee.gradient = degrade
	add_child(_trainee)
	for _i: int in 90:
		_point.x += VITESSE
		suivre(_trainee, _point, LONGUEUR)
		await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var y := int(_point.y)
	var fond := RenderingServer.get_default_clear_color().get_luminance()
	var pres := image.get_pixel(int(_point.x) - 10, y).get_luminance() - fond
	var loin := image.get_pixel(int(_point.x) - int(VITESSE * (LONGUEUR - 4)), y).get_luminance() - fond
	var depart := image.get_pixel(30, y).get_luminance() - fond
	if _trainee.get_point_count() == LONGUEUR and pres > 0.5 and loin < pres * 0.4 and absf(depart) < 0.02:
		print("EXEMPLE VERIFIE : %d points ; luminance au-dessus du fond %.2f près du point, %.2f à l'arrière, %.2f au départ"
				% [_trainee.get_point_count(), pres, loin, depart])
	else:
		push_error("%d points ; près %.2f, loin %.2f, départ %.2f" % [_trainee.get_point_count(), pres, loin, depart])
	get_tree().quit()


## La traînée suit `point` : sa position est ajoutée à la fin, les plus anciennes sont retirées au-delà de `longueur`.
func suivre(trainee: Line2D, point: Vector2, longueur: int) -> void:
	trainee.add_point(point)
	while trainee.get_point_count() > longueur:
		trainee.remove_point(0)
