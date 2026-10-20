shader_type spatial;

//render_mode world_vertex_coords;

#include "res://6_assets/shaders/common/utils.gdshaderinc"
#include "res://6_assets/shaders/common/triplanar_sampling.gdshaderinc"
//@ 11+
#include "res://6_assets/shaders/effects/rain_ripples.gdshaderinc"
//@ all

uniform float specular : hint_range(0, 1) = 0.5f;
uniform float roughness : hint_range(0, 1) = 0.5f;
uniform float metalic : hint_range(0, 1) = 0.0f;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec2 uv_tiling = vec2(1.0);
uniform sampler2D albedo_texture;

uniform sampler2D noise;
uniform float noiseScale = 0.25;
uniform float normalScale = 0.15;

uniform bool use_global_position = true;

//@ 11+
group_uniforms Rain;
// 0 = ignore la pluie, 1 = la surface se mouille (activé sur la route)
uniform float rain_receiver : hint_range(0.0, 1.0) = 0.0;
uniform float rain_darkening : hint_range(0.0, 1.0) = 0.45;
uniform float rain_wet_roughness : hint_range(0.0, 1.0) = 0.25;
// Part de la surface couverte de flaques (lisses, très réfléchissantes)
uniform float rain_puddle_amount : hint_range(0.0, 1.0) = 0.4;
uniform float rain_puddle_darkening : hint_range(0.0, 1.0) = 0.35;
uniform float rain_drops_per_meter = 2.5;
uniform float rain_ripple_strength = 0.6;
group_uniforms;
//@ all

varying vec3 global_position;

void vertex() {
	global_position = VERTEX;
	if(use_global_position) {
		vec4 pos_h = (MODEL_MATRIX * vec4(global_position, 1.0));
		global_position = pos_h.xyz / pos_h.w;
	}
}

void fragment() {
	vec3 global_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	SPECULAR = specular;
	ROUGHNESS = roughness;
	METALLIC = metalic;
	vec3 sampled_noise = sampleTriplanar(noise, global_position, global_normal, noiseScale).rgb;

	global_normal = noiseNormalTransformer(global_normal, sampled_noise, normalScale);
	ALBEDO = noiseColorTransformer(albedo.rgb * texture(albedo_texture, UV * uv_tiling).rgb, sampled_noise);

//@ 11+
	// Pluie : surface mouillée, flaques et impacts de gouttes (seulement sur les faces orientées vers le ciel)
	float wet = rain_wetness * rain_receiver * smoothstep(0.6, 0.9, global_normal.y);
	if (wet > 0.001) {
		float puddle = rain_puddle_mask(global_position.xz, rain_puddle_amount) * smoothstep(0.3, 0.8, wet);
		ALBEDO *= mix(1.0, 1.0 - rain_darkening, wet) * mix(1.0, 1.0 - rain_puddle_darkening, puddle);
		ROUGHNESS = mix(mix(ROUGHNESS, rain_wet_roughness, wet), 0.02, puddle);
		SPECULAR = mix(SPECULAR, 0.6, wet);
		// Les flaques sont plates : elles effacent le relief de la route
		global_normal = normalize(mix(global_normal, vec3(0.0, 1.0, 0.0), puddle));
		vec3 rain = rain_ripples(global_position.xz, TIME, rain_intensity, rain_drops_per_meter);
		float ripple = rain_ripple_strength * mix(0.35, 1.0, puddle) * wet;
		global_normal = normalize(global_normal + vec3(rain.x, 0.0, rain.y) * ripple);
	}
//@ all
	NORMAL = normalize((VIEW_MATRIX * vec4(global_normal, 0.0)).xyz);
}