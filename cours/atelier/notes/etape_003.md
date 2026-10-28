# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Les briques de tout jeu d'action : une santé qui encaisse et soigne, une machine à états
qui fait passer une entité d'un comportement à l'autre, et une première entité qui s'en sert.

Ce qu'on obtient : un mannequin d'entraînement. Un coup l'étourdit et le fait pencher ; il se redresse ; à zéro
point de vie, il tombe et ne réagit plus.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Ouvrir `3_entities/training_dummy/training_dummy.tscn` pour voir le mannequin et ses enfants.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. L'ordre d'exécution, nommé

`1_core/process_order.gd` donne un nom à chaque priorité : les entrées, puis les composants, puis la logique
des entités, puis les vues, puis la caméra. Un nœud prend la sienne (`process_physics_priority`,
`process_priority`) ; jamais un nombre écrit sur place.

### 2. La santé, un composant

`1_core/components/health_component.gd` garde les points de vie. `take_damage` refuse un coup nul, un coup
pendant le répit, un coup après la mort ; il ne retire jamais plus que ce qui reste, ouvre le répit
d'invincibilité, émet `damaged`, et `died` une seule fois. `heal` ne dépasse pas le maximum et ne relève pas un
mort. Le répit se décompte dans `tick`, appelé à chaque image de physique : un test peut l'appeler lui-même.
Le maximum et le répit viennent d'un `.tres` de `5_data`.

### 3. Une machine à états générique

`1_core/state_machine/state.gd` : un état a `enter`, `exit`, `physics_update`, et demande le suivant par le
signal `finished`. `1_core/state_machine/state_machine.gd` prend ses enfants `State` comme états, entre dans
l'état initial, ne fait tourner que l'état actif, et change d'état sur `finished` ou `transition_to` (qui refuse
un état inconnu ou déjà actif, et annonce le changement par `state_changed`).

### 4. Le mannequin : logique, états, vue

`3_entities/training_dummy/training_dummy.gd` relie sa santé à sa machine : un coup qui laisse des points de
vie fait passer à Hit, la mort à Defeated. `dummy_hit_state.gd` décompte l'étourdissement puis demande Idle.
`training_dummy_view.gd` lit l'état et penche la vue vers l'inclinaison voulue, avec un amortissement
exponentiel (`1 - exp(-vitesse × delta)`) : le même mouvement à 30 ou à 144 images par seconde. La vue montre
l'état ; elle ne le décide jamais.
