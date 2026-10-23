# Beehave (IA : arbres de comportement en GDScript)

Version vérifiée : v2.9.3 (2026-08-18), GDScript pur, licence MIT, dépôt `bitbrain/beehave` (3 307 étoiles au
2026-10-22). Ses notes de version la disent compatible avec Godot 4.7. Exemple minimal vérifié dans Godot 4.7.2 :
`python -m usine.rag.plugins verifier beehave`.

## Ce qu'il résout

Un arbre de comportement fait de nœuds de scène : un `BeehaveTree` (qui « tique » à chaque image) contient des
composites (`SelectorComposite`, `SequenceComposite`, leurs variantes aléatoires et réactives,
`SimpleParallelComposite`), des décorateurs (`InverterDecorator`, `RepeaterDecorator`, `CooldownDecorator`,
`TimeLimiterDecorator`…) et des feuilles : conditions (`ConditionLeaf`) et actions (`ActionLeaf`). Chaque nœud rend
`SUCCESS`, `FAILURE` ou `RUNNING`. Un `Blackboard` (nœud) partage les données entre les feuilles.

## Le choisir, ou un autre ?

- **Godot seul** suffit pour une machine à états simple.
- **Beehave** : tout est en GDScript, lisible et modifiable, et l'arbre se compose dans l'éditeur comme une scène.
- **LimboAI** est plus rapide (C++) et ajoute des machines à états hiérarchiques ; à préférer pour beaucoup
  d'agents.
- Les deux ne cohabitent pas : Beehave déclare `class_name Blackboard`, LimboAI enregistre une classe native
  `Blackboard`. Avec les deux dans un projet, Godot 4.7.2 refuse le script de Beehave : « Parse Error: Class
  "Blackboard" hides a native class » (`res://addons/beehave/blackboard.gd:2`, vérifié).

## API (lue dans le code de la v2.9.3)

- `BeehaveTree` : propriétés `actor`, `blackboard`, `enabled`, `tick_rate`, `process_thread` (`IDLE`, `PHYSICS`,
  `MANUAL`) ; `tick()`, `interrupt()`, `enable()`, `disable()` ; signaux `tree_enabled`, `tree_disabled`.
- Feuilles et composites : redéfinir `tick(actor: Node, blackboard: Blackboard) -> int`, et au besoin
  `before_run(actor, blackboard)`, `after_run(actor, blackboard)`.

## Installation

1. Copier `addons/beehave/`.
2. Activer le plugin : il ajoute les autoloads `BeehaveGlobalMetrics`
   (`res://addons/beehave/metrics/beehave_global_metrics.gd`) et `BeehaveGlobalDebugger`
   (`res://addons/beehave/debug/global_debugger.gd`). Sans le second, un `BeehaveTree` échoue à son `_ready`
   (`get_node("BeehaveGlobalDebugger")`).

## Exemple minimal (vérifié)

`exemple/exemple.gd` : un sélecteur essaie une séquence « cible visible → poursuivre », sinon patrouille. La cible
devient visible à l'image 5. Après 10 images : 4 patrouilles, puis 5 poursuites.

```gdscript
class CibleVisible extends ConditionLeaf:
	func tick(actor: Node, _blackboard: Blackboard) -> int:
		return SUCCESS if bool(actor.get("cible_visible")) else FAILURE
```

## Pièges (relevés par l'exemple)

- Lancé par le binaire de l'éditeur sans débogueur attaché (un test sans fenêtre, par exemple), Beehave écrit
  « ERROR: Can't send message. No active debugger » à chaque image, et « ERROR: Capture not registered:
  'beehave'. » : il ne vérifie que `OS.has_feature("editor")` avant d'envoyer ses messages
  (`debug/debugger_messages.gd`). Ces lignes viennent du plugin, pas du jeu. Dans un jeu exporté, ou lancé depuis
  l'éditeur avec son débogueur, elles disparaissent.
- Une feuille lit l'acteur sans le connaître : `actor.get("cible_visible")` rend un `Variant`, à convertir
  (`bool(...)`, `int(...)`) quand les avertissements sont des erreurs.
