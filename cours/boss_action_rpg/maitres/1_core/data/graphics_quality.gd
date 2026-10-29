class_name GraphicsQuality extends Resource
## Un niveau de qualité graphique : ce que le rendu s'autorise. La qualité haute garde tout ; la basse vise un petit PC
## (carte graphique intégrée) : les effets d'écran les plus coûteux coupés, le rendu 3D plus petit puis agrandi par
## FSR, peu de lumières qui font des ombres (et des ombres moins chères), une brume de repli sans brouillard
## volumétrique.

## Le nom du niveau (haute, basse).
@export var id: StringName
## L'éclairage global par champs de distance (SDFGI), le plus coûteux.
@export var sdfgi: bool = true
## L'éclairage indirect calculé à l'écran (SSIL).
@export var ssil: bool = true
## L'occlusion ambiante calculée à l'écran (SSAO).
@export var ssao: bool = true
## La lueur autour des points lumineux (glow).
@export var glow: bool = true
## Le brouillard volumétrique (la brume au sol) ; sans lui, la brume de repli, faite de nappes.
@export var volumetric_fog: bool = true
## Le rendu 3D se fait à cette part de la résolution de l'écran (1 : pleine), puis il est agrandi.
@export_range(0.25, 1.0, 0.01) var scale_3d: float = 1.0
## Vrai : l'agrandissement se fait par FSR 1 ; faux : simplement.
@export var fsr: bool = false
## Au plus ce nombre de lumières du décor font des ombres : les plus proches du lieu du combat.
@export_range(0, 64) var shadow_lights: int = 64
## Vrai : les ombres des lumières omnidirectionnelles se font en deux demi-sphères (deux passes) au lieu d'un cube
## (six), sauf avec le moteur Compatibilité, qui n'a que les cubes.
@export var cheap_omni_shadows: bool = false
## La taille de l'atlas des ombres des lumières du décor, en pixels.
@export_range(256, 16384) var shadow_atlas: int = 4096
## La taille de l'atlas des ombres de la lune, en pixels.
@export_range(256, 16384) var directional_shadow: int = 4096
## La portée des lumières du décor est ramenée à au plus cette distance, en mètres (0 : laissée telle quelle).
@export_range(0.0, 200.0, 0.5) var light_range_max: float = 0.0
## La lumière ambiante est multipliée par autant : sans éclairage global, la salle perd la lumière que renvoient les
## murs ; on la lui rend, à peu de frais.
@export_range(0.0, 10.0, 0.05) var ambient_scale: float = 1.0
