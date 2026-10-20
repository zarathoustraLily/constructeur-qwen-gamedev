# Le sous-arbre FRAPPER - Attaque

## Rôle

Le sous-arbre FRAPPER est responsable de l'attaque. Il choisit l'arme à utiliser et applique les dégâts.

## Les variables

| Variable | Type | Description |
|----------|------|-------------|
| `outils` | `Array` | La liste des outils disponibles. |
| `outil_actuel` | `String` | Le nom de l'outil actuellement utilisé. |
| `cooldown` | `float` | Le temps de recharge de l'outil. |

## Le choix d'outil

Le choix d'outil est délégué à `BPC_WeaponManager.choisir()`.

```gdscript
var outil := BPC_WeaponManager.new(fiche.outils)
var nom_outil: String = outil.choisir(distance, pv_cible, pv_max_cible)
```

## L'application des dégâts

```gdscript
var degats: int = BPC_DegratsPipeline.calculer(
    base = outil_degat,
    mult = 1.0,
    additif = 0,
    est_crit = BPC_DegratsPipeline.est_critique(pv_cible, pv_max_cible),
    mult_crit = 3.0
)
cible.prendre_degrats(degats, self)
```

## La transition

```gdscript
# Après l'attaque, retourner à AVANCER.
etat = Etat.AVANcER
```

## Exemple d'utilisation

```gdscript
# Dans _physics_process
if etat == Etat.FRAPPER:
    var outil := BPC_WeaponManager.new(fiche.outils)
    var nom_outil: String = outil.choisir(distance, pv_cible, pv_max_cible)
    if nom_outil != "":
        var degats: int = _calculer_degats(nom_outil)
        cible.prendre_degrats(degats, self)
        etat = Etat.AVANcER
```
