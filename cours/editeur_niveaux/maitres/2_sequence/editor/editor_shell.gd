class_name EditorShell
extends Control
## La coquille de l'éditeur de niveaux : la fenêtre, son titre et sa barre d'état. À cette étape, elle s'ouvre vide (F5)
## et dit qu'aucune salle n'est ouverte ; la salle, la vue et les panneaux s'y logeront aux étapes suivantes.

## Le texte de la barre d'état vient de changer.
signal status_changed(text: String)

## Ce que dit la barre d'état quand rien n'est ouvert.
const NOTHING_OPEN: String = "Aucune salle ouverte"

@onready var _status: Label = $Layout/Status


func _ready() -> void:
	show_status(NOTHING_OPEN)


## Écrit `text` dans la barre d'état et le signale.
func show_status(text: String) -> void:
	_status.text = text
	status_changed.emit(text)


## Le texte affiché dans la barre d'état.
func status() -> String:
	return _status.text
