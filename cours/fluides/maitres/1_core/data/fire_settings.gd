class_name FireSettings extends Resource
## Les réglages d'un feu : ce qui brûle, à quelle vitesse, ce que ça dégage.

## La température à partir de laquelle le carburant brûle.
@export_range(0.0, 10.0, 0.01) var ignition: float = 0.3
## Le carburant brûlé par seconde dans une case.
@export_range(0.0, 50.0, 0.1) var burn_rate: float = 3.0
## La chaleur rendue par unité de carburant brûlé.
@export_range(0.0, 20.0, 0.1) var heat: float = 2.0
## La suie laissée par unité de carburant brûlé.
@export_range(0.0, 5.0, 0.01) var soot_yield: float = 0.5
## La dilatation du gaz par unité de carburant brûlé.
@export_range(0.0, 5.0, 0.01) var expansion: float = 0.3
## La poussée de la chaleur, en cases par seconde² par degré.
@export_range(0.0, 100.0, 0.1) var buoyancy: float = 12.0
## Le poids de la suie, en cases par seconde² par unité.
@export_range(0.0, 100.0, 0.1) var soot_weight: float = 2.0
## La part de chaleur perdue par seconde.
@export_range(0.0, 10.0, 0.01) var cooling: float = 1.2
