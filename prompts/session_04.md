# Session 4 — RAG Godot, outils pour OpenCode, enregistreur

Modèle conseillé : Sonnet 5.5. Lis d'abord `CLAUDE.md` et `ETAT.md`.

## Objectif

Équiper Qwen dans OpenCode, sans jamais l'encadrer :

- un RAG de documentation ;
- les outils déterministes et les juges, exposés en MCP ;
- une fiche par compétence ;
- un enregistreur transparent des sessions.

## Livrables

1. **`usine/rag`**
   - Ingestion de la documentation Godot officielle (dépôt godot-docs, branche correspondant à 4.7 : pages rst et référence des classes), découpée en fragments avec source et titre.
   - Index SQLite FTS5 où la recherche exacte est prioritaire : `CharacterBody2D` doit sortir en tête.
   - Vecteurs sqlite-vec en option, désactivés par défaut ; ils pourront être calculés plus tard sur la machine via llama-server.
   - Construction de l'index exécutable hors-ligne, à partir d'une copie locale du dépôt.
   - Vérification automatique qu'aucune solution des jeux gelés n'entre dans l'index.
2. **`mcp_serveur`** (SDK MCP officiel en Python, transport stdio). Il expose : `vocab_lookup`, `search_docs`, `scene_read`, `scene_write`, `describe_project`, `apply_edits`, `check_script`, `load_scene`, `run_tests`.
   - Descriptions courtes : chaque outil déclaré coûte des jetons de prompt à chaque tour.
3. **`skills/`** : 13 fiches `SKILL.md`, une par compétence, courtes, au format des skills GodotPrompter. Chacune dit quand l'utiliser, le format d'entrée et de sortie, et l'outil juge à appeler.
4. **`outils/opencode_fusion.py`** : ajoute au `opencode.json` d'un projet l'entrée `mcp.usine-godot` et le chemin de `skills/`.
   - Ne touche ni à `godot-ai` ni aux autres entrées ; sauvegarde avant écriture.
   - Explique comment pointer le modèle d'OpenCode vers le proxy de capture par une surcharge dans le `opencode.json` du projet, sans modifier la config globale (elle est régénérée par un script de l'utilisateur).
5. **`usine/capture`** : un proxy HTTP OpenAI-compatible entre OpenCode et llama-server (port configurable, 8090 vers 8080 par défaut).
   - Il relaie à l'identique, y compris le streaming SSE, et n'altère jamais le contenu.
   - Il enregistre chaque échange en JSONL, au format de session de `CLAUDE.md`.

## Preuve de fin (dans le cloud)

- Un faux serveur OpenAI rejoue un échange scripté : le proxy le relaie octet pour octet et l'enregistre.
- Le serveur MCP répond à `list_tools` et à chaque outil sur `godot/reference`.
- `search_docs("CharacterBody2D")` renvoie la page de la classe en premier.
- `pytest` est vert.

## À livrer aussi

`VERIFIER_EN_LOCAL.md`, qui dit comment :

1. lancer le proxy ;
2. fusionner la config dans un projet de l'utilisateur ;
3. ouvrir OpenCode et demander une petite fonctionnalité ;
4. constater que Qwen appelle `scene_write` puis `run_tests` et que la session est enregistrée.

## Fin de session

Mettre à jour `ETAT.md`, puis committer et pousser.
