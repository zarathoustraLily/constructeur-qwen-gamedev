# Journal du suivi

Une ligne par événement, la plus récente en bas : `AAAA-MM-JJ HH:MM — <ID> — <qui> — <événement> — <détail ou lien>`.
Événements : réservée, livrée, vérifiée (acceptée), refusée, reprise, désaccord, décision de laurent.

2026-10-26 — — Claude (session du fil principal) — création du dossier — demande de laurent : « fais un dossier
RAPPORT DE SUIVIS ou tu mets toutes les etapes a suivre juq'ua la finalisation du processus et ou plusieurs ia
peuvent collaborer et verifier le travial de l'autre »
2026-10-26 — B6, E2 — Claude (fil principal) — dépendance ajoutée — les paires RAG et les sessions attendent un RAG
complet (R1, R2), remarque de laurent : « pourquoi ne sais tu pas qu'on devais preparer le RAG pour les shaders »
2026-10-26 — R1 — Claude (fil principal) — réservée — catalogue d'effets et de shaders
2026-10-26 — R1 — Claude (fil principal) — avancée — 6 effets vérifiés 6/6 (flash, dissolution, contour, bouclier,
vignette, pixelisation) ; fiches réécrites depuis le code que Godot a fait tourner ; indexés dans le RAG
2026-10-26 — R3 — Claude (fil principal) — mesure — banc hors même cours 14/87 pages, 31/87 utiles (30/87 avant) :
pas de recul
2026-10-26 — R3 — Claude (fil principal) — banc ajouté — questions de godot-docs-dataset (accord de laurent pour
le téléchargement) : `python -m usine.rag banc-docs` ; défauts corrigés : OS et IP sans membres, membres d'un mot ;
pages about/, community/, engine_details/ utiles ajoutées ; banc en français inchangé
2026-10-26 — R1 — Claude (fil principal) — faite — 11 effets vérifiés 11/11 (+ eau stylisée, vent dans l'herbe,
particules d'impact, nombres de dégâts, traînée) ; banc hors même cours 14/87 et 32/87 ; à vérifier par une autre IA
2026-10-26 — R2 — Claude (fil principal) — réservée — catalogues de morceaux de code
2026-10-26 — R2 — Claude (fil principal) — avancée — 9 morceaux vérifiés 9/9 (état étourdi, caméra lissée,
inventaire, graine, terrain, vision, couches et masques, réglages sauvegardés, manette) ; banc hors même cours 33/87
2026-10-26 — R2 — Claude (fil principal) — faite — 11 morceaux vérifiés 11/11 (+ barre de vie, menu à la manette) ;
banc hors même cours 14/87 et 34/87 ; à vérifier par une autre IA
2026-10-26 — A7 — Claude (fil principal) — faite — outil voir_scene (accord de laurent : « Oui, construis ») ;
vérifié sur le vrai bug de caméra du roguelike de laurent (0/12 dans le champ) et sur sa correction (12/12)
2026-10-26 — A8 — Claude (fil principal) — ajoutée — cas fabriqués et paires « situer la caméra et les objets »
2026-10-27 — A8 — Claude (fil principal) — générateur fait — `python -m usine.paires camera` : 13 défauts, chaque cas
vérifié par deux rendus ; 6 niveaux → 75 cas, 140 paires ≤ 1 024 jetons ; nombres de paires à fixer par laurent
2026-10-27 — A8 — Claude (fil principal) — paires de 1 024 faites — 300 décidées par laurent ; 311 (13 niveaux
complets), aucune trop longue après passage à 2 ou 3 objets ; ligne voir_scene ajoutée dans AGENTS.md (accord)
