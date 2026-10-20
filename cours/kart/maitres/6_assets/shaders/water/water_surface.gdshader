shader_type spatial;
render_mode world_vertex_coords, depth_draw_always, cull_disabled;

#include "res://6_assets/shaders/water/ocean_common.gdshaderinc"
#include "res://6_assets/shaders/water/water_textures.gdshaderinc"
#include "res://6_assets/shaders/common/utils.gdshaderinc"
#include "res://6_assets/shaders/common/screen_space_reflections.gdshaderinc"
//@ 11+
#include "res://6_assets/shaders/effects/rain_ripples.gdshaderinc"
//@ all



// Reflet du soleil
uniform float specular_strength = 1.0;
uniform float specular_power = 1500.0;

// ALPHA commence à décroître vers 0 au-delà de view_distance_max * view_fade_start
uniform float view_fade_start = 0.95;

// Couleurs
uniform vec4 deep_color:source_color = vec4(0.004f, 0.016f, 0.047f, 1.0);
uniform vec4 shallow_color:source_color = vec4(0, 0.729412, 0.988235, 1);


group_uniforms Fresnel;
/******************************************************************************/
// Les réglages PBR (specular, metallic) changent beaucoup le rendu de Fresnel : y toucher si ces
// seuls réglages ne suffisent pas.

// Fresnel
uniform float fresnel_offset = 0.02;
uniform float fresnel_strength = 0.0;
uniform float fresnel_power = 5.0;
uniform float fresnel_exposure = 0.03;
uniform vec4 fresnel_sky_color:source_color = vec4(1.6f, 4.8f, 6.4f, 1.0);


group_uniforms PhysicallyBasedRendering;
/******************************************************************************/
uniform float pbr_specular_strength = 0.1;
uniform float pbr_specular_offset = 0.1;
uniform float pbr_metallic_strength = 0.0;


group_uniforms Refraction;
/******************************************************************************/
// À refaire entièrement.

uniform float refraction_factor_min = 0.0;
uniform float refraction_factor_max = 0.025;
uniform float refraction_distance_power = 1.55;
uniform float refraction_distance_max = 30000.0;
uniform float refraction_background_brightness = 0.2;

// Force de la réfraction selon la distance entre le pixel de l'océan et l'objet derrière
// lui.
uniform float refraction_depth_factor = 1.0;


group_uniforms SubSurfaceScattering;
/******************************************************************************/
uniform float sss_backlight_strength = 0.0125;
uniform float sss_backlight_fov = 10.0;
uniform float sss_backlight_depth = 15.0;
uniform float sss_upwelling = 0.075;
uniform vec4 sss_color:source_color = vec4(0, 0.729412, 0.988235, 1);


group_uniforms Whitecaps;
/******************************************************************************/
// Écume des crêtes, par le déterminant jacobien : là où la surface se resserre, elle moutonne.
// Plus tard : calculer jacobien et écume dans un autre shader, pour une écume qui dure et se
//       dissipe.

uniform float foam_jacobian_limit = 0.5;
uniform float foam_coverage = 0.1;
uniform float foam_mix_strength = 1.0;
uniform float foam_diffuse_strength = 1.0;
uniform vec4 foam_diffuse_color:source_color = vec4(0.91764706373215, 0.96862745285034, 1.0, 1.0);
uniform sampler2D foam_texture : hint_default_white;


group_uniforms Internal;
/******************************************************************************/
// Réglés pendant le jeu : une valeur posée dans l'éditeur risque d'être écrasée.

// Nombre de sommets par côté des carrés de maillage qui portent ce shader.
uniform float vertex_resolution = 256.0;


group_uniforms Internal.WaveDeformModifiers;
/******************************************************************************/

// Aplatit les vagues avec la distance à la caméra.
// Appliqué après le calcul des normales et de l'écume des crêtes.
uniform float amplitude_scale_min = 0.25;
uniform float amplitude_scale_max = 1.0;
uniform float amplitude_scale_fade_distance = 12000.0;


uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

group_uniforms Caustics;

uniform sampler2D caustics_texture;
uniform float caustics_strength = 0.5;
uniform float caustics_scale = 0.002;
uniform float caustics_speed = 0.1;

group_uniforms;

group_uniforms AdditionalMaps;
uniform float  wave_scale = 0.1;
uniform float  wave_strength = 0.25;
uniform sampler2D normal1;
uniform vec2 wave_dir1 = vec2(1.0, 0.0);
uniform sampler2D normal2;
uniform vec2 wave_dir2 = vec2(0.0, 1.0);
uniform float wave_speed : hint_range(0.0, 0.2) = 0.015;
group_uniforms;

