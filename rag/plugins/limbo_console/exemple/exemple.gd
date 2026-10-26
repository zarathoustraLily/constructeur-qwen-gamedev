extends Node
## Exemple minimal de Limbo Console (v0.8.0, GDScript) : déclarer une commande de développement (« degats 5 »),
## puis l'exécuter comme si on la tapait dans la console du jeu.

var _sante: int = 20


func _ready() -> void:
	# Le nom et le type des arguments viennent de la signature de la méthode : « degats 5 » donne montant = 5.
	LimboConsole.register_command(_degats, "degats", "retire des points de vie au joueur")
	LimboConsole.execute_command("degats 5")
	if LimboConsole.has_command("degats") and _sante == 15:
		print("EXEMPLE VERIFIE : commande « degats 5 » exécutée, santé %d" % _sante)
	else:
		push_error("commande présente : %s, santé %d" % [LimboConsole.has_command("degats"), _sante])
	get_tree().quit()


func _degats(montant: int) -> void:
	_sante -= montant
