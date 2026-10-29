class_name SpectreSettings extends Resource
#@ 11
## Réglages des spectres : quand le boss les appelle, comment ils planent autour du héros, annoncent et font leur
## plongée, ce qu'elle coûte au héros, et combien de tirs les dissipent.

## Le boss les appelle quand sa vie passe sous cette part (de 0 à 1) : 0,7, quand il en a perdu 30 %.
@export_range(0.0, 1.0, 0.01) var summon_ratio: float = 0.7
#@ 12+
## Réglages des spectres : comment ils sortent (le boss les appelle à sa seconde phase), planent autour du héros,
## annoncent et font leur plongée, ce qu'elle coûte au héros, et combien de tirs les dissipent.

#@ all
## Le temps entre la sortie de deux spectres, en secondes : ils ne plongent pas ensemble.
@export_range(0.0, 10.0, 0.1) var stagger: float = 1.2
## La hauteur à laquelle ils planent au-dessus du héros, en mètres.
@export_range(0.5, 10.0, 0.1) var hover_height: float = 2.6
## Le rayon du cercle qu'ils décrivent autour du héros, en mètres.
@export_range(1.0, 30.0, 0.5) var hover_radius: float = 6.0
## La vitesse de ce cercle, en radians par seconde.
@export_range(0.0, 5.0, 0.05) var orbit_speed: float = 0.6
## La vitesse à laquelle ils rejoignent leur place sur le cercle (suivi exponentiel, par seconde).
@export_range(0.1, 20.0, 0.1) var follow_speed: float = 2.5
## Le temps passé à planer avant d'annoncer une plongée, en secondes.
@export_range(0.1, 20.0, 0.1) var hover_time: float = 2.5
## L'annonce : le spectre s'arrête et s'illumine pendant ce temps, en secondes ; c'est le moment de rouler.
@export_range(0.1, 5.0, 0.05) var windup_time: float = 0.7
## L'éclat pendant l'annonce (paramètre `intensity` du shader).
@export_range(0.0, 10.0, 0.1) var windup_intensity: float = 5.0
## L'éclat ordinaire.
@export_range(0.0, 10.0, 0.1) var base_intensity: float = 1.6
## La vitesse de la plongée, en m/s.
@export_range(1.0, 60.0, 0.5) var dive_speed: float = 18.0
## La plongée s'arrête au plus tard après ce temps, en secondes.
@export_range(0.1, 5.0, 0.05) var dive_max_time: float = 1.0
## Le temps pour remonter après une plongée, en secondes.
@export_range(0.1, 10.0, 0.1) var recover_time: float = 1.2
## Les dégâts d'une plongée qui touche.
@export_range(0.0, 200.0, 1.0) var damage: float = 18.0
## Le temps pour se dissiper une fois abattu, en secondes.
@export_range(0.05, 5.0, 0.05) var fade_time: float = 0.8
