---
name: usine-s3-donnees
description: S3 — Traduire des chiffres de design en ressource .tres ou en table de données. Quand il faut fixer des valeurs de jeu (PV, vitesses, vagues) dans des données plutôt que dans le code.
---

# S3 — Traduire des chiffres de design en ressource .tres ou en table de données.

**Quand l'utiliser** : Quand il faut fixer des valeurs de jeu (PV, vitesses, vagues) dans des données plutôt que dans le code.

**Entrée** : les chiffres, leurs bornes et la classe de ressource visée (script `extends Resource` avec `@export`).

**Sortie** : un `.tres` (ou les éditions `set_resource_value` sur un `.tres` existant) dont chaque propriété existe et respecte ses bornes.

- Types exacts : `int` sans décimale, `float` avec, `Vector2(...)`.
- Une valeur hors bornes se corrige dans la demande, pas en silence.

**Juge** : `apply_edits` (validation des propriétés), `load_scene`/`run_tests` qui lisent la ressource.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
