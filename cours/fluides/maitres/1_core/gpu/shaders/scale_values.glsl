#[compute]
#version 450

// Multiplie chaque valeur du tampon par `factor`. La carte lance les invocations par groupes de 64, en parallèle.
layout(local_size_x = 64) in;

// Les valeurs, lues et réécrites sur place.
layout(set = 0, binding = 0, std430) restrict buffer Values {
	float data[];
} values;

// Les constantes poussées : quelques octets posés à chaque lancement, sans créer de tampon.
layout(push_constant, std430) uniform Constants {
	float factor;
} constants;

// Une invocation par valeur. Le dernier groupe déborde quand la taille n'est pas un multiple de 64 : on n'écrit pas au-delà.
void main() {
	uint index = gl_GlobalInvocationID.x;
	if (index < values.data.length()) {
		values.data[index] *= constants.factor;
	}
}
