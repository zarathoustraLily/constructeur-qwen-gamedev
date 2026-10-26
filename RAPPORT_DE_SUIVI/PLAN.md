# Plan jusqu'à la fin du processus

Chaque étape a un identifiant (A1, B3…). Les durées sont des **estimations** en jours de travail d'une IA ; le temps
de machine (générations, entraînements) est donné à part. Les commandes marquées « à créer » n'existent pas encore :
les écrire fait partie de l'étape. Sources des décisions : `CLAUDE.md` (décisions 1 à 19, sections 3, 5, 7).

## Vue d'ensemble : six voies qui avancent en parallèle

| Voie | Étapes | Peut commencer |
| --- | --- | --- |
| A. Rattrapage | A1 à A6 | tout de suite (A1 attend la capture A5, faite par laurent) |
| B. Paires courtes, palier 1 (12 000 × 1 024) | B1 à B9 | tout de suite ; B6 attend A5 |
| C. Premier entraînement (5090) | C1 à C5 | C1 tout de suite ; C2 quand B1 à B4 sont vérifiées |
| D. Paires courtes, palier 2 (10 000 × 2 048) | D1 à D6 | tout de suite (D1, D2) ; D3 après B7 |
| E. Sessions OpenCode (3 000) | E1 à E5 | après A1, A2 et A5 |
| F. Mesure | F1 à F4 | après C4, puis après chaque étape d'entraînement |
| R. RAG (en continu) | R1 à R3 | tout de suite |
| G. Godot 4.8 | G1 à G3 | en attente de la version stable |

Avec trois IA en parallèle (une sur B1 à B5, une sur B7 puis D3, une sur A, D1, D2), le premier entraînement d'essai
(C2) devient possible en 3 à 4 jours, l'étape 1 complète en 1 à 1,5 semaine, l'étape 3 en 2,5 à 3 semaines
(estimation). Le goulot est la 5090 : générations Godot et entraînements passent l'un après l'autre.

---

## A. Rattrapage (ce qui devait être fini)

### A1 — Le plan dans les sessions au format d'OpenCode
- **Pourquoi** : 0 session sur 358 ne contient le plan ; la règle de la section 3 l'exige (constaté le 2026-10-22).
- **Dépend de** : A5 (savoir comment OpenCode transmet l'`AGENTS.md` d'un projet).
- **Faire** : dans `usine/cours/base/opencode.py`, insérer le bloc permanent du socle (`godot/socle_jeu/AGENTS.md`,
  « EN PERMANENCE ») exactement là et sous la forme où OpenCode le met.
- **Preuve** : `python -m usine.cours.base assembler --cours kart` puis un contrôle : 203/203 exemples contiennent le
  plan, à l'endroit capturé.
- **Vérification** : rejouer ; comparer le texte inséré à la capture de A5, caractère pour caractère.
- **Estimation** : 0,5 jour.

### A2 — Partage 40/40/20 dans l'assembleur
- **Pourquoi** : décision 3 modifiée le 2026-10-26 ; les bases sont au 50/50 sans analyse.
- **Faire** : un troisième type « analyse » dans `usine/cours/base/assembler.py` (lire une sortie, reconnaître,
  comparer, diagnostiquer) ; l'assembleur équilibre création, débogage et analyse à 40/40/20 en jetons de réponse,
  étape par étape (règle 7.1).
- **Preuve** : `controles.json` d'un cours affiche les trois parts, chacune à ± 3 points de la cible.
- **Vérification** : rejouer l'assemblage, recompter avec `usine/cours/base/jetons.py`.
- **Estimation** : 1 jour.

### A3 — Regénérer la base des bâtiments sur le PC
- **Pourquoi** : elle n'existe que dans le cloud, avec un générateur ancien.
- **Dépend de** : A1, A2.
- **Preuve** : `python -m usine.cours.base tout --cours batiments_proceduraux` ; `problèmes : 0`.
- **Machine** : environ 1 h de Godot (estimation). Accord de laurent.

### A4 — Espaces de fin des messages
- **Pourquoi** : le gabarit de Qwen 3.8 les retire, LLaMA-Factory (`qwen3_5`) les garde (seule différence relevée
  entre les deux rendus, essai du 2026-10-22).
- **Faire** : retirer les espaces de fin de chaque message à l'export.
- **Preuve** : rendu d'un exemple par le gabarit du GGUF (`opencode.rendre`) identique à l'entrée de LLaMA-Factory.
- **Estimation** : 0,25 jour.

### A5 — Capture d'une vraie session OpenCode (laurent)
- **Pourquoi** : débloque A1, B6, E et la forme des images. Forme réelle d'un appel MCP dans `execute` (Code Mode),
  chargement de l'`AGENTS.md`, transmission d'une image à llama-server.
