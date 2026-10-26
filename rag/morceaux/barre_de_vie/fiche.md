# Barre de vie qui écoute le composant de vie et glisse vers la nouvelle valeur

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier barre_de_vie`.

## Ce que fait le morceau

Une `ProgressBar` reçoit le `HealthComponent` du socle par `setup()` et écoute son signal `damaged` ; à chaque coup, un `Tween` la fait glisser vers la vie restante. Un coup pendant le glissement arrête le précédent et repart de la valeur affichée.

## Quand l'employer

Vie du joueur dans le HUD, vie d'un boss, barre au-dessus d'un ennemi, endurance, jauge de bouclier.

Dans un projet qui suit le plan : `4_ui/hud/health_bar/` (scène et script) ; le niveau lui donne le composant de vie par `setup()` (principe 4) ; elle affiche et ne décide de rien (principe 1), et ne lit rien à chaque image.

## Le code (`4_ui/hud/health_bar/health_bar.gd`, vérifié)

```gdscript
class_name HealthBar
extends ProgressBar
## Barre de vie : elle écoute le HealthComponent qu'on lui donne et glisse vers la nouvelle valeur. Elle affiche,
## elle ne décide de rien (aucune lecture à chaque image). Entrées : setup().

## Durée du glissement vers la nouvelle valeur, en secondes (réglée dans la scène du HUD).
@export var slide_duration: float = 0.0

var _tween: Tween


func setup(health: HealthComponent) -> void:
	max_value = health.max_health
	value = health.current_health
	health.damaged.connect(_on_damaged)


func _on_damaged(_amount: int, current: int) -> void:
	if _tween != null:
		_tween.kill()  # un coup pendant le glissement : on repart de la valeur affichée
	_tween = create_tween()
	_tween.tween_property(self, "value", float(current), slide_duration)
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : barre à 10.0 sur 10 ; coup de 3 : 8.50 à mi-glissement, 7.0 à la fin ; coups de 2 puis 4 : 1.0.

## Pièges

- La barre écoute un signal (`damaged`) au lieu de lire la vie à chaque image (règle du HUD du socle ; mesuré : 7 après un coup de 3, 1 après deux coups rapprochés).
- `max_value` vient du composant au `setup()` : une barre laissée à 100 par défaut afficherait 7 % pour 7 points (référence des classes, `Range.max_value`, défaut 100).
- Deux coups rapprochés : arrêter le `Tween` précédent (`kill()`) avant d'en créer un, sinon deux animations écrivent la même valeur (mesuré : la barre finit sur la vie restante).
