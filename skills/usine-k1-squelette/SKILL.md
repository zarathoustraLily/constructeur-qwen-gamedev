---
name: usine-k1-squelette
description: K1 — Écrire le squelette .gd d'une interface : signatures typées, corps vides. Quand une interface (signaux, variables, méthodes) est donnée et que le script n'existe pas encore.
---

# K1 — Écrire le squelette .gd d'une interface : signatures typées, corps vides.

**Quand l'utiliser** : Quand une interface (signaux, variables, méthodes) est donnée et que le script n'existe pas encore.

**Entrée** : l'interface (noms, types, arguments, retours, `class_name`, `extends`).

**Sortie** : le script avec chaque déclaration exacte et des corps minimaux (`pass`, ou `return` d'une valeur du bon type).

- GDScript typé : `func take_damage(amount: int) -> void:` ; `signal died` ; `@export var speed: float = 120.0`.
- `extends` sur une classe réelle (`vocab_lookup`).

**Juge** : `check_script` sans erreur ; signatures identiques à l'interface.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