- **Qui** : laurent sur son PC, avec le proxy de l'usine (`usine/capture`), une IA prépare la procédure dans
  `VERIFIER_EN_LOCAL.md`.
- **Condition** : aucune campagne en cours.
- **Preuve** : un fichier de session dans `donnees/sessions/` avec un `AGENTS.md`, un appel `search_docs` et une image.

### A6 — `capture_frames` : zone et définition (proposé)
- **Pourquoi** : décision 19.5, demander un agrandissement ou une définition. Proposé, pas encore décidé.
- **Faire si laurent accepte** : ajouter `zone` et `definition` à `mcp_serveur/outils.py`.

---

## B. Paires courtes, palier 1 : 12 000 paires de 1 024 jetons au plus (décision 19.1)

Toutes les familles vont dans un nouveau paquet `usine/paires/` (à créer), une famille par module, sorties dans
`donnees/paires/<famille>/`. Format commun d'une paire : système (plan ou non, selon l'exception de la section 3),
demande, réponse, champs `famille`, `sujet`, `type` (création, débogage, analyse), `preuve` (commande et sortie).
Chaque paire est vérifiée par Godot, `extension_api.json` ou la vraie recherche du RAG (décision 19.1).

| ID | Famille | Type | Cible indicative | Source de la vérité | Estimation |
| --- | --- | --- | --- | --- | --- |
| B1 | Erreur de compilation → ligne corrigée | débogage | 2 000 | poseur de fautes (`usine/cours/base/mutations.py`) ; `--check-only` strict | 1 jour |
| B2 | Erreur de shader → correction | débogage | 800 | fautes de shader ; rendu en Compatibilité (règle 5.4) | 1 jour |
| B3 | Erreur à l'exécution → correction (instance nulle, chemin de nœud, signal) | débogage | 1 000 | fautes injectées ; lancement, sortie lue | 1,5 jour |
| B4 | Lire une sortie de Godot (réussi ou non, ligne qui compte, catégorie, `fichier:ligne`) | analyse | 1 500 | sorties réelles des cours, étiquettes connues (D1) | 1 jour |
| B5 | Création courte : appel exact pour une intention, signatures typées, petite fonction d'après un contrat | création | 4 000 | code vérifié des cours et des démos ; `extension_api.json` ; tests | 2 jours |
| B6 | RAG : formuler la requête, trier les résultats, appliquer l'extrait | création | 700 | vrai `search_docs` ; la page attendue dans les 3 premiers | 1 jour, après A5 |
| B7 | Images (4 niveaux × 500) : reconnaître, comparer deux étapes, voulu ou défaut, relier à la ligne | analyse, débogage | 2 000 | vérité du moteur (nœuds visibles, position projetée, défaut injecté) ; juge visuel | 3 jours |

Le partage 40/40/20 se règle en jetons de réponse à l'assemblage (B8), pas au nombre de paires.

### B8 — Assembleur du palier 1
- **Faire** : réunir les familles, plafonner chaque genre de faute (règle 7.7), retirer les quasi-doublons, exclure
  les tâches gelées et Starfox (dédoublonnage par fragments, règle 4), compter les jetons avec le tokenizer de
  Qwen 3.8 (règle 5.8), refuser tout exemple au-delà de 1 024, équilibrer 40/40/20 par sujet.
- **Preuve** : `python -m usine.paires assembler --palier 1` (à créer) ; `controles.json` : 0 problème, parts par
  sujet, plus long exemple ≤ 1 024.
- **Estimation** : 1,5 jour.

### B9 — Génération sur le PC
- **Machine** : 3 à 14 h de Godot (estimation). Accord de laurent ; PC libre.

**Vérification commune à B1 à B7** : rejouer la génération sur un sous-ensemble (graine fixe), comparer ; tirer
20 paires au hasard et relire (PROTOCOLE, § 5).

---

## C. Premier entraînement sur la 5090

### C1 — Réglages de LLaMA-Factory pour Qwen 3.8
- **Faire** : un fichier de réglages : `model_name_or_path: G:/llm_lora_trainer/qwen38_27b`, `quantization_bit: 4`,
  `lora_rank: 16`, `lora_target: all`, `template: qwen3_5`, `enable_thinking: false` (règle 7.6),
  `cutoff_len: 1024` puis `2048`, une époque, sauvegarde du LoRA. Les images : `freeze_vision_tower: true`.
- **Base** : les essais de mémoire du 2026-10-22 (`donnees/essais/`, `ETAT.md`).
- **Estimation** : 0,5 jour.

### C2 — Entraînement d'essai (environ 6 000 paires de B1 à B4)
- **But** : tester la chaîne entière, pas la qualité.
- **Machine** : quelques heures de 5090 (environ 270 jetons/s mesuré). Accord de laurent ; Blender fermé.
- **Preuve** : journal de LLaMA-Factory, perte qui baisse, LoRA écrit.

