# Tableau de suivi

États : à faire · réservée · faite · vérifiée · refusée · en attente de <ID>. Règles : `PROTOCOLE.md`.
Une ligne par étape de `PLAN.md`. Mettre à jour en même temps que `journal.md`.

| ID | Étape | État | Réalisé par | Vérifié par | Preuve |
| --- | --- | --- | --- | --- | --- |
| A1 | Plan dans les sessions OpenCode | en attente de A5 | | | |
| A2 | Partage 40/40/20 dans l'assembleur | faite (2026-10-27) ; écart d'analyse comblé à l'étape d'entraînement par les paires d'analyse (tranché par Claude sur délégation) | Claude, fil principal | | kart 43/43/14, roguelike 44/42/13, 0 problème (ETAT) |
| A3 | Regénérer la base des bâtiments sur le PC | en attente de A1, A2 | | | |
| A4 | Espaces de fin des messages | faite (2026-10-27) | Claude, fil principal | | rendus identiques : kart 203/203, roguelike 155/155, paires 430/430 (ETAT) |
| A5 | Capture d'une session OpenCode | format capturé sans llama-server (2026-10-27) : AGENTS.md, Code Mode, image ; reste la capture dans l'environnement réel de laurent (llama-server chargé) | Claude, fil principal | | `outils/capturer_opencode.py`, requêtes dans `donnees/capture_opencode/` (ETAT) |
| A6 | `capture_frames` : zone et définition | proposé, attend laurent | | | |
| A7 | Outil `voir_scene` : voir la scène 3D comme dans l'éditeur | faite (2026-10-26) | Claude, fil principal | | bug réel : 0/12 objets dans le champ, « à l'horizontale » ; corrigé : 12/12 ; tests et preuve 17/17 (ETAT) |
| A8 | Cas fabriqués « situer la caméra et les objets », puis paires | 1 024 faites (2026-10-27) ; 2 048 avec image à faire | Claude, fil principal | | 13 niveaux : 162 cas vérifiés, 0 rejeté, 311 paires ≤ 1 024 jetons, 26 par défaut commun (ETAT) |
| A9 | Lire l'interface de l'éditeur Godot (A : fenêtre entière ; B : par godot-ai) | A : outil MCP et générateur faits (2026-10-27), 300 paires (délégation), plan ajouté (palier 2) ; B attend la capture chez laurent | Claude, fil principal | | `voir_editeur` : preuve du serveur 18/18 ; essai 2 niveaux : 50 paires ≤ 2 040 jetons, 0 rejet (ETAT) |
| A10 | Timing : ce qu'on voit contre ce qu'on doit produire | générateur fait (2026-10-27), 300 paires (délégation) | Claude, fil principal | | 1 jeu : 23 paires, 9 défauts sur 10 au symptôme mesuré (ETAT) |
| B1 | Paires : erreur de compilation → correction | fait (2026-10-27) : kart 957, roguelike 625, bâtiments 2 186 | Claude, fil principal | | `volume.log`, ETAT |
| B2 | Paires : erreur de shader → correction | fait (2026-10-27) : kart 184, roguelike 27 ; bâtiments tous > 1 024 (shader entier dans la sortie) | Claude, fil principal | | `volume.log`, ETAT |
| B3 | Paires : erreur à l'exécution → correction | générateur fait (2026-10-27), palier 2 avec le plan (délégation) ; volume en B9 | Claude, fil principal | | essai kart et roguelike : 26 paires vérifiées sur 31, 0 trop longue (ETAT) |
| B4 | Paires : lire une sortie de Godot | générateur fait (2026-10-27), tiré de B1 à B3 sans relancer Godot | Claude, fil principal | | essai : 36 lectures, 18 échecs, 18 réussites, ≤ 980 jetons (ETAT) |
| B5 | Paires : création courte | fonction d'après son contrat : 105 (58 au palier 1) ; **source épuisée** (blocs, fonctions non jugées, exemples de la doc : sans suite, ETAT) | Claude, fil principal | | `volume.log`, ETAT |
| B6 | Paires : RAG | en attente de A5, R1, R2 | | | |
| B7 | Paires : images, 4 niveaux | à faire | | | |
| B8 | Assembleur du palier 1 | fait ; règle des sujets sans création **à trancher par laurent** | Claude, fil principal | | `controles_palier_1.json` : 1 579 paires, 0 problème |
| B9 | Génération du palier 1 sur le PC | fait (2026-10-27, 2 h 08 puis 54 min) | Claude, fil principal | | `donnees/paires/volume.log` |
| C1 | Réglages de LLaMA-Factory | faite (2026-10-27) | Claude, fil principal | | `python -m usine.entrainement reglages` ; tests (ETAT) |
| C2 | Entraînement d'essai (≈ 6 000 paires) | en attente de B1-B4, C1 | | | |
| C3 | Conversion GGUF et chargement | en attente de C2 | | | |
| C4 | Courte campagne de contrôle | proposé, attend laurent | | | |
| C5 | Étape 1 complète | en attente de B9, C3 | | | |
| D1 | Morceaux de jeu point par point | « fonction d'après son contrat » : 47 au palier 2 ; reste les points des notes | Claude, fil principal | | `volume.log`, ETAT |
| D2 | Morceaux tirés des démos | à faire | | | |
| D3 | Séquences de 5 images | en attente de B7 | | | |
| D4 | Assembleur du palier 2 | fait | Claude, fil principal | | `controles_palier_2.json` : 278 paires, 0 problème |
| D5 | Génération du palier 2 sur le PC | fait avec B9 | Claude, fil principal | | `donnees/paires/volume.log` |
| D6 | Étape 2 | en attente de C5, D5 | | | |
| E1 | Regénérer les 732 sessions | en attente de A1, A2, A4 | | | |
| E2 | Nouvelles sessions OpenCode | en attente de A5, R1, R2 | | | |
| E3 | Assembleur des sessions | en attente de E1, E2 | | | |
| E4 | Essai de débit sur carte louée | en attente de C1 | | | |
| E5 | Étape 3 | en attente de D6, E3, E4 | | | |
| F1 | Campagne de contrôle après l'étape 2 | proposé | | | |
| F2 | Campagne Starfox avec le LoRA final, avec et sans RAG | en attente de E5 | | | |
| F3 | Comparaison avec t1 et Qwen seul | en attente de F2 | | | |
| F4 | RFT puis RLVR | plus tard | | | |
| R1 | Catalogue d'effets et de shaders | faite (2026-10-26) | Claude, fil principal | | 11 effets vérifiés 11/11 par leurs pixels et indexés : `python -m usine.rag.effets verifier` (ETAT, 2026-10-26) |
| R2 | Catalogues de morceaux de code | faite (2026-10-26) | Claude, fil principal | | 11 morceaux vérifiés 11/11 par leur comportement et indexés : `python -m usine.rag.morceaux verifier` (ETAT, 2026-10-26) |
| R3 | Reconstruire le RAG et rejouer les bancs | après chaque ajout | | | 2026-10-26 : banc 14/87 pages, 34/87 utiles hors même cours ; banc-docs membres 970/1000, classes 652/652, guides 820/905 (page) et 729/905 (section) |
| G1 | Comparaison des API sur la 4.8 stable | en attente de la sortie | | | |
| G2 | Documentation 4.8 dans le RAG | en attente de G1 | | | |
| G3 | Paires 4.8 | en attente de la décision de migrer | | | |

## Déjà fait et vérifié avant ce tableau

Preuves datées dans `ETAT.md` : cours (bâtiments 39/39, kart 14/14, roguelike 14/14) ; bases du kart (203) et du
roguelike (155) ; RAG (glossaire, nos sources, banc 11 → 30 utiles sur 87) ; 21 fiches de plugins (21/21) ;
mesures de mémoire de la 5090 ; comparaison des API 4.7.2 et 4.8-beta1 ; 476 tests du dépôt.
