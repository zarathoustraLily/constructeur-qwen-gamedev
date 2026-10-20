# Le sous-arbre AVANCER - Mouvement vers la cible

## Rôle

Le sous-arbre AVANCER est responsable du mouvement de l'ennemi vers la cible. Il calcule la direction et applique la vitesse.

## Les variables

| Variable | Type | Description |
|----------|------|-------------|
| `vitesse` | `float` | La vitesse de déplacement (unités/seconde). |
| `portee` | `float` | La portée d'attaque (distance min pour frapper). |
| `portee_buffer` | `float` | Le buffer de portée (marge de sécurité). |

## Le calcul

```gdscript
var direction: Vector3 = (position_cible - position_ennemi).normalized()
var deplacement: Vector3 = direction * vitesse * delta
position_ennemi += deplacement
```

## La condition de transition

```gdscript
var dist: float = (position_cible - position_ennemi).length()
if dist <= portee + portee_buffer:
    etat = Etat.FRAPPER
elif dist > distance_max:
    etat = Etat.REPLI
```

## Exemple d'utilisation

```gdscript
# Dans _physics_process
if etat == Etat.AVANcER:
    var dir: Vector3 = (cible.global_position - global_position).normalized()
    velocity = dir * fiche.vitesse
    move_and_slide()
    
    var dist: float = (cible.global_position - global_position).length()
    if dist <= fiche.portee + fiche.portee_buffer:
        etat = Etat.FRAPPER
```