### C3 — Conversion et chargement
- **Faire** : `python -m usine.rft gguf …` (existe) ; charger dans llama-server (`--lora`), sans `-ngl`.
- **Preuve** : llama-server démarre avec le LoRA et répond à une requête.

### C4 — Courte campagne de contrôle (proposé)
- **But** : moins de fautes de Godot 3, de typage et de compilation qu'avec Qwen seul ?
- **Outil** : `outils/comparer_campagnes.py` (existe).

### C5 — Étape 1 complète : une époque sur les 12 000 paires
- **Machine** : environ 12 h (estimation au débit mesuré).

---

## D. Paires courtes, palier 2 : 10 000 paires de 2 048 jetons au plus, avec le plan

| ID | Famille | Cible | Source | Estimation |
| --- | --- | --- | --- | --- |
| D1 | Morceaux de jeu, point par point des cours (création et débogage d'un morceau : un état, une IA, un shader, une UI…) | 4 500 | 485 points des notes ; code vérifié des 67 projets | 3 jours |
| D2 | Morceaux tirés des 138 démos officielles (celles qui compilent en 4.7.2) | 2 500 | démos vérifiées (`donnees/rag/verification_demos.json`) | 2 jours |
| D3 | Séquences de 5 images en 640 × 360 : comparer, temporalité (rapide, lent, espacement), une étape d'itération et de diagnostic (décisions 19.5 et 19.6) | 3 000 | parties scriptées (`play_sequence`), instants connus, défauts injectés | 4 jours |
| D4 | Assembleur du palier 2 (mêmes contrôles que B8, plafond 2 048, plan présent) | — | — | 1 jour |
| D5 | Génération sur le PC | — | — | machine : à mesurer |
| D6 | Étape 2 : une époque sur les 12 000 + les 10 000 | — | — | machine : environ 33 h |

Le trou de la grille (audio, optimisation, mémoire, plugins) se remplit par du débogage (décision 17) dans D1 et D2 ;
les fiches de plugins (`rag/plugins/`) fournissent la matière « plugins ».

---

## E. Sessions OpenCode : 3 000 (décision 19.2)

| ID | Étape | Dépend de | Estimation |
| --- | --- | --- | --- |
| E1 | Regénérer les 732 sessions existantes (kart, roguelike, bâtiments) : plan (A1), 40/40/20 (A2), espaces (A4) | A1, A2, A4 | machine : quelques heures |
| E2 | Nouvelles sessions : démos, jouer et regarder (O1), boucles d'images, RAG appelé puis employé (décision 18.2), audio, optimisation, mémoire, plugins | A5 | 4 à 5 jours |
| E3 | Assembleur des sessions (plafond 32 768, aucune troncature, règle 7.5) | E1, E2 | 0,5 jour |
| E4 | Essai de débit sur la carte louée (H200 ou B300, avec `flash-linear-attention`, `causal-conv1d`, Liger) | C1 | 1 h de location |
| E5 | Étape 3 : les 3 000 sessions + environ 5 000 paires courtes reprises | E3, E4 | location : 45 à 95 € (estimation) |

La réflexion écrite en clair dans les sessions reste **proposée** (pas un bloc de réflexion, règle 7.6).

---

## F. Mesure (décision 1 : le test qui fait foi est la campagne réelle)

- **F1** : campagne de contrôle après l'étape 2 (proposé).
- **F2** : campagne Starfox propre avec le LoRA final, avec et sans RAG (décision 18.2).
- **F3** : comparaison avec t1 et Qwen seul (`outils/comparer_campagnes.py`).
- **F4** : ensuite, RFT sur les sessions réussies du LoRA, puis RLVR sur les tâches réussies en partie (décision 18.4).

---

## R. RAG (en continu, une IA peut s'en charger seule)

- **R1** : catalogue d'effets et de shaders vérifiés (eau, dissolution, contour, flash d'impact, traînées…), même
  modèle que `rag/plugins/` (fiche + exemple rendu en Compatibilité). Estimation : 3 jours.
- **R2** : catalogues de morceaux de code (procédural, machines à états, VFX, caméras, inventaires, UI). 2 jours.
- **R3** : après chaque ajout, `python -m usine.rag construire` puis `python -m usine.rag banc` ; le score ne doit
  pas baisser (aujourd'hui, hors même cours : 14/87 pages, 30/87 utiles).

---

## G. Godot 4.8 (en attente de la version stable)

- **G1** : refaire `python -m usine.vocab difference` sur la stable (aujourd'hui 287 différences utiles avec la
  beta1).
- **G2** : indexer la documentation 4.8 dans le RAG.
- **G3** : les paires 4.8 (6 par différence, ≤ 10 % des paires courtes, décision 19.7), seulement si laurent passe
  ses projets en 4.8.
