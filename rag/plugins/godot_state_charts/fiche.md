# Godot State Charts (machines à états hiérarchiques, en nœuds)

Version vérifiée : v0.22.5 (2026-06-26), GDScript pur, licence MIT, dépôt `derkork/godot-statecharts` (1 623
étoiles au 2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 : `python -m usine.rag.plugins verifier
godot_state_charts`.

## Ce qu'il résout

Des diagrammes d'états (statecharts) faits de nœuds : un `StateChart` contient un seul état racine, qui contient
des états. Un `CompoundState` n'a qu'un enfant actif à la fois, un `ParallelState` les a tous ; un `AtomicState` est
une feuille ; un `HistoryState` revient au dernier état quitté. Les transitions (`Transition`) sont des nœuds enfants
de l'état qu'elles quittent : un événement (`event`), une cible (`to`), un délai, une garde (`Guard`,
`ExpressionGuard`, `StateIsActiveGuard`, `AllOfGuard`, `AnyOfGuard`, `NotGuard`). La hiérarchie et le parallélisme
évitent l'explosion du nombre d'états d'une machine à plat.

## Le choisir, ou Godot seul ?

- **Godot seul** : une machine à états simple (un nœud par état, comme `1_core/state_machine/` du roguelike de nos
  cours) suffit tant que les états ne se combinent pas.
- **Godot State Charts** : quand un personnage a plusieurs dimensions d'état en même temps (se déplacer et viser,
  arme et posture), des sous-états, ou des transitions temporisées et gardées, le tout visible dans l'arbre de la
  scène.
- Pour l'IA de nombreux agents, LimboAI (machines hiérarchiques et arbres de comportement en C++) est plus rapide.

## API (lue dans le code de la v0.22.5)

- `StateChart` : `send_event(event)`, `set_expression_property(nom, valeur)`, `get_expression_property(nom)`,
  `step()`, `freeze()`, `thaw()` ; signal `event_received(event)`.
- États (`StateChartState`) : propriété `active` ; signaux `state_entered`, `state_exited`, `state_processing(delta)`,
  `state_physics_processing(delta)`, `state_input(event)`, `state_unhandled_input(event)`, `event_received`,
  `transition_pending`.
- `CompoundState` : `initial_state` (chemin vers l'état de départ) ; signaux `child_state_entered`,
  `child_state_exited`.
- `Transition` : `event`, `to`, `guard`, `delay_in_seconds` ; signal `taken`.
- États prêts à l'emploi pour l'animation : `AnimationPlayerState`, `AnimationTreeState`. Sauvegarde :
  `StateChartSerializer`.

## Installation

Copier `addons/godot_state_charts/`. Aucun autoload : les nœuds s'emploient dès que le dossier est dans le projet.

## Exemple minimal (vérifié)

`exemple/exemple.gd` : « Patrouille » → « Poursuite » sur l'événement `cible_vue`, envoyé à l'image 3. À l'image
10 : « Poursuite » est actif et n'a été entré qu'une fois.

```gdscript
var vers_poursuite := Transition.new()
vers_poursuite.event = &"cible_vue"
vers_poursuite.to = NodePath("../../Poursuite")
patrouille.add_child(vers_poursuite)
racine.initial_state = NodePath("Patrouille")
_diagramme.send_event(&"cible_vue")
```

## Pièges (relevés par l'exemple)

- Un `CompoundState` créé par le code n'a pas d'état initial : « No initial state set for state 'Racine' ». Le
  donner avec `initial_state` avant d'ajouter le diagramme à l'arbre (l'éditeur le remplit seul).
- Le chemin `to` d'une transition part de la transition elle-même : depuis `Patrouille/VersPoursuite`,
  `../../Poursuite`.
- Un `StateChart` exige exactement un enfant, et un état : sinon « StateChart must have exactly one child ».
- L'état initial n'est entré qu'après le `_ready` du diagramme (`_enter_initial_state.call_deferred()`, lu dans
  `state_chart.gd`, non mesuré) : un événement envoyé dans ce même `_ready` arriverait avant tout état actif.
