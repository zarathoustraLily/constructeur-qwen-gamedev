extends Node
## Variables générales du jeu, en un seul endroit (singleton GameState).
## Celles que lisent les shaders sont recopiées dans leur paramètre global (project.godot,
#@ 6-10
## [shader_globals]) à chaque changement : un script règle GameState.player_position, et non
#@ 11+
## [shader_globals]) à chaque changement : un script règle GameState.rain_intensity, et non
#@ all
## RenderingServer directement.

## Position du kart du joueur (shaders : herbe qui s'écarte, eau).
var player_position := Vector3.ZERO:
	set(valeur):
		player_position = valeur
		RenderingServer.global_shader_parameter_set("player_position", valeur)
#@ 11+

## Force de la pluie, de 0 (rien) à 1 (averse) : anneaux d'impact sur la mer et la route.
var rain_intensity := 0.0:
	set(valeur):
		rain_intensity = valeur
		RenderingServer.global_shader_parameter_set("rain_intensity", valeur)

## Route mouillée, de 0 à 1 : suit la pluie avec retard.
var rain_wetness := 0.0:
	set(valeur):
		rain_wetness = valeur
		RenderingServer.global_shader_parameter_set("rain_wetness", valeur)
#@ all

## Vent (herbe, palmiers) : valeurs de départ lues dans project.godot.
var wind_direction: Vector3 = _reglage("wind_direction", Vector3(0.707, 0, 0.707)):
	set(valeur):
		wind_direction = valeur
		RenderingServer.global_shader_parameter_set("wind_direction", valeur)

## Force du vent (herbe, palmiers) ; valeur de départ lue dans project.godot.
var wind_strength: float = _reglage("wind_strength", 2.0):
	set(valeur):
		wind_strength = valeur
		RenderingServer.global_shader_parameter_set("wind_strength", valeur)


func _reglage(nom: String, defaut: Variant) -> Variant:
	var reglage: Variant = ProjectSettings.get_setting("shader_globals/" + nom)
	return reglage["value"] if reglage is Dictionary and reglage.has("value") else defaut
