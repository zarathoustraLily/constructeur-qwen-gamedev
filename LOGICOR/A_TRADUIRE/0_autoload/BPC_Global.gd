extends Node
## BPC_Global.gd
## Autoload unique : état global de la partie, signaux partagés, navigation.

# État de la partie
var partie_en_cours: bool = false
var niveau_courant: int = 1
var numero_salle: int = 1
var argent: int = 0
var profondeur: int = 0

# Signaux
signal partie_demarree()
signal partie_terminee(victoire: bool)
signal niveau_change(nouveau_niveau: int)
signal salle_change(nouvelle_salle: int)
signal argent_change(nouvelle_valeur: int)
signal heros_mort()


## Démarrer une nouvelle partie.
func demarrer_partie() -> void:
	partie_en_cours = true
	niveau_courant = 1
	numero_salle = 1
	argent = 0
	profondeur = 0
	partie_demarree.emit()


## Terminer la partie.
func terminer_partie(victoire: bool) -> void:
	partie_en_cours = false
	partie_terminee.emit(victoire)


## Passer au niveau suivant.
func niveau_suivant() -> void:
	niveau_courant += 1
	numero_salle = 1
	profondeur += 1
	niveau_change.emit(niveau_courant)


## Passer à la salle suivante.
func salle_suivant() -> void:
	numero_salle += 1
	salle_change.emit(numero_salle)


## Ajouter de l'argent.
func ajouter_argent(montant: int) -> void:
	argent += montant
	argent_change.emit(argent)


## Dépenser de l'argent.
func depenser_argent(montant: int) -> bool:
	if argent < montant:
		return false
	argent -= montant
	argent_change.emit(argent)
	return true
