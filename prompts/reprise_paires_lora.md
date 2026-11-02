# Prompt de reprise — les paires du LoRA de Qwen pour Godot

Écrit le 2026-11-02 à 23:54, à la demande de laurent, d'après l'état relevé à 09:15, juste après le second assemblage ; vérifié inchangé à 23:54 (paliers de 09:01, aucun commit ni aucune chaîne depuis). Une copie est dans le dépôt de l'usine : `D:\constructeur-qwen-gamedev\prompts\reprise_paires_lora.md`. Le niveau de boss lui-même a son propre prompt : `PROMPT_REPRISE.md`, dans ce dossier.

---

## 1. Le prompt (à donner tel quel)

> Tu reprends pour laurent la fabrication des paires qui formeront le LoRA de Qwen à coder des jeux sous Godot 4.7.2, là où l'IA précédente s'est arrêtée le 2026-11-02 à 09:15 : toutes les chaînes sont finies, les deux paliers sont assemblés, rien ne tourne. Le partage 40/40/20 (création / débogage / analyse, en jetons de réponse) n'est pas atteint, et la façon de le combler attend la décision de laurent.
>
> Avant toute action, lis dans cet ordre :
> 1. `D:\constructeur-qwen-gamedev\CLAUDE.md` : les « Règles qui priment » l'emportent sur tout ; lis surtout les décisions 17 à 22 (décision 20 : aucun entraînement tant que les paires ne sont pas finies ; décision 21 : le débogage n'est jamais coupé) ;
> 2. ce fichier en entier : `D:\GODOT\PROJETS_DEMOS\PROJET_BOSS_ACTION_RPG\SUIVIS_PROGRESSION\PROMPT_REPRISE_PAIRES.md` ;
> 3. dans le même dossier, `bilan_paires_2026-11-02.md` (le compte par projet et par catégorie), puis la fin de `suivi.md` ;
> 4. dans `D:\constructeur-qwen-gamedev\ETAT.md`, la section « Cours fluides — 2026-11-01 », jusqu'au paragraphe « Assemblage du 2026-11-02 » ;
> 5. les mémoires rangées dans `C:\Users\laure\.claude\projects\D--GODOT-PROJETS-DEMOS-PROJET-BOSS-ACTION-RPG\memory\` (index : `MEMORY.md`).
>
> Vérifie ensuite l'état réel au lieu de te fier au journal : `git status` et `git log -3` du dépôt `D:\constructeur-qwen-gamedev` (branche `claude/observation-visuelle`), les processus Python et Godot qui tournent et sur quel projet, la date de `donnees\entrainement\palier_1.jsonl` et de `palier_2.jsonl`.
>
> Puis :
> - si laurent n'a pas encore dit comment combler la création qui manque, pose-lui la question du § 2.4, sans la trancher à sa place ;
> - sa réponse donnée, explique-lui ce que tu vas faire (dossiers, outils, durée) et attends son accord explicite avant de construire ; puis avance une étape à la fois, chaque paire vérifiée de façon déterministe ;
> - à la fin de chaque étape : réassemble les deux paliers, refais le bilan (§ 4), tiens les journaux (`suivi.md`, `ETAT.md`, ce fichier et sa copie), committe tes seuls chemins et pousse.
>
> Réponds à laurent en français, court, la réponse d'abord, chaque affirmation sourcée (fichier, commande ou mesure). Ne présente jamais une proposition comme sa décision. Suis ses règles du § 3 telles qu'elles sont écrites. Tiens les journaux à chaque étape : une autre IA doit pouvoir reprendre à tout moment.

---

## 2. La situation au 2026-11-02, 09:15

### 2.1 Ce qui est fait

- `FloodSolver` et `GpuFlood`, le solveur de crue des fluides, sont corrigés : commit 17dd4e4, après l'accord de laurent (« Oui, après les chaînes »). Plus de NaN, plus de surface qui bout à forte poussée ; les étapes 22 à 27 des fluides sont vertes par la garde de la carte. Les 515 paires faites avec l'ancien solveur sont écartées dans `donnees/paires/perimees_fluides_crue.jsonl` : un fichier posé à la racine de `donnees/paires/` n'est pas lu par l'assembleur.
- `voir_fluide` (séquences de 5 images de fluides en 640 × 360, sans fenêtre ni carte) a donné 3 930 paires en huit passes : graines 1, 3 et 5 pour les vagues, la SPH et le FLIP, 4 et 7 pour la fumée, 6 et 7 pour le feu, 8 et 9 pour la crue refaite. La graine 2 a planté sans rien écrire.
- Les lectures sont refaites (`lecture`, `debogage_boucle`, `analyse_sessions`, `rag`) : plus aucune paire ne cite les anciennes lignes du solveur.
- Second assemblage à 09:01, bilan compté après le partage, `ETAT.md` et le § 0 de `PROMPT_REPRISE.md` à jour ; commit ae8d9a0 poussé.

### 2.2 Ce qui part à l'entraînement

Compté après le partage 40/40/20 ; les totaux par type sont ceux de `donnees/entrainement/controles_palier_1.json` et `controles_palier_2.json`.

| Format | Paires | Jetons | Une époque sur la 5090 (estimée) | Jetons de réponse C / D / A |
|---|---|---|---|---|
| 1 024 | 18 444 | 12,6 M | 13,1 h | 27,7 / 47,5 / 24,8 |
| 2 048 | 11 879 | 19,4 M | 20,2 h | 36,0 / 42,8 / 21,2 |
| Ensemble | 30 323 | 32,0 M | 33,3 h | 31,6 / 45,3 / 23,1 |
| max (sessions longues, pour RunPod) | 644 : kart 365, roguelike 279 | – | – | – |

Par projet, en nombre de paires, C / D / A (C = création, D = débogage, A = analyse) :

| Projet | 1 024 | 2 048 | max | Total | Jetons de réponse C / D / A (1 024 et 2 048) |
|---|---|---|---|---|---|
| fluides | 1 435 / 2 464 / 1 968 | 986 / 2 026 / 1 225 | – | 10 104 | 36 / 43 / 21 |
| bâtiments | 707 / 2 186 / 1 554 | 626 / 838 / 779 | – | 6 690 | 26 / 50 / 24 |
| boss | 541 / 1 652 / 1 222 | 616 / 691 / 563 | – | 5 285 | 34 / 44 / 21 |
| kart | 226 / 1 141 / 907 | 195 / 742 / 585 | 38 / 162 / 165 | 4 161 | 17 / 53 / 30 |
| roguelike | 208 / 652 / 521 | 198 / 408 / 351 | 28 / 124 / 127 | 2 617 | 26 / 45 / 29 |
| atelier | 598 / – / 103 | 314 / 229 / 90 | – | 1 334 | 76 / 15 / 9 |
| jeux générés | – / 149 / 210 | – / 255 / 162 | – | 776 | 0 / 74 / 26 |
| **Total** | 3 715 / 8 244 / 6 485 | 2 935 / 5 189 / 3 755 | 66 / 286 / 292 | 30 967 | 32 / 45 / 23 |

Le détail par sous-catégorie (procédural, gameplay, shaders, 3D, interface, VFX, contrôle, physique, audio, optimisation, mémoire, tests, plugins, et la marque « machine à états ») est dans `bilan_paires_2026-11-02.md`.

Au regard des objectifs : la décision 19 prévoit 12 000 paires de 1 024 jetons, dont 2 000 d'analyse d'images (il y en a 18 444, dont 1 604 portent des images), et 10 000 de 2 048, dont 3 000 analyses de séquences d'images (11 879, dont 1 757 portent des images, et 1 457 sont des séquences de `voir_fluide`). La décision 22 prévoit 600 sessions longues pour RunPod ; laurent : « ok tu en feras en moyenne 600 longue avec le meme type de composition 40/40/20 pour le boss ». Aucune n'est faite.

### 2.3 Le 40/40/20 n'est pas atteint

L'assembleur (`usine/paires/assembler.py`, fonction `equilibrer`) règle chaque sujet sur le plus grand de la création et du débogage, les garde tous deux entiers (décision 21) et ne retire que l'analyse en trop. Il manque environ 1,27 M jetons de création pour égaler le débogage au total, 1,73 M si l'on compte sujet par sujet comme l'assembleur. Les plus gros trous, en jetons de création, au palier 1 puis au palier 2 : procédural 472 000 et 108 000, gameplay 323 000 et 104 000, shaders 254 000 et 117 000, 3D 138 000 et 16 000, physique 0 et 56 000, interface 26 000 et 32 000, VFX 27 000 et 36 000 (champ `trous` de `controles_palier_*.json`).

Pourquoi aucun réglage des familles ne le comble :
- `usine/paires/bloc.py` (`variantes`) essaie déjà le bloc retiré, une déclaration typée gardée à sa valeur nulle, le dernier bloc remplacé par le retour nul, et ces versions avec les avertissements ignorés ;
- ce qui reste rejeté, ce sont surtout des lignes qu'aucun test ne juge (`outils\paires\rejets_creation.py`, relevé du 2026-11-02) :

| Cours | `creation_bloc` : lignes qu'aucun test ne juge | `creation_bloc` : sans le bloc, le script ne passe plus l'analyse | `creation_fonction` : fonctions qu'aucun test ne juge |
|---|---|---|---|
| boss | 2 103 | 703 | 225 |
| bâtiments | 1 551 (« rien ne le juge ») | 859 | – |
| roguelike | 369 | 204 | 106 |
| kart | 209 | 378 | 152 |
| atelier | 104 | 70 | 5 |
| fluides | 1 | 4 | – |

- `creation_calcul` ne vaut que pour les shaders de calcul (`.glsl` de `1_core/`), et seuls les fluides en ont.

### 2.4 La question qui attend laurent

« Comment combler la création qui manque ? » Trois voies ; à lui de choisir :
1. **ajouter des tests** dans les cours, pour que les lignes aujourd'hui rejetées deviennent des paires de création vérifiées ;
2. **prendre un autre juge** que les tests, à définir ; il doit rester déterministe (décision 18.1) ;
3. **couper du débogage** : le ratio serait atteint tout de suite, mais cela revient sur la décision 21 et jette environ 1,27 M jetons déjà vérifiés.

Proposition de l'IA précédente, pas une décision de laurent : la voie 1, parce qu'elle ne relâche pas la vérification et ne perd pas de débogage. Ce que laurent a dit de plus récent sur le sujet (2026-11-02, vers minuit) : « ok on passera sans doute a plus de paires plus tard, pour le moment conserve le ratio et ocntinue ton travail ! ».

Attention : `cours/boss_action_rpg/` porte des changements non commités de l'autre session (« Analyse de l'incident »), qui attendent laurent ; n'y écris rien, même des tests, sans son accord.

### 2.5 Ce qui attend aussi laurent

- `demarche` et les familles du boss sur ses étapes 26 à 29 (`--etapes 26,27,28,29 --depuis 25`), et `faute_calcul` sur le boss : après sa décision sur ces étapes.
- `shader` du boss et ses 600 sessions longues : il faut la 5090, donc Qwen arrêté (le `llama-server` du port 8080 sert OpenCode), avec son accord.

### 2.6 Reste ensuite

- les séquences d'images des autres jeux : seuls les fluides en ont ;
- la base longue des bâtiments, à régénérer : elle n'existe que dans le cloud.

### 2.7 Laissés en place, rien supprimé

- `%TEMP%\usine_voir_fluide_ek8dz41o` et `%TEMP%\usine_voir_fluide_g71id40r`, de passes interrompues ;
- dans `donnees/paires/voir_fluide/images`, les images sans paire de la graine 2 et de la crue des graines 1 et 3 ;
- `voir_fluide/bilan_g004.json` n'existe pas ; les 253 paires de la graine 4 sont lues.

### 2.8 Pièges relevés

- Pour arrêter une passe : la chaîne PowerShell d'abord, puis Python, puis Godot, chacun par son PID. Sinon Python relance un Godot qui tient encore le dossier de travail, et la passe suivante échoue (`FileExistsError` : `godot.materialiser` efface puis recrée ce dossier).
- Une seule passe de `voir_fluide` à la fois : toutes partagent `donnees/cours/fluides/base/travail/voir_fluides_027`. Elle n'écrit qu'à la fin de chaque genre : un plantage au milieu d'un genre perd ce genre. Une graine neuve par passe, pour ne pas mêler les images : la prochaine libre est 10.
- En production, bien moins de fautes se voient qu'aux essais : vagues 21 à 22 sur 300, crue 25 à 30, SPH 30 à 34, FLIP 117 à 123 ; fumée 46 et 51 sur 200, feu 55 et 58.
- Un script PowerShell est lu à son lancement : le modifier ne change pas une chaîne qui tourne ; un Python déjà lancé garde l'ancien module.
- PowerShell 5.1 : `git commit -F -` suivi d'une chaîne n'envoie rien (message vide, commit annulé) : écrire le message dans un fichier UTF-8 et faire `git commit -F <fichier>`.
- Après une commande refusée, vérifier ce qui a tourné avant de relancer ; ne jamais mettre un arrêt et une suppression dans la même commande.

---

## 3. Les règles de laurent (telles qu'elles sont écrites)

- « Rien ne se lance sur son PC ni sur son llama-server sans son accord, pas même un rejeu court. »
- « Pendant une campagne : ne jamais modifier `D:\constructeur-qwen-gamedev` ni `D:\GODOT\projet_starfox` ; personne d'autre n'utilise llama-server. »
- « Feu vert : quand laurent réfléchit, on ne construit rien ; on attend son accord explicite. »
- « On explique ce qu'on veut faire avant de demander une autorisation (dossier, dépôt, outil). »
- « Tout se discute dans le fil principal, jamais dans des sous-fils » ; pas de sous-agents.
- « Pas de discussion de PR ni de git : les opérations nécessaires se font sans en faire un sujet ; seule la demande d'accord reste, en une phrase. »
- Décision 20 : « tu ne réentraînes rien tant qu'on n'a pas fini les paires d'entraînement ». Rien sur `llama-server`, aucun entraînement. Lancer Godot sans fenêtre (`--headless`) pour fabriquer, importer et tester fait partie du travail accepté.
- La souris : « j'ai besoin de pouvoir utiliser mon pc et de ne pas avoir la souris mobilisee a chaque essai godot » ; « ne bloque pas ma souris ». Aucune fenêtre de Godot en série : `--headless`, ou le bureau caché de `usine/bureau_cache.py` ; un rendu en fenêtre demande son accord (`USINE_FENETRES=1`).
- Tuer seulement les processus qu'on a lancés, par PID. Archives : extraites dans un dossier neuf, rien exécuté.
- Téléchargements (musique, sons, Mixamo) : son accord pour chacun (nom, source, taille, licence) ; Mixamo demande son compte.
- Sons TII (`tii_sci_fi`) : licence « No AI Training » : jeu final seulement ; sons muets dans les projets qui produisent les données.
- `F:\REVERSe\RECONSTRUCTION` : n'y toucher ni à ses Godot (on les reconnaît à leur ligne de commande). Mémoire `reverse-hades-ii` : diagnostic de méthode seulement.
- Carte graphique (mémoire `ecran-bleu-du-2026-11-01`) : tout Godot sur la carte passe par `usine/garde_carte.py`, `usine/bureau_cache.py` ou `godot.tester_gdunit`, jamais lancé à la main ; un seul à la fois ; au plus deux chaînes, en priorité basse. Ne pas relancer `faute_calcul` ni `compilation_calcul` sans son accord.
- Commits : tes seuls chemins, jamais `git add -A cours`. Ce qui reste non commité dans `cours/boss_action_rpg/` et le paragraphe « Étapes 26 à 29 (2026-11-01) » d'`ETAT.md` appartiennent à l'autre session et attendent laurent.
- Chaque paire vérifiée de façon déterministe (décision 18.1) ; une réponse n'écrit jamais une sortie de commande ; on corrige le générateur, jamais sa sortie ; pas de paires d'images écrites à la main : la vérité vient du moteur.
- Rien de supprimé définitivement : les dossiers temporaires et les images orphelines restent en place ou sont déplacés.

---

## 4. Outils et commandes

- **Dépôt** : `D:\constructeur-qwen-gamedev`, branche `claude/observation-visuelle` ; `donnees/` est ignoré par git. Push : `git -c credential.username=zarathoustraLily push origin claude/observation-visuelle`. Les commits finissent par la ligne d'attribution de l'IA qui les fait (jusqu'ici `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- **`ETAT.md` sans le paragraphe de l'autre session** : faire la même édition sur la copie de travail et sur `git show :ETAT.md` ; écrire la seconde par `git hash-object -w --stdin`, puis `git update-index --cacheinfo 100644,<hash>,ETAT.md` ; vérifier que `git show :ETAT.md` ne contient pas « Étapes 26 à 29 (2026-11-01) ». Même principe pour `PROMPT_REPRISE.md` et sa copie `prompts/reprise_boss_action_rpg.md` : la même édition sur les deux, sans recopier l'un sur l'autre (l'original porte la section des étapes 26 à 29). Ce fichier-ci, lui, se recopie tel quel dans `prompts/reprise_paires_lora.md`.
- **Assembler** (depuis le dépôt, en priorité basse, environ 1 min 30 chacun) : `python -m usine.paires assembler --palier 1`, puis `--palier 2`. L'assembleur lit `donnees/paires/*/paires*.jsonl`, recompte les jetons, écarte les doublons et les réponses répétées plus de 20 fois, puis fait le partage par sujet. Sorties : `donnees/entrainement/palier_<N>.jsonl`, `controles_palier_<N>.json`, `dataset_info.json`.
- **Bilan** (`SUIVIS_PROGRESSION\outils\paires\`) : `lire_controles.py` (les contrôles des deux paliers) ; `ratio_assemble.py` (le ratio en jetons de réponse) ; `python bilan_paires.py <dossier>\bilan.json` (environ 2 min 30 : le compte par projet, type et sujet, dans le même ordre et avec la même graine que l'assembleur), puis `python bilan_tableaux.py <dossier>` (les tableaux, dans `<dossier>\bilan_paires.md`) ; `rejets_creation.py` (pourquoi les familles de création rejettent). `bilan_paires.py` ne lit que les sessions longues du kart et du roguelike : y ajouter celles du boss quand elles existeront.
- **`voir_fluide`** : `python -m usine.paires voir_fluide --genres <gaz,feu,vagues,crue,flip,sph> --scenes 40 --fautes <N> --graine <G>` (jusqu'ici 300 fautes pour l'eau, 200 pour la fumée et le feu). Durées mesurées : 17 min pour vagues, SPH et FLIP (graine 5), 4 min pour la crue, 64 min pour le feu, 125 min pour la fumée et le feu. Sorties : `donnees/paires/voir_fluide/paires_g<G>.jsonl`, `bilan_g<G>.json`, `images/`.
- **Godot 4.7.2** : `D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe` (`…_console.exe` dans le même dossier pour lire la sortie). Sur la carte : l'Intel (`--gpu-index 1`) par `garde_carte.executer_carte`, arrêt à 8 plantages en 10 min (3 sur la 5090) ; `python usine/bureau_cache.py --rearmer` seulement avec l'accord de laurent ; `DISABLE_VULKAN_OBS_CAPTURE=1`.
- **Scripts plus anciens** (chaînes `.ps1`, tirages de `voir_fluide`, écart des paires périmées) : dans le scratchpad de la session f96add4f, `C:\Users\laure\AppData\Local\Temp\claude\D--GODOT-PROJETS-DEMOS-PROJET-BOSS-ACTION-RPG\f96add4f-1276-498c-aa92-8a01b9ab174f\scratchpad`. Ce dossier temporaire peut disparaître.
