---
name: usine-f1-reglages
description: F1 — Trouver les valeurs de réglage qui atteignent une cible chiffrée (vitesse, distance, durée en frames). Quand une cible de game feel est donnée en nombres (ex. 120 px en 30 frames) et qu'il faut régler des `@export`.
---

# F1 — Trouver les valeurs de réglage qui atteignent une cible chiffrée (vitesse, distance, durée en frames).

**Quand l'utiliser** : Quand une cible de game feel est donnée en nombres (ex. 120 px en 30 frames) et qu'il faut régler des `@export`.

**Entrée** : la cible, les paramètres réglables (`@export` du script), la physique (60 images/s par défaut).

**Sortie** : les valeurs, posées par `set_property` (nœud) ou dans le script.

- Calculer avant d'essayer : distance = vitesse × frames / 60 ; durée d'un minuteur = frames / 60.
- Respecter le type (`float`) et les bornes des `@export_range`.

**Juge** : Test en physique déterministe qui mesure en frames (`run_tests`).

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
