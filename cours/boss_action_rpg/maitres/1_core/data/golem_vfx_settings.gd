class_name GolemVfxSettings extends Resource
## Réglages des effets visuels du golem : l'onde de poussière de ses impacts, la traînée de son marteau, le tremblement
## de la caméra, l'éclat des jointures de son armure en seconde phase.

## La durée de l'onde au sol, en secondes.
@export_range(0.05, 5.0, 0.05) var shockwave_time: float = 0.7
## L'onde s'étend jusqu'à cette part du rayon du coup (un peu au-delà : on voit où il a frappé).
@export_range(0.5, 3.0, 0.05) var shockwave_reach: float = 1.3
## Le rayon de l'onde du rugissement, au passage à la seconde phase, en mètres.
@export_range(0.5, 30.0, 0.5) var roar_radius: float = 7.0
## La traînée du marteau dure autant, en secondes.
@export_range(0.05, 1.0, 0.01) var trail_time: float = 0.22
## La traînée part du bout du marteau et remonte d'autant vers le manche, en mètres.
@export_range(0.1, 5.0, 0.05) var trail_width: float = 1.4
## La traînée commence autant avant la fenêtre du marteau et finit autant après, en secondes de clip.
@export_range(0.0, 1.0, 0.01) var trail_margin: float = 0.12
## L'ampleur du tremblement de la caméra à un impact, en mètres, à la distance zéro.
@export_range(0.0, 2.0, 0.01) var slam_shake: float = 0.35
## La durée du tremblement à un impact, en secondes.
@export_range(0.0, 3.0, 0.05) var slam_shake_time: float = 0.45
## Au-delà de cette distance de l'impact, en mètres, la caméra ne tremble plus.
@export_range(1.0, 100.0, 1.0) var shake_range: float = 25.0
## L'ampleur du tremblement du rugissement, en mètres.
@export_range(0.0, 2.0, 0.01) var roar_shake: float = 0.25
## La durée du tremblement du rugissement, en secondes.
@export_range(0.0, 3.0, 0.05) var roar_shake_time: float = 1.2
## L'éclat des jointures de l'armure en seconde phase.
@export_range(0.0, 16.0, 0.1) var glow_energy: float = 2.0
## Le temps pour qu'elles s'allument (ou s'éteignent à sa chute), en secondes.
@export_range(0.0, 10.0, 0.1) var glow_time: float = 1.5
## La braise palpite : la part de l'éclat qui va et vient.
@export_range(0.0, 1.0, 0.01) var glow_pulse: float = 0.3
## La vitesse de la palpitation, en radians par seconde.
@export_range(0.0, 20.0, 0.1) var glow_pulse_speed: float = 2.4
#@ 19+
## L'éclat que donne aux jointures un tir qui porte.
@export_range(0.0, 16.0, 0.1) var hit_glow: float = 3.5
## Le temps pour que cet éclat retombe, en secondes.
@export_range(0.01, 2.0, 0.01) var hit_glow_time: float = 0.2
#@ 20+
## L'aura qui borde sa silhouette, éveillé.
@export_range(0.0, 8.0, 0.05) var aura_first: float = 1.0
## L'aura en seconde phase.
@export_range(0.0, 8.0, 0.05) var aura_second: float = 1.8
## Le temps pour que l'aura change, en secondes.
@export_range(0.05, 10.0, 0.05) var aura_time: float = 1.5
## L'aura palpite : la part de son éclat qui va et vient.
@export_range(0.0, 1.0, 0.01) var aura_pulse: float = 0.25
## La vitesse de la palpitation, en radians par seconde.
@export_range(0.0, 20.0, 0.1) var aura_pulse_speed: float = 3.2
## L'énergie de sa lumière, par point d'aura.
@export_range(0.0, 20.0, 0.1) var aura_light: float = 3.0
## La part des braises qui montent autour de lui, éveillé (toutes en seconde phase).
@export_range(0.0, 1.0, 0.01) var embers_first: float = 0.5
#@ all
