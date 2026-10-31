class_name GolemAttack extends Resource
## Une attaque du golem : le clip qu'elle joue, quand il s'en sert (distance au héros, phase du combat), quand son
## marteau frappe, comment son buste se penche pour que le coup passe à la hauteur du héros (ses clips frappent à sa
## propre hauteur, quatre fois celle du héros), et si elle écrase le sol (une onde autour du point d'impact). Les
## instants sont ceux du clip, en secondes, mesurés sur le clip avec le penché (marteau au ras du sol devant lui).

## Le nom de l'attaque.
@export var id: StringName
## Le clip joué.
@export var clip: StringName
## Il s'en sert à partir de cette distance au héros, en mètres.
@export_range(0.0, 50.0, 0.5) var min_range: float = 0.0
## Il s'en sert jusqu'à cette distance, en mètres.
@export_range(0.0, 50.0, 0.5) var max_range: float = 8.0
## La phase du combat à partir de laquelle il s'en sert (1 ou 2).
@export_range(1, 2) var from_phase: int = 1
## Il se tourne vers le héros jusqu'à cet instant (l'élan) ; ensuite, le coup part droit et peut s'esquiver.
@export_range(0.0, 10.0, 0.01) var track_until: float = 0.5
## Le marteau frappe à partir de cet instant (sa zone de coup s'allume).
@export_range(0.0, 10.0, 0.01) var strike_start: float = 0.9
## Le marteau ne frappe plus à partir de cet instant.
@export_range(0.0, 10.0, 0.01) var strike_end: float = 1.1
## Les dégâts du marteau.
@export_range(0.0, 500.0, 1.0) var damage: float = 30.0
## Le penché du buste pendant la frappe, en radians.
@export_range(0.0, 1.5, 0.01) var bend: float = 0.0
## Il commence à se pencher à cet instant ; il l'est tout à fait de strike_start à strike_end.
@export_range(0.0, 10.0, 0.01) var bend_start: float = 0.5
## Il est redressé à cet instant.
@export_range(0.0, 10.0, 0.01) var bend_end: float = 1.6
## Vrai si le coup écrase le sol : une onde frappe autour du point d'impact.
@export var slam: bool = false
## L'instant de l'impact au sol.
@export_range(0.0, 10.0, 0.01) var slam_time: float = 0.0
## Le point d'impact, depuis son corps à cet instant, en mètres : x vers sa droite, y devant lui.
@export var slam_offset: Vector2 = Vector2.ZERO
## Le rayon de l'onde, en mètres.
@export_range(0.0, 20.0, 0.1) var slam_radius: float = 3.5
## Les dégâts de l'onde.
@export_range(0.0, 500.0, 1.0) var slam_damage: float = 25.0
## Vrai si le coup est visé : le déplacement que porte le clip s'allonge ou se raccourcit (entre aim_min et aim_max
## fois) pour que l'impact tombe sur le héros.
@export var aimed: bool = false
## Le déplacement visé ne descend pas sous cette part de celui du clip.
@export_range(0.1, 2.0, 0.05) var aim_min: float = 0.6
## Le déplacement visé ne dépasse pas cette part de celui du clip.
@export_range(0.1, 2.0, 0.05) var aim_max: float = 1.1
## Le temps de récupération après le clip, en secondes : la fenêtre pour le punir.
@export_range(0.0, 10.0, 0.1) var recover: float = 1.5
#@ 20+
## Le sort que lance ce coup : fireball ou lightning (vide : aucun).
@export var spell: StringName = &""
## La vitesse de son clip : moins de 1 étire le geste, pour qu'un sort s'annonce.
@export_range(0.1, 2.0, 0.05) var clip_rate: float = 1.0
## Le sort se prépare à partir de cet instant du clip : c'est l'annonce.
@export_range(0.0, 10.0, 0.01) var charge_start: float = 0.0
## Le sort part à cet instant du clip.
@export_range(0.0, 10.0, 0.01) var cast_time: float = 0.0
## Le nombre de boules ou d'éclairs.
@export_range(1, 8) var spell_count: int = 1
## Les dégâts de chaque boule ou éclair.
@export_range(0.0, 500.0, 1.0) var spell_damage: float = 20.0
## Il ne relance pas ce coup avant autant de secondes.
@export_range(0.0, 60.0, 0.5) var cooldown: float = 0.0
#@ all


## Le penché du buste à l'instant `t` du clip : rien avant bend_start, `bend` pendant la frappe, rien après bend_end.
func bend_at(t: float) -> float:
	return bend * smoothstep(bend_start, strike_start, t) * (1.0 - smoothstep(strike_end, bend_end, t))


## Vrai si, à la distance `distance` du héros et dans la phase `phase`, il peut s'en servir.
func allowed(distance: float, phase: int) -> bool:
	return phase >= from_phase and distance >= min_range and distance <= max_range
