# CLAUDE.md — constructeur-qwen-gamedev

## Mission

Construire une **usine** qui fabrique des données vérifiées pour entraîner un LoRA de **Qwen3.8-27B** sur **13 compétences étroites** de développement Godot, puis mesurer honnêtement le gain obtenu.

Qwen travaille dans **OpenCode**. L'usine l'équipe d'outils et trie ses sessions. On commence par Godot ; Unreal 5.8 réutilisera la même usine plus tard.

Le document de conception (lecture humaine) est ici : https://claude.ai/code/artifact/076d696f-40e9-4330-9182-ee98631fb470. Ce fichier en est le résumé exécutable. En cas de doute, **ce fichier fait foi**.

## Où tourne quoi

| Lieu | Ce qui s'y passe |
| --- | --- |
| Session cloud (toi) | Écrire le code, les tests et les simulations. Linux, **sans GPU, sans Qwen, sans Windows, sans OpenCode**. |
| Machine de l'utilisateur | Tout le reste. Windows 11, RTX 5090 32 Go, 64 Go de RAM, bientôt **hors-ligne**. Le dépôt y arrive via un mini-PC (`git pull`), puis une clé USB. |

Conséquences :

- **Tout ce qui dépend de Qwen, d'OpenCode ou de Windows est livré avec deux choses** :
  - une simulation testée dans le cloud (faux serveur OpenAI-compatible, échanges rejoués) ;
  - une procédure `VERIFIER_EN_LOCAL.md` (commandes cmd.exe et résultat attendu). Côté machine, c'est elle qui fait foi.
- **Code multiplateforme** : `pathlib`, aucun chemin en dur. Tous les chemins de la machine vont dans `config.toml`, dont le modèle est `config.example.toml`.
- **Aucune dépendance réseau à l'exécution.** Les dépendances Python sont listées dans `requirements.txt`, pour une installation hors-ligne par wheelhouse.
- **Godot dans le cloud** : télécharger Godot 4.7.2 Linux (headless) depuis les releases officielles si le réseau le permet. Sinon, marquer les tests moteur `skip` et le noter dans `ETAT.md`. Ne jamais versionner le binaire.

## Machine de l'utilisateur (faits vérifiés)

