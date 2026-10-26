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

## Où en est le projet (2026-10-26)

Fait et vérifié : les trois cours (67 projets Godot 4.7.2), les bases d'entraînement du kart et du roguelike
(358 sessions, à regénérer), les vérificateurs, le format d'OpenCode et le comptage des jetons de Qwen 3.8, le RAG
amélioré (glossaire, cours indexés, 21 fiches de plugins vérifiées), les mesures de la 5090, la comparaison des API
4.7.2 et 4.8-beta1, 476 tests du dépôt qui passent. Détail et preuves : `ETAT.md`.

Reste : les générateurs de paires courtes (22 000 paires), la regénération des sessions longues, les trois étapes
d'entraînement et les campagnes de mesure. Voir `PLAN.md`.

Page de présentation pour laurent : https://claude.ai/artifact/MBs9NEGC78Ld6HR4uQtGV3
