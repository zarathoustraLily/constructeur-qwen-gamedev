extends Node
## Service audio du jeu : les bus de la musique et des effets, et leur volume réglé en valeur linéaire (de 0 à 1,
## comme un curseur). Les menus et les réglages passent par lui ; personne d'autre ne touche aux bus d'AudioServer.

## Le volume du bus `bus` vient de changer ; `linear` : sa nouvelle valeur, de 0 à 1.
signal volume_changed(bus: StringName, linear: float)

## Le bus de la musique.
const MUSIC: StringName = &"Music"
## Le bus des effets sonores.
const SFX: StringName = &"SFX"


func _ready() -> void:
	ensure_bus(MUSIC)
	ensure_bus(SFX)


## L'index du bus `bus_name`, créé à la fin de la liste et envoyé vers Master s'il n'existait pas.
func ensure_bus(bus_name: StringName) -> int:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index >= 0:
		return index
	AudioServer.add_bus()
	index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")
	return index


## Règle le volume du bus `bus_name` (de 0 à 1, borné) ; à 0, le bus est coupé.
func set_volume(bus_name: StringName, linear: float) -> void:
	var index: int = ensure_bus(bus_name)
	var value: float = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, Volume.to_db(value))
	AudioServer.set_bus_mute(index, value <= 0.0)
	volume_changed.emit(bus_name, value)


## Le volume du bus `bus_name`, de 0 à 1 : 0 s'il est coupé ou s'il n'existe pas.
func volume(bus_name: StringName) -> float:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return Volume.to_linear(AudioServer.get_bus_volume_db(index))