- **Godot 4.7.2 headless** : `D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`. Le dossier porte le nom de l'exe ; l'éditeur est l'exe sans `_console`.
- **Projets Godot existants** : `D:\GODOT\projet_hades`, `projet_starfox`, `projet_mario`.
- **`D:\GODOT\AGENTS.md`** fixe déjà les conventions d'OpenCode : un `plan.md` à cocher, rester loin de ~80 000 jetons de contexte, confier les explorations lourdes à un subagent. Ne pas le contredire.
- **llama-server** (llama.cpp, build d'août 2026) :
  - API OpenAI-compatible sur `http://127.0.0.1:8080/v1`, **un seul serveur à la fois** ;
  - modèle Qwen3.8-27B GGUF Q4, architecture hybride `qwen35` ;
  - pour OpenCode, le lanceur coupe le raisonnement (`--reasoning off --reasoning-budget 0 --no-prefill-assistant`), sinon OpenCode boucle ;
  - ne jamais passer `-ngl` : ce build refuse de démarrer, il faut laisser le placeur automatique.
- **Plusieurs LoRA** : llama-server en charge plusieurs (`--lora a.gguf --lora b.gguf`) et accepte un champ `lora` par requête (`[{"id": 0, "scale": 1.0}]`). Il sait contraindre la sortie par schéma JSON ou grammaire GBNF.
- **OpenCode** : application de bureau 2.0.6 ; l'utilisateur n'utilise que la GUI.
  - Ordre de lecture de la config, la dernière source gagne : `~/.config/opencode/opencode.json`, puis `opencode.jsonc`, puis le `opencode.json` du dossier de travail. Aucune variable d'environnement n'est lue.
  - Les serveurs MCP se déclarent dans le `opencode.json` du projet :
    `"mcp": {"<nom>": {"type": "local", "enabled": true, "command": ["exe", "arg"], "timeout": 120000}}`
  - Les skills se déclarent avec `"skills": {"paths": ["..."]}`.
  - Les outils MCP apparaissent via le Code Mode : `tools["<nom>"].outil({...})`.
  - La v2 n'exécute ni les plugins v1 ni le LSP.
- **Déjà installés** : le serveur MCP `godot-ai` (47 outils, ports 8000/9500) et les 57 skills GodotPrompter. Nos outils s'ajoutent, ils ne remplacent rien.
- **Entraînement** : un QLoRA rang 16 a déjà été entraîné et fusionné sur ce poste avec LLaMA-Factory (modèle de rétro-ingénierie). Unsloth est l'alternative. Les bases HF sont dans `G:\llm_lora_trainer\`.

## Règles non négociables

1. **Équiper Qwen, jamais le gouverner.** Aucune boucle de contrôle autour d'OpenCode à l'usage, aucun découpage forcé en tâches, aucun minuteur qui coupe une session. Le portillon et le juge servent uniquement à trier les données d'entraînement.
2. **Déterministe d'abord.** Aucun LLM dans les juges, le portillon, les traducteurs ni les générateurs de vérité terrain.
3. **Juges hors de portée.** Les tests cachés d'une tâche ne sont jamais dans l'espace que l'agent peut modifier ; on les copie au moment de juger.
4. **Jeux de test gelés avant tout entraînement.**
   - 50 à 100 tâches par compétence, avec leur empreinte SHA-256.
   - Exclues de l'entraînement comme du RAG, avec dédoublonnage par fragments de texte.
5. **Corriger le générateur, jamais la sortie.** Une tâche ou une donnée fausse se répare dans le code qui l'a produite.
6. **Vocabulaire réel uniquement.** Toute classe, propriété, signal ou méthode Godot se vérifie dans `extension_api.json`. Ne rien inventer.
7. **Édition atomique.** Toute modification de projet se fait sur une copie de travail, remplacée de façon atomique seulement si le juge passe. Sinon la copie est jetée. Leçon tirée d'Unreal : un « non sauvé » qui reste modifié en mémoire n'est pas un rollback.
8. **Processus.** Ne tuer que les PID lancés par notre code, jamais par motif de ligne de commande.
9. **Pas de réseau à l'exécution** et pas d'appel externe ; le seul serveur LLM est local. Exception : le script optionnel de référence frontière (session 6), jamais lancé automatiquement.
10. **Langue** : commentaires, messages et documents en français ; identifiants cohérents dans chaque module.

## Les 13 compétences

| ID | Entrée → sortie | Juge (sans LLM) | Mode |
| --- | --- | --- | --- |
| C1 | Demande → règles JSON (étant donné / quand / alors / observable) | Schéma valide ; les observables existent dans le vocabulaire | Un appel |
| C2 | Règles → tests GdUnit4 | Ils se chargent ; au moins 1 test par règle ; rouges au départ ; tuent les mutants | Agentique |
| S1 | Règles → spec de scène JSON | Écrivain `.tscn`, puis chargement headless | Un appel |
| S2 | Scène + règles → connexions `source.signal → cible.méthode` | Le signal et la méthode existent (arité), la connexion est présente | Un appel |
| S3 | Chiffres de design → `.tres` ou table | Schéma, chargement, bornes | Un appel |
| K1 | Interface → `.gd` avec méthodes vides | `--check-only`, gdlint, signatures identiques | Un appel |
| K2 | Contrat + tests rouges → corps de méthode | Tests visés verts, aucune régression | Agentique |
| K3 | Test rouge + log → patch minimal | Vert, sans régression, patch sous une taille plafond | Agentique |
| K4 | Script + rapport lint/complexité → refactor | Tests verts, métrique améliorée | Agentique |
| D1 | Log moteur → catégorie + fichier:ligne | Étiquette connue d'avance (bug injecté) | Un appel |
| D2 | Description du projet → liste d'éditions | Applicateur déterministe, puis tests | Agentique |
| F1 | Cible chiffrée → valeurs de réglage | Test en physique déterministe (mesures en frames) | Un appel |
| F2 | Signal de jeu → widget mis à jour | Test headless qui lit le widget | Agentique |

Hors catalogue : le game design, le « fun », le rendu et l'animation n'ont pas de juge exact. Ils restent des décisions de l'utilisateur.

## Formats communs (extensibles sans casser)

**Verdict** — tout juge renvoie ceci :

```json
{"ok": false, "etape": "run_tests", "duree_s": 1.8,
 "erreurs": [{"fichier": "res://scripts/hero.gd", "ligne": 42,
              "categorie": "null_instance", "message": "..."}],
 "tests": {"total": 6, "passes": 5, "echecs": ["test_dash_iframes"]}}
```

Catégories d'erreur de départ : `parse_error`, `null_instance`, `invalid_node_path`, `signal_missing`, `type_error`, `test_failure`, `autre`.

**Tâche** — un dossier par tâche :

```
donnees/taches/<competence>/<id>/
  tache.json      {id, competence, consigne, origine, empreinte, gelee}
  depart/         projet Godot de départ (copié à chaque essai)
  reference/      solution de référence (jamais montrée à l'agent)
  tests_caches/   tests du juge (copiés seulement au moment de juger)
```

**Session enregistrée** — JSONL, une ligne par message au format chat OpenAI (`role`, `content`, `tool_calls`, `tool_call_id`). Une ligne d'en-tête porte `{tache_id, competence, verdict_final}`.

## Arborescence cible

```
usine/            paquet Python
  vocab/          extension_api.json → SQLite ; vocab_lookup
  juge/           check_script, load_scene, run_tests → verdict
  scene/          spec ↔ .tscn (déterministe)
  projet/         describe_project, apply_edits
  generateurs/    aller_retour, masquage, mutation, mutants, inverse, invention
  portillon/      règles d'acceptation, gel, dédoublonnage
  capture/        proxy OpenAI-compatible → sessions JSONL
  rft/            essais, filtre, export SFT, conversion GGUF, lanceur multi-LoRA
  mesure/         4 configurations, GameDevBench, rapport
  rag/            documentation Godot → SQLite FTS5 (+ sqlite-vec en option) ; search_docs
mcp_serveur/      serveur MCP (stdio) qui expose les outils
skills/           une fiche par compétence (SKILL.md)
godot/reference/  projet Godot de référence + GdUnit4
outils/           scripts d'installation et de fusion de config
donnees/          (ignoré par git) tâches, sessions, jeux gelés, index
tests/            pytest
prompts/          les 6 prompts de session
ETAT.md           journal de reprise
```

## Mesure (résumé)

- **Pour chaque compétence**, sur son jeu gelé, avec le même prompt, la même grammaire et le même budget, on compare quatre configurations : Qwen de base ± RAG, Qwen + LoRA ± RAG.
- **Score** : réussite au premier essai selon le juge, avec un intervalle de Wilson à 95 %.
- **Victoire étroite** : les deux conditions à la fois.
  - LoRA + RAG dépasse base + RAG au-delà de l'intervalle.
  - LoRA + RAG atteint ou dépasse la référence frontière, mesurée sans adaptation et avec le même RAG.
- **Après chaque tour**, on rejoue les 13 jeux gelés : aucune compétence ne doit reculer.

## Manière de travailler dans une session

- **Lire** `CLAUDE.md`, `ETAT.md`, puis le prompt de la session (`prompts/session_0N.md`). Ne pas rediscuter les décisions de ce fichier.
- **Une session = un livrable + sa preuve de fin**, exécutée et collée dans `ETAT.md`.
- **Budget** : la session est payée par un crédit limité.
  - Pas d'exploration hors sujet.
  - Pas de recherche web, sauf pour vérifier une version ou une option en ligne de commande.
- **Fin de session** : mettre à jour `ETAT.md` (fait, preuve, reste à faire, pièges), puis committer et pousser sur la branche de la session.
