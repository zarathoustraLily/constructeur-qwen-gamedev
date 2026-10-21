extends State
## État témoin pour les tests de la machine à états : il note chaque appel reçu.

## Appels reçus, dans l'ordre : « enter <état quitté> », « exit », « physics ».
var calls: Array[String] = []


func enter(previous_state: StringName) -> void:
	calls.append("enter " + previous_state)


func exit() -> void:
	calls.append("exit")


func physics_update(_delta: float) -> void:
	calls.append("physics")
