class_name Connections extends RefCounted
## Brancher et débrancher des signaux sans doublon ni oubli : un même branchement fait deux fois appelle deux fois
## (ou lève une erreur) ; un branchement oublié garde en vie ce qu'il vise et l'appelle après coup.


## Branche `callable` sur `sig` s'il ne l'est pas déjà ; rend vrai si un branchement a été fait.
static func connect_once(sig: Signal, callable: Callable) -> bool:
	if sig.is_connected(callable):
		return false
	sig.connect(callable)
	return true


## Débranche tout ce qui est branché sur `sig` ; rend le nombre de branchements retirés.
static func disconnect_all(sig: Signal) -> int:
	var count: int = 0
	for connection: Dictionary in sig.get_connections():
		sig.disconnect(connection["callable"])
		count += 1
	return count
