class_name MenuDef
extends Resource
## Le menu principal (`5_data/jeu/menu.tres`) : le titre, les choix et l'écran où mène chacun, puis tout le
## mouvement (le motion design) : quand et comment le titre et les choix entrent, comment le fond glisse et la
## planète flotte, comment un choix se met en avant, comment l'écran part. Régler le mouvement, c'est changer ces
## valeurs, sans toucher au code.

## Identifiant du menu.
@export var id: StringName = &"menu"
## Le titre du jeu.
@export var game_title: String = ""
## Les choix, dans l'ordre de l'écran.
@export var items: Array[StringName] = []
## Le texte de chaque choix.
@export var labels: Dictionary[StringName, String] = {}
## L'écran où mène chaque choix (absent ou vide : pas encore disponible).
@export var targets: Dictionary[StringName, StringName] = {}
## Le choix qui quitte le jeu.
@export var quit_item: StringName = &""

@export_group("Mise en page")
## La taille du titre, en points.
@export var title_font_size: int = 0
## La hauteur du titre à l'arrivée, en pixels depuis le haut.
@export var title_y_px: float = 0.0
## La taille d'un choix, en pixels.
@export var item_size_px: Vector2 = Vector2.ZERO
## La taille du texte d'un choix, en points.
@export var item_font_size: int = 0
## La place du premier choix à l'arrivée (coin haut gauche), en pixels.
@export var items_origin_px: Vector2 = Vector2.ZERO
## L'écart vertical entre deux choix, en pixels.
@export var item_spacing_px: float = 0.0
## La place de la planète (coin haut gauche) et sa taille, en pixels.
@export var planet_rect_px: Rect2 = Rect2()

@export_group("Entrée")
## Le moment où le titre commence à entrer, en secondes.
@export var title_delay_s: float = 0.0
## La durée de l'entrée du titre, en secondes.
@export var title_in_s: float = 0.0
## La hauteur d'où le titre tombe, en pixels au-dessus de sa place.
@export var title_drop_px: float = 0.0
## Le moment où le premier choix commence à entrer, en secondes.
@export var items_delay_s: float = 0.0
## La durée de l'entrée d'un choix, en secondes.
@export var item_in_s: float = 0.0
## Le décalage entre l'entrée de deux choix, en secondes.
@export var item_stagger_s: float = 0.0
## La distance d'où un choix arrive, en pixels à droite de sa place.
@export var item_slide_px: float = 0.0

@export_group("Fond et planète")
## La vitesse du glissement du fond, en pixels par seconde.
@export var background_speed_px_s: float = 0.0
## La course du fond : il glisse de 0 à cette distance, puis revient, en pixels.
@export var background_travel_px: float = 0.0
## L'amplitude du flottement de la planète, en pixels.
@export var planet_bob_px: float = 0.0
## La durée d'un flottement complet de la planète, en secondes.
@export var planet_period_s: float = 0.0

@export_group("Choix et départ")
## L'agrandissement du choix mis en avant.
@export var focus_scale: float = 1.0
## La durée de la mise en avant, en secondes.
@export var focus_s: float = 0.0
## Le point fixe de l'agrandissement d'un choix, en fraction de sa taille ((0,5 ; 0,5) : son centre).
@export var focus_pivot: Vector2 = Vector2.ZERO
## Le décalage du choix mis en avant, en pixels vers la droite.
@export var focus_shift_px: float = 0.0
## La durée du tremblement d'un choix pas encore disponible, en secondes.
@export var refuse_s: float = 0.0
## L'amplitude de ce tremblement, en pixels.
@export var refuse_px: float = 0.0
## Le nombre d'allers-retours de ce tremblement.
@export var refuse_shakes: int = 0
## La durée du départ de l'écran, en secondes.
@export var leave_s: float = 0.0


## La durée de toute l'entrée : quand le dernier choix est arrivé et le titre aussi, en secondes.
func intro_s() -> float:
	var last_item: float = items_delay_s + item_stagger_s * maxi(items.size() - 1, 0) + item_in_s
	return maxf(title_delay_s + title_in_s, last_item)


## Les erreurs de la donnée, une par faute ; vide quand elle est juste.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id == &"":
		errors.append("menu : id vide")
	if game_title.strip_edges().is_empty():
		errors.append("menu : titre vide")
	if items.is_empty():
		errors.append("menu : aucun choix")
	for item: StringName in items:
		if labels.get(item, "").strip_edges().is_empty():
			errors.append("menu : choix « %s » sans texte" % item)
	if quit_item != &"" and not items.has(quit_item):
		errors.append("menu : le choix qui quitte (« %s ») n'est pas dans les choix" % quit_item)
	for duration: float in [title_delay_s, title_in_s, items_delay_s, item_in_s, item_stagger_s, focus_s, refuse_s,
			leave_s]:
		if duration < 0.0:
			errors.append("menu : durée négative")
			break
	if planet_period_s <= 0.0:
		errors.append("menu : période de la planète nulle")
	if focus_scale < 1.0:
		errors.append("menu : un choix mis en avant ne rapetisse pas")
	return errors
