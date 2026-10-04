---
name: usine-c1-regles
description: C1 — Transformer une demande de jeu en règles testables (étant donné / quand / alors / observable), en JSON. Quand la demande décrit un comportement de jeu à implémenter ou à tester, avant d'écrire le code ou les tests.
---

# C1 — Transformer une demande de jeu en règles testables (étant donné / quand / alors / observable), en JSON.

**Quand l'utiliser** : Quand la demande décrit un comportement de jeu à implémenter ou à tester, avant d'écrire le code ou les tests.

**Entrée** : la demande, en langage courant.

**Sortie** : un tableau JSON, une règle par comportement observable :

```json
[{"id": "R1", "etant_donne": "le héros a 3 PV", "quand": "il touche un fantôme",
  "alors": "il perd 1 PV et devient invulnérable 0,5 s",
  "observable": [{"noeud": "Hero", "classe": "CharacterBody2D", "membre": "hp"}]}]
```

- Un observable est une propriété, un signal ou une méthode qui existe : classe native vérifiée par `vocab_lookup(classe, membre)`, ou variable/signal d'un script du projet (`describe_project`).
- Pas de règle sur le rendu, le « fun » ou l'animation : ils n'ont pas de juge exact.

**Juge** : Le JSON se lit, et chaque observable existe (`vocab_lookup`, `describe_project`).

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
