# LimboAI (IA : arbres de comportement et machines à états)

Version vérifiée : v1.8.1 (2026-08-20), GDExtension compilée pour 4.6 (`compatibility_minimum = "4.2"`), licence
MIT, dépôt `limbonaut/limboai` (3 074 étoiles au 2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 :
`python -m usine.rag.plugins verifier limboai`.

## Ce qu'il résout

Deux outils d'IA écrits en C++, pilotés en GDScript :
- une **machine à états hiérarchique** : `LimboHSM` (elle-même un `LimboState`) contient des `LimboState`, reliés par
  des transitions nommées par des événements ;
- des **arbres de comportement** : une ressource `BehaviorTree` dont la racine est une tâche (`BTSequence`,
  `BTSelector`, des actions `BTAction`…), jouée par un nœud `BTPlayer`, avec un tableau noir (`Blackboard`) partagé.

Le code natif est rapide ; l'éditeur ajoute un éditeur visuel d'arbres et un débogueur.

## Le choisir, ou Godot seul ?

- **Godot seul** suffit pour une machine à états simple : un nœud par état et un script qui change d'état (comme
  dans le roguelike de nos cours, `1_core/state_machine/`).
- **LimboAI** sert quand l'IA grandit : beaucoup d'ennemis, des comportements composés (patrouiller, poursuivre,
  attaquer, fuir), un arbre à régler sans toucher au code, ou un débogage visuel de l'IA.
- Beehave fait la même chose en GDScript pur : plus facile à lire et à modifier, plus lent à grande échelle.

## API vérifiée (classes enregistrées dans 4.7.2)

- `LimboHSM` : `add_transition(from_state, to_state, event, guard)`, `initialize(agent, parent_scope)`,
  `set_active(active)`, `get_active_state()`, `change_active_state(state)`, `anystate()` ; signal
  `active_state_changed`.
- `LimboState` : `named(name)`, `dispatch(event, cargo)`, `add_event_handler(event, handler)`, `call_on_enter`,
  `call_on_exit`, `call_on_update`, `set_guard(guard_callable)`, `get_blackboard()` ; à redéfinir : `_setup()`,
  `_enter()`, `_exit()`, `_update(delta)` ; signaux `entered`, `exited`, `updated`.
- `BTPlayer` : propriété `behavior_tree`, `set_active`, `set_scene_root_hint(scene_root)`, `get_blackboard()`,
  `restart()` ; signal `behavior_tree_finished`.
- `BTTask` (et `BTAction`) : à redéfinir `_tick(delta) -> Status` (renvoie `SUCCESS`, `FAILURE` ou `RUNNING`),
  `_enter()`, `_exit()`, `_setup()` ; `get_blackboard()`, `get_agent()`.
- `Blackboard` : `get_var(var_name, default, complain)`, `set_var(var_name, value)`, `has_var(var_name)`.

## Installation

Copier `addons/limboai/` (le dossier `bin/` contient les bibliothèques de chaque plateforme et
`limboai.gdextension`). Rien à activer : Godot charge l'extension au premier import du projet.

## Exemple minimal (vérifié)

`exemple/exemple.gd` : une `LimboHSM` passe de « Patrouille » à « Poursuite » sur l'événement `cible_vue`, et un
`BTPlayer` joue une séquence qui contient une action. Après 10 images : état actif « Poursuite », action jouée
9 fois.

```gdscript
_hsm.add_transition(_patrouille, _poursuite, &"cible_vue")
add_child(_hsm)
_hsm.initialize(self)
_hsm.set_active(true)
_hsm.dispatch(&"cible_vue")
```

## Pièges (relevés par l'exemple)

- Un `BTPlayer` créé par le code n'a pas de propriétaire : « Failed to detect scene root - can't initialize ». Lui
  donner la racine avec `set_scene_root_hint(self)` avant de l'ajouter à l'arbre (ou un `owner`).
- `Blackboard.get_var` se plaint d'une variable absente (« Variable "passages" not found ») : passer `complain =
  false` en troisième argument quand l'absence est normale.
- `initialize(agent)` se fait après l'ajout de la `LimboHSM` à l'arbre, puis `set_active(true)`.
- LimboAI et Beehave ne cohabitent pas : la classe native `Blackboard` de LimboAI fait refuser celle de Beehave
  (« Parse Error: Class "Blackboard" hides a native class », vérifié dans 4.7.2). Choisir l'un des deux.
