---
name: usine-f2-widget
description: F2 — Mettre à jour un widget d'interface quand un signal de jeu est émis. Quand le HUD ou un menu doit refléter un état de jeu (PV, pièces, vague).
---

# F2 — Mettre à jour un widget d'interface quand un signal de jeu est émis.

**Quand l'utiliser** : Quand le HUD ou un menu doit refléter un état de jeu (PV, pièces, vague).

**Entrée** : le signal de jeu (source, arguments), le widget (`Label`, `ProgressBar`…), la scène d'interface.

**Sortie** : la connexion (`connect`) et la méthode qui met à jour le widget (`add_function`), par `apply_edits`.

- Propriétés réelles du widget : `Label.text`, `ProgressBar.value`/`max_value` (`vocab_lookup`).
- Initialiser l'affichage dans `_ready` puis suivre le signal ; pas de mise à jour dans `_process`.

**Juge** : Test headless qui émet le signal puis lit le widget (`run_tests`).

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
