class_name DisclaimerDef
extends Resource
## L'écran d'avertissement (`5_data/jeu/avertissement.tres`) : son titre, son texte, la consigne pour le passer, et ses
## durées. On ne peut le passer qu'après un temps de lecture minimal ; s'il a une durée d'affichage, il passe seul
## au bout de ce temps.

## Identifiant de l'écran.
@export var id: StringName = &"avertissement"
## Le titre.
@export var title: String = ""
## Le texte de l'avertissement.
@export_multiline var body: String = ""
## La consigne qui apparaît quand on peut passer l'écran.
@export var hint: String = ""
## La durée d'une respiration de la consigne (de pleine à pâle), en secondes.
@export var hint_pulse_s: float = 0.0
## L'opacité la plus basse de la consigne pendant sa respiration.
@export var hint_low_alpha: float = 0.0
## La durée de l'apparition et de la disparition, en secondes.
@export var fade_s: float = 0.0
## Le temps de lecture minimal avant de pouvoir passer l'écran, en secondes.
@export var skip_after_s: float = 0.0
## Au bout de ce temps, l'écran passe seul, en secondes (0 : jamais).
@export var auto_next_s: float = 0.0
## L'écran qui suit (vide : l'enchaînement s'arrête là).
@export var next_screen: StringName = &""


## Les erreurs de la donnée, une par faute ; vide quand elle est juste.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("avertissement : id vide")
	if body.strip_edges().is_empty():
		errors.append("avertissement : texte vide")
	if hint.strip_edges().is_empty():
		errors.append("avertissement : consigne vide")
	if fade_s < 0.0 or skip_after_s < 0.0 or auto_next_s < 0.0:
		errors.append("avertissement : durée négative")
	if auto_next_s > 0.0 and auto_next_s < skip_after_s:
		errors.append("avertissement : il passerait seul avant qu'on puisse le passer")
	return errors
