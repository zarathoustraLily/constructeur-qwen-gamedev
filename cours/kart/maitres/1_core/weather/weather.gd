class_name Weather extends RefCounted
## La météo d'une partie : la force de la pluie, le mouillage de la route, qui la suit avec retard, et l'orage.
## update() la fait avancer d'un pas et dit si un éclair tombe ; la scène qui la possède en transmet l'état aux
## shaders (GameState), à la pluie dessinée et aux roues. Le hasard des éclairs vient de la graine des
## réglages : un même orage, éclair pour éclair (règle SIM-09).

## Réglages (5_data/weather/storm.tres).
var settings: WeatherSettings
## Force de la pluie, de 0 à 1.
var intensity: float = 0.0
## Mouillage de la route, de 0 à 1.
var wetness: float = 0.0
## Temps avant le prochain éclair (s).
var next_strike: float = 0.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(weather_settings: WeatherSettings) -> void:
	settings = weather_settings
	intensity = settings.intensity
	wetness = intensity if settings.start_wet else 0.0
	_rng.seed = settings.random_seed
	_schedule_strike()


## Avance la météo de `delta` secondes ; vrai si un éclair tombe à ce pas.
func update(delta: float) -> bool:
	wetness = move_toward(wetness, intensity, settings.wetness_speed * delta)
	if intensity < settings.lightning_min_intensity:
		return false
	next_strike -= delta
	if next_strike > 0.0:
		return false
	_schedule_strike()
	return true


func _schedule_strike() -> void:
	next_strike = _rng.randf_range(settings.lightning_interval_min, settings.lightning_interval_max)
