class_name SphKernels extends RefCounted
## Les noyaux de SPH, en deux dimensions : comment une particule pèse sur ce qui l'entoure, selon la distance. Tous s'annulent à la
## portée `radius`, et au-delà : c'est ce qui permet de ne regarder que les voisines.


## Le poids d'une voisine à distance² `squared` : il sert à la densité. Son intégrale sur le disque vaut 1, et il ne demande pas de
## racine carrée, parce qu'on l'appelle pour chaque paire.
static func density_weight(squared: float, radius: float) -> float:
	var gap: float = radius * radius - squared
	return 4.0 / (PI * pow(radius, 8.0)) * gap * gap * gap if gap > 0.0 else 0.0


## La pente du noyau de pression à la distance `distance`. Elle ne s'annule pas au contact, contrairement au noyau de densité : deux
## particules collées se repoussent vraiment.
static func pressure_slope(distance: float, radius: float) -> float:
	var gap: float = radius - distance
	return -30.0 / (PI * pow(radius, 5.0)) * gap * gap if gap > 0.0 else 0.0


## Le laplacien du noyau de viscosité : toujours positif, il rapproche les vitesses sans jamais les écarter.
static func viscosity_curve(distance: float, radius: float) -> float:
	var gap: float = radius - distance
	return 40.0 / (PI * pow(radius, 5.0)) * gap if gap > 0.0 else 0.0
