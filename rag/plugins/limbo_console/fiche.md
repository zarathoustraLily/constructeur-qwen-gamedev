# Limbo Console (console de développement dans le jeu)

Version vérifiée : v0.8.0 (2026-06-20), GDScript, licence MIT, dépôt `limbonaut/limbo_console` (428 étoiles au
2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 : `python -m usine.rag.plugins verifier limbo_console`.

## Ce qu'il résout

Une console qui s'ouvre pendant la partie (comme celle de Quake) : on y tape des commandes déclarées par le code
(`degats 5`, `teleporter 10 0 3`, `vague 7`), avec l'autocomplétion, l'historique et des alias. Pratique pour
tester un niveau, une vague ou un réglage sans refaire tout le chemin jusqu'à lui. D'après l'article « Best Godot
Plugins in 2026 » (ziva.sh), une option la retire des versions finales (non vérifié ici).

## Le choisir, ou Godot seul ?

- **Godot seul** : des raccourcis clavier de débogage dans un script de développement suffisent pour deux ou trois
  actions.
- **Limbo Console** : quand les actions de test se multiplient, avec des arguments, et qu'on veut les enchaîner
  dans un script de commandes (`execute_script`).

## API (lue dans le code de la v0.8.0)

- Autoload `LimboConsole` : `register_command(callable, nom, description)`, `unregister_command`,
  `has_command(nom)`, `get_command_names()`, `execute_command(ligne, silent)`, `execute_script(fichier)`,
  `add_alias(alias, commande)`, `add_argument_autocomplete_source(commande, argument, source)`.
- Affichage : `info`, `warn`, `error`, `debug`, `print_line`, `print_boxed`, `clear_console()`.
- Fenêtre : `open_console()`, `close_console()`, `toggle_console()`, `is_open()` ; signal `toggled(is_shown)`.

## Installation

1. Copier `addons/limbo_console/`.
2. Activer le plugin : il ajoute l'autoload `LimboConsole` (`res://addons/limbo_console/limbo_console.gd`).

## Exemple minimal (vérifié)

`exemple/exemple.gd` : la commande `degats` prend un entier ; `execute_command("degats 5")` fait passer la santé de
20 à 15.

```gdscript
LimboConsole.register_command(_degats, "degats", "retire des points de vie au joueur")
LimboConsole.execute_command("degats 5")

func _degats(montant: int) -> void:
	_sante -= montant
```

## Pièges

- Le type des arguments vient de la signature de la méthode : `montant: int` reçoit l'entier 5 (mesuré).
- C'est un outil de développement : les commandes ne remplacent pas les tests, elles aident à les préparer.
