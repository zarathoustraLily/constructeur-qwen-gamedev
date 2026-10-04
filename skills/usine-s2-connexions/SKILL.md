---
name: usine-s2-connexions
description: S2 — Relier les signaux d'une scène aux méthodes (source.signal → cible.méthode). Quand un comportement dépend d'un signal qui n'est pas encore connecté.
---

# S2 — Relier les signaux d'une scène aux méthodes (source.signal → cible.méthode).

**Quand l'utiliser** : Quand un comportement dépend d'un signal qui n'est pas encore connecté.

**Entrée** : la scène (`describe_project` donne les ids de nœuds) et les règles.

**Sortie** : des éditions `connect`, appliquées par `apply_edits` :

```json
[{"op": "connect", "source": "ghost", "signal": "died", "cible": "main", "methode": "_on_ghost_died"}]
```

- Le signal existe sur la source (`vocab_lookup` ou `signal` du script) ; la méthode existe sur la cible avec le bon nombre d'arguments (sinon l'ajouter avec `add_function`).
- Préférer la connexion déclarée dans la scène à `connect()` dans `_ready`.

**Juge** : `apply_edits` refuse un signal ou une méthode inconnus (arité comprise), puis lance les tests.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
