class_name HeroMoveState extends State
## L'état Move du héros : il court, ou sprinte tant que le bouton de roulade est tenu et qu'il lui reste de
## l'endurance ; une roulade demandée part dès qu'il a de l'endurance (Roll). Essoufflé (le sprint a vidé la jauge),
## il ne sprinte plus avant d'avoir relâché le bouton : sans cette règle, il repartirait par saccades à chaque
## remontée.
#@ 5+
## Gâchette tenue, l'arme tire à sa cadence ; pas pendant une roulade (l'état Roll ne tire pas).
#@ all

## Le héros piloté.
@export var hero: Hero

## Vrai quand le sprint a vidé l'endurance, jusqu'à ce que le bouton soit relâché.
var winded: bool = false


## Le sprint s'arrête en quittant la course.
func exit() -> void:
	hero.sprinting = false


## Une roulade en mémoire part si l'endurance le permet ; sinon il court ou sprinte, et le sprint dépense.
func physics_update(delta: float) -> void:
	if hero.stamina.can_spend() and hero.roll_buffer.consume():
		finish(&"Roll")
		return
	if not hero.dodge_held:
		winded = false
	hero.sprinting = (hero.dodge_held and not winded and not hero.aiming and not hero.stick.is_zero_approx()
			and hero.stamina.can_spend())
	if hero.sprinting:
		hero.stamina.spend(hero.settings.sprint_cost * delta)
		winded = not hero.stamina.can_spend()
#@ 5+
	if hero.trigger:
		hero.gun.pull(hero.aim_point())
#@ all
	hero.step(delta)
