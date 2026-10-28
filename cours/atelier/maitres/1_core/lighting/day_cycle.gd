class_name DayCycle extends Node
## Le cycle jour-nuit : l'heure avance de 0 à 1 et boucle ; le soleil (une DirectionalLight3D) tourne avec elle,
## s'éteint la nuit, culmine à midi, et passe de la couleur de l'aube à celle de midi.

## Le soleil piloté.
@export var sun: DirectionalLight3D
## Durée du jour, énergie, couleurs.
@export var settings: DaySettings

## L'heure, de 0 à 1 (0 : minuit, 0,5 : midi).
var time_of_day: float = 0.0


func _ready() -> void:
	time_of_day = settings.start_time
	apply()


func _process(delta: float) -> void:
	advance(delta)


## Fait passer `delta` secondes de jeu, puis met le soleil à l'heure.
func advance(delta: float) -> void:
	time_of_day = fposmod(time_of_day + delta / settings.day_length, 1.0)
	apply()


## Met le soleil à l'heure : son angle, son énergie, sa couleur.
func apply() -> void:
	sun.rotation.x = sun_pitch(time_of_day)
	sun.light_energy = sun_energy(time_of_day, settings)
	sun.light_color = sun_color(time_of_day, settings)


## L'angle du soleil autour de x à l'heure `time` (radians) : à l'horizon à l'aube (0,25), au zénith à midi (vers
## le bas : -PI/2), sous l'horizon la nuit.
static func sun_pitch(time: float) -> float:
	return -sin((time - 0.25) * TAU) * PI / 2.0


## L'énergie du soleil à l'heure `time` : nulle la nuit, maximale à midi.
static func sun_energy(time: float, day: DaySettings) -> float:
	return maxf(sin((time - 0.25) * TAU), 0.0) * day.noon_energy


## La couleur du soleil à l'heure `time` : celle de l'aube près de l'horizon, celle de midi en haut.
static func sun_color(time: float, day: DaySettings) -> Color:
	var height: float = clampf(sin((time - 0.25) * TAU), 0.0, 1.0)
	return day.dawn_color.lerp(day.noon_color, height)