group_uniforms ShallowWater;
// Eau claire : on voit le fond (sable) à travers l'eau peu profonde, déformé par les vagues.
// Profondeur (m) à partir de laquelle le fond n'est presque plus visible
uniform float clear_depth = 6.0;
// Absorption relative par canal : le rouge disparaît en premier, le bleu en dernier (dégradé sable -> turquoise -> bleu)
uniform vec3 absorption_rgb = vec3(1.0, 0.36, 0.26);
uniform vec4 clear_water_tint : source_color = vec4(0.72, 0.96, 1.0, 1.0);
uniform float clear_water_brightness = 1.0;
// Décalage du fond (m par m de profondeur) selon l'inclinaison de la surface : effet de parallaxe
uniform float parallax_strength = 0.6;
// Caustiques projetées sur le fond visible
uniform float floor_caustics_strength = 0.6;
group_uniforms;

//@ 11+
group_uniforms Rain;
// Anneaux d'impact des gouttes (intensité pilotée par le global « rain_intensity »)
uniform float rain_drops_per_meter = 2.0;
uniform float rain_normal_strength = 0.9;
uniform float rain_ring_brightness = 0.2;
group_uniforms;
//@ all

// Uniformes d'instance
/******************************************************************************/
instance uniform float patch_size = 512.0;
instance uniform float min_lod_morph_distance;
instance uniform float max_lod_morph_distance;

// Varyings
/******************************************************************************/
varying vec3 world_vertex;
varying float jacobian_determinant;
varying float wave_height;
varying float foam_mix_factor;
varying float foam_specular_factor;

vec2 lod_morph(float morph_factor, vec2 grid_pos) {
	vec2 fracPart = fract(grid_pos.xy * vertex_resolution * 0.5) * 2.0 / vertex_resolution;
	return fracPart * patch_size * morph_factor;
}

vec3 HDR(vec3 color, float e) {
	return 1.0 - exp(-color * e);
}

varying mat4 model_mat;

void vertex() {
	float linear_dist = length(VERTEX - CAMERA_POSITION_WORLD);

	// Transition entre niveaux de détail (geomorph)
	float morph_factor = (clamp(linear_dist, min_lod_morph_distance, max_lod_morph_distance) - min_lod_morph_distance) / (max_lod_morph_distance - min_lod_morph_distance);
	VERTEX.xz -= lod_morph(morph_factor, UV);

	// Déformation du domaine
	vec2 domain_warped_uv = domain_warp(VERTEX.xz, linear_dist);

	// Déplacement du sommet
	float wave_height_multiplier = get_island_height_multiplier(VERTEX);

	vec3 displacement = get_displacement(domain_warped_uv);
//@ 9+
	displacement += vec3(0, sample_water_waves_height(VERTEX) + sample_water_ripples(VERTEX) * 0.5, 0);
//@ all

	VERTEX += displacement * wave_height_multiplier;
	world_vertex = VERTEX;

	// Normales de la surface et jacobien
	vec4 nj = get_normals_jacobian(domain_warped_uv, displacement);
	NORMAL = nj.xyz * normal_factor;
	jacobian_determinant = nj.w;

	// Atténuation de l'amplitude avec la distance
	// Aplatit les vagues avec la distance à la caméra, après le calcul des normales : au loin, les
	// normales gardent le relief.
	float amplitude_fade_range = clamp(linear_dist, 0.0, amplitude_scale_fade_distance) / amplitude_scale_fade_distance;
	VERTEX.y *= mix(amplitude_scale_max, amplitude_scale_min, amplitude_fade_range);

	model_mat = transpose(inverse(MODELVIEW_MATRIX));
}

