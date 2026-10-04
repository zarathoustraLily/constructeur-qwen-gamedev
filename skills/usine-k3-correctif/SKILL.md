---
name: usine-k3-correctif
description: K3 — Corriger un test rouge par un patch minimal. Quand un test échoue et que son journal pointe un comportement faux.
---

# K3 — Corriger un test rouge par un patch minimal.

**Quand l'utiliser** : Quand un test échoue et que son journal pointe un comportement faux.

**Entrée** : le test rouge, son journal (`run_tests`), le code.

**Sortie** : le plus petit changement qui rend le test vert, par `apply_edits` (`replace_function`) ou une édition de ligne.

- Trouver la cause (comparaison, constante, signe, appel oublié) avant de modifier.
- Ne jamais modifier le test ni désactiver une assertion. Quelques lignes au plus.

**Juge** : `run_tests` : vert, sans régression ; patch sous la taille plafond.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
