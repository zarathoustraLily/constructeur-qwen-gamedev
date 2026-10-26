# Tableau de suivi

États : à faire · réservée · faite · vérifiée · refusée · en attente de <ID>. Règles : `PROTOCOLE.md`.
Une ligne par étape de `PLAN.md`. Mettre à jour en même temps que `journal.md`.

| ID | Étape | État | Réalisé par | Vérifié par | Preuve |
| --- | --- | --- | --- | --- | --- |
| A1 | Plan dans les sessions OpenCode | en attente de A5 | | | |
| A2 | Partage 40/40/20 dans l'assembleur | à faire | | | |
| A3 | Regénérer la base des bâtiments sur le PC | en attente de A1, A2 | | | |
| A4 | Espaces de fin des messages | à faire | | | |
| A5 | Capture d'une session OpenCode (laurent) | à faire (laurent) | | | |
| A6 | `capture_frames` : zone et définition | proposé, attend laurent | | | |
| B1 | Paires : erreur de compilation → correction | à faire | | | |
| B2 | Paires : erreur de shader → correction | à faire | | | |
| B3 | Paires : erreur à l'exécution → correction | à faire | | | |
| B4 | Paires : lire une sortie de Godot | à faire | | | |
| B5 | Paires : création courte | à faire | | | |
| B6 | Paires : RAG | en attente de A5, R1, R2 | | | |
| B7 | Paires : images, 4 niveaux | à faire | | | |
| B8 | Assembleur du palier 1 | en attente de B1 | | | |
| B9 | Génération du palier 1 sur le PC | en attente de B8 | | | |
| C1 | Réglages de LLaMA-Factory | à faire | | | |
| C2 | Entraînement d'essai (≈ 6 000 paires) | en attente de B1-B4, C1 | | | |
| C3 | Conversion GGUF et chargement | en attente de C2 | | | |
| C4 | Courte campagne de contrôle | proposé, attend laurent | | | |
| C5 | Étape 1 complète | en attente de B9, C3 | | | |
| D1 | Morceaux de jeu point par point | à faire | | | |
| D2 | Morceaux tirés des démos | à faire | | | |
| D3 | Séquences de 5 images | en attente de B7 | | | |
| D4 | Assembleur du palier 2 | en attente de D1 | | | |
| D5 | Génération du palier 2 sur le PC | en attente de D4 | | | |
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
| R1 | Catalogue d'effets et de shaders | réservée (2026-10-26) | Claude, fil principal | | 6 effets vérifiés 6/6 et indexés (ETAT, 2026-10-26) ; eau, traînées à faire |
| R2 | Catalogues de morceaux de code | à faire | | | |
| R3 | Reconstruire le RAG et rejouer les bancs | après chaque ajout | | | 2026-10-26 : banc 14/87 pages, 31/87 utiles hors même cours ; banc-docs membres 970/1000, classes 652/652, guides 820/905 (page) et 729/905 (section) |
| G1 | Comparaison des API sur la 4.8 stable | en attente de la sortie | | | |
| G2 | Documentation 4.8 dans le RAG | en attente de G1 | | | |
| G3 | Paires 4.8 | en attente de la décision de migrer | | | |

## Déjà fait et vérifié avant ce tableau

Preuves datées dans `ETAT.md` : cours (bâtiments 39/39, kart 14/14, roguelike 14/14) ; bases du kart (203) et du
roguelike (155) ; RAG (glossaire, nos sources, banc 11 → 30 utiles sur 87) ; 21 fiches de plugins (21/21) ;
mesures de mémoire de la 5090 ; comparaison des API 4.7.2 et 4.8-beta1 ; 476 tests du dépôt.
