# CLAUDE.md — constructeur-qwen-gamedev

## Règles qui priment

Demande de laurent du 2026-10-14 : deux séries de règles s'imposent au dépôt.

- **Celles du projet « Poursuivre le projet de laurent »**, tirées de son mode d'emploi (état au 2026-10-11) : sections 1 à 4.
- **Celles de la passe « bâtiments procéduraux »** (2026-10-13 et 14) : sections 5 à 7.

Elles l'emportent sur le reste de ce fichier, sur le code et sur les documents du dépôt : quand le reste les contredit, c'est le reste qu'on corrige. Chaque point a un statut : **décidé** (laurent l'a validé : on l'applique), **proposé** (on le présente comme tel et on attend son accord), **ouvert** (on ne le tranche pas sans lui). Ne jamais présenter une proposition comme une décision de laurent.

### 1. Travailler avec laurent (décidé)

- Réponses courtes, en français, qui commencent par la réponse ; chaque affirmation est sourcée.
- Tout se discute dans le fil principal, jamais dans des sous-fils.
- Pas de discussion de PR ni de git : les opérations nécessaires se font sans en faire un sujet ; seule la demande d'accord reste, en une phrase.
- Feu vert : quand laurent réfléchit, on ne construit rien ; on attend son accord explicite.
- On explique ce qu'on veut faire avant de demander une autorisation (dossier, dépôt, outil).
- Rien ne se lance sur son PC ni sur son llama-server sans son accord, pas même un rejeu court.
- Pendant une campagne : ne jamais modifier `D:\constructeur-qwen-gamedev` ni `D:\GODOT\projet_starfox` ; personne d'autre n'utilise llama-server.

### 2. Décisions de laurent (décidé)

1. Tester en conditions réelles, sur des campagnes Starfox propres, avec LoRA seulement ; plus de tâches mises de côté pour des tests : « je m'en fous des tests, je teste en réel dans des conditions propres ».
2. Garder les domaines et les compétences, et les diviser en sujets : gameplay, VFX, shaders, optimisation, gestion de la mémoire, UI, contrôle à la manette, audio, physique, graphisme 3D et 2D, procédural, plugins et leur usage, création de tests.
3. Dans chaque sujet, 50 % de création depuis une description et 50 % de débogage : « ça permet au LoRA d'apprendre la construction et le débogage ». Le partage se compte en jetons de réponse (choix du 2026-10-13).
4. Réflexes à apprendre : tester après chaque modification (`check_script`, puis `run_tests` ou `load_scene`) ; plusieurs captures par phase ; ne pas refaire un travail déjà validé ; le RAG pour des suggestions ; vérifier le gameplay avant la requête suivante. Lui donner une béquille.
5. Le plan d'organisation fourni en contexte prime sur ce que le modèle a appris.
6. Le gameplay s'enseigne par des boucles de test sur des suites de captures.
7. Jugement visuel : une base de problèmes, avec des jeux créés pour ça (collision, caméra…).
8. laurent crée 3 ou 4 jeux d'un seul niveau qui mêlent les compétences ; Qwen apprend à les coder morceau par morceau.
9. Un RAG beaucoup mieux construit, avec des conseils de plugins et d'effets.
10. Trouver une parade aux réécritures identiques.
11. Optimisation et gameplay font partie des sujets.
12. Godot 4.7.2 (2026-10-06). Ordre de la béquille (2026-10-09) : retour des outils, socle et plan, déclaration d'action, mesure par campagnes, entraînement.
13. Position du 2026-10-08 : ne pas raccourcir les résultats d'outils ni découper les sessions longues sans en reparler avec lui ; le LoRA apprend un cheminement.
14. Le harnais d'usage est OpenCode (2026-10-14, réponse à « Quel harnais retenez-vous pour l'usage ? » : « open code »). Les données d'entraînement prennent ses outils et son format (section 7, règle 4).

### 3. Pièges et interdits (décidé)

