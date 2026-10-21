class_name AttackSettings extends Resource
## Les réglages d'un coup : son animation, ses dégâts, son recul, la vitesse de marche pendant le coup, et le
## moment où un coup suivant peut s'enchaîner. Un .tres par coup, dans 5_data (règle DAT-01).

## L'état d'animation du coup, dans l'arbre d'animation du personnage.
@export var animation: StringName = &""
## Dégâts de base, en points de vie.
@export var damage: float = 0.0
## Vitesse du recul donné à la cible, en m/s, vers l'avant du personnage.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var knockback: float = 0.0
## Vitesse de marche pendant le coup, en m/s (0 : on frappe sur place).
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var movement_speed: float = 0.0
## L'esquive peut-elle interrompre le coup ?
@export var dash_cancel: bool = false
## Délai après le début du coup au bout duquel un coup demandé entre-temps s'enchaîne, en secondes.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var queue_time: float = 0.0
