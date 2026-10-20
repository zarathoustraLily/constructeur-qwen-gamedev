extends Node
## Chef d'orchestre (singleton GameFlow) : enchaîne les étapes de 2_sequence/sequence.tres,
## dans l'ordre (menus, cinématiques, niveaux). Après la dernière étape, on revient à la première.
## Aucune étape ne change de scène elle-même : elle respecte le contrat Step (1_core/step/step.gd)
## et émet « terminee » ou « a_rejouer », que GameFlow écoute. L'interface superposée (pause)
## peut appeler quitter().

## La séquence jouée ; les tests la remplacent par une séquence de leur choix.
var sequence: Sequence = preload("res://2_sequence/sequence.tres")


func _ready() -> void:
	get_tree().scene_changed.connect(_ecouter_etape)
	# La première scène est ajoutée après les singletons : on l'écoute à la fin de l'image.
	_ecouter_etape.call_deferred()


## Branche GameFlow sur les signaux de l'étape en cours, si la scène courante est une étape.
func _ecouter_etape() -> void:
	var etape := get_tree().current_scene as Step
	if etape == null or etape.terminee.is_connected(etape_suivante):
		return
	etape.terminee.connect(etape_suivante)
	etape.a_rejouer.connect(recommencer)


## Rang de l'étape en cours dans la séquence, ou -1 si la scène lancée n'en fait pas partie
## (une scène ouverte seule depuis l'éditeur, par exemple).
func etape_courante() -> int:
	var scene := get_tree().current_scene
	return sequence.etapes.find(scene.scene_file_path) if scene else -1


## Chemin de l'étape qui suit `chemin` ; après la dernière, la première.
## Une scène hors séquence est suivie de la première étape.
func etape_apres(chemin: String) -> String:
	var rang := sequence.etapes.find(chemin)
	return sequence.etapes[(rang + 1) % sequence.etapes.size()]


## Passe à l'étape suivante ; après la dernière, revient à la première.
func etape_suivante() -> void:
	if sequence.etapes.is_empty():
		return
	var scene := get_tree().current_scene
	get_tree().change_scene_to_file(etape_apres(scene.scene_file_path if scene else ""))


## Relance l'étape en cours depuis le début.
func recommencer() -> void:
	get_tree().reload_current_scene()


## Quitte le jeu.
func quitter() -> void:
	get_tree().quit()