- Jamais dans les données : une session avec une réécriture identique, une modification non testée ou sans vérification du gameplay.
- L'export garde le texte de chaque tour qui contient un appel d'outil (sans lui, le LoRA t1 n'écrit plus rien) ; le plan reste dans le prompt d'entraînement.
- Le harnais vérifie après la dernière écriture : la campagne V2 a été cassée par sa dernière action.
- Partir d'un projet qui suit déjà le plan : Starfox a son propre dossier `scripts/`.
- Pas de campagne sans LoRA.
- Pas d'alias dans `apply_edits` : décision de conception du dépôt, pas de laurent (accepter `nom` ou `function` changerait les notes des jeux gelés).
- Ne pas fusionner la branche de travail sans l'accord de laurent ni la vérification locale ; ne pas écraser les corrections V2 non commitées de son PC.

### 4. Points ouverts (ne pas trancher sans laurent)

- Les 221 tâches déjà gelées : les verser à l'entraînement découle de la décision 1, mais reste à confirmer ; d'ici là elles restent exclues (règle 4).
- La compétence longue « de bout en bout » ; un entraînement sur des requêtes courtes, puis longues.
- Les huit points à trancher des règles d'architecture (2D et 3D, format des données…) et la place de `6_assets/` hors des décors procéduraux.
- L'origine des réécritures identiques.

### 5. Vérification (passe « bâtiments procéduraux »)

1. Toute sortie de Godot citée est réelle : Godot 4.7.2 lancé sur l'état exact du projet. On n'en retire que les lignes vides, les lignes d'information (version, pilote) et les avertissements propres à la machine (V-Sync, cache de shaders).
2. Toute preuve est relue dans sa source : signatures dans `extension_api.json` du binaire 4.7.2, descriptions dans la référence des classes à l'étiquette `4.7.2-stable`, documentation dans `godot-docs` (branche stable), noms de Godot 3 dans `editor/project_upgrade/renames_map_3_to_4.cpp`.
3. Les avertissements de GDScript sont des erreurs, typage compris : `untyped_declaration`, `narrowing_conversion`, `integer_division`, `unused_*`, `shadowed_*`… à 2 dans le bloc `[debug]` de `project.godot`. Cela vaut pour les projets qui suivent le plan (socle, cours). Les jeux sources des 221 tâches gelées gardent leurs réglages : les changer toucherait aux tâches gelées, dont le sort est ouvert (section 4).
4. Un shader ne se compile qu'au rendu : après tout changement de shader, une image en Compatibilité (`--rendering-method gl_compatibility`).
5. On lit chaque ligne de sortie : un test peut finir avec le code 0 et contenir des « SCRIPT ERROR ».
6. Sur une erreur de shader, la ligne « at: » fait foi : quand le shader contient des `#include`, Godot 4.7.2 décale l'extrait affiché d'une ligne par `#include` placé au-dessus de l'erreur.
7. Une consigne d'édition cite un passage unique dans le fichier au moment où on l'applique ; rejouées à la lettre, les consignes redonnent le code attendu.
8. Les jetons se comptent avec le tokenizer de Qwen 3.8 et son gabarit de chat, lus dans son GGUF (le modèle de laurent ou son vocabulaire seul), jamais par une estimation en caractères. Le `ggml-vocab-qwen35.gguf` des tests de llama.cpp est un autre vocabulaire (151 936 jetons, contre 248 320).

### 6. Décors procéduraux : rangement

| Quoi | Où |
| --- | --- |
| Générateurs `@tool` et leurs scènes | `6_assets/Mesh/Procedural/<famille>/` |
| Shaders | `6_assets/Shader/Procedural/<famille>/` |
| Données : palettes, listes, cotes (scripts de constantes) | `5_data/DECORS/<famille>/` |
| Outils communs : maillage, fonctions de shader partagées | `1_core/procedural/`, `6_assets/Shader/Procedural/` |
| Tests | `7_tests/`, en miroir du chemin testé |

Les générateurs peuvent connaître `1_core/` et `5_data/`. Ailleurs, `5_data/` et `6_assets/` restent sans code. Le juge des règles applique ce tableau (`usine/structure/regles.py`, table `DECORS`) ; les autres règles d'architecture, typage des tableaux et des dictionnaires compris (COD-02), s'appliquent aussi aux décors.

### 7. Données d'entraînement (passe « bâtiments procéduraux »)

1. Le 50/50 de la décision 3 se compte en jetons de réponse, étape par étape.
2. Une réponse n'écrit jamais la sortie d'une commande : la sortie réelle arrive dans le message suivant. Le débogage suit les vagues de Godot : une faute de syntaxe cache le reste de l'analyse, un shader s'arrête à sa première erreur, certaines fautes n'apparaissent qu'à l'exécution.
3. Une faute n'apparaît dans une réponse que comme le texte à remplacer.
4. Les outils des données sont ceux du harnais d'usage, OpenCode (décision 14) : avant l'entraînement, commandes et éditions sont converties en ses appels d'outils, texte gardé (t1 a appris `read_file` et `write_file`, absents d'OpenCode).
5. Chaque exemple tient sous `cutoff_len` (32 768 jetons sur la B300) : aucun n'est tronqué.
6. Données sans raisonnement : `enable_thinking: false`. Sinon, avec le gabarit `qwen3_8`, LLaMA-Factory entraîne un bloc de réflexion vide sous la consigne « Reasoning effort is set to xhigh », et le LoRA apprend à ne pas réfléchir.
7. Une case de la grille n'écrase pas les autres : d'une base volumineuse, on ne garde qu'une part.

