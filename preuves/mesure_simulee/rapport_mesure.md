# Rapport de mesure (résultats simulés)

Score : réussite au premier essai selon le juge de la tâche, intervalle de Wilson à 95 % entre crochets.
Verdict (CLAUDE.md) : **victoire** si LoRA + RAG dépasse base + RAG au-delà de l'intervalle **et** atteint la frontière mesurée avec le même RAG ; **défaite** si LoRA + RAG est sous base + RAG au-delà de l'intervalle ; **égalité** sinon (motif en dernière colonne).

> Résultats SIMULÉS (usine/mesure/simulation.py) : aucun modèle n'a tourné.

| Compétence | n | base | base + RAG | LoRA | LoRA + RAG | frontière | frontière + RAG | Verdict | Motif |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| C1 | — | — | — | — | — | — | — | **non mesuré** | LoRA + RAG ou base + RAG non mesurée |
| C2 | — | — | — | — | — | — | — | **non mesuré** | LoRA + RAG ou base + RAG non mesurée |
| S1 | 50 | 50,0 % [36,6 ; 63,4] (25/50) | 60,0 % [46,2 ; 72,4] (30/50) | 80,0 % [67,0 ; 88,8] (40/50) | 88,0 % [76,2 ; 94,4] (44/50) | — | — | **égalité** | gain sur base + RAG, mais frontière non mesurée : victoire non établie |
| S2 | 50 | 60,0 % [46,2 ; 72,4] (30/50) | 70,0 % [56,2 ; 80,9] (35/50) | 30,0 % [19,1 ; 43,8] (15/50) | 36,0 % [24,1 ; 49,9] (18/50) | 82,0 % [69,2 ; 90,2] (41/50) | 88,0 % [76,2 ; 94,4] (44/50) | **défaite** | LoRA + RAG sous base + RAG au-delà de l'intervalle |
| S3 | — | — | — | — | — | — | — | **non mesuré** | LoRA + RAG ou base + RAG non mesurée |
| K1 | 50 | 60,0 % [46,2 ; 72,4] (30/50) | 64,0 % [50,1 ; 75,9] (32/50) | 66,0 % [52,2 ; 77,6] (33/50) | 70,0 % [56,2 ; 80,9] (35/50) | 76,0 % [62,6 ; 85,7] (38/50) | 80,0 % [67,0 ; 88,8] (40/50) | **égalité** | intervalles qui se chevauchent : pas de gain au-delà de l'intervalle |
| K2 | 50 | 24,0 % [14,3 ; 37,4] (12/50) | 28,0 % [17,5 ; 41,7] (14/50) | 40,0 % [27,6 ; 53,8] (20/50) | 44,0 % [31,2 ; 57,7] (22/50) | — | — | **égalité** | intervalles qui se chevauchent : pas de gain au-delà de l'intervalle |
| K3 | 50 | 36,0 % [24,1 ; 49,9] (18/50) | 40,0 % [27,6 ; 53,8] (20/50) | 62,0 % [48,2 ; 74,1] (31/50) | 68,0 % [54,2 ; 79,2] (34/50) | — | — | **égalité** | gain sur base + RAG, mais frontière non mesurée : victoire non établie |
| K4 | — | — | — | — | — | — | — | **non mesuré** | LoRA + RAG ou base + RAG non mesurée |
| D1 | 50 | 40,0 % [27,6 ; 53,8] (20/50) | 48,0 % [34,8 ; 61,5] (24/50) | 70,0 % [56,2 ; 80,9] (35/50) | 80,0 % [67,0 ; 88,8] (40/50) | 60,0 % [46,2 ; 72,4] (30/50) | 72,0 % [58,3 ; 82,5] (36/50) | **victoire** | gain sur base + RAG et frontière atteinte |
| D2 | — | — | — | — | — | — | — | **non mesuré** | LoRA + RAG ou base + RAG non mesurée |
| F1 | 50 | 20,0 % [11,2 ; 33,0] (10/50) | 24,0 % [14,3 ; 37,4] (12/50) | 60,0 % [46,2 ; 72,4] (30/50) | 66,0 % [52,2 ; 77,6] (33/50) | 80,0 % [67,0 ; 88,8] (40/50) | 84,0 % [71,5 ; 91,7] (42/50) | **égalité** | gain sur base + RAG, mais sous la frontière |
| F2 | — | — | — | — | — | — | — | **non mesuré** | LoRA + RAG ou base + RAG non mesurée |
| E | 50 | 10,0 % [4,3 ; 21,4] (5/50) | 12,0 % [5,6 ; 23,8] (6/50) | 18,0 % [9,8 ; 30,8] (9/50) | 20,0 % [11,2 ; 33,0] (10/50) | — | — | **égalité** | intervalles qui se chevauchent : pas de gain au-delà de l'intervalle |

Bilan : défaite 1, non mesuré 6, victoire 1, égalité 6
