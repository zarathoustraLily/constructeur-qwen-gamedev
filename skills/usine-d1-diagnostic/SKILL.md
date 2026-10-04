---
name: usine-d1-diagnostic
description: D1 — Lire un journal Godot et désigner la catégorie d'erreur et sa ligne exacte. Quand Godot affiche une erreur (SCRIPT ERROR, Parse Error, Invalid call, Node not found…) et qu'il faut la localiser.
---

# D1 — Lire un journal Godot et désigner la catégorie d'erreur et sa ligne exacte.

**Quand l'utiliser** : Quand Godot affiche une erreur (SCRIPT ERROR, Parse Error, Invalid call, Node not found…) et qu'il faut la localiser.

**Entrée** : le journal moteur (sortie de `run_tests`, `load_scene` ou du jeu).

**Sortie** : `{"categorie": "...", "fichier": "res://…", "ligne": N}`. Catégories : `parse_error`, `null_instance`, `invalid_node_path`, `signal_missing`, `type_error`, `test_failure`, `missing_resource`, `autre`.

- Prendre la ligne du script du projet (`at: … (res://…:N)`), pas celle d'un addon.
- La première erreur est souvent la cause, les suivantes ses conséquences.

**Juge** : Comparaison exacte avec la cause connue (catégorie, fichier, ligne).

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
