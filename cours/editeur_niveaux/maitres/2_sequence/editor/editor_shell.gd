class_name EditorShell
extends Control
#@ 1-5
## La coquille de l'éditeur de niveaux : la fenêtre, son titre et sa barre d'état. À cette étape, elle s'ouvre vide (F5)
## et dit qu'aucune salle n'est ouverte ; la salle, la vue et les panneaux s'y logeront aux étapes suivantes.
#@ 6+
## La coquille de l'éditeur de niveaux : la fenêtre, son titre, la vue de dessus et la barre d'état. Au démarrage, elle
## ouvre la salle de départ (`start_room`), vérifiée face au catalogue, et la cadre dans la vue ; on la parcourt à la
## souris (molette : zoom autour du curseur ; bouton du milieu : déplacer la vue).
#@ all

## Le texte de la barre d'état vient de changer.
signal status_changed(text: String)

## Ce que dit la barre d'état quand rien n'est ouvert.
const NOTHING_OPEN: String = "Aucune salle ouverte"
#@ 6+

## La salle ouverte au démarrage.
@export_file("*.tres") var start_room: String = ""
## Le catalogue des assets du jeu.
@export var catalog: AssetCatalogDef
## Les réglages de l'éditeur.
@export var settings: EditorSettingsDef

var _store: RoomStore = RoomStore.new()
var _document: RoomDocument = RoomDocument.new()
var _transform: ViewTransform = ViewTransform.new()
#@ all

@onready var _status: Label = $Layout/Status
#@ 6+
@onready var _view: RoomView = $Layout/Body/RoomView
@onready var _view_input: RoomViewInput = $Layout/Body/RoomViewInput
#@ all


func _ready() -> void:
#@ 1-5
	show_status(NOTHING_OPEN)
#@ 6+
	_transform.setup(settings)
	_view.setup(_document, catalog, _transform)
	_view_input.setup(_view, _transform, settings)
	_view.resized.connect(frame_room)
	if start_room.is_empty():
		show_status(NOTHING_OPEN)
	else:
		open_room(start_room)
#@ all


## Écrit `text` dans la barre d'état et le signale.
func show_status(text: String) -> void:
	_status.text = text
	status_changed.emit(text)


## Le texte affiché dans la barre d'état.
func status() -> String:
	return _status.text
#@ 6+


## Le document de la salle ouverte.
func document() -> RoomDocument:
	return _document


## Ouvre la salle `path` : elle doit être valide, et ne citer que des calques et des assets du catalogue.
func open_room(path: String) -> bool:
	var room: RoomData = _store.load_room(path)
	var errors: Array[String] = _store.errors.duplicate()
	if room != null:
		errors.append_array(catalog.room_errors(room))
	if not errors.is_empty() or not _document.open(room):
		errors.append_array(_document.errors)
		show_status("Ouverture impossible : " + "; ".join(errors))
		return false
	frame_room()
	show_status("%s : %d choses" % [room.display_name, room.thing_count()])
	return true


## Cadre la salle ouverte dans la vue (au démarrage, puis chaque fois que la vue change de taille).
func frame_room() -> void:
	var room: RoomData = _document.snapshot()
	if room != null and _view.size.x > 0.0 and _view.size.y > 0.0:
		_transform.frame(room.size_m, _view.size)
#@ all
