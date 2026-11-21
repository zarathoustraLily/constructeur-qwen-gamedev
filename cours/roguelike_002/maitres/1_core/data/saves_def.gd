class_name SavesDef
extends Resource
## Les sauvegardes (`5_data/jeu/sauvegardes.tres`) : combien d'emplacements, où et sous quel nom on les écrit, la
## version du format, la salle d'une partie neuve, les écrans d'où l'on vient et où l'on va, et les textes de l'écran
## des sauvegardes.

## Identifiant des sauvegardes.
@export var id: StringName = &"sauvegardes"
## Le titre de l'écran.
@export var title: String = ""
## Le nombre d'emplacements.
@export var slot_count: int = 0
## Le dossier des sauvegardes.
@export var directory: String = ""
## Le nom du fichier d'un emplacement ; `%d` devient son numéro (à partir de 1).
@export var file_pattern: String = ""
## La version du format : un fichier d'une autre version n'est pas chargé.
@export var version: int = 0
## La salle où commence une partie neuve.
@export var start_room: String = ""
## L'écran d'où l'on vient (B y revient).
@export var back_screen: StringName = &""
## L'écran où mène une partie lancée (neuve ou continuée).
@export var start_screen: StringName = &""

@export_group("Textes")
## Le nom d'un emplacement ; `%d` devient son numéro.
@export var slot_label: String = ""
## Ce que montre un emplacement libre.
@export var empty_label: String = ""
## Ce que montre un emplacement illisible.
@export var unreadable_label: String = ""
## Ce que montre un emplacement d'une autre version.
@export var other_version_label: String = ""
## Le résumé d'une sauvegarde ; reçoit la salle et la date.
@export var summary_format: String = ""
## Le texte de chaque action : &"continuer", &"effacer", &"retour".
@export var action_labels: Dictionary[StringName, String] = {}
## La question avant d'effacer.
@export var confirm_text: String = ""
## Le mot qui confirme l'effacement.
@export var yes_label: String = ""
## Le mot qui l'annule.
@export var no_label: String = ""


## Les erreurs de la donnée, une par faute ; vide quand elle est juste.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("sauvegardes : id vide")
	if slot_count < 1:
		errors.append("sauvegardes : aucun emplacement")
	if not directory.begins_with("user://"):
		errors.append("sauvegardes : le dossier doit être dans user://")
	if not file_pattern.contains("%d") or not slot_label.contains("%d"):
		errors.append("sauvegardes : nom de fichier ou d'emplacement sans numéro (%d)")
	if version < 1:
		errors.append("sauvegardes : version absente")
	for action: StringName in [&"continuer", &"effacer", &"retour"]:
		if action_labels.get(action, "").is_empty():
			errors.append("sauvegardes : action « %s » sans texte" % action)
	if confirm_text.is_empty() or yes_label.is_empty() or no_label.is_empty():
		errors.append("sauvegardes : confirmation sans texte")
	return errors
