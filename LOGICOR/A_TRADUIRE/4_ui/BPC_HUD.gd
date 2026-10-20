extends CanvasLayer
## BPC_HUD.gd
## L'interface : barres PV, souffle, notifications.

@export var heros: Node

@onready var barre_vie: ProgressBar = $Vie/BarreVie
@onready var barre_souffle: ProgressBar = $Souffle/BarreSouffle
@onready var label_vie: Label = $Vie/LabelVie


func _ready() -> void:
	if heros and heros.stats:
		var fiche: FicheHeros = heros.stats.fiche
		barre_vie.max_value = fiche.vie_max if fiche else 30
		barre_vie.value = barre_vie.max_value
		barre_souffle.max_value = fiche.souffle_max if fiche else 50
		barre_souffle.value = barre_souffle.max_value


func _process(_delta: float) -> void:
	if not heros or not heros.stats:
		return
	barre_vie.value = heros.stats.vie
	barre_souffle.value = heros.stats.souffle
	label_vie.text = "%d / %d" % [heros.stats.vie, barre_vie.max_value]