void fragment() {
	// Facteur de Fresnel du fragment
	float fresnel_factor = clamp(pow(abs(1.0 - dot(NORMAL, normalize(VIEW))), fresnel_power), -1.0, 1.0);
	float fresnel = fresnel_factor * fresnel_strength + fresnel_offset;

	// Profondeur linéaire entre chaque pixel de l'océan et ce qui est derrière lui.
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(vec3(SCREEN_UV * 2.0 - 1.0, depth), 1.0);
	view /= view.w;
	float linear_depth = -view.z;

	vec4 depth_position = INV_VIEW_MATRIX * view;
	depth_position.xyz /= depth_position.w;

	// Distance entre la caméra et chaque pixel de l'océan.
	float linear_dist = length(world_vertex - CAMERA_POSITION_WORLD);
	float water_depth =  world_vertex.y - depth_position.y;

	// Réfraction, selon la profondeur entre le pixel de l'océan et l'objet derrière. Elle s'efface
	// avec la distance, pour une transition douce vers les niveaux de détail moins fins.
	float refraction_factor = clamp(linear_depth * refraction_depth_factor, refraction_factor_min, refraction_factor_max);
	vec2 refracted_uv = SCREEN_UV - NORMAL.xz * refraction_factor;
	vec3 background_color = textureLod(screen_texture, refracted_uv, 0.0).rgb;
	float refraction_blend_factor = clamp(pow(linear_depth, refraction_distance_power), 0.0, refraction_distance_max) / refraction_distance_max;
	vec3 water_color = mix(background_color * shallow_color.rgb * refraction_background_brightness, deep_color.rgb, refraction_blend_factor * (1.0 - fresnel));

	water_color = mix(deep_color.rgb, water_color, 1.0 / pow(1.0 + max(water_depth, 0.0), 1.1));

	// Caustiques
	if (water_depth > 0.0) {
	    float c = mix(texture(caustics_texture, depth_position.xz * 0.1 + TIME * vec2(0.01, 0.02)).r, texture(caustics_texture, depth_position.xz * 0.059 + TIME * vec2(-0.012, -0.04)).r, 0.5);
	    water_color += c * caustics_strength / pow(1.0 + water_depth, 2.0);
	}

	 // Fresnel
	vec3 sky = fresnel_sky_color.rgb * fresnel;
	vec3 water = (1.0 - fresnel) * water_color * fresnel_sky_color.rgb;
	water_color = HDR(sky + water, fresnel_exposure);

	// Écume : faible profondeur
	foam_mix_factor = clamp(1.0 / pow(1.0 + water_depth, 8.0), 0.0, 1.0);

//@ 9+
	// Écume : écume accumulée
	foam_mix_factor += sample_foam_mask(world_vertex);
	// Écume : les vagues d'impact passent par le masque d'écume, pas par cette ligne
	foam_mix_factor += sample_water_ripples(world_vertex) * 3.0;
//@ all

	// Plus tard : l'écume de la houle FFT
	foam_mix_factor = clamp(foam_mix_factor, 0.0, 1.0);
	float foam_texture_sample = 0.5 * (texture(foam_texture, world_vertex.xz * uv_scale * 10.0 - 0.00137 * TIME).r + texture(foam_texture, world_vertex.xz * uv_scale * 6.0 + 0.001 * TIME).r);
	foam_mix_factor = smoothstep(0.6, 0.9, 0.6 * foam_texture_sample + 0.5 * foam_mix_factor);

	ALBEDO = mix(water_color, vec3(1.0), foam_mix_factor);
	foam_specular_factor = (1.0 - foam_mix_factor);


	// Fondu avec la distance
	float fade_start = view_distance_max * view_fade_start;
	ALPHA = 1.0 - (clamp(linear_dist, fade_start, view_distance_max) - fade_start) / (view_distance_max - fade_start);

	// Autres réglages PBR
	ROUGHNESS = foam_mix_factor + 0.02;
	METALLIC = pbr_metallic_strength * foam_specular_factor;
	SPECULAR = pbr_specular_strength * foam_specular_factor * fresnel_factor + pbr_specular_offset;


	// Cartes de normales
	vec2 normal_offset1 = (TIME * wave_dir1) * wave_speed;
	vec2 normal_offset2 = (TIME * wave_dir2) * wave_speed;
	vec3 wave_normals = blend_normals(texture(normal1, world_vertex.xz * wave_scale + normal_offset1).rgb, texture(normal2, world_vertex.xz * wave_scale + normal_offset2).rgb);
	wave_normals = scale_normal_strength(wave_normals, wave_strength);

//@ 8-8
	NORMAL_MAP = wave_normals;
//@ 9+
	NORMAL_MAP = blend_normals(wave_normals, compute_ripples_normal(world_vertex));
//@ all

//@ 11+
	// Pluie : anneaux d'impact sur la surface
	vec3 rain = rain_ripples(world_vertex.xz, TIME, rain_intensity, rain_drops_per_meter) * foam_specular_factor;
	vec3 rain_normal = normalize(vec3(-rain.x * rain_normal_strength, -rain.y * rain_normal_strength, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP = blend_normals(NORMAL_MAP, rain_normal);
	ALBEDO = mix(ALBEDO, vec3(1.0), clamp(rain.z, 0.0, 1.0) * rain_ring_brightness);
//@ all

	// --- Eau claire peu profonde : fond visible avec parallaxe ---
	// Le point du fond vu sans réfraction est décalé selon l'inclinaison de la surface et la profondeur,
	// puis reprojeté à l'écran : plus l'eau est profonde, plus le fond « glisse » sous les vagues.
	vec3 detail_normal = NORMAL_MAP * 2.0 - 1.0;
	vec3 surface_normal_world = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec2 tilt = surface_normal_world.xz + detail_normal.xy * 0.6;
	float shift_depth = clamp(water_depth, 0.0, 6.0);
	vec3 shifted_floor = depth_position.xyz + vec3(tilt.x, 0.0, tilt.y) * shift_depth * parallax_strength;
	vec4 shifted_clip = PROJECTION_MATRIX * VIEW_MATRIX * vec4(shifted_floor, 1.0);
	vec2 floor_uv = clamp(shifted_clip.xy / shifted_clip.w * 0.5 + 0.5, vec2(0.001), vec2(0.999));

	// Si le point décalé tombe sur un objet devant la surface de l'eau, on garde le point non décalé
	vec4 floor_view = INV_PROJECTION_MATRIX * vec4(floor_uv * 2.0 - 1.0, texture(depth_texture, floor_uv).r, 1.0);
	floor_view /= floor_view.w;
	if (-floor_view.z < -VERTEX.z) {
		floor_uv = SCREEN_UV;
		floor_view = view;
	}
	vec3 floor_world = (INV_VIEW_MATRIX * vec4(floor_view.xyz, 1.0)).xyz;
	float floor_depth = max(world_vertex.y - floor_world.y, 0.0);

	if (floor_depth > 0.0 && floor_depth < clear_depth * 3.0) {
		// Trajet de la lumière dans l'eau : surtout la profondeur, un peu le trajet oblique
		float light_path = mix(floor_depth, length(world_vertex - floor_world), 0.3);
		vec3 transmittance = exp(-absorption_rgb * light_path * 3.0 / clear_depth);
		vec3 floor_color = textureLod(screen_texture, floor_uv, 0.0).rgb;
		float floor_caustics = mix(texture(caustics_texture, floor_world.xz * 0.1 + TIME * vec2(0.01, 0.02)).r,
			texture(caustics_texture, floor_world.xz * 0.059 + TIME * vec2(-0.012, -0.04)).r, 0.5);
		floor_color *= 1.0 + floor_caustics * floor_caustics_strength;

		// Moins de transparence en vue rasante (reflet de Fresnel) et sous l'écume
		float see_through = (1.0 - fresnel_factor) * (1.0 - foam_mix_factor);
		float visibility = clamp(dot(transmittance, vec3(0.3, 0.4, 0.3)), 0.0, 1.0) * see_through;
		ALBEDO *= 1.0 - visibility;
		EMISSION += floor_color * transmittance * clear_water_tint.rgb * clear_water_brightness * see_through;
	}

	wave_height = world_vertex.y;

	// Réflexions en espace écran (SSR)
	float far_clip = 256.0;
	int steps = 16;
	float ssr_screen_fade = 0.05;
	float ssr_strength = 0.1 * foam_specular_factor;

	mat3 TBN = mat3(
		-(model_mat * vec4(TANGENT, 0.0)).xyz,
		(model_mat * vec4(BINORMAL, 0.0)).xyz,
		(model_mat * vec4(NORMAL, 0.0)).xyz
	);

	vec3 ssr_normal = apply_normal_map(TBN, NORMAL, NORMAL_MAP, 0.1);

	vec4 SSR = get_screen_space_reflection(far_clip, steps, ssr_screen_fade, VIEW, ssr_normal, VERTEX, PROJECTION_MATRIX, INV_PROJECTION_MATRIX, depth_texture, screen_texture);
	ALBEDO = mix(ALBEDO, SSR.rgb , SSR.w * ssr_strength);
}

void light() {
	vec3 half_vector = normalize(LIGHT + VIEW);

	// Reflet spéculaire
	float spec = clamp(pow(dot(NORMAL, half_vector), specular_power), 0.0, 1.0) * specular_strength;
	SPECULAR_LIGHT += (LIGHT_COLOR * ALBEDO * ATTENUATION / PI) * clamp(dot(NORMAL, half_vector), 0.0, 1.0) * foam_specular_factor;
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * spec * foam_specular_factor;

	// Diffusion sous la surface
	vec3 sss_sun_light = sss_color.rgb * ATTENUATION;

	// Diffusion : contre-jour dans les vagues
	float sss = sss_backlight_strength * max(0.0, wave_height + sss_backlight_depth) * pow(max(0.0, dot(-LIGHT, VIEW)), 4.0);
	sss *= pow(0.5 - 0.5 * dot(-LIGHT, half_vector), 3.0);
	sss *= sss_backlight_fov * pow(max(0.0, dot(VIEW, half_vector)) , 2.0);
	vec3 sss_result = sss * sss_sun_light;

	// Diffusion : lumière qui remonte
	sss_result += sss_upwelling * max(0.0, dot(LIGHT, half_vector)) * sss_sun_light;
	SPECULAR_LIGHT += sss_result * foam_specular_factor;

	// Éclairage de l'écume
	DIFFUSE_LIGHT += foam_diffuse_strength * foam_mix_factor * foam_diffuse_color.rgb * ATTENUATION;
}