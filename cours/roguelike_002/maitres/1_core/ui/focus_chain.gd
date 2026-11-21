class_name FocusChain extends RefCounted
## Enchaîne le focus d'une colonne de contrôles : chacun nomme son voisin du dessous et du dessus, le dernier menant au
## premier. Godot n'a plus à chercher le voisin d'après la place à l'écran, qu'un conteneur ne calcule qu'à l'image
## suivante (sans cela, la flèche du bas ne bouge pas le focus juste après la construction d'une liste).


## Enchaîne `controls` de haut en bas, en boucle.
static func link_column(controls: Array[Control]) -> void:
	var count: int = controls.size()
	for i: int in count:
		var control: Control = controls[i]
		var below: Control = controls[(i + 1) % count]
		var above: Control = controls[(i + count - 1) % count]
		control.focus_neighbor_bottom = control.get_path_to(below)
		control.focus_neighbor_top = control.get_path_to(above)
		control.focus_next = control.focus_neighbor_bottom
		control.focus_previous = control.focus_neighbor_top
