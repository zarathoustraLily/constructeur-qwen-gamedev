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
