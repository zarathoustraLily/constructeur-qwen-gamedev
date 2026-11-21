class_name OptionsDef
extends Resource
## Les options du jeu (`5_data/jeu/options.tres`) : les difficultés, les définitions d'écran, les volumes (un par bus
## audio), leurs valeurs par défaut, le fichier où on les enregistre, et les textes de l'écran des options. Ajouter
## une difficulté ou une définition, c'est ajouter une ligne ici.

## Identifiant des options.
@export var id: StringName = &"options"
## Le titre de l'écran.
@export var title: String = ""
## Le fichier où les options sont enregistrées.
@export var file_path: String = ""
## L'écran où l'on revient en quittant les options.
@export var back_screen: StringName = &""

@export_group("Difficulté")
## Les difficultés, de la plus facile à la plus dure.
@export var difficulties: Array[StringName] = []
## Le texte de chaque difficulté.
@export var difficulty_labels: Dictionary[StringName, String] = {}
## La difficulté par défaut.
@export var default_difficulty: StringName = &""

@export_group("Écran")
## Les définitions d'écran proposées, en pixels.
@export var resolutions: Array[Vector2i] = []
## La définition par défaut.
@export var default_resolution: Vector2i = Vector2i.ZERO
## Le plein écran par défaut.
@export var default_fullscreen: bool = false

@export_group("Son")
## Les bus audio réglables, dans l'ordre de l'écran.
@export var volume_buses: Array[StringName] = []
## Le volume par défaut de chaque bus, de 0 à 1.
@export var default_volume: float = 1.0
## Le pas d'un réglage de volume, de 0 à 1.
@export var volume_step: float = 0.0

@export_group("Textes")
## Le texte de chaque ligne : &"difficulte", &"definition", &"plein_ecran", un par bus, &"retour".
@export var row_labels: Dictionary[StringName, String] = {}
## Le mot du plein écran activé.
@export var on_label: String = ""
## Le mot du plein écran désactivé.
@export var off_label: String = ""
## Le caractère d'un cran de volume plein.
@export var volume_full_mark: String = ""
## Le caractère d'un cran de volume vide.
@export var volume_empty_mark: String = ""


## Les erreurs de la donnée, une par faute ; vide quand elle est juste.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("options : id vide")
	if not file_path.begins_with("user://"):
		errors.append("options : le fichier doit être dans user://")
	if difficulties.is_empty() or not difficulties.has(default_difficulty):
		errors.append("options : difficulté par défaut absente des difficultés")
	for difficulty: StringName in difficulties:
		if difficulty_labels.get(difficulty, "").is_empty():
			errors.append("options : difficulté « %s » sans texte" % difficulty)
	if resolutions.is_empty() or not resolutions.has(default_resolution):
		errors.append("options : définition par défaut absente des définitions")
	if volume_step <= 0.0 or volume_step > 1.0:
		errors.append("options : pas de volume hors de ]0, 1]")
	if default_volume < 0.0 or default_volume > 1.0:
		errors.append("options : volume par défaut hors de [0, 1]")
	for row: StringName in rows():
		if row_labels.get(row, "").is_empty():
			errors.append("options : ligne « %s » sans texte" % row)
	if on_label.is_empty() or off_label.is_empty() or volume_full_mark.is_empty() or volume_empty_mark.is_empty():
		errors.append("options : mot du plein écran ou cran de volume vide")
	return errors


## Les lignes de l'écran, dans l'ordre : difficulté, définition, plein écran, un volume par bus, retour.
func rows() -> Array[StringName]:
	var all: Array[StringName] = [&"difficulte", &"definition", &"plein_ecran"]
	all.append_array(volume_buses)
	all.append(&"retour")
	return all
