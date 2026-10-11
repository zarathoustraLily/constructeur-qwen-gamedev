extends Node
## Scène de démarrage : passe la main au chef d'orchestre, qui charge la première étape.


func _ready() -> void:
	GameFlow.start.call_deferred()
