class_name StudioDef
extends Resource
## L'écran du studio (`5_data/jeu/studio.tres`) : le nom de la boîte, les durées de son apparition, de sa tenue et de
## sa disparition, et ce qu'on charge en fond pendant qu'il s'affiche. L'écran reste tant que la tenue minimale n'est
## pas finie ET que le chargement n'est pas fini : un chargement lent allonge la tenue, jamais l'inverse.

## Identifiant de l'écran.
@export var id: StringName = &"studio"
## Le nom de la boîte, affiché sous la marque.
@export var studio_name: String = ""
## La durée de l'apparition, en secondes.
@export var fade_in_s: float = 0.0
## La tenue minimale, en secondes, une fois l'apparition finie.
@export var min_hold_s: float = 0.0
## La durée de la disparition, en secondes.
@export var fade_out_s: float = 0.0
## Les ressources à charger en fond pendant l'écran.
@export var preload_paths: Array[String] = []
## L'écran qui suit (vide : l'enchaînement s'arrête là).
@export var next_screen: StringName = &""


## Les erreurs de la donnée, une par faute ; vide quand elle est juste.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("studio : id vide")
	if studio_name.strip_edges().is_empty():
		errors.append("studio : nom de la boîte vide")
	if fade_in_s < 0.0 or min_hold_s < 0.0 or fade_out_s < 0.0:
		errors.append("studio : durée négative")
	for path: String in preload_paths:
		if not ResourceLoader.exists(path):
			errors.append("studio : ressource à charger introuvable (%s)" % path)
	return errors
