# Le sous-arbre OUTILLER - Choix d'arme

## Rôle

Le sous-arbre OUTILLER est responsable du choix de l'arme. Il sélectionne l'outil le plus approprié en fonction de la distance, des PV de la cible, et des conditions.

## Les variables

| Variable | Type | Description |
|----------|------|-------------|
| `outils` | `Array` | La liste des outils disponibles. |
| `outil_actuel` | `String` | Le nom de l'outil actuellement utilisé. |

## Les 5 priorités

| # | Priorité | Description |
|---|----------|-------------|
| 1 | `force_interrompre` | L'arme est forcée par un événement (ex: boss enrage). |
| 2 | `force_suivant` | L'arme est forcée pour le prochain coup (ex: enchaînement). |
| 3 | `enchaîne` | L'arme est enchaînée avec la précédente (ex: combo). |
| 4 | `combo_actif` | L'arme fait partie du combo actif. |
| 5 | `options_arme` | L'arme est éligible et forcée par les options. |

## Le choix

```gdscript
func choisir(distance: float, pv_cible: int, pv_max_cible: int) -> String:
    if outils.is_empty():
        return ""
    for outil in outils:
        var nom: String = outil.get("nom", "")
        var when: String = outil.get("when", "toujours")
        var portee: float = outil.get("portee", 100.0)
        if _condition_verifiee(when, distance, pv_cible, pv_max_cible):
            if distance <= portee:
                outil_actuel = nom
                return nom
    return outil_actuel
```

## Les conditions

| Condition | Description |
|-----------|-------------|
| `toujours` | L'outil est toujours disponible. |
| `de_loin` | L'outil est disponible si la distance > 300. |
| `de_pret` | L'outil est disponible si la distance < 200. |
| `pv_bas` | L'outil est disponible si PV cible < 30%. |
| `pv_haut` | L'outil est disponible si PV cible > 70%. |

## Exemple d'utilisation

```gdscript
var outils := [
    {"nom": "Slam", "when": "toujours", "portee": 120.0},
    {"nom": "Charge", "when": "toujours", "portee": 400.0},
    {"nom": "TirLoin", "when": "de_loin", "portee": 800.0},
]
var outil := BPC_WeaponManager.new(outils)
var nom: String = outil.choisir(distance, pv_cible, pv_max_cible)
```
