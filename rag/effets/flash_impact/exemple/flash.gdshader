shader_type spatial;
// Flash d'impact : la surface tourne à la couleur du flash quand `flash` monte vers 1 (un coup reçu), puis revient.

uniform vec4 base_color : source_color = vec4(0.8, 0.15, 0.1, 1.0);
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = mix(base_color.rgb, flash_color.rgb, flash);
	// L'émission garde le flash visible même dans l'ombre.
	EMISSION = flash_color.rgb * flash;
}
