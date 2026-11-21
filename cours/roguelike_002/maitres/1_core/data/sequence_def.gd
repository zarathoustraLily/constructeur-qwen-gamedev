class_name SequenceDef
extends Resource
## L'enchaînement des écrans (`5_data/jeu/sequence.tres`) : chaque écran a un nom et une scène ; le premier ouvre le
## jeu, et chaque écran dit, quand il a fini, le nom du suivant. Ajouter un écran, c'est ajouter une ligne ici.

## Identifiant de l'enchaînement.
@export var id: StringName = &"sequence"
## Le nom du premier écran (vide : la coquille s'ouvre sans écran).
@export var first_screen: StringName = &""
## Les écrans : nom → chemin de leur scène.
@export var screens: Dictionary[StringName, String] = {}
## La graine du hasard de la partie.
@export var rng_seed: int = 0


## Les erreurs de la donnée, une par faute ; vide quand elle est juste.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("sequence : id vide")
	if first_screen != &"" and not screens.has(first_screen):
		errors.append("sequence : premier écran « %s » absent des écrans" % first_screen)
	for screen: StringName in screens:
		if not ResourceLoader.exists(screens[screen]):
			errors.append("sequence : écran « %s », scène introuvable (%s)" % [screen, screens[screen]])
	return errors
