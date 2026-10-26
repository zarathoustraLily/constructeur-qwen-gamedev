# Réglages sauvegardés d'une partie à l'autre (ConfigFile, user://)

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier reglages_sauvegardes`.

## Ce que fait le morceau

Les réglages du joueur (volume, sensibilité) s'écrivent dans un fichier `ConfigFile` de `user://` et se relisent au lancement. Un fichier absent ou abîmé laisse les valeurs par défaut, et le code d'erreur dit pourquoi.

## Quand l'employer

Options du jeu, touches redéfinies, dernier niveau atteint, meilleurs scores.

Dans un projet qui suit le plan : l'outil de lecture et d'écriture dans `1_core/save/` ; un service de `0_autoload/` (comme `audio_manager` pour le volume) l'emploie au démarrage et à chaque changement.

## Le code (`1_core/save/settings_store.gd`, vérifié)

```gdscript
class_name SettingsStore
extends RefCounted
## Réglages du joueur (volume, sensibilité) gardés dans un fichier ConfigFile, d'une partie à l'autre. Un fichier
## absent ou illisible redonne les valeurs par défaut. Entrées : load_from(), save_to().

const SECTION := "reglages"

var music_volume: float = 1.0
var sensitivity: float = 1.0


## Lit le fichier ; rend le code d'erreur de ConfigFile.load (OK, ERR_FILE_NOT_FOUND, ERR_PARSE_ERROR…). En cas
## d'erreur, les valeurs par défaut restent.
func load_from(path: String) -> Error:
	var file := ConfigFile.new()
	var error := file.load(path)
	if error != OK:
		return error
	music_volume = file.get_value(SECTION, "music_volume", music_volume)
	sensitivity = file.get_value(SECTION, "sensitivity", sensitivity)
	return OK


func save_to(path: String) -> Error:
	var file := ConfigFile.new()
	file.set_value(SECTION, "music_volume", music_volume)
	file.set_value(SECTION, "sensitivity", sensitivity)
	return file.save(path)
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : enregistré puis relu (volume 0.35, sensibilité 1.80) ; fichier absent : File not found, défauts gardés ; fichier abîmé : Parse error, défauts gardés.

## Pièges

- Fichier absent : `ConfigFile.load` rend `ERR_FILE_NOT_FOUND` (mesuré) ; c'est le cas normal au premier lancement, pas une panne.
- Fichier abîmé : la lecture rend `ERR_PARSE_ERROR` et les valeurs par défaut restent (mesuré) ; le moteur écrit aussi une ligne « ERROR: ConfigFile parse error at … » dans la sortie (mesuré). Ne jamais écraser les réglages par des valeurs à moitié lues.
- `res://` est en lecture seule une fois le jeu exporté : les sauvegardes vont dans `user://` (godot-docs, « File paths in Godot projects » ; non mesuré ici).
