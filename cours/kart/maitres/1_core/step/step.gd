class_name Step extends Node
## Contrat d'une étape du déroulé (menu, cinématique, niveau) : la scène racine de chaque étape
## listée dans 2_sequence/sequence.tres porte ce script, ou un script qui en hérite.
## Quand l'étape a fini, elle appelle terminer() ; pour être rejouée depuis le début, rejouer().
## Elle ne charge jamais une autre scène : le chef d'orchestre (0_autoload/game_flow.gd) écoute
## ses signaux et fait la transition.

## Émis quand l'étape est finie : le déroulé passe à l'étape suivante.
signal terminee
## Émis quand l'étape doit être rejouée depuis le début (le joueur a perdu, par exemple).
signal a_rejouer


## Signale la fin de l'étape.
func terminer() -> void:
	terminee.emit()


## Demande à rejouer l'étape depuis le début.
func rejouer() -> void:
	a_rejouer.emit()
