class_name MenuFocus extends RefCounted
## Navigation au clavier et à la manette dans une liste verticale de contrôles : chaque contrôle connaît son
## voisin du dessus et du dessous (croix, stick, flèches), et le focus peut boucler du dernier au premier.


## Relie les contrôles `controls`, dans l'ordre, de haut en bas ; avec `loop`, le dernier mène au premier et
## inversement. Les contrôles doivent être dans l'arbre : un voisin est un chemin de nœud.
static func chain(controls: Array[Control], loop: bool) -> void:
	var count: int = controls.size()
	for i: int in count:
		var current: Control = controls[i]
		var above: int = neighbor_index(count, i, -1, loop)
		var below: int = neighbor_index(count, i, 1, loop)
		current.focus_neighbor_top = current.get_path_to(controls[above]) if above >= 0 else NodePath()
		current.focus_neighbor_bottom = current.get_path_to(controls[below]) if below >= 0 else NodePath()
		current.focus_previous = current.focus_neighbor_top
		current.focus_next = current.focus_neighbor_bottom


## L'index du voisin de `index` à `step` cases (-1 au-dessus, 1 en dessous) dans une liste de `count`
## contrôles : avec `loop`, la liste boucle ; sans, -1 quand on en sort.
static func neighbor_index(count: int, index: int, step: int, loop: bool) -> int:
	var target: int = index + step
	if loop:
		return posmod(target, count)
	return target if target >= 0 and target < count else -1


## Le premier des contrôles `controls` qui peut prendre le focus (can_focus) ; null s'il n'y en a aucun.
static func first_focusable(controls: Array[Control]) -> Control:
	for control: Control in controls:
		if can_focus(control):
			return control
	return null


## Vrai si `control` peut prendre le focus : visible dans l'arbre, focus permis, et pas un bouton désactivé.
static func can_focus(control: Control) -> bool:
	if not control.is_visible_in_tree() or control.focus_mode == Control.FOCUS_NONE:
		return false
	var button: BaseButton = control as BaseButton
	return button == null or not button.disabled
