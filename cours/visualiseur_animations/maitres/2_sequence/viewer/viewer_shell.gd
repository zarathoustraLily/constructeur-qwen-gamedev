class_name ViewerShell extends Control
## La coquille du visualiseur d'animations : elle lit les réglages, cherche les assets et les range dans la liste, par
## catégorie. La barre d'état dit ce qu'on a trouvé, ou le premier problème rencontré.
#@ 2+
## Choisir un asset le montre dans la scène et liste ses animations ; choisir une animation la joue.
#@ 3+
## La caméra tourne autour de l'asset (souris, stick droit) ou prend la vue du jeu (bouton, Y, G) ; un clip fait pour
## un angle passe à la variante de l'angle de la caméra. La barre d'état dit l'angle et la vue.
#@ all
## Les réglages : `5_data/visualiseur/config.json` dans le projet ; un visualiseur exporté lit le `config.json` posé à
## côté de son exécutable, s'il y en a un.

## Le texte de la barre d'état vient de changer.
signal status_changed(text: String)

## Les réglages du projet.
const CONFIG_PATH: String = "res://5_data/visualiseur/config.json"
## Le nom des réglages posés à côté d'un visualiseur exporté.
const EXPORTED_CONFIG: String = "config.json"

## Le fichier de réglages à lire ; un test donne le sien.
@export var config_path: String = CONFIG_PATH
#@ 2+
## Vrai pour avancer la lecture à la main (les tests).
@export var manual: bool = false
#@ all

@onready var _list: AssetList = %AssetList
@onready var _status: Label = %Status
#@ 2+
@onready var _stage: ViewerStage = %ViewerStage
@onready var _clips: ClipList = %ClipList
#@ 3+
@onready var _orbit: OrbitInput = %OrbitInput
@onready var _game_view_button: Button = %GameViewButton
@onready var _stage_container: SubViewportContainer = %StageContainer
#@ all

var _config: ViewerConfig
var _entries: Array[AssetEntry] = []
var _problems: Array[String] = []
#@ 2+
var _shown: AssetEntry
var _error: String = ""
#@ all


func _ready() -> void:
#@ 2+
	_stage.set_manual(manual)
	_list.asset_chosen.connect(show_asset)
	_clips.clip_chosen.connect(play_clip)
#@ 3+
	_orbit.rig_changed.connect(_on_rig_changed)
	_game_view_button.pressed.connect(_orbit.toggle_game_view)
	_stage_container.gui_input.connect(_on_stage_input)
#@ all
	_config = ViewerConfig.load_file(_resolved_config_path())
	var scanner: AssetScanner = AssetScanner.scan(_config.sources)
	_entries = scanner.entries
	_problems.assign(_config.errors)
	_problems.append_array(scanner.errors)
#@ 3+
	_orbit.rig.use_config(_config)
#@ all
	_list.show_entries(_entries)
	_update_status()


## Le texte de la barre d'état.
func status() -> String:
	return _status.text


## Les assets trouvés, dans l'ordre de la liste.
func entries() -> Array[AssetEntry]:
	return _entries


## La liste des assets.
func asset_list() -> AssetList:
	return _list
#@ 2+


## Montre l'asset `entry` et liste ses animations ; une erreur de chargement va dans la barre d'état.
func show_asset(entry: AssetEntry) -> void:
	_shown = entry
	_error = _stage.show_entry(entry, _config)
#@ 3+
	if _error.is_empty():
		_orbit.rig.frame(_stage.subject_bounds())
		_on_rig_changed()
#@ 2+
	_refresh_clips()
	_update_status()


## Choisit l'asset `id` dans la liste, comme un clic ; faux s'il n'y est pas.
func choose_asset(id: String) -> bool:
	return _list.choose(id)


## Joue l'animation `clip` de l'asset montré ; faux s'il n'en a pas de ce nom.
func play_clip(clip: String) -> bool:
	var subject: Subject = _stage.subject()
#@ 2
	if subject == null or not subject.play(clip):
#@ 3+
	if subject == null or not subject.play_base(clip):
#@ 2+
		return false
	_update_status()
	return true


## La scène de l'asset.
func stage() -> ViewerStage:
	return _stage


## La liste des animations.
func clip_list() -> ClipList:
	return _clips
#@ 3+


## Les commandes de la caméra.
func orbit() -> OrbitInput:
	return _orbit
#@ all


func _resolved_config_path() -> String:
	if OS.has_feature("template"):
		var beside: String = OS.get_executable_path().get_base_dir().path_join(EXPORTED_CONFIG)
		if FileAccess.file_exists(beside):
			return beside
	return config_path
#@ 2+


func _refresh_clips() -> void:
	var subject: Subject = _stage.subject()
	var names: Array[String] = []
	var labels: Array[String] = []
	if subject != null:
#@ 2
		names = subject.clips()
#@ 3+
		# Une ligne par nom de base : salut_angle_0 … salut_angle_270 font une ligne « salut · 4 angles ».
		names = AngleClips.bases(subject.clips())
		for base: String in names:
			var count: int = AngleClips.angles(subject.clips(), base).size()
			labels.append(base if count == 0 else "%s · %d angles" % [base, count])
#@ 2+
	_clips.show_clips(names, labels, _current_clip_name())


func _current_clip_name() -> String:
	var subject: Subject = _stage.subject()
	if subject == null:
		return ""
#@ 2
	return subject.current_clip()
#@ 3+
	return subject.current_base()
#@ all


func _update_status() -> void:
	var text: String = "%d asset%s" % [_entries.size(), "s" if _entries.size() > 1 else ""]
#@ 2+
	if _shown != null:
		if not _error.is_empty():
			text = "%s : %s" % [_shown.id, _error]
		else:
			var subject: Subject = _stage.subject()
			var count: int = subject.clips().size()
			text = "%s · %d animation%s · %s" % [_shown.id, count, "s" if count > 1 else "", subject.current_clip()]
#@ 3+
			text += " · angle %d° · %s" % [roundi(_orbit.rig.view_yaw()), "vue du jeu" if _orbit.rig.game_view
					else "vue libre"]
#@ all
	if not _problems.is_empty():
		text += " · %d problème%s : %s" % [_problems.size(), "s" if _problems.size() > 1 else "", _problems[0]]
	_status.text = text
	status_changed.emit(text)
#@ 3+


func _on_rig_changed() -> void:
	_orbit.rig.apply(_stage.camera())
	_game_view_button.set_pressed_no_signal(_orbit.rig.game_view)
	var subject: Subject = _stage.subject()
	if subject != null:
		var before: String = subject.current_clip()
		subject.set_view_angle(_orbit.rig.view_yaw())
		if subject.current_clip() != before:
			_clips.mark(subject.current_base())
	_update_status()


func _on_stage_input(event: InputEvent) -> void:
	if _orbit.handle(event):
		accept_event()
#@ all