## Mission

Construire une **usine** qui fabrique des données vérifiées pour entraîner un LoRA de **Qwen3.8-27B** sur **15 compétences étroites** de développement Godot, puis mesurer honnêtement le gain obtenu.

Qwen travaille dans **OpenCode**, le harnais d'usage (« Règles qui priment », décision 14). L'usine l'équipe d'outils et trie ses sessions. On commence par Godot ; Unreal 5.8 réutilisera la même usine plus tard.

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
4. **Jeux gelés : on n'en crée plus** (décision 1 de laurent : le test qui fait foi est la campagne en conditions réelles, avec LoRA).
   - Les 221 tâches déjà gelées gardent leur empreinte SHA-256.
   - Elles restent exclues de l'entraînement comme du RAG, avec dédoublonnage par fragments de texte, tant que laurent n'a pas décidé de les verser à l'entraînement (point ouvert).
5. **Corriger le générateur, jamais la sortie.** Une tâche ou une donnée fausse se répare dans le code qui l'a produite.
6. **Vocabulaire réel uniquement.** Toute classe, propriété, signal ou méthode Godot se vérifie dans `extension_api.json`. Ne rien inventer.
7. **Édition atomique.** Toute modification de projet se fait sur une copie de travail, remplacée de façon atomique seulement si le juge passe. Sinon la copie est jetée. Leçon tirée d'Unreal : un « non sauvé » qui reste modifié en mémoire n'est pas un rollback.
8. **Processus.** Ne tuer que les PID lancés par notre code, jamais par motif de ligne de commande.
9. **Pas de réseau à l'exécution** et pas d'appel externe ; le seul serveur LLM est local. Exception : le script optionnel de référence frontière (session 6), jamais lancé automatiquement.
10. **Langue** : commentaires, messages et documents en français ; identifiants cohérents dans chaque module.

