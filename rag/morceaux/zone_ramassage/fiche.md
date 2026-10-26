# Couches et masques de collision : une zone que seul le joueur déclenche

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier zone_ramassage`.

## Ce que fait le morceau

Une pièce (`Area3D`) surveille la couche « joueur » par son masque et n'est sur aucune couche. Un ennemi qui la traverse ne la déclenche pas ; le joueur, oui : elle émet `collected` puis se libère.

## Quand l'employer

Objets à ramasser, déclencheurs de porte ou de cinématique, zones de dégâts, points de passage.

Dans un projet qui suit le plan : la scène et son script dans `3_entities/pickups/<objet>/` ; couches et masques posés dans la scène, pas dans le script (le script de `3_entities/` n'écrit aucun nombre, règle DAT-01) ; noms des couches dans `project.godot` (ceux du socle : decor, joueur, ennemis, tirs_joueur, tirs_ennemis).

## Le code (`project.godot`, extrait vérifié)

```ini
[layer_names]

3d_physics/layer_1="decor"
3d_physics/layer_2="joueur"
3d_physics/layer_3="ennemis"
3d_physics/layer_4="tirs_joueur"
3d_physics/layer_5="tirs_ennemis"
```

## Le code (`3_entities/pickups/coin/coin.gd`, vérifié)

```gdscript
class_name Coin
extends Area3D
## Pièce à ramasser : seul le joueur la ramasse. Couches et masque sont posés dans coin.tscn : la zone surveille la
## couche « joueur » (masque) et n'est elle-même sur aucune couche. Émet : collected (le niveau compte le score, la vue
## joue le son).

signal collected


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node3D) -> void:
	collected.emit()
	queue_free()
```

## Le code (`3_entities/pickups/coin/coin.tscn`, vérifié)

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://3_entities/pickups/coin/coin.gd" id="1_coin"]

[sub_resource type="SphereShape3D" id="SphereShape3D_zone"]
radius = 1.0

[node name="Coin" type="Area3D"]
collision_layer = 0
collision_mask = 2
script = ExtResource("1_coin")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("SphereShape3D_zone")
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : ennemi (couche 3) dans la zone, 0 ramassage ; joueur (couche 2) : ramassée après 2 image(s) de physique, pièce libérée.

## Pièges

- La zone détecte un corps si son **masque** contient la **couche** du corps (mesuré : ennemi sur la couche 3, aucune détection ; joueur sur la couche 2, détecté).
- Dans la scène, `collision_mask = 2` est un champ de bits : la couche 2 vaut 2, la couche 3 vaudrait 4 ; en code, `set_collision_mask_value(2, true)` prend le numéro (référence des classes, `CollisionObject3D`).
- Un corps qui entre dans la zone n'est vu qu'après des images de physique : 2 ici (mesuré : 0 ramassage tout de suite) ; la liste des corps d'une zone change une fois par pas de physique (référence des classes, `Area3D.get_overlapping_bodies`). Un test attend `physics_frame` avant de conclure.
