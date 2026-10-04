---
name: usine-k2-corps
description: K2 — Écrire le corps d'une méthode d'après son contrat et des tests rouges. Quand une méthode existe (signature et doc ##) mais que son corps manque, et que des tests la visent.
---

# K2 — Écrire le corps d'une méthode d'après son contrat et des tests rouges.

**Quand l'utiliser** : Quand une méthode existe (signature et doc ##) mais que son corps manque, et que des tests la visent.

**Entrée** : le contrat (`##` au-dessus de la fonction), les tests rouges, le script.

**Sortie** : le corps seulement, par `apply_edits` avec `replace_function` + `corps` (la signature et la doc restent).

- Lire les tests visés avant d'écrire ; ne pas toucher aux tests.
- Un exemple de démo qui compile (`search_docs(..., source="exemples")`) vaut mieux qu'un souvenir d'API.

**Juge** : `run_tests` : les tests visés passent, aucun autre ne casse.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
