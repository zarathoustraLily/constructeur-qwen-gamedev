---
name: usine-s1-scene
description: S1 — Construire une scène .tscn depuis des règles, via une spec JSON. Quand il faut créer ou refaire une scène (nœuds, propriétés, ressources, instances).
---

# S1 — Construire une scène .tscn depuis des règles, via une spec JSON.

**Quand l'utiliser** : Quand il faut créer ou refaire une scène (nœuds, propriétés, ressources, instances).

**Entrée** : les règles ; `scene_read` d'une scène voisine comme modèle.

**Sortie** : une spec JSON, écrite par `scene_write(chemin, spec)` (jamais de .tscn tapée à la main) :

```json
{"racine": {"nom": "Piege", "type": "Area2D", "script": "res://scripts/piege.gd",
  "enfants": [{"nom": "Forme", "type": "CollisionShape2D",
               "proprietes": {"shape": {"SubResource": "forme"}}}]},
 "ressources_internes": [{"nom": "forme", "type": "RectangleShape2D",
                          "proprietes": {"size": {"Vector2": [48, 16]}}}],
 "ressources_externes": [{"chemin": "res://scripts/piege.gd", "type": "Script"}]}
```

Valeurs typées : `{"Vector2": [x, y]}`, `{"Color": [r, g, b, a]}`, `{"ExtResource": "res://…"}`, `{"SubResource": "nom"}`.

**Juge** : `scene_write` valide la spec contre le vocabulaire, écrit sur une copie et n'applique que si `load_scene` passe ; puis `run_tests`.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
