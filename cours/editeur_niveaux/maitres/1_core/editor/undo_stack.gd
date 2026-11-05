class_name UndoStack
extends RefCounted
## L'historique d'une salle : une suite d'instantanés (`RoomData`), et un curseur sur l'état courant.
## Un instantané de salle coûte peu : ses tableaux compacts se copient à l'écriture. Tant qu'une colonne n'a pas changé,
## l'instantané et la salle partagent le même bloc de mémoire ; seule la colonne modifiée (les positions, pour un
## déplacement) est recopiée. Chaque instantané porte un numéro de révision : le document s'en sert pour savoir si
## l'état courant est celui qu'on a enregistré.

## Le nombre d'instantanés gardés au plus ; au-delà, les plus anciens sont oubliés.
const MAX_STATES: int = 200

var _states: Array[RoomData] = []
var _revisions: Array[int] = []
var _cursor: int = -1
var _next_revision: int = 0


## Repart de l'état `initial` : l'historique ne contient plus que lui.
func reset(initial: RoomData) -> void:
	_states = [initial.duplicate(true) as RoomData]
	_revisions = [_new_revision()]
	_cursor = 0


## Une copie de l'état courant, ou null si l'historique est vide.
func current() -> RoomData:
	return null if _cursor < 0 else _states[_cursor].duplicate(true) as RoomData


## Le numéro de révision de l'état courant (-1 si l'historique est vide).
func revision() -> int:
	return -1 if _cursor < 0 else _revisions[_cursor]


## Ajoute `state` après l'état courant ; les états qu'on avait annulés sont oubliés.
func push(state: RoomData) -> void:
	if _cursor < 0:
		reset(state)
		return
	_states.resize(_cursor + 1)
	_revisions.resize(_cursor + 1)
	_states.append(state.duplicate(true) as RoomData)
	_revisions.append(_new_revision())
	_cursor += 1
	while _states.size() > MAX_STATES:
		_states.remove_at(0)
		_revisions.remove_at(0)
		_cursor -= 1


## Vrai s'il reste un état avant le courant.
func can_undo() -> bool:
	return _cursor > 0


## Vrai s'il reste un état annulé après le courant.
func can_redo() -> bool:
	return _cursor >= 0 and _cursor + 1 < _states.size()


## Revient à l'état précédent ; rend sa copie (l'état courant si rien n'est à annuler).
func undo() -> RoomData:
	if can_undo():
		_cursor -= 1
	return current()


## Refait l'état suivant ; rend sa copie (l'état courant si rien n'est à refaire).
func redo() -> RoomData:
	if can_redo():
		_cursor += 1
	return current()


func _new_revision() -> int:
	_next_revision += 1
	return _next_revision
