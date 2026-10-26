# Eau stylisée animée (shader spatial, sommets)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier eau_stylisee`.

## Ce que fait l'effet

Deux houles, des sinus qui avancent avec le temps, soulèvent les sommets d'un plan ; les crêtes sont plus claires que les creux. La normale est recalculée d'après la pente de la surface.

## Quand l'employer

Lac, mer, rivière stylisés ; fond d'un niveau ; eau d'une fontaine.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le shader (`eau.gdshader`, vérifié)

```glsl
shader_type spatial;
// Eau stylisée : deux houles (des sinus qui avancent avec TIME) soulèvent les sommets ; les crêtes sont plus claires
// que les creux. Le plan doit être subdivisé : seules ses sommets bougent.

uniform vec4 couleur_creux : source_color = vec4(0.02, 0.2, 0.4, 1.0);
uniform vec4 couleur_crete : source_color = vec4(0.5, 0.85, 0.95, 1.0);
uniform float amplitude = 0.15;
uniform float longueur_onde = 2.0;
uniform float vitesse = 1.5;

varying float hauteur;

void vertex() {
	float k = 6.2832 / longueur_onde;
	float phase_x = VERTEX.x * k + TIME * vitesse;
	float phase_z = VERTEX.z * k * 0.7 + TIME * vitesse * 1.3;
	hauteur = sin(phase_x) * 0.6 + sin(phase_z) * 0.4;
	VERTEX.y += hauteur * amplitude;
	// La pente de la surface donne la normale : sans elle, l'éclairage resterait celui du plan plat.
	float pente_x = cos(phase_x) * 0.6 * k * amplitude;
	float pente_z = cos(phase_z) * 0.4 * k * 0.7 * amplitude;
	NORMAL = normalize(vec3(-pente_x, 1.0, -pente_z));
}

void fragment() {
	ALBEDO = mix(couleur_creux.rgb, couleur_crete.rgb, hauteur * 0.5 + 0.5);
	ROUGHNESS = 0.25;
}
```

## Le piloter depuis GDScript (vérifié)

```gdscript
## Régler la houle : `amplitude` en mètres, `vitesse` 0 pour figer l'eau.
func regler_vagues(materiau: ShaderMaterial, amplitude: float, vitesse: float) -> void:
	materiau.set_shader_parameter(&"amplitude", amplitude)
	materiau.set_shader_parameter(&"vitesse", vitesse)
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : 0 points changés en 20 images eau figée, 753 eau animée ; écart de luminance crête/creux 0.21.

## Pièges

- Le plan doit être subdivisé (`subdivide_width`, `subdivide_depth`) : le shader ne déplace que des sommets, et un plan de 4 sommets ne fait pas de vagues (non mesuré ici).
- Sans la normale recalculée, l'éclairage reste celui du plan plat : les vagues ne se voient qu'à la couleur (non mesuré ici).
- `vitesse` multiplie `TIME` : la changer en cours fait sauter la phase des vagues (se déduit du shader ; non mesuré ici). Pour ralentir en douceur, avancer sa propre horloge depuis GDScript et la passer en paramètre.
- `vitesse` à 0 fige l'eau (mesuré : 0 point changé en 20 images).
