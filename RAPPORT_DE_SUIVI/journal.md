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
2026-10-27 — A9 — Claude (fil principal) — ajoutée — lire l'interface de l'éditeur ; choix de laurent : « Les deux »
2026-10-27 — (proposition) — Claude (fil principal) — refusée — familles « défauts de texture », « effets cassés »,
« copier un effet d'après une image » : laurent : « non l'iasse tomber ca je vais le faire moi meme »
2026-10-27 — A9 — Claude (fil principal) — partie A faite — outil MCP voir_editeur (preuve 18/18), famille
« lire l'éditeur » (essai : 50 paires) ; A8 : cause « autre caméra courante » corrigée (mesuré), paires régénérées
2026-10-27 — A10 — Claude (fil principal) — ajoutée et générateur fait — accord de laurent (« oui ») ;
capture_frames corrigé : Capture posée après Trace, sinon la légende perdait le journal
2026-10-27 — A4 — Claude (fil principal) — faite — les cours rognaient déjà ; paires : système rogné et export
vers_llamafactory ; rendu de LLaMA-Factory identique au gabarit sur 788 exemples
2026-10-27 — A2 — Claude (fil principal) — faite — analyses tirées des sessions de débogage, équilibrage par
étape ; analyse à 14 % (kart) et 13 % (roguelike) au lieu de 20 % : moyen de combler à trancher par laurent
2026-10-27 — B1, B2 — Claude (fil principal) — générateurs faits — compilation et shaders sur le code des cours ;
note de l'extrait de shader décalé de plusieurs lignes ajoutée au générateur des cours
2026-10-27 — (délégation) — laurent : « fais ce qui semble le plus pertinent [...] developper un jeu en godot de facon
continue jsuq'ao botenir le resultat » ; tranché par Claude : A2 comblé par les paires d'analyse, 300 timing et 300
éditeur, B3 au palier 2, création au palier 1 quand le plan n'y joue aucun rôle (détail dans ETAT)
2026-10-27 — B3 — Claude (fil principal) — générateur fait — chemin de nœud et type du nœud ; cas isolé par `-i`,
ou scène lancée sans fenêtre ; 26/31 vérifiées, 0 trop longue ; compacter corrigé (cas FAILED et résumé gardés)
2026-10-27 — B4 — Claude (fil principal) — générateur fait — lectures tirées de B1 à B3 (sortie fautive et corrigée)
2026-10-27 — D1, B5 — Claude (fil principal) — générateur fait — fonction d'après son contrat, rouge sans le corps et
verte avec ; 12/12 sur l'essai du kart
2026-10-27 — A9 — Claude (fil principal) — corrigé — le plan manquait aux paires de plus de 1 024 jetons
2026-10-27 — C1 — Claude (fil principal) — faite — réglages des trois étapes, rien n'est lancé
