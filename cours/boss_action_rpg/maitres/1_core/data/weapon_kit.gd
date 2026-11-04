class_name WeaponKit extends Resource
## Une arme qu'on prend à l'établi : son nom, ce qu'on en dit, sa forme, ses réglages. L'arme du héros (HeroGun) reste le même
## nœud : prendre une arme, c'est lui donner d'autres réglages.

## Les formes d'armes (WeaponShapes les bâtit). STICK : la baguette qui ne tire pas.
enum Shape { NAILER, CORK, NEEDLE, CAPS, STICK }

## Son nom, dans l'interface.
@export var display_name: String = ""
## Ce qu'en dit l'invite, en quelques mots.
@export var description: String = ""
## Sa forme.
@export var shape: Shape = Shape.NAILER
## Sa cadence, ses dégâts, ses projectiles.
@export var gun: GunSettings
## Sa chaleur.
@export var heat: HeatSettings
