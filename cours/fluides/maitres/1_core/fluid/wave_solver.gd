class_name WaveSolver extends RefCounted
## La surface de l'eau : une hauteur par case, qui oscille. L'équation des ondes dit qu'une case accélère vers la moyenne de ses voisines.
## Il faut donc se souvenir de deux surfaces : la vitesse d'une case est l'écart entre sa hauteur et sa hauteur d'avant.

## Le plus grand chemin, en cases, qu'une onde peut faire en un pas. Au-delà de 1 / √2 en deux dimensions, le schéma explose.
const MAX_COURANT := 0.7

## Les réglages de la surface.
var settings: WaveSettings
## La hauteur de l'eau.
var surface: FluidField

var _previous: FluidField
var _next: FluidField


func _init(wave_settings: WaveSettings) -> void:
	settings = wave_settings
	surface = FluidField.new(settings.width, settings.height)
	_previous = FluidField.new(settings.width, settings.height)
	_next = FluidField.new(settings.width, settings.height)


## Le nombre de pas pour avancer de `delta` secondes sans dépasser `MAX_COURANT`.
static func substeps(delta: float, speed: float) -> int:
	return maxi(ceili(delta * speed / MAX_COURANT), 1)


## Pose une bosse d'eau immobile : ajoutée aux deux surfaces, elle n'a pas de vitesse, et elle ne crée aucune eau en retombant.
func drop(center_x: float, center_y: float, radius: float, amount: float) -> void:
	surface.add_disc(center_x, center_y, radius, amount)
	_previous.add_disc(center_x, center_y, radius, amount)


## Avance de `delta` secondes.
func step(delta: float) -> void:
	var count: int = substeps(delta, settings.speed)
	var courant: float = delta / count * settings.speed
	for _i: int in count:
		_advance(courant * courant)


## Un pas : chaque case garde sa vitesse, amortie, et accélère vers ses voisines.
func _advance(courant_squared: float) -> void:
	for y: int in surface.height:
		for x: int in surface.width:
			var here: float = surface.at(x, y)
			var around: float = _height(x - 1, y) + _height(x + 1, y) + _height(x, y - 1) + _height(x, y + 1) - 4.0 * here
			var moved: float = here + (here - _previous.at(x, y)) * settings.damping + courant_squared * around
			_next.put(x, y, moved)
	var oldest: FluidField = _previous
	_previous = surface
	surface = _next
	_next = oldest


## La hauteur en (`x`, `y`). Au-delà du bord, c'est celle du bord : l'eau n'y va pas, et l'onde repart.
func _height(x: int, y: int) -> float:
	return surface.at(clampi(x, 0, surface.width - 1), clampi(y, 0, surface.height - 1))
