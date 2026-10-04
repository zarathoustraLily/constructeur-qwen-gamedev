---
name: usine-c2-tests
description: C2 — Écrire les tests GdUnit4 qui vérifient des règles, rouges avant l'implémentation. Quand on a des règles (C1) et qu'il faut les tests avant le code.
---

# C2 — Écrire les tests GdUnit4 qui vérifient des règles, rouges avant l'implémentation.

**Quand l'utiliser** : Quand on a des règles (C1) et qu'il faut les tests avant le code.

**Entrée** : les règles JSON et le projet.

**Sortie** : des suites GdUnit4 dans `res://tests/` (`extends GdUnitTestSuite`, fonctions `test_…`), au moins un test par règle, nommé d'après la règle.

- Instancier les scènes avec `auto_free(load(...).instantiate())`, ajouter à l'arbre si `_ready` compte.
- Tester un comportement, pas un détail d'implémentation : un mutant du code doit faire échouer au moins un test.
- Avant l'implémentation, les nouveaux tests doivent être **rouges**.

**Juge** : `run_tests("res://tests/<suite>.gd")` : les suites se chargent, au moins un test par règle, rouges au départ.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
