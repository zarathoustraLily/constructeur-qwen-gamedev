# Health, HitBoxes, HurtBoxes (santé, dégâts et zones de coups, 2D et 3D)

Version vérifiée : v5.0.4 (2026-07-21), GDScript pur, licence MIT, dépôt
`cluttered-code/godot-health-hitbox-hurtbox` (174 étoiles au 2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 :
`python -m usine.rag.plugins verifier health_hitbox_hurtbox`.

## Ce qu'il résout

Le combat par composants :
- `Health` (nœud) : points de vie, dégâts, soins, mort, résurrection, modificateurs par type d'action ;
- `HitBox3D` / `HitBox2D` (`Area3D` / `Area2D`) : la zone qui frappe ; à l'entrée d'une zone qui encaisse, elle lui
  applique ses actions (`HealthAction`) ;
- `HurtBox3D` / `HurtBox2D` : la zone qui encaisse, reliée à une `Health`, avec des multiplicateurs ;
- `HitScan3D` / `HitScan2D` (`RayCast3D` / `RayCast2D`) : les tirs instantanés ;
- les variantes `Basic…` règlent le cas courant : une action de dégâts (ou de soin) d'un montant donné.

## Le choisir, ou Godot seul ?

- **Godot seul** : une `Area3D` dont le signal `area_entered` appelle une méthode `take_damage` suffit ; c'est ce
  que font les composants du roguelike de nos cours (`1_core/components/`).
- **Le plugin** : quand il faut des types de dégâts (cinétique, poison…), des multiplicateurs par zone (tête,
  armure), du soin, la mort et la résurrection signalées, en 2D comme en 3D, sans réécrire ces composants.

## API (lue dans le code de la v5.0.4)

- `Health` : `current`, `max`, `damageable`, `healable`, `killable`, `revivable`, `entity`, `modifiers` ;
  `damage(amount, incrementer, multiplier, type)`, `heal(…)`, `kill()`, `fill()`, `is_dead()`, `is_alive()`,
  `is_full()`, `percent()` ; signaux `damaged(entity, type, amount, incrementer, multiplier, applied)`, `healed`,
  `died`, `revived`, `first_hit`, `full`, `not_damageable`, `already_dead`…
- `HitBox3D` : `actions`, `ignore_collisions` ; signaux `hurt_box_entered`, `action_applied`, `hit_box_entered`,
  `unknown_area_entered`. `BasicHitBox3D` : `affect` (`DAMAGE` ou soin), `amount`.
- `HurtBox3D` : `health`, `modifiers`. `BasicHurtBox3D` : `damage_multiplier`, `heal_multiplier`,
  `heal_on_damage`, `damage_on_heal`.

## Installation

Copier `addons/health_hitbox_hurtbox/`. Aucun autoload.

## Exemple minimal (vérifié)

`exemple/exemple.gd` : deux sphères qui se recouvrent ; la zone qui frappe (3 dégâts) entre dans la zone qui
encaisse. Mesuré : santé 7/10, un seul signal `damaged`, avec 3 points appliqués.

```gdscript
var encaisse := BasicHurtBox3D.new()
encaisse.health = _sante
var frappe := BasicHitBox3D.new()
frappe.amount = 3
```

## Pièges

- Le coup part du signal `area_entered` : une seule fois à l'entrée, pas à chaque image du recouvrement (mesuré :
  un seul `damaged` en 10 images). Pour des dégâts continus, il faut sortir puis rentrer, ou appeler
  `Health.damage` soi-même.
- Les deux zones doivent se voir : calque de la zone qui encaisse dans le masque de celle qui frappe (ici, les
  valeurs par défaut).
