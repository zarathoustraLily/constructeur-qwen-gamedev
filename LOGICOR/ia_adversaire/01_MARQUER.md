# Le sous-arbre MARQUER - BPC_AggroSense

## Rôle

Le sous-arbre MARQUER est responsable du ciblage. Il détermine si l'ennemi a une cible valide et si la cible est en portée.

## Les variables

| Variable | Type | Description |
|----------|------|-------------|
| `mark` | `Node` | La cible actuelle (null si aucune). |
| `distance_max` | `float` | La portée maximale de détection. |
| `distance_min` | `float` | La portée minimale de détection. |

## Les méthodes

### `marquer(cible: Node)`

Définit la cible actuelle.

```gdscript
func marquer(cible: Node) -> void:
    mark = cible
```

### `retirer_marque()`

Retire la cible actuelle.

```gdscript
func retirer_marque() -> void:
    mark = null
```

### `en_portee(position_cible: Vector3, position_ennemi: Vector3) -> bool`

Vérifie si la cible est en portée.

```gdscript
func en_portee(position_cible: Vector3, position_ennemi: Vector3) -> bool:
    if not mark:
        return false
    var dist: float = (position_cible - position_ennemi).length()
    return dist <= distance_max and dist >= distance_min
```

### `cible_morte() -> bool`

Vérifie si la cible est morte.

```gdscript
func cible_morte() -> bool:
    if not mark:
        return true
    if mark.has_method("est_mort"):
        return mark.est_mort()
    return not is_instance_valid(mark)
```

## Exemple d'utilisation

```gdscript
var aggro := BPC_AggroSense.new(600.0, 0.0)
aggro.marquer(player)
if aggro.en_portee(player.global_position, self.global_position):
    print("Cible en portée")
if aggro.cible_morte():
    aggro.retirer_marque()
```
