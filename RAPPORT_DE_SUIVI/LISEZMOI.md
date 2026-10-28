# Rapport de suivi : de l'usine au LoRA entraîné

Demande de laurent (2026-10-26) : un dossier qui liste toutes les étapes jusqu'à la fin du processus, où plusieurs IA
peuvent travailler en parallèle et vérifier le travail les unes des autres, pour raccourcir les délais.

## Ce que contient ce dossier

| Fichier | Rôle |
| --- | --- |
| `PLAN.md` | toutes les étapes, de ce qui reste à finir jusqu'au LoRA mesuré en campagne : objectif, dépendances, sorties, commande de preuve, critère d'acceptation, ce que le vérificateur rejoue |
| `TABLEAU.md` | l'état de chaque étape en une ligne : à faire, réservée, faite, vérifiée, refusée ; qui l'a faite, qui l'a vérifiée, où est la preuve |
| `PROTOCOLE.md` | les règles de travail à plusieurs IA : réserver une étape, la livrer, la faire vérifier par une autre IA, trancher un désaccord |
| `journal.md` | une ligne datée par événement (réservation, livraison, vérification, refus, décision de laurent) |
| `modeles/` | les gabarits d'une livraison (`LIVRAISON.md`) et d'une vérification (`VERIFICATION.md`) |
| `verifications/` | un rapport de vérification par étape vérifiée (`<ID>.md`) |

## Avant toute chose, pour chaque IA

1. Lire `CLAUDE.md` en entier : ses « Règles qui priment » l'emportent sur ce dossier. En particulier :
   - tout se fait en français ; chaque affirmation est sourcée ;
   - rien ne se lance sur le PC de laurent ni sur son llama-server sans son accord ;
   - chaque exemple d'entraînement est vérifié de façon déterministe, jamais par un modèle (décision 18.1, règle 2) ;
   - on corrige le générateur, jamais la sortie (règle 5) ;
   - les sorties de Godot citées sont réelles (règle 5.1) et lues ligne par ligne (règle 5.5).
2. Lire `ETAT.md` (le journal des preuves) et `PLAN.md`.
3. Suivre `PROTOCOLE.md` pour réserver, livrer et vérifier.

## Où en est le projet (2026-10-28)

Fait (preuves datées dans `ETAT.md`, état de chaque étape dans `TABLEAU.md`) :
- les trois cours (67 projets Godot 4.7.2) et les bases d'entraînement du kart et du roguelike (358 sessions, à
  regénérer en E1) ; RAG (docs, cours, 11 effets, 11 morceaux, 21 fiches de plugins, bancs) ;
- les générateurs de paires courtes : compilation (B1), shader (B2), exécution (B3), lecture d'une sortie (B4),
  fonction d'après son contrat (B5/D1), RAG par le Code Mode (B6), caméra (A8), éditeur (A9), timing (A10) ;
  l'assembleur des deux paliers (B8, D4) ; la génération en volume (`python -m usine.paires volume`, B9/D5) ;
- palier 1 : **1 579 paires** vérifiées (≈ 1 h sur la 5090) ; palier 2 : **278** ; règle de laurent du
  2026-10-27 : au palier 1, un sujet sans création est gardé entier (décision 17) ;
- format d'OpenCode 2.1.4 relevé sans llama-server (A5, partie 1) ; réglages et lanceur de LLaMA-Factory (C1,
  `python -m usine.entrainement reglages|lancer`) ;
- **étape 1 de l'entraînement lancée le 2026-10-28** sur les 1 579 paires (accord de laurent : « vas sy he te
  l'aisse l'ordinateur »), sortie `donnees/entrainement/lora_etape_1/` (journal, bilan).

Ce qui manque le plus : de la **création** vérifiée (le palier 1 en manque d'environ 820 000 jetons ; les sources
essayées sans suite sont listées dans `ETAT.md` pour ne pas les refaire), les **images** (B7 : 2 000 paires au palier
1 ; D3 : 3 000 séquences au palier 2), et les sessions longues (E1, E2), qui attendent la capture d'OpenCode dans
l'environnement réel de laurent (A5, partie 2 : llama-server chargé).

## À déléguer maintenant (travaux indépendants)

Chaque lot se réserve dans `TABLEAU.md` (PROTOCOLE). Les générations et les rendus passent sur la 5090 **l'un après
l'autre** : pas de rendu Godot pendant un entraînement (la carte est pleine), pas deux générations du même cours à la
fois (elles matérialisent les mêmes projets d'étape, `donnees/cours/<cours>/projets/`).

| Lot | Quoi | Point de départ | Preuve attendue |
| --- | --- | --- | --- |
| B7 | Images, 4 niveaux × 500 (décision 19.3) : reconnaître, comparer deux étapes, voulu ou défaut, relier à la ligne. Vérité du moteur (nœuds visibles, position projetée, défaut injecté) | `usine/paires/camera.py` (images et vérité par deux rendus), `usine/observation/juge_visuel.py`, `usine/generateurs/observation_visuelle.py` (défauts visibles des bâtiments), `mcp_serveur/` (`voir_scene`) | `donnees/paires/<famille>/bilan.json`, paires ≤ 1 024 jetons images comprises (plafond 2 040 au palier 2), 0 problème à l'assembleur |
| D3 | Séquences de 5 images en 640 × 360 (décisions 19.5 et 19.6) : temporalité, espacement, itération « je ne vois rien → cause » | `usine/paires/timing.py` (A10 : timing mesuré), `usine/observation/` (`play_sequence`, parties scriptées) | paires ≤ 2 040 jetons, vérité par construction (instant, place à l'écran, existence de l'événement) |
| D1 | Création d'un morceau de jeu d'après un **point** des notes de cours (`cours/<cours>/notes/etape_NNN.md`, titres `###`) : le code que l'étape ajoute pour ce point, jugé par les tests de l'étape (rouges sans le morceau, verts avec) | `usine/paires/creation.py` (même juge, une fonction à la fois), `usine/cours/base/creation.py` (états avant et après d'une étape) | palier 2 avec le plan, ≤ 2 048 jetons ; part de création au palier 2 |
| C3 | Après l'étape 1 : convertir le LoRA en GGUF (`convert_lora_to_gguf.py` de llama.cpp, chemin à renseigner dans `config.toml`) et le charger dans llama-server (`--lora`), sans `-ngl` | `donnees/entrainement/lora_etape_1/` | llama-server démarre avec le LoRA et répond ; **accord de laurent** pour toucher à llama-server |

Page de présentation pour laurent : https://claude.ai/artifact/MBs9NEGC78Ld6HR4uQtGV3
