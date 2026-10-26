# Pixelisation de l'écran (shader canvas_item, texture d'écran)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier pixelisation`.

## Ce que fait l'effet

L'image déjà dessinée est relue (`hint_screen_texture`) par blocs de `taille` pixels : chaque bloc prend une seule couleur. Effet rétro, transition, ou écran brouillé.

## Quand l'employer

Transition entre scènes, effet de téléportation, style rétro. Un `ColorRect` plein écran au-dessus de la scène porte le shader.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le shader (`pixelisation.gdshader`, vérifié)

```glsl
shader_type canvas_item;
// Pixelisation de l'écran : on relit l'image déjà dessinée (hint_screen_texture) par blocs de `taille` pixels, chaque
// bloc prenant la couleur de son premier pixel. À poser sur un ColorRect plein écran, au-dessus de la scène.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float taille = 8.0;

void fragment() {
	vec2 ecran = vec2(textureSize(screen_texture, 0));
	vec2 premier_pixel = floor(SCREEN_UV * ecran / taille) * taille;
	// On lit le centre du pixel (+ 0,5) : lu sur son bord, le filtre « nearest » prend parfois le voisin.
	COLOR = texture(screen_texture, (premier_pixel + 0.5) / ecran);
}
```

## Le piloter depuis GDScript (vérifié)

```gdscript
## Taille des blocs, en pixels de l'écran ; 1 laisse l'image intacte.
func pixeliser(materiau: ShaderMaterial, taille: float) -> void:
	materiau.set_shader_parameter(&"taille", taille)
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : 223 changements de couleur à l'intérieur des blocs de 8 pixels sans l'effet, 223 avec des blocs de 1, 0 avec des blocs de 8.

## Pièges

- `filter_nearest` sur la texture d'écran, comme dans l'exemple de godot-docs (screen-reading_shaders.rst) : un filtre lissé mélangerait les pixels voisins au bord des blocs (non mesuré ici).
- Lire chaque bloc au centre de son premier pixel (`+ 0.5`) : lu sur le bord du pixel, une première version de cet exemple prenait parfois le voisin (mesuré : 222 changements au lieu de 223 avec des blocs de 1).
- Le shader ne voit que ce qui est dessiné avant lui, « what lies behind » (godot-docs, screen-reading_shaders.rst) : l'interface dessinée au-dessus reste nette.