## Les 15 compétences

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
| E | Jeu 2D non optimisé → même jeu, plus efficace (optimisation stricte) | Comportement intact (tests), rendu intact (réglages et signature de l'affichage), 0 allocation après l'échauffement, lots de dessin ≤ référence × 1,05, temps ≤ référence × 1,15 | Agentique |
| O1 | Jeu qui se comporte mal en partie → correctif minimal, trouvé en observant des parties | Séquences scriptées rejouées sans fenêtre à cadence fixe, monde de vérité de la référence : gravité, hauteur, sous le sol, traversée d'obstacle, enfouissement du bas visible, caméra (dans le champ, au-dessus du sol, derrière la marche) ; patch plafonné | Agentique |

E (ajoutée le 2026-10-05, spécification de laurent) : la tâche contient un départ naïf et une référence optimisée, vérifiés identiques en comportement et en rendu à la génération. Les seuils sont relatifs à la référence, sauf les allocations (0). En headless, les draw calls valent 0 : les lots de dessin sont comptés dans l'arbre de la scène. Le temps est mesuré au moment de juger, sur la même machine, et seulement pour les tâches qui le déclarent. Détails : `usine/efficience/`.

O1 (ajoutée le 2026-10-20, demande de laurent : « corriger en observant ») : un bug de gameplay injecté (le kart vole, traverse un arbre, s'enfonce à moitié dans la route en tournant, la caméra le filme de face) est trouvé en jouant. L'outil `play_sequence` joue une séquence scriptée et dit quelles règles de partie cassent, à quelle image et sur quel objet. « Regarder la partie » se fait par des mesures exactes, image par image. Le monde de vérité (formes de collision de la référence, posées en fantôme) rend visible une collision retirée. Les seuils sont réglés pour que la référence passe ; le portillon exige un départ rouge à l'étape observation. Première source : le kart (`[sources]` de config.toml). Détails : `usine/observation/`.

Hors catalogue : le game design, le « fun », le rendu et l'animation n'ont pas de juge exact. Ils restent des décisions de l'utilisateur.

Grille (décisions 2 et 3 de laurent) : chaque compétence se décline par sujet ; dans chaque case, moitié création, moitié débogage, comptées en jetons de réponse.

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
  efficience/     compétence E : mesure headless (allocations, lots, rendu, temps), rendu intact, juge
  observation/    compétence O1 : parties scriptées sans fenêtre, monde de vérité, règles de partie, juge
  rag/            doc Godot 4.7 + démos officielles 4.7 qui compilent → SQLite FTS5 (+ sqlite-vec en option) ; search_docs
  cours/          cours en étapes : maîtres balisés → un projet Godot par étape ; juge et vérification Godot ;
                  base/ : base d'entraînement tirée du cours, au format d'OpenCode (création et débogage,
                  sorties réelles de Godot)
cours/            sources des cours (maîtres, notes, manifeste) : batiments_proceduraux/ (3 villes × 13 étapes)
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

Le test qui fait foi est la campagne en conditions réelles (décision 1). La mesure qui suit reste dans le code ; elle ne se lance que si laurent la demande.

- **Pour chaque compétence**, sur son jeu gelé, avec le même prompt, la même grammaire et le même budget, on compare quatre configurations : Qwen de base ± RAG, Qwen + LoRA ± RAG.
- **Score** : réussite au premier essai selon le juge, avec un intervalle de Wilson à 95 %.
- **Victoire étroite** : les deux conditions à la fois.
  - LoRA + RAG dépasse base + RAG au-delà de l'intervalle.
  - LoRA + RAG atteint ou dépasse la référence frontière, mesurée sans adaptation et avec le même RAG.
- **Après chaque tour**, on rejoue les 15 jeux gelés : aucune compétence ne doit reculer.

## Manière de travailler dans une session

- **Lire** `CLAUDE.md`, `ETAT.md`, puis le prompt de la session (`prompts/session_0N.md`). Ne pas rediscuter les décisions de ce fichier.
- **Une session = un livrable + sa preuve de fin**, exécutée et collée dans `ETAT.md`.
- **Budget** : la session est payée par un crédit limité.
  - Pas d'exploration hors sujet.
  - Pas de recherche web, sauf pour vérifier une version ou une option en ligne de commande.
- **Fin de session** : mettre à jour `ETAT.md` (fait, preuve, reste à faire, pièges), puis committer et pousser sur la branche de la session.
