# Vent dans l'herbe (shader spatial, sommets)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier vent_herbe`.

## Ce que fait l'effet

Le haut de chaque brin se balance et son pied reste planté : le déplacement croît avec la hauteur du sommet et suit la position du brin dans le monde, pour que les brins voisins ne bougent pas ensemble.

## Quand l'employer

Herbe, fleurs, roseaux, feuillage. Pour beaucoup de brins, un `MultiMeshInstance3D` avec le même matériau : la position dans le monde (`MODEL_MATRIX`) décale chaque instance.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le shader (`herbe.gdshader`, vérifié)

```glsl
shader_type spatial;
// Vent dans l'herbe : le haut du brin se balance, le pied reste planté. Le déplacement croît avec la hauteur du sommet
// (1 - UV.y : sur un QuadMesh, UV.y vaut 0 en haut) et suit la position du brin dans le monde, pour que les brins
// voisins ne bougent pas tous ensemble.
render_mode cull_disabled;

uniform vec4 couleur_pied : source_color = vec4(0.1, 0.35, 0.08, 1.0);
uniform vec4 couleur_pointe : source_color = vec4(0.55, 0.85, 0.3, 1.0);
uniform float force = 0.3;
uniform float vitesse = 2.0;

void vertex() {
	float haut = 1.0 - UV.y;
	vec3 monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.x += sin(TIME * vitesse + monde.x * 0.8 + monde.z * 0.6) * force * haut * haut;
}

void fragment() {
	ALBEDO = mix(couleur_pied.rgb, couleur_pointe.rgb, 1.0 - UV.y);
}
```

## Le piloter depuis GDScript (vérifié)

```gdscript
## Régler le vent : `force` 0 pour l'arrêter.
func regler_vent(materiau: ShaderMaterial, force: float, vitesse: float) -> void:
	materiau.set_shader_parameter(&"force", force)
	materiau.set_shader_parameter(&"vitesse", vitesse)
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : sans vent, 0 pixel changé ; avec du vent, 2335 pixels changés en haut du brin, 0 au pied.

## Pièges

- Sur un `QuadMesh`, `UV.y` vaut 0 en haut : le facteur de hauteur est `1 - UV.y` (mesuré : le pied ne bouge pas, le haut bouge).
- Le brin doit être subdivisé en hauteur (`subdivide_depth`) pour se courber ; sinon il pivote d'un bloc (non mesuré ici).
- `cull_disabled` (« Culling disabled (double sided) », godot-docs, spatial_shader.rst) : un brin est une seule face, qu'on doit voir des deux côtés.
