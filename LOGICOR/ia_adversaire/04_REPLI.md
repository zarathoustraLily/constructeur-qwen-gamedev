# Le sous-arbre REPLI - Fuite

## Rôle

Le sous-arbre REPLI est responsable de la fuite. L'ennemi s'éloigne de la cible si elle est trop loin ou s'il est en danger.

## Les variables

| Variable | Type | Description |
|----------|------|-------------|
| `repli_seuil` | `float` | Le seuil de PV sous lequel l'ennemi fuit. |
| `distance_max` | `float` | La portée maximale de détection. |

## La condition d'entrée

```gdscript
# Entrer en REPLI si :
# 1. La cible est trop loin (> distance_max).
# 2. Les PV de l'ennemi sont sous repli_seuil.
if dist > distance_max:
    etat = Etat.REPLI
elif pv_ennemi < int(float(pv_max_ennemi) * repli_seuil):
    etat = Etat.REPLI
```

## Le mouvement

```gdscript
# S'éloigner de la cible.
var direction: Vector3 = (position_ennemi - position_cible).normalized()
var deplacement: Vector3 = direction * vitesse * delta
position_ennemi += deplacement
```

## La transition

```gdscript
# Sortir de REPLI si :
# 1. La cible est morte.
# 2. Les PV sont récupérés (> repli_seuil).
if cible_morte():
    etat = Etat.ATTENTE
elif pv_ennemi > int(float(pv_max_ennemi) * repli_seuil):
    etat = Etat.AVANcER
```

## Exemple d'utilisation

```gdscript
# Dans _physics_process
if etat == Etat.REPLI:
    var dir: Vector3 = (global_position - cible.global_position).normalized()
    velocity = dir * fiche.vitesse
    move_and_slide()
    
    if cible.est_mort():
        etat = Etat.ATTENTE
    elif stats.vie > int(float(stats.vie_max) * fiche.repli_seuil):
        etat = Etat.AVANcER
```
