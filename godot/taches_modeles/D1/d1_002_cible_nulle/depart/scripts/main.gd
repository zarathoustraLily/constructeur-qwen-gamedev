extends Node2D
## Scène principale : relie le héros, les vagues et le HUD.

@onready var hero: Hero = $Hero
@onready var spawner: WaveSpawner = $WaveSpawner
@onready var hud: Hud = $Hud


func _ready() -> void:
	GameState.coins_changed.connect(hud._on_coins_changed)
	hero.health.health_changed.connect(hud._on_health_changed)
	hud._on_health_changed(hero.health.current_health, hero.health.max_health)
	hud._on_coins_changed(GameState.coins)
	spawner.target = hero
	spawner.start_next_wave()


func _on_wave_cleared(_number: int) -> void:
	spawner.start_next_wave()
