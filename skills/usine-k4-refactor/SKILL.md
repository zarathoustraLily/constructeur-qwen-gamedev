---
name: usine-k4-refactor
description: K4 — Restructurer un script pour améliorer une métrique (lint, complexité) sans changer son comportement. Quand un rapport de lint ou de complexité signale un script, et que des tests le couvrent.
---

# K4 — Restructurer un script pour améliorer une métrique (lint, complexité) sans changer son comportement.

**Quand l'utiliser** : Quand un rapport de lint ou de complexité signale un script, et que des tests le couvrent.

**Entrée** : le script, le rapport (règle, ligne, métrique), les tests.

**Sortie** : le script réécrit (`replace_function`, `add_function`) : extraction de fonctions, retours anticipés, constantes nommées, types explicites.

- Mêmes signatures publiques, mêmes signaux.
- Une étape à la fois, `run_tests` entre deux.

**Juge** : `run_tests` vert et métrique améliorée.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
