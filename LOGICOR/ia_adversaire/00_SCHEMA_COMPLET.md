# Schéma complet de l'IA - LOGICOR

## Architecture

L'IA est un arbre de décision à 6 états, avec 3 sous-arbres :

```
                    ┌─────────────┐
                    │  ATTENTE    │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   MARQUER   │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   AVANCER   │◄────┐
                    └──────┬──────┘     │
                           │            │
                    ┌──────▼──────┐     │
                    │   FRAPPER   │─────┘
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │    MORT     │
                    └─────────────┘
```

## Les 6 états

| État | Condition d'entrée | Action | Transition |
|------|-------------------|--------|------------|
| `ATTENTE` | Pas de cible valide | Aucune | → `MARQUER` si cible |
| `MARQUER` | Cible valide | Cibler le joueur | → `AVANCER` |
| `AVANCER` | Cible en portée | Se déplacer vers la cible | → `FRAPPER` si proche, → `REPLI` si loin |
| `FRAPPER` | Cible à portée d'attaque | Attaquer | → `AVANCER` |
| `REPLI` | Cible trop loin | S'éloigner | → `ATTENTE` |
| `MORT` | PV ≤ 0 | Aucune | Terminal |

## Les 3 sous-arbres

### 1. MARQUER (BPC_AggroSense)

```gdscript
class_name BPC_AggroSense
extends RefCounted

var mark: Node = null
var distance_max: float = 600.0
var distance_min: float = 0.0

func marquer(cible: Node) -> void:
    mark = cible

func retirer_marque() -> void:
    mark = null

func en_portee(position_cible: Vector3, position_ennemi: Vector3) -> bool:
    if not mark:
        return false
    var dist: float = (position_cible - position_ennemi).length()
    return dist <= distance_max and dist >= distance_min

func cible_morte() -> bool:
    if not mark:
        return true
    if mark.has_method("est_mort"):
        return mark.est_mort()
    return not is_instance_valid(mark)
```

### 2. OUTILLER (BPC_WeaponManager)

```gdscript
class_name BPC_WeaponManager
extends RefCounted

var outils: Array = []
var outil_actuel: String = ""

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

func _condition_verifiee(when: String, distance: float, pv_cible: int, pv_max_cible: int) -> bool:
    match when:
        "toujours":
            return true
        "de_loin":
            return distance > 300.0
        "de_pret":
            return distance < 200.0
        "pv_bas":
            return pv_cible < int(float(pv_max_cible) * 0.3)
        "pv_haut":
            return pv_cible > int(float(pv_max_cible) * 0.7)
        _:
            return true
```

### 3. STADES (BPC_PhaseManager._verifier_stades)

```gdscript
func _verifier_stades() -> void:
    if stades.is_empty():
        return
    var fraction: float = float(pv_courant) / float(pv_max)
    for i in range(stades.size() - 1, -1, -1):
        var seuil: float = stades[i].get("seuil", 1.0)
        if fraction <= seuil:
            if i != stade_actuel:
                stade_actuel = i
            break
```

## Les 5 priorités d'arme

1. `force_interrompre` : L'arme est forcée par un événement.
2. `force_suivant` : L'arme est forcée pour le prochain coup.
3. `enchaîne` : L'arme est enchaînée avec la précédente.
4. `combo_actif` : L'arme fait partie du combo actif.
5. `options_arme` : L'arme est éligible et forcée par les options.

## Les stades (phases de boss)

| Stade | Seuil | Armes | Comportement |
|-------|-------|-------|--------------|
| 0 | 1.00 | Slam, Charge | Normal |
| 1 | 0.60 | TirRapide | Pressant |
| 2 | 0.30 | TirLoin, TirRapide | Furieux |
