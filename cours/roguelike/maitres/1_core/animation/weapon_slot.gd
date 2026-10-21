class_name WeaponSlot extends BoneAttachment3D
## L'emplacement de l'arme, accroché à l'os d'une main. Les animations d'attaque l'écrivent image par image
## (des pistes de valeurs dans les fichiers .res du paquet d'animations KayKit) : la forme du coup
## (attack_mode), l'effacement de l'effet de lame (vfx_threshold) et la partie du coup qui frappe (enabled).
#@ 6+
## Pendant cette partie, la zone de coup (shapecast) est active.
#@ all

#@ 8+
## Émis par l'animation de tir d'un ennemi à distance, à l'instant où il lance sa boule de feu. C'est
## l'animation qui l'émet : l'avertissement « signal jamais employé » ne vaut pas ici.
@warning_ignore("unused_signal")
signal ranged_attack
#@ 6+
## Émis quand l'arme commence à frapper (enabled passe à vrai) : le son du coup s'y branche.
signal slash

#@ all
## Les formes de coup.
enum Mode {NONE, SLASH, STAB}

#@ 6+
## La zone de coup de l'arme, active seulement pendant la partie du coup qui frappe.
@export var shapecast: ShapeCast3D
#@ all
## La forme du coup en cours.
@export var attack_mode: Mode = Mode.NONE
## Effacement de l'effet de lame : 0, visible en entier ; 1, effacé.
@export var vfx_threshold: float = 0.0
#@ 3-5
## Vrai pendant la partie du coup qui frappe.
@export var enabled: bool = false
#@ 6+
## Vrai pendant la partie du coup qui frappe : la zone de coup est alors active, et le passage à vrai émet slash.
@export var enabled: bool = false:
	set(value):
		if not enabled and value:
			slash.emit()
		enabled = value
		if shapecast != null:
			shapecast.enabled = enabled
#@ all
