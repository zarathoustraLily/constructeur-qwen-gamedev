---
name: usine-d2-editions
description: D2 — Modifier un projet par une liste d'éditions JSON, tout ou rien. Quand une fonctionnalité touche plusieurs fichiers (nœuds, scripts, connexions) d'un projet existant.
---

# D2 — Modifier un projet par une liste d'éditions JSON, tout ou rien.

**Quand l'utiliser** : Quand une fonctionnalité touche plusieurs fichiers (nœuds, scripts, connexions) d'un projet existant.

**Entrée** : `describe_project` (ids `<scène>:<chemin>`), la demande.

**Sortie** : une liste pour `apply_edits(edits)`. Opérations : `add_node`, `del_node`, `set_property`, `attach_script`, `connect`, `disconnect`, `add_signal`, `add_function`, `replace_function`, `set_resource_value`.

```json
[{"op": "add_node", "parent": "main", "nom": "Minuteur", "type": "Timer", "proprietes": {"wait_time": 2.5}},
 {"op": "connect", "source": "main:Minuteur", "signal": "timeout", "cible": "main", "methode": "_on_minuteur_timeout"},
 {"op": "add_function", "script": "res://scripts/main.gd", "code": "func _on_minuteur_timeout() -> void:\n\tpass"}]
```

- Les ids viennent de `describe_project` ; un id inconnu refuse toute la liste.

**Juge** : `apply_edits` : validation, copie de travail jugée (import, scripts, scènes, tests), remplacement atomique seulement si tout passe.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
