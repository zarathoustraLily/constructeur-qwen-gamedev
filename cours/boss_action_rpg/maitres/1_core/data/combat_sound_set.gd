class_name CombatSoundSet extends Resource
## Les sons du combat, un par événement, et les foulées qui rythment les pas.

@export_group("Héros")
## Un tir.
@export var shot: SoundCue
## Un pas.
@export var hero_step: SoundCue
## Une roulade.
@export var roll: SoundCue
## L'élan d'un saut.
@export var jump: SoundCue
## Le retour au sol après un saut.
@export var land: SoundCue
## Touché.
@export var hero_hurt: SoundCue
## Abattu.
@export var hero_down: SoundCue
## Une fiole bue.
@export var heal: SoundCue
## Un pas tous les tant de mètres parcourus au sol.
@export_range(0.2, 5.0, 0.05) var hero_stride: float = 1.6

@export_group("Impacts des tirs")
## Un tir dans le décor.
@export var hit_decor: SoundCue
## Un tir sur le corps du Gardien.
@export var hit_golem: SoundCue
## Un tir dans son point faible.
@export var hit_weak_point: SoundCue
## Un tir arrêté par son bouclier.
@export var hit_shield: SoundCue
## Un tir sur un spectre.
@export var hit_spectre: SoundCue

@export_group("Gardien")
## Un pas.
@export var golem_step: SoundCue
## Son marteau touche le héros.
@export var golem_hammer: SoundCue
## Il écrase le sol.
@export var golem_slam: SoundCue
## Il se réveille.
@export var golem_wake: SoundCue
## Sa seconde phase commence.
@export var golem_phase: SoundCue
## Il tombe.
@export var golem_down: SoundCue
## Un pas tous les tant de mètres parcourus.
@export_range(0.5, 10.0, 0.05) var golem_stride: float = 2.6
#@ 20+
## Il prépare un sort.
@export var golem_charge: SoundCue
## Une boule de feu part.
@export var fireball_throw: SoundCue
## Une boule de feu explose.
@export var fireball_blast: SoundCue
## Un éclair marque le sol.
@export var lightning_mark: SoundCue
## Un éclair frappe.
@export var lightning_strike: SoundCue
#@ all

@export_group("Spectres")
## Un spectre annonce sa plongée.
@export var spectre_windup: SoundCue
## Un spectre abattu se dissipe.
@export var spectre_gone: SoundCue
