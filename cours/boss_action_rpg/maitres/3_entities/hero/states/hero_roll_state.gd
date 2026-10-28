class_name HeroRollState extends State
## L'état Roll du héros : une roulade de durée fixe vers le stick (ou droit devant, stick lâché), qui coûte de
## l'endurance ; aucun coup ne porte au début ; à la fin, il revient à la course (Move). La direction est prise une
## fois au départ : une roulade engage, on ne la corrige pas en route.

## Le héros piloté.
@export var hero: Hero

## Le temps écoulé depuis le début de la roulade, en secondes.
var elapsed: float = 0.0

var _direction: Vector3 = Vector3.FORWARD


## Le départ : la direction est fixée, le corps s'y tourne d'un coup, l'endurance est dépensée, l'invulnérabilité
## commence.
func enter(_previous: StringName) -> void:
	elapsed = 0.0
	_direction = hero.roll_direction()
	hero.rotation.y = Motion.yaw_of(_direction)
	hero.stamina.spend(hero.settings.roll_cost)
	hero.invulnerable = true


## L'invulnérabilité ne survit jamais à la roulade.
func exit() -> void:
	hero.invulnerable = false


## Le héros glisse à la vitesse de la roulade ; l'invulnérabilité finit après son temps ; la roulade finie, Move.
func physics_update(delta: float) -> void:
	elapsed += delta
	hero.invulnerable = elapsed < hero.settings.roll_invulnerable_time
	hero.slide(delta, _direction * hero.settings.roll_speed)
	if elapsed >= hero.settings.roll_duration:
		finish(&"Move")
