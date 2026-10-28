class_name HeroDeadState extends State
## L'état Dead du héros : tombé, il ne fait plus rien ; seule la gravité le pose au sol. Il n'en sort pas : c'est le
## niveau qui recommence (la scène principale écoute `Hero.defeated`).

## Le héros piloté.
@export var hero: Hero


## Il s'arrête net ; seule la gravité agit.
func physics_update(delta: float) -> void:
	hero.slide(delta, Vector3.ZERO)
