# Mode d'emploi pour continuer le projet de laurent

LoRA de Qwen 3.8 qui développe des jeux Godot : état au 11 octobre 2026 au soir, et marche à suivre.

**Conventions de ce document**

- Ce document remplace la conversation, que tu n'as pas vue. La mémoire du projet Claude est désactivée : ce fichier est la seule trace durable de ce qui a été dit (notes).
- Trois statuts, jamais mélangés : « décidé par laurent » (section 10), « proposé », c'est-à-dire non validé (section 11), et « ouvert » (section 12). Dans les sections 13 à 15, chaque étape porte son statut.
- Sources citées entre parenthèses :
  - (notes) : notes écrites à la fin de la conversation principale du 11 octobre 2026 avec laurent. Elles font autorité pour l'historique, les décisions et les préférences.
  - `chemin:ligne` : fichier du dépôt sur la branche de travail, commit `83e8bc4`. « (main) » renvoie au commit `4296a4e` de `main`.
  - (V2), (Appr.), (Règles1), (Transcr.), (Transcr. complète), (Béquille) et (P: nom de fichier) : documents décrits en 3.6.
  - (fil, HH:MM) : message du fil principal du 11 octobre avec laurent, cité par son heure UTC (décrit en 3.6). Ses phrases sont recopiées, orthographe normalisée.
- Les chiffres et les faits techniques ont été vérifiés dans leur source première (dépôt, documents du projet, transcriptions) : le texte donne la valeur vérifiée, avec sa source. Ce qui demande une décision de laurent est en section 12.1, avec les options.
- Ce qui ne peut se vérifier que sur le PC de laurent porte la mention « à vérifier ». Ne jamais chercher à le vérifier soi-même sur son PC ni sur son llama-server sans son accord.

## 0. À lire en premier

1. **Qui.** laurent (GitHub zarathoustraLily) possède le projet ; il parle français et teste lui-même, sur son PC Windows (section 2).
2. **But.** Améliorer la création et l'utilisation d'un LoRA pour Qwen 3.8, servi sur son PC par llama-server, qui développe des jeux Godot 4.7.2 (notes).
3. **Moyens.** Un harnais d'agent, un RAG, une béquille (guide AVANT / PENDANT / APRÈS) et surtout un nouvel entraînement, avec un dataset bien meilleur et un RAG reconstruit (notes).
4. **État.** Le LoRA actuel, t1, a des défauts établis en conditions réelles : il n'écrit plus de texte, il a appris un mauvais nom de champ, il réécrit les fichiers à l'identique et il ne range rien selon le plan (sections 6 et 7).
5. **Dernière campagne.** laurent a jugé la V2 : « le résultat est un échec... c'est le pire des 4 » (fil, 09:08).
6. **Construit, non fusionné.** Sur la branche `claude/project-thread-12uh5s` : béquille, socle de jeu propre, juge des règles d'architecture, 124 tâches « nettoyer », nouveau tri des sessions (section 9).
7. **Sur le PC seulement.** Les corrections V2 (M1 à M5), non commitées (section 5).
8. **Rien n'est tranché** sur les huit points ouverts des règles ni sur la plupart des propositions (sections 8, 11 et 12).
9. **Statuts.** Ce que laurent a décidé est en section 10, ce qui est proposé en section 11, ce qui est ouvert en section 12. Ne jamais présenter une proposition comme sa décision.
10. **Prochaine action.** Faire trancher laurent, une question à la fois : la 2D et la 3D dans les règles, puis `6_assets/`, puis les trois questions de la section 12.1, puis les propositions de la section 11 (section 15).
11. **Feu vert.** Ne rien construire sans son accord explicite : quand il réfléchit, il ne veut pas qu'on lance du travail (section 2.3).
12. **Interdits.** Ne rien lancer sur son PC ni sur son llama-server sans son accord ; ne jamais toucher `D:\constructeur-qwen-gamedev` ni `D:\GODOT\projet_starfox` pendant une campagne (section 2.3).
13. **Forme.** Réponses courtes, en français, qui commencent par la réponse, sourcées, dans le fil principal, sans parler de PR ni de git (section 2.1).

## 1. Le projet et son but

### 1.1 Qui, quoi, où

- **Propriétaire** : laurent, compte GitHub zarathoustraLily. Dépôt public https://github.com/zarathoustraLily/constructeur-qwen-gamedev, branche par défaut `main`. La branche de travail `claude/project-thread-12uh5s` porte la béquille, le socle et le juge de règles ; elle n'est pas fusionnée (notes).
- **But** : améliorer la création et l'utilisation d'un LoRA pour Qwen 3.8 qui développe des jeux Godot. Quatre leviers : le harnais d'agent, le RAG, la béquille (guide AVANT / PENDANT / APRÈS) et surtout un entraînement propre, avec un dataset bien meilleur et un RAG reconstruit (notes).
- **Mission écrite dans le dépôt** : une « usine » qui fabrique des données vérifiées pour entraîner un LoRA de Qwen3.8-27B sur des compétences étroites de Godot, puis mesurer honnêtement le gain ; Unreal 5.8 réutilisera la même usine plus tard (CLAUDE.md:5-7).
- **Ce qu'aucun juge exact ne couvre** selon le dépôt : le game design, le « fun », le rendu et l'animation, qui restent des décisions de l'utilisateur (CLAUDE.md:84). Les juges de gameplay et de diagnostic visuel proposés en section 11 visent une partie de ce trou.

### 1.2 Chronologie

| Date | Événement | Source |
| --- | --- | --- |
| 3 au 5 octobre | Construction de l'usine : vocabulaire, juge, traducteurs, générateurs, portillon, gel, RAG, serveur MCP, boucle RFT, mesure. Générateurs et juges : environ trois jours. | ETAT.md:5-21 ; notes |
| 6 octobre | laurent décide de rester sous Godot 4.7.2. | ETAT.md:1006-1012 |
| 6 au 8 octobre | Gel complet (221 tâches gelées) et tour t1 sur le PC, 48 h, du 6 octobre 09:28 au 8 octobre 09:43 ; 93 sessions exportées pour l'entraînement (section 7, point 5). | notes ; ETAT.md:1018 ; Transcr. complète l. 5474-5498 |
| 8 octobre | Entraînement du LoRA t1 sur RunPod (H200), 2 h 04. Le soir, laurent l'essaie dans OpenCode et le juge « mauvais ». | ETAT.md:1019-1020 |
| Nuit du 8 au 9 | Trois campagnes de 2 h sur Starfox, avec LoRA : « harnais + RAG », « harnais », « sans harnais ». | Transcr. l. 3103, 4316-4329 |
| 9 octobre | Page « La béquille de Qwen » ; laurent fixe l'ordre de travail : retour des outils, socle et plan, déclaration d'action, mesure par campagnes, entraînement. | Béquille ; ETAT.md:1024 |
| 11 octobre, nuit | Béquille, points 1 à 9, construite sur la branche : commits `682acbf`, `664c3fc` et `70af300`, de 02:17 à 03:15 UTC ; 356 tests verts, annoncés à laurent à 03:19. Guide AVANT / PENDANT / APRÈS préparé avec laurent, puis campagne « RAG + guide » de 02:51 à 04:51 UTC, qui cale à partir de 1 h 17. | ETAT.md:1026-1103 ; fil, 01:53-02:47, 03:19 et 04:56 ; P: causes_campagne_11oct.md |
| 11 octobre, matin | Corrections V2 (M1 vers 05:05 UTC) et campagne V2. Document « Apprentissages » envoyé sans consigne (07:56) : du travail sur les règles est lancé, alors que pour laurent c'était « juste une réflexion » (08:16) ; l'arrêt arrive trop tard (section 9.2). laurent juge la V2 « le pire des 4 » (09:08) et arrête un rejeu : « SURTOUT PAS » (11:45). Juge des règles et socle nettoyé sur la branche (commit `83e8bc4`, 11:57 UTC). | V2 ; fil ; ETAT.md:1105-1148 ; notes |
| 11 octobre, après-midi | Décisions sur le dataset : catégories (12:18), optimisation et gameplay (12:22, 12:25), ses jeux de référence (12:24), réflexes (12:46), base de problèmes visuels (12:53), 50/50 (13:00). Règles1 reçu (16:06). | fil ; Règles1 |
| 11 octobre, soir | Demande de ce mode d'emploi (21:16). | fil |

### 1.3 Ce que laurent a dit vouloir

Ces phrases ne sont pas des décisions formelles ; elles disent son intention. Elles viennent de la transcription du 8 au 11 octobre (Transcr.) et du fil principal du 11 octobre (fil), orthographe normalisée. Ses décisions, avec ses mots, sont en section 10.

- « Je veux surtout avec l'utilisation du RAG, parce que pour moi c'est le plus important » (8 octobre, 23:43).
- « Ce LoRA doit apprendre justement au modèle à trouver un cheminement » (8 octobre, 18:46).
- Sur le RAG actuel : « ça manque d'extraits d'exemples, de bugs potentiels, de tous les outils qui pourraient être utiles relativement à la tâche [...] ça ne décompose pas non plus en thématiques adjacentes, comme quoi considérer quand un ennemi est touché, ou où se trouvent les fichiers » (9 octobre, 05:14). « Il faut faire des RAG par résumé sémantique et des graphes relationnels entre les données pour que ça aille hyper vite » (05:17). « Le RAG, l'appel par requête ne me plaît pas du tout » (05:00).
- « Ce qui lui manque, c'est plus l'assemblage [...] mettre tout un exemple de niveau est plus pertinent que de lui donner une simple brique en contexte » (9 octobre, 05:29).
- « L'idée, c'est de donner à Qwen pour chaque action une béquille qui l'aide à avoir une connaissance préalable de qualité » (9 octobre, 05:40). Son exemple du laser, qui a besoin d'un timing, d'un état, d'une collision, d'un son et d'un effet visuel (05:45), a donné l'outil `prepare_action`.
- Il veut pouvoir importer un niveau de Blender et placer ou déplacer les ennemis à la main, en vue de dessus (9 octobre, 06:01). Le socle pose donc les acteurs à la main dans la scène (godot/socle_jeu/ORGANISATION.md:52).
- « Quand on code, il faut des tests de performance et des tests de suivi de chaque script, pouvoir voir le comportement en temps réel » (9 octobre, 06:27).
- L'ordre des dossiers vient de lui : « autoload est le directeur, le chef d'orchestre, core le cœur, c'est nettement plus important que l'asset » (9 octobre, 06:47).
- « Ce qui m'inquiète, c'est l'organisation et la demande de complément d'information dans le RAG, surtout que je veux ajouter des conseils possibles de plugins ou de FX dans le prochain RAG » (fil, 06:50).
- Sur les données de t1 : « il n'y a aucun algo, shader, aucun son, aucune UI, et il n'y avait pas de nomenclature de procédure, comme savoir où écrire ou consulter le projet pour savoir où on en est, ni savoir si un morceau de code exemple existe déjà » (fil, 07:31).
- Sur le guide de la campagne du 11 octobre : une première version d'« AVANT chaque étape » était à ses yeux « scolaire, c'est ce qui rend le travail pourri » (fil, 02:25). Il voulait qu'avant chaque étape Qwen liste les connaissances nécessaires, se demande « si j'ajoute que le but, c'est de rendre le projet professionnel et superbe, quelles connaissances pourraient t'être utiles ? », puis les cherche dans le RAG (fil, 02:16).
- Sur les captures : Qwen ne recevait pas une suite d'images, « donc il ne pouvait analyser ni la jouabilité ni la rationalité des mouvements et du gameplay » (fil, 02:31).
- Sur le volume : « ça devient un peu colossal comme création de dataset, non ? On va finir avec des dizaines de milliers de paires, non ? » (fil, 13:12). Les volumes proposés en réponse sont en 11.4.

## 2. Comment travailler avec laurent

### 2.1 La forme

- Français. Des réponses courtes qui commencent par la réponse, avec des affirmations sourcées (notes).
- Tout se discute dans le fil principal. Il a rejeté avec colère la dispersion dans des sous-fils : « qui t'as demandé de répondre ailleurs ? j'arrive plus à suivre » (fil, 01:46).
- Pas de discussion de PR ni de git : « on s'en fout de la PR ». Il veut parler de la création et de l'utilisation du LoRA (fil, 01:46 et 02:20). Les opérations git nécessaires se font sans en faire un sujet ; seule la demande d'accord reste, en une phrase (voir 2.3).
- Il remarque les délais : répondre vite, vérifier ensuite si besoin (notes).

### 2.2 Ce qu'il teste, et comment

- Il teste en conditions réelles, sur des campagnes Starfox propres, pas sur des jeux de test mis de côté : « je m'en fous des tests, je teste en réel dans des conditions propres » (fil, 07:23). Même idée le 8 octobre : « je vois moi-même la différence quand je code avec lui et sans lui » (Transcr., 23:39).
- Une seule campagne, avec LoRA ; pas de campagne sans LoRA : « on ne fait qu'une campagne avec LoRA, le LoRA a démontré son efficacité » (fil, 06:50). La campagne sans LoRA que conseille le document V2 (§8) est donc exclue.

### 2.3 Feu vert et interdits

- Quand il réfléchit, il ne veut pas qu'on lance du travail. Le document « Apprentissages », envoyé sans consigne (fil, 07:56), était « juste une réflexion pour savoir comment enseigner un codage propre à Qwen grâce au LoRA » (fil, 08:16). Demander un feu vert explicite avant de construire (notes).
- Il a dit « SURTOUT PAS » quand un rejeu tournait sur son llama-server, juste après « tu as relancé le test ? » (fil, 11:45). Ne rien lancer sur son PC ni sur son llama-server sans son accord explicite (notes).
- Pendant une campagne : ne jamais modifier `D:\constructeur-qwen-gamedev` ni `D:\GODOT\projet_starfox`, et personne d'autre n'utilise llama-server (notes ; V2, §5).
- Il corrige quand on se trompe sur ses décisions. Toujours distinguer ce qu'il a décidé (section 10) de ce qu'on propose (section 11) (notes).

### 2.4 Les règles du dépôt

`CLAUDE.md` se déclare « ce qui fait foi » (CLAUDE.md:9). Ses dix règles non négociables (CLAUDE.md:48-61), résumées :

1. Équiper Qwen, jamais le gouverner : aucune boucle de contrôle autour d'OpenCode à l'usage ; le portillon et le juge servent seulement à trier les données d'entraînement.
2. Déterministe d'abord : aucun LLM dans les juges, le portillon, les traducteurs ni les générateurs de vérité terrain.
3. Juges hors de portée : les tests cachés ne sont copiés qu'au moment de juger.
4. Jeux de test gelés avant tout entraînement, exclus de l'entraînement et du RAG. Leur usage est une question ouverte pour laurent (section 12.1, question 1).
5. Corriger le générateur, jamais la sortie.
6. Vocabulaire réel uniquement, vérifié dans `extension_api.json`.
7. Édition atomique sur une copie de travail.
8. Ne tuer que les processus lancés par notre code.
9. Pas de réseau à l'exécution ; le seul serveur LLM est local.
10. Commentaires, messages et documents en français.

### 2.5 Ce que peut faire une IA dans le cloud

- Une session cloud écrit le code, les tests et les simulations, sous Linux, sans GPU, sans Qwen, sans Windows et sans OpenCode (CLAUDE.md:13-16).
- Tout ce qui dépend de Qwen, d'OpenCode ou de Windows est livré avec une simulation testée dans le cloud et une procédure `VERIFIER_EN_LOCAL.md`, qui fait foi côté machine (CLAUDE.md:20-22).
- Godot 4.7.2 Linux headless se télécharge dans le cloud (`outils/installer_godot_cloud.sh` ; CLAUDE.md:25).
- Manière de travailler du dépôt : lire `CLAUDE.md` et `ETAT.md` ; un livrable et sa preuve de fin, collée dans `ETAT.md` ; en fin de session, mettre `ETAT.md` à jour, committer et pousser sur la branche de la session (CLAUDE.md:145-152).

## 3. Où sont les choses

### 3.1 Le PC de laurent

Windows 11, machine lolo_stormy (notes) ; RTX 5090 32 Go et 64 Go de RAM, bientôt hors ligne ; le dépôt y arrive par un mini-PC (`git pull`), puis une clé USB (CLAUDE.md:16).

| Chemin | Contenu | Source |
| --- | --- | --- |
| `D:\constructeur-qwen-gamedev` | Copie de travail du dépôt, sur `main`, avec les corrections V2 non commitées (section 5). | notes |
| `D:\constructeur-qwen-gamedev\outils\` (hors dépôt) | `campagne_harnais.py`, `comparer_campagnes.py`, `harnais_maison.py`, `capture_godot.py`, `convertir_lora_qwen38.py`, et la sauvegarde `campagne_harnais.py.sauvegarde-20261011`. | notes ; V2, §9 ; Transcr. l. 4365 |
| `D:\constructeur-qwen-gamedev\donnees\rft\t1` | Le tour t1 : `registre.csv`, `retenus.csv`, `acquises.txt`, `a_refaire.txt`, `bilan.json`, `sessions\`, `export\` (dont `export\runpod\`, les fichiers envoyés au pod). Contenu à vérifier sur le PC. | notes ; Transcr. l. 126-134 ; Transcr. complète l. 2365-2372 |
| `D:\constructeur-qwen-gamedev\donnees\geles` | Les jeux gelés (221 tâches). | notes |
| `D:\constructeur-qwen-gamedev\donnees\bequille_qwen.html` | La page « La béquille de Qwen ». | ETAT.md:1024 |
| `D:\GODOT\projet_starfox` | Projet de départ des campagnes. Il a son propre dossier `scripts/`, hors du plan en huit dossiers. Ni dossier de tests ni GdUnit4 : `addons/` ne contient que `godot_ai`. Son `plan.md` avait 8 étapes cochées au départ. | notes ; P: causes_campagne_11oct.md, §4 ; Transcr. l. 3101 |
| `D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` | Godot 4.7.2 en console. Le dossier porte le nom de l'exécutable. | CLAUDE.md:29 |
| `D:\GODOT\AGENTS.md` | Conventions OpenCode de laurent : un `plan.md` à cocher, rester loin d'environ 80 000 jetons de contexte, confier les explorations lourdes à un sous-agent. Ne pas le contredire. | CLAUDE.md:31 |
| `D:\GODOT\projet_hades`, `projet_mario`, `projet_starfox_02` | Autres projets ; `projet_starfox_02` a été fait avec Claude Opus, aidé par laurent, et ne suit pas non plus une organisation professionnelle. | CLAUDE.md:30 ; Transcr., 9 octobre 04:47 |
| `G:\QWEN-GODOt` | Espace des campagnes : `PROMPT.md`, `PROMPT_BEQUILLE.md` (guide puis `PROMPT.md`), `LANCER_CAMPAGNES.bat`, `LANCER_CAMPAGNE_GUIDE_V2.bat`, `_journaux\` (journaux et marqueurs de fin), `starfox_harnais_RAG_bequille_V2\` (copie du projet modifiée par la V2). | notes |
| `G:\QWEN-GODOt\_journaux\<campagne>\` | `journal.txt`, `bilan.json`, `sessions\`, `captures\`, `etat.txt` (avancement en une ligne). Dossiers : `starfox-avec harnais et avec RAG` (9 octobre), `starfox_avec_harnais et avec RAG et avec guide AVANT PENDANT APRES` (11 octobre), `starfox_harnais_RAG_bequille_V2` (V2). | V2, §5 et §6 |
| `G:\QWEN-GODOt\_journaux\starfox_harnais_RAG_bequille_V2\avant_correction` | Originaux des fichiers corrigés après la V2 ; `apres_correction\` et `apres_camera\` gardent les captures de contrôle. | notes ; P: v2_trois_campagnes.md |
| `G:\llm_lora_trainer\` | Bases Hugging Face, dont `qwen38_27b`. | CLAUDE.md:46 ; Transcr. l. 79 |
| `E:\llama_models\qwen3.8\` et `E:\llama_models\LORA\lora_pour_qwen3827bq4\` | Le modèle GGUF, le projecteur de vision et `LORA_coding_godot-f16.gguf`. | Transcr. l. 2269 |

Deux détails pratiques : `py -3.12` est obligatoire sur ce PC, c'est le seul Python qui a le module `mcp` (V2, §5) ; la procédure `VERIFIER_EN_LOCAL.md` est celle qui fait foi sur la machine, avec les étapes 22, 23 et 24 encore à faire (notes ; VERIFIER_EN_LOCAL.md:542-628).

### 3.2 Le modèle et le serveur

- Qwen 3.8 multimodal, servi par llama-server sur `http://127.0.0.1:8080`, une requête à la fois, avec le projecteur de vision `--mmproj mmproj-qwen3.8-BF16.gguf` et le LoRA `LORA_coding_godot-f16.gguf` à l'échelle 1.0. Godot 4.7.2 (notes).
- Le dépôt précise : Qwen3.8-27B en GGUF Q4, architecture hybride `qwen35`, API OpenAI-compatible sur `/v1` ; llama-server accepte plusieurs LoRA et un champ `lora` par requête (`[{"id": 0, "scale": 1.0}]`) (CLAUDE.md:32-37).
- Ligne de lancement de laurent, envoyée le 8 octobre à 20:16 puis corrigée à 20:17 (doublons `--host` et `--port` retirés) (Transcr. l. 2259, 2269). Ne pas la modifier sans lui :

```bat
start "Llama Server Qwen3.8 AGENT + LORA GODOT" llama-server.exe -m "E:\llama_models\qwen3.8\Qwen3.8-27B-UD-Q4_K_XL--vraimodel.gguf" --mmproj "E:\llama_models\qwen3.8\mmproj-qwen3.8-BF16.gguf" -ngl 99 -c 200000 -fa on --parallel 1 --cache-type-k q8_0 --cache-type-v turbo3 --spec-type draft-mtp,ngram-mod --spec-draft-n-max 3 --jinja --reasoning off --reasoning-budget 0 --no-prefill-assistant --lora "E:\llama_models\LORA\lora_pour_qwen3827bq4\LORA_coding_godot-f16.gguf" --host 127.0.0.1 --port 8080
```

- Cette ligne passe `-ngl 99`, alors que `CLAUDE.md:36` dit de ne jamais passer `-ngl`, parce que le build de l'époque refusait de démarrer : question ouverte pour laurent (section 12.1, question 2). Le contexte réellement utilisable avec `-c 200000` n'a jamais été mesuré : à vérifier sur le PC (section 12.2).
- Vérifier que le LoRA est chargé : `http://127.0.0.1:8080/lora-adapters` doit montrer `LORA_coding_godot-f16.gguf` avec `"scale": 1.0` (V2, §5).
- Cache de llama-server : un bloc fixe de 13 507 jetons en tête du message système coûte 7,6 s au premier envoi, puis 0,3 s ; la moindre modification au début oblige à tout recalculer (ETAT.md:1022 ; Transcr. l. 4343-4356).
- Coût des images : sur les Qwen récents, environ un millier de jetons par image en 720p, et le harnais de campagne joint deux images par capture (notes).

### 3.3 L'entraînement

- LLaMA-Factory sur RunPod (notes). Le tour t1 a été entraîné sur une H200 SXM (143 771 MiB vus par `nvidia-smi`, 5,39 $ de l'heure), avec le gabarit RunPod « Code Canvas - Llama-Factory - Liger - Unsloth » (Transcr. l. 20, 58, 177, 808).
- Résultat : QLoRA rang 16, 2 époques, 24 pas, 2 h 04, perte 0,078 ; converti en `LORA_coding_godot-f16.gguf` (233 Mo) (ETAT.md:1019). Les détails, la mémoire et les leviers sont en section 14.

### 3.4 Le dépôt et ses branches

- `main` est au commit `4296a4e` (fusion du 6 octobre). La branche de travail est au commit `83e8bc4`, six commits au-dessus de `main` : `76294f2` (décision du gel sous 4.7.2, étape 21), `682acbf` (béquille, point 1), `664c3fc` (point 2), `70af300` (points 3 à 9), `ddd3de4` (preuve dans `ETAT.md`), `83e8bc4` (règles d'architecture).
- Fichiers de référence : `CLAUDE.md` (résumé exécutable du projet), `ETAT.md` (journal de reprise, 1 363 lignes), `VERIFIER_EN_LOCAL.md` (procédure Windows), `config.example.toml` (modèle de `config.toml`).
- Dossiers : `usine/` (le paquet Python), `mcp_serveur/` (serveur MCP « usine-godot »), `skills/` (une fiche `SKILL.md` par compétence), `godot/` (`reference`, `survivor`, `kenney_platformer`, `kenney_racing`, `socle_jeu`, `taches_modeles`), `tests/`, `preuves/`, `prompts/`.
- Absent du dépôt : le harnais de campagne et l'outil de comparaison, `harnais_maison.py`, `capture_godot.py`, `convertir_lora_qwen38.py`, les corrections V2 et toutes les données (`/donnees/` est ignoré par git, `.gitignore`).
- Pour lire le dépôt depuis le cloud : `git clone --depth 1 https://github.com/zarathoustraLily/constructeur-qwen-gamedev`, puis `git fetch --depth 50 origin claude/project-thread-12uh5s` (annexe B.8). Le dépôt n'utilise pas Git LFS ; `.gitattributes` force les fins de ligne LF, sauf pour `.bat` et `.cmd` (CRLF).
- `outils/` n'est pas ignoré par git : sur le PC, les outils hors dépôt (`campagne_harnais.py`, `comparer_campagnes.py`…) devraient donc apparaître comme fichiers non suivis (`??`) dans `git status --short` (`.gitignore` ; non vérifié sur le PC).

### 3.5 Le serveur MCP « usine-godot »

`mcp_serveur/serveur.py` expose les outils de l'usine par stdio (lancement : `python mcp_serveur/serveur.py --projet <dossier>`). Sur `main` : `vocab_lookup`, `search_docs`, `scene_read`, `scene_write`, `describe_project`, `apply_edits`, `check_script`, `load_scene`, `run_tests`, `measure_efficiency` (10 outils, mcp_serveur/serveur.py:46-85 (main)). La branche ajoute `check_structure`, `prepare_action` et `capture_frames` (mcp_serveur/serveur.py:89-106). `outils/opencode_fusion.py` déclare ce serveur et les fiches dans l'`opencode.json` d'un projet (VERIFIER_EN_LOCAL.md:257-266).

### 3.6 Les documents

Tous sont dans le dossier partagé des sessions cloud, `/mnt/project-files/` ; ce qui compte est recopié ici.

| Abréviation | Fichier | Contenu |
| --- | --- | --- |
| (V2) | `uploads/hearth/09e9589f-332d-4769-bcbb-d1842aedcbbd` | « Campagne Godot harnais + RAG + béquille, V2 » : corrections M1 à M5, lancement, comparaison, limites. |
| (Appr.) | `uploads/hearth/899e3085-5350-4e58-8ee8-1103e6c531bf` | « Ce que cette conversation a établi » : vérification des 51 règles, faits Godot, usage des règles pour l'entraînement (section 9), sources. Version vivante des règles : https://claude.ai/artifact/SwDCw4gh7EGF4vxWBFAmgQ |
| (Règles1) | `uploads/hearth/a59be4b8-6956-4851-bb63-8ae59b7f6ca3` | Les règles d'architecture vérifiées, recopiées en annexe A. |
| (Transcr.) | `uploads/hearth/2014a8aa-a569-49c1-ad36-db33dbf414ea` | Transcription de la conversation du 8 au 11 octobre (dialogue seul) : entraînement RunPod, campagnes, béquille. Citée par numéro de ligne ou par heure UTC. |
| (Transcr. complète) | `uploads/hearth/b27d0311-71aa-4750-bc3f-36574554a6ed` | La même avec les sorties d'outils. |
| (Béquille) | `uploads/hearth/b4ee773e-c654-4fd5-a1cf-2b6e17183a5c` | Page HTML « La béquille de Qwen » : dix points, trois moments, ordre de construction. |
| (P: ...) | `v2_trois_campagnes.md`, `causes_campagne_11oct.md`, `guide_vs_rag_9oct.md`, `gamedevbench_333_par_categorie.md` | Analyses des campagnes et classement de GameDevBench. |
| (fil) | Fichier de session de la conversation principale du 11 octobre, hors du dossier partagé | Messages de laurent, cités par heure UTC ; les phrases utiles sont recopiées dans ce document. |

Autres fichiers du même dossier : `uploads/hearth/750acb71-...` (cahier des charges de la compétence E par laurent), plusieurs versions anciennes d'`ETAT.md`, deux archives sur Hades II (`.notes/inputs.md` les décrit). Le document de conception d'origine est un artefact : https://claude.ai/code/artifact/076d696f-40e9-4330-9182-ee98631fb470 (CLAUDE.md:9).

## 4. L'usine sur main

### 4.1 Les compétences

Tableau des compétences de laurent, relevé sur `main` au commit `4296a4e` ; laurent l'a recopié dans le fil (notes ; fil, 12:18) :

| Domaine | Compétence | Sessions d'entraînement (sur 93) | Tâches gelées (sur 221) |
| --- | --- | --- | --- |
| Debug | K3 : corriger un test rouge par un patch minimal | 29 | 50 |
| Debug | D1 : lire un log et trouver fichier:ligne | 0 | 6 |
| Algo, optimisation | E : rendre un jeu 2D plus efficace, même rendu | 43 | 50 |
| Physique | F1 : régler vitesse et dash du héros | 0 | 50 |
| Écrire du code | K1 : script depuis une interface | 6 | 12 |
| Écrire du code | K2 : corps de méthode depuis contrat et tests | 10 | 36 |
| Scènes et signaux | S1 : créer une scène | 5 | 10 |
| Scènes et signaux | S2 : brancher un signal | 0 | 7 |

- D1, F1, K1, S1 et S2 se jouent en un seul appel (4 à 8 s) ; K2, K3 et E sont agentiques (notes ; `usine/mesure/reponses.py:36`).
- `CLAUDE.md:63-80` décrit 14 compétences (C1, C2, S1, S2, S3, K1, K2, K3, K4, D1, D2, F1, F2, E). C1, C2, S3, K4, D2 et F2 n'avaient pas de générateur (ETAT.md:1011) ; la branche donne à K4 ses tâches « nettoyer » (section 9).

### 4.2 Le format d'une tâche

Un dossier par tâche : `tache.json` (`id`, `competence`, `consigne`, `origine`, `empreinte`, `gelee`, et un champ `juge` facultatif), `depart/` (projet de départ, copié à chaque essai), `reference/` (solution superposée au départ, jamais montrée à l'agent), `tests_caches/` (copiés dans `res://tests_juge` seulement au moment de juger) (CLAUDE.md:99-107 ; usine/taches.py:1-26). L'empreinte est un SHA-256 du contenu (usine/taches.py:65-78) ; les fins de ligne sont forcées en LF (`.gitattributes`).

### 4.3 La génération des tâches

`python -m usine.generateurs produire` passe chaque projet source dans les générateurs, avec une graine fixe (usine/generateurs/produire.py:1-41, 71-77) :

| Générateur | Compétences | Principe |
| --- | --- | --- |
| masquage | K2, K1 | K2 : un corps de méthode vidé ; K1 : une interface (classe, méthodes, signaux, variables) à réécrire (notes). |
| aller-retour | S1, S2 | S1 : une spec de scène puis `scene_write` ; S2 : des connexions, jugées par `preparer_edits` (notes ; usine/projet/editions.py:733). |
| inverse | F1 | Paramètres du héros tirés au hasard et mesurés en images ; il faut retrouver des `@export` de `scripts/hero.gd` qui donnent ces mesures, à 0,5 px près (usine/generateurs/inverse.py:1-12). Seulement sur `godot/reference` (usine/generateurs/sources.py:11-12). |
| mutation | K3, D1 | K3 : un mutant que les tests du projet voient, patch plafonné à 6 lignes (usine/generateurs/mutation.py:41, 89). D1 : un bug injecté, réponse attendue catégorie, fichier et ligne. |
| efficience | E | Paires de jeux 2D écrites par le générateur : départ naïf et référence optimisée, identiques en comportement et en rendu (CLAUDE.md:82). |
| salissures (branche) | K4 | Une violation de règle injectée dans le socle propre (section 9). |

Projets sources (usine/generateurs/sources.py:38-43) : `reference` (le jeu 2D de la session 1), `survivor` (« 01-survivor », bullet heaven 2D sous licence MIT, 128 tests portés de GUT), `kenney_platformer` et `kenney_racing` (kits 3D de Kenney, code MIT et assets CC0, tests GdUnit4 écrits pour l'usine). Chaque générateur a un plafond par source.

### 4.4 Le portillon et le gel

- Une candidate est acceptée si son format est valide (champs, empreinte, au moins un test caché), si le départ est rouge et la référence verte 3 fois sur 3, si ses tests cachés tuent au moins 50 % des mutants de la référence (8 mutants au plus), et si elle ne double pas un jeu gelé (empreinte, ou fragments au-delà d'un Jaccard de 0,8). Pour E, le départ doit échouer à l'étape `mesure_efficience` et la référence y passer (usine/portillon/regles.py:1-17, 57-71 ; config.example.toml:41-45).
- Coût : environ 14 jugements par candidate, environ 20 s chacun sur 4 cœurs ; un cache des verdicts accélère les relances (ETAT.md:1363).
- Gel : tirage reproductible par compétence, cible 50 tâches, au plus la moitié des tâches qualifiées ; le manifeste ne se réécrit pas ; `--completer-gel` ajoute sans retirer, et seulement avant le premier entraînement (usine/portillon/gel.py:1-12 ; ETAT.md:1011). Les sessions et le RAG excluent les tâches gelées (`usine/portillon/exclusion.py` ; `python -m usine.rag verifier`).
- Sur le PC : 221 tâches gelées, soit E 50, F1 50, K3 50, K2 36, K1 12, S1 10, S2 7, D1 6 (notes). Leur usage, mesure ou entraînement, est une question ouverte pour laurent (section 12.1, question 1).

### 4.5 Les juges et le format du verdict

Tout juge rend le même verdict (CLAUDE.md:88-97 ; usine/juge/verdict.py:68-74), complété par `tache_id` :

```json
{"ok": false, "etape": "run_tests", "duree_s": 1.8,
 "erreurs": [{"fichier": "res://scripts/hero.gd", "ligne": 42, "categorie": "null_instance", "message": "..."}],
 "tests": {"total": 6, "passes": 5, "echecs": ["test_dash_iframes"]}}
```

- Catégories : `parse_error`, `null_instance`, `invalid_node_path`, `signal_missing`, `type_error`, `missing_resource`, `test_failure`, `autre` (usine/juge/verdict.py:15-24). E ajoute `efficience_allocations`, `efficience_draw_calls`, `efficience_temps`, `rendu_degrade` (usine/efficience/juge.py:36) ; `apply_edits` ajoute `id_inconnu`, `vocab_inconnu`, `valeur_invalide` (usine/projet/EDITS_GODOT.md:104) ; le juge des règles ajoute `regle` et `structure`, avec l'identifiant de la règle (section 8).
- Juge commun : `juger_tache` (usine/taches.py:96-140 (main) ; 107-157 sur la branche). Il compose le projet (départ, référence ou candidat), applique le plafond `patch_max_lignes` s'il existe, puis appelle `juger_projet` (usine/juge/projet.py:98-104).
- `preparer_copie` (usine/juge/projet.py:32-46) copie le projet, pose le socle de l'usine (`usine/socle.py`), ajoute GdUnit4 et les tests cachés dans `res://tests_juge`. `juger_sur_place` (usine/juge/projet.py:49-95) enchaîne `import`, `check_script` (`--check-only`, un lancement pour tout le lot puis script par script si besoin), `load_scene`, puis `run_tests` avec GdUnit4. `tache.json` peut fixer `juge.etapes` et `patch_max_lignes` (usine/taches.py:9-11).
- E : `usine/efficience/juge.py` (`completer`, étape `mesure_efficience`, ligne 175) exige le rendu intact, 0 allocation après l'échauffement, des lots de dessin au plus à 1,05 fois la référence et un temps au plus à 1,15 fois, ce dernier seulement si la tâche le déclare (usine/efficience/juge.py:1-34 ; notes).
- Détail par compétence (notes) : K3, mutant et tests du projet, `patch_max_lignes` 6 ; K2, corps de méthode vidé ; D1, bug injecté, réponse catégorie, fichier, ligne ; K1, classe, méthodes, signaux, variables ; S1, spec puis `scene_write` ; S2, `preparer_edits` ; F1, `@export` de `scripts/hero.gd`, mesures en images, tolérance 0,5 px.
- Pièges du juge (ETAT.md:1341-1349) : `--check-only` ignore les autoloads (relance avec autoloads dans `usine/juge/gd/charger_script.gd`) ; GdUnit4 en headless exige `--ignoreHeadlessMode` ; l'import prend environ 9 s par copie, un jugement environ 15 s ; un journal reproductible demande `--fixed-fps 60`.

### 4.6 La boucle RFT

- `usine/rft/tour.py` (lignes 87-127) : pour chaque tâche, N essais (`essais.py`), puis réécriture atomique de `registre.csv` après chaque tâche (une tâche finie n'est jamais refaite, une tâche coupée est refaite en entier), puis filtre, export et `bilan.json`.
- `usine/rft/essais.py` : en un appel, appel direct à llama-server, sortie contrainte par le schéma JSON de la compétence, température 0,7 et graine plus numéro d'essai, jugement par `reponses.juger_reponse` (usine/rft/essais.py:34-47, 111-129 ; usine/mesure/reponses.py:227). En agentique, copie du départ, l'agent maison joue, puis `juger_tache` juge la copie (usine/rft/essais.py:131-137).
- L'agent maison (`usine/rft/agent.py`) donne les outils du serveur MCP plus `list_files`, `read_file` et `write_file` (lignes 34-60), met la fiche de compétence dans le message système (lignes 63-70, 148) et demande de finir par un court message sans appel d'outil (lignes 29-32). Budget : 40 appels au modèle (usine/rft/essais.py:46 ; config.example.toml:87). Fins possibles : `termine`, `budget`, `erreur_appel` (lignes 138-172).
- Chaque essai est enregistré en JSONL : une ligne d'en-tête (`tache_id`, `competence`, `verdict_final`, `harnais`, `graine`, `temperature`, `lora`, `fin`, `tools`…), puis un message par ligne (usine/rft/essais.py:146-151 ; CLAUDE.md:109).
- Tri sur `main` : par tâche, la réussite la plus courte, mesurée sur la seule production du modèle (texte et arguments d'appels, pas les résultats d'outils) (usine/rft/filtre.py:1-5, 17-29 (main) ; usine/rft/essais.py:83-90). Filtre de difficulté : sur 8 essais, une tâche réussie plus de 6 fois est « acquise » et n'est pas exportée ; une tâche jamais réussie va dans `a_refaire.txt` (usine/portillon/difficulte.py:13-23 ; usine/rft/filtre.py:41-58).
- Le portillon et les juges sont décrits dans `portillon/regles.py` ; gdlint est annoncé comme juge de K1 (CLAUDE.md:72) mais n'est employé nulle part dans le code (notes ; vérifié par recherche dans le dépôt).

### 4.7 L'export

`usine/rft/export.py` écrit, pour un tour :

- `sft.jsonl` : les messages au format chat OpenAI, avec `tool_calls` ; il garde tout, texte compris (usine/rft/export.py:4-5, 189-190 ; ETAT.md:948).
- `llamafactory/usine_godot.jsonl` : le format sharegpt de LLaMA-Factory (`human`, `gpt`, `function_call`, `observation`). Un message assistant qui porte des appels devient un tour `function_call` qui ne garde que les appels : **son texte est perdu** (usine/rft/export.py:87-91). Plusieurs résultats d'outils successifs forment un seul tour `observation` (lignes 94-95) ; l'alternance est stricte (lignes 98-103).
- `llamafactory/dataset_info.json` et `qwen38_qlora_r16.yaml` : QLoRA rang 16, alpha 32, dropout 0,05, `lora_target: all`, 4 bits bitsandbytes, `template: qwen3`, `cutoff_len: 16384`, sans packing, `train_on_prompt: false`, lot de 1, accumulation 8, taux 1e-4, 2 époques, cosinus, échauffement 0,05, bf16 (usine/rft/export.py:110-122).
- `unsloth/` : l'alternative Unsloth, qui lit `sft.jsonl` (`train_on_responses_only`, sans packing) (usine/rft/export.py:158-163 ; usine/rft/modeles/entrainer_unsloth.py).
- La perte ne porte que sur les messages assistant ; le packing est désactivé parce que rien ne garantit la remise à zéro de l'état récurrent entre exemples sur l'architecture hybride (usine/rft/export.py:13-18).
- Règle 4 : une session d'une tâche gelée, ou qui reprend ses fragments, est écartée (usine/rft/export.py:20-21, 174-182).

### 4.8 Entraînement, conversion, lancement

- Procédure du dépôt (VERIFIER_EN_LOCAL.md:410-430) : `llamafactory-cli train <yaml>`, puis `python -m usine.rft gguf` (`convert_lora_to_gguf.py --outtype f16`), puis `python -m usine.rft lanceur`, qui écrit un `.bat` avec un `--lora` par adaptateur, `--reasoning off --reasoning-budget 0 --no-prefill-assistant` et sans `-ngl`.
- En pratique pour t1 : le YAML a été adapté au pod, avec `template: qwen3_8` au lieu de `qwen3` (Transcr. l. 136-143) ; le convertisseur de llama.cpp plantait sur ce LoRA, parce que `lora_target: all` touche aussi les couches d'attention linéaire (`out_proj`), et un lanceur local `outils/convertir_lora_qwen38.py` a été écrit sur le PC (Transcr. complète l. 4066).

### 4.9 La mesure du dépôt

`usine/mesure` compare quatre configurations (base ou LoRA, avec ou sans RAG) sur les jeux gelés, avec un intervalle de Wilson et une règle de non-régression (CLAUDE.md:136-143), et contient un adaptateur GameDevBench (`usine/mesure/gamedevbench.py`). laurent évalue désormais par campagnes Starfox avec LoRA (décision 1, section 10) : cette mesure n'est plus son critère, et le sort des jeux gelés dont elle dépend est ouvert (section 12.1, question 1).

## 5. Le harnais de campagne, la béquille et les corrections V2 non commitées

### 5.1 Ce qu'est une campagne

- Le harnais copie `D:\GODOT\projet_starfox`, jeu déjà fait avec son `plan.md`, dans un dossier de sortie neuf. Il ne copie que si ce dossier ne contient pas déjà de `project.godot` (V2, §5 ; Transcr. l. 3091-3101).
- Le prompt demande d'améliorer le jeu pendant deux heures (Transcr., 8 octobre 23:49). La campagne dure 120 minutes, plus la fin de l'action en cours (V2, §5).
- Les sessions s'enchaînent. Une session finit par budget, par contexte plein ou par erreur d'appel ; la suivante repart d'une conversation vide avec le même prompt, et seuls les fichiers du projet, dont `plan.md`, font le lien. Personne ne dit à Qwen à quelle étape il en est (Transcr. l. 3478, 3640).
- llama-server ne traite qu'une demande à la fois : les campagnes passent l'une après l'autre (Transcr. l. 3017).
- Une fenêtre Godot s'ouvre quelques secondes à chaque capture (V2, §5).

### 5.2 Le harnais et ses outils

- `outils\campagne_harnais.py`, équipement `usine_rag`. Outils donnés à Qwen : `search_docs`, `vocab_lookup`, `read_file`, `write_file`, `apply_edits`, `check_script`, `run_tests`, `load_scene`, `capture_ecran` (notes ; `read_file` : P: causes_campagne_11oct.md, §3, et les lectures de `plan.md` comptées dans P: v2_trois_campagnes.md). Les campagnes du 8 octobre donnaient aussi de quoi lister les fichiers (Transcr. l. 3007) ; le nom exact de cet outil est à vérifier dans `campagne_harnais.py`, sur le PC.
- `apply_edits` accepte les opérations `add_node`, `del_node`, `set_property`, `attach_script`, `connect`, `disconnect`, `add_signal`, `add_function`, `replace_function` (champs `script`, `fonction`, `corps` ou `code`) et `set_resource_value` (notes ; usine/projet/EDITS_GODOT.md:35-46). Les éditions sont tout ou rien : au premier refus rien n'est écrit, et la copie n'est gardée que si le juge passe (usine/projet/EDITS_GODOT.md:65-79).
- `capture_ecran` lance le jeu et joint deux PNG par capture, comme de vraies images (notes).

### 5.3 Lancer, suivre, comparer

- Lancement V2 : `G:\QWEN-GODOt\LANCER_CAMPAGNE_GUIDE_V2.bat`, ou `cd /d D:\constructeur-qwen-gamedev` puis `py -3.12 outils\campagne_harnais.py D:\GODOT\projet_starfox "G:\QWEN-GODOt\starfox_harnais_RAG_bequille_V2" --equipement usine_rag --minutes 120 --prompt G:\QWEN-GODOt\PROMPT_BEQUILLE.md` (notes).
- Marqueur de fin : `G:\QWEN-GODOt\_journaux\TERMINE_GUIDE_V2.txt` (notes). Avancement : `etat.txt` dans le dossier de journaux (V2, §5).
- Comparaison : `outils\comparer_campagnes.py` sur les trois dossiers de journaux ; il affiche un tableau Markdown, une colonne par campagne (notes ; V2, §6).
- Retour arrière du harnais : `outils/campagne_harnais.py.sauvegarde-20261011` (notes).

### 5.4 La béquille

- Principe (Béquille) : ne pas rendre Qwen plus savant, mais lui mettre la bonne information sous les yeux au bon moment. En permanence : le plan d'organisation, les conventions, un exemple complet, en cache. Avant l'action : Qwen dit ce qu'il va faire et reçoit où travailler, l'exemple à imiter, les règles et les pièges. Après l'action : le retour d'outil dit ce qui s'est vraiment passé. La page précise que ses dix points sont des propositions ; l'ordre de construction a été décidé par laurent (ETAT.md:1024).
- Dans les campagnes : `PROMPT_BEQUILLE.md` place un guide AVANT / PENDANT / APRÈS devant `PROMPT.md`, avec le plan de dossiers `0_autoload` à `7_tests`, `plan.md` et `plans/etape_N.md`, et la règle « fini quand : verdict écrit » (notes). Le fichier n'est ni dans le dépôt ni dans le dossier partagé : son texte exact est à vérifier sur le PC.
- Dans le dépôt : `godot/socle_jeu/AGENTS.md` est la version de la branche. Bloc permanent : les cinq principes et le tableau des dossiers (lignes 1-19). Avant chaque étape : ouvrir `plan.md`, écrire le but, le type d'action et les fichiers, appeler `prepare_action`, lister les noms Godot et les chercher, cinq recherches au plus (lignes 21-25). Après chaque action : lancer les tests, ne pas réécrire un fichier qui ne change pas, chercher la doc après une erreur, écrire un verdict en trois lignes après chaque capture, `check_structure`, cocher `plan.md`, compte rendu final (lignes 27-33).

### 5.5 Les corrections V2 (sur le PC seulement, non commitées)

La campagne du 11 octobre a calé : `TrackBuilder.gd` réécrit 31 fois, passé de 11 051 à 23 434 caractères, réponse coupée au-delà de 8 192 jetons, appel coupé gardé dans l'historique, puis HTTP 500 de llama-server et 14 sessions mortes sur les 16 dernières (V2, §1 ; P: causes_campagne_11oct.md, §1). Cinq corrections ont suivi (notes ; V2, §2). Leur code n'existe que sur le PC, non commité : les descriptions ci-dessous viennent des notes et du document V2, et le code exact est à vérifier sur place.

- **M1**, `usine/rft/agent.py`, fonction `neutraliser_arguments`, appelée dans `Campagne.executer` (`outils/campagne_harnais.py`) : un appel d'outil tronqué est remplacé dans l'historique par `{"arguments_illisibles": "N caractères, coupés ou mal formés"}`, avec une erreur qui conseille `apply_edits` ou `replace_function`. Cause corrigée : un appel tronqué gardé dans l'historique faisait répondre llama-server en HTTP 500 (« Failed to parse tool call arguments as JSON »). Auteur : un autre fil, le 11 octobre vers 05:05 UTC, soit 07:05 à l'heure du PC (V2, §2 ; fil, 05:06).
- **M2**, `usine/projet/editions.py` : refus plus clairs (« replace_function : champ « fonction » manquant… », « champs non reconnus : function (champs de replace_function : script, fonction, corps, code) »), table `CHAMPS` ; la catégorie `id_inconnu` de ce cas devient `valeur_invalide`. Aucune édition n'est acceptée ou refusée autrement qu'avant.
- **M3**, `outils/campagne_harnais.py`, fonction `langage_edition()` : ajoute au message système la liste des champs de chaque opération, tirée de `usine/projet/EDITS_GODOT.md`, avec l'exemple `{"op": "replace_function", "script": "res://scripts/hero.gd", "fonction": "try_dash", "code": "func try_dash() -> void:\n\tpass"}`.
- **M4** : `MAX_JETONS` passe de 8192 à 16000.
- **M5** : signal `ecriture_sans_effet` et compteur `ecritures_sans_changement` dans `bilan.json`.
- Tests : `tests/test_editions.py` 40 sur 40 ; 81 sur 81 avec `test_rft.py` et `test_mesure.py` (notes ; V2, §4).
- **Pas d'alias** : décision de conception du document V2 (§3), pas de laurent. `nom` désigne déjà le nom de nœud dans `add_node`, et `preparer_edits` est le juge de S2 : accepter `nom` ou `function` changerait les notes des jeux gelés. Deux tests de `tests/test_editions.py` la verrouillent.
- La branche de travail ne contient pas ces changements (notes ; vérifié : ni `neutraliser_arguments`, ni table `CHAMPS`, ni `MAX_JETONS` dans le dépôt).
- À la fusion : M5 fait doublon avec la branche, qui signale l'écriture sans effet directement dans `write_file` ; le retirer de l'outil de campagne ce jour-là (V2, §7).

### 5.6 Limites connues du harnais

- Le langage d'édition n'a aucune opération pour ajouter une variable : Qwen doit réécrire le fichier entier dès qu'il lui faut une variable de plus (V2, §7).
- Quand un script ne compile plus, l'erreur d'origine arrive en cinquième position du verdict, après celles des scripts qui en dépendent (V2, §7).
- Une seule campagne par cas, à température 0,7 : une partie des écarts tient au hasard (V2, §7).
- Ce que la branche apporte et que le harnais du PC n'utilise pas : l'écriture vérifiée de l'agent maison (usine/rft/agent.py:97-104), le rapport de vocabulaire de `check_script`, les fiches jointes aux erreurs, `capture_frames` (grille horodatée et journal `Trace`), `prepare_action` et `check_structure`. `capture_ecran` doit encore être branché sur `usine.retour.capture` (VERIFIER_EN_LOCAL.md:632 ; ETAT.md:1097).

## 6. Ce que les campagnes ont montré

### 6.1 Les cinq campagnes

Toutes sur Starfox, 2 h chacune, avec LoRA : trois dans la nuit du 8 au 9 octobre (« harnais + RAG », « harnais », « sans harnais » ; Transcr. l. 3103), celle du 11 octobre (« RAG + guide ») et la V2 (« RAG + guide + M1 à M5 »). laurent a jugé la V2 « le pire des 4 » (fil, 09:08) ; sur ce décompte, voir 12.3.

### 6.2 Les trois campagnes comparées

Chiffres de l'outil `comparer_campagnes.py` sur les trois dossiers de journaux (notes ; V2, §6 ; P: v2_trois_campagnes.md, qui donne aussi la colonne V2 complète, les durées et les pas).

| Mesure | 9 oct. (RAG) | 11 oct. (RAG + guide) | V2 (RAG + guide + M1 à M5) |
| --- | --- | --- | --- |
| Durée | 2:00:08 | 2:00:00 | 2:00:06 |
| Sessions | 18 | 28 | 21 |
| Pas (réponses du modèle) | 643 | 628 | 728 |
| Fins par budget, contexte, erreur d'appel | 10, 7, 0 | 9, 4, 14 | 11, 9, 0 : aucune session morte |
| Réponses coupées | 0 | 14 | 0 |
| `search_docs` | 4 | 59 | 17 |
| `vocab_lookup` | 4 | 22 | 14 |
| `write_file` | 227 | 158 | 233 |
| Écritures identiques à la précédente du même fichier | 133 | 37 | 121 ; le signal M5 est sorti 125 fois |
| `apply_edits` | 97 | 22 | 96 |
| `apply_edits` acceptés | 33 | 1 | 34 |
| `apply_edits` refusés à la validation | 57 | 20 | 16 |
| `apply_edits` refusés par le juge | 7 | 0 | 46, dont 44 parce que le script ne compile plus |
| `replace_function` avec `script` et `fonction` | 46 sur 90 | 0 sur 43 | 108 sur 108 avec `fonction`, aucun `nom` ni `function` |
| `check_script` | 86 (6 échecs) | 82 (13 échecs) | 61 (2 échecs) |
| `run_tests` et `load_scene` | 0 et 0 | 0 et 0 | 0 et 0 |
| `capture_ecran` | 113 | 80 | 93 |
| Messages qui contiennent du texte | 0 | 0 | 0 |
| Verdicts écrits après une capture | 0 | 0 | 0 dans les messages ; 2 dans des fichiers (`plans/etape_71.md`, `plans/etape_73.md`) |

Pour le 11 octobre, un premier décompte donnait 50 écritures identiques sur 158 ; l'outil en compte 37 parce qu'il ignore les écritures coupées (P: guide_vs_rag_9oct.md ; V2, §6).

Rangement, d'après P: guide_vs_rag_9oct.md et P: v2_trois_campagnes.md : aucun dossier `0_` à `7_` créé, aucune scène `.tscn` ni ressource `.tres` dans les trois campagnes. `plan.md` : 18 lectures et 22 écritures, 38 cases cochées le 9 octobre ; 31 et 31, 52 cases et 2 sous-plans le 11 octobre ; 32 et 58, 75 cases cochées et 9 sous-plans pour la V2. Seul nouveau script : `scripts/AudioManager.gd` le 11 octobre, `scripts/AudioFX.gd` pour la V2, tous deux dans l'ancien `scripts/`.

### 6.3 La nuit du 8 au 9 octobre

| Mesure | Sans harnais | Harnais | Harnais + RAG |
| --- | --- | --- | --- |
| Sessions | 23 | 22 | 18 |
| Lignes ajoutées et retirées | 1 725 et 160 | 1 316 et 158 | 1 304 et 130 |
| Améliorations cochées dans `plan.md` | 27 | 25 | 30 |
| Erreurs du moteur sur 15 s | 0 | 0 | 0 |
| Éditions refusées | outil absent | 65 | 70 |
| Écritures identiques à la précédente | 158 sur 286 | 148 sur 252 | 133 sur 227 |
| Recherches dans la doc | outil absent | outil absent | 4 |
| Captures prises, puis commentées | 136, puis 0 | 132, puis 0 | 113, puis 0 |

Source : Transcr. l. 4318-4329. Conclusion de l'époque : sur cette tâche ouverte, les outils et le RAG n'ont pas fait de différence mesurable (Transcr. l. 4333). Total des trois : 57 % d'écritures identiques et 381 captures, aucune commentée (ETAT.md:1021).

### 6.4 La V2 en détail

- **Rangement** : aucun dossier `0_` à `7_`, aucune scène, aucun `.tres` ; seul nouveau script `AudioFX.gd`, dans l'ancien `scripts/` ; `plan.md` tenu (75 cases cochées) et 9 sous-plans (notes).
- **Lancement cassé par la toute dernière action**, à 2:00:06 : `TrackBuilder.gd` réécrit avec `.replace("S", "stars")`, `.replace("N", …)` et `.replace("R", …)`, qui remplaçaient chaque majuscule (`SPEED` devenait `starsPEED`, `Node3D` devenait `nebula_rootode3D`). Corrigé aux lignes 210, 222, 238, 298, 338, 345, 446, 457 et 464 : le nœud passe par `set()`. Le minuteur s'est arrêté avant toute vérification (notes). Le même fichier produisait 120 erreurs « get_node_or_null on a null value » (P: v2_trois_campagnes.md).
- **Caméra à l'envers depuis la session 13** : la ligne du roulis `GameManager.gd:247` réécrivait toute la rotation après le `look_at` ; elle est remplacée par une rotation de roulis seule (notes), `rotate_object_local` (P: v2_trois_campagnes.md). Ni le projet de départ ni les campagnes du 9 et du 11 n'avaient ce défaut (même source).
- **Vision** : Qwen reçoit de vraies images. Il a écrit deux verdicts, dans `plans/etape_71.md` et `etape_73.md` (session 20), dont « Lisibilité : excellente… Ce n'est pas un défaut », alors que la caméra regardait vers l'arrière et que le vaisseau n'était qu'une tache au fond (capture `s020_p21`). Il décrit ce qu'il s'attend à voir. Après chacune des 36 captures prises depuis la session 13, il est passé à `plan.md` ou à `TrackBuilder.gd` (notes).
- **RAG** : 17 `search_docs`, toutes dans les sessions 3, 5 et 14, surtout pour vérifier des noms connus ; un seul nom nouveau, `mix_rate`, réutilisé ensuite (notes). Exemples de requêtes : `Environment tonemap_mode`, `glow_intensity`, `StandardMaterial3D rim` (P: v2_trois_campagnes.md).
- **Jugement de laurent** : « le résultat est un échec... c'est le pire des 4 » (fil, 09:08).

### 6.5 Les leçons

- Le contexte peut battre l'entraînement quand l'instruction est concrète : « fonction » 108 fois sur 108, contre le « nom » appris (notes).
- Le plan de dossiers a été ignoré : le projet avait déjà son dossier `scripts/` et rien ne refusait un fichier mal placé (notes).
- Ce qui est demandé noir sur blanc est fait : Qwen a lu `plan.md` en premier dans 48 sessions sur 48 ; `search_docs`, seulement proposé, a servi 4 fois (Transcr. l. 3369, 3389).

### 6.6 Les défauts constatés, en bref

Aucun texte, donc ni annonce, ni verdict, ni compte rendu ; réécritures identiques massives ; `apply_edits` mal employé, puis éditions qui cassent la compilation ; jamais de `run_tests` ni de `load_scene` ; captures non jugées, ou jugées sur ce qu'il s'attend à voir ; plan de dossiers ignoré ; RAG peu consulté et seulement pour vérifier des noms ; dernière action non vérifiée qui casse le jeu (sources : 6.2 à 6.4).

## 7. Les causes établies des défauts du LoRA t1

Toutes ces causes viennent des notes ; les preuves ajoutées sont sourcées.

1. **Mutisme.** L'export LLaMA-Factory a retiré le texte des 179 tours qui mêlaient texte et appel d'outil : le LoRA n'écrit plus de texte, donc ni verdict ni compte rendu (notes). Mécanisme : usine/rft/export.py:87-91. Détail : dans `usine_godot.jsonl`, les 892 tours `function_call` n'ont plus de texte, seuls les 90 messages finaux en gardent (P: causes_campagne_11oct.md, §3). Rejeu d'une même étape : avec le LoRA à 1,0, contenu vide ; à 0, Qwen écrit « I can see the issues: the HUD has overlapping labels… » (même source). La limite était notée dès le 5 octobre (ETAT.md:948).
2. **Le champ « nom » appris** dans les données d'entraînement, employé à la place de « fonction » (notes). Les données de t1 contiennent 136 `replace_function`, dont 111 refusés ; 63 emploient `nom`, tous refusés : le LoRA a aussi appris qu'un refus est normal (P: causes_campagne_11oct.md, §2). La fiche K3 dit d'utiliser `replace_function` sans nommer ses champs (skills/usine-k3-correctif/SKILL.md).
3. **Couverture étroite.** 93 sessions : E 43, K3 29, K2 10, K1 6, S1 5 ; aucune S2, F1 ni D1, bien que t1 ait joué 50 tâches F1, 8 tâches S2 et 4 tâches D1 (400, 64 et 32 essais) (notes ; bilan et registre de t1, Transcr. complète l. 5474-5498). Projets sources : surtout de petits jeux 2D (`reference`, `survivor`, paires de la compétence E), plus deux kits 3D de Kenney, `kenney_platformer` et `kenney_racing`, pour K1, K2, K3, S1, S2 et D1 (usine/generateurs/sources.py:38-43). La part de sessions 3D parmi les 93 est à vérifier dans `donnees/rft/t1`, sur le PC. Ni machine à états, ni interface, ni effets, ni shaders (notes) ; laurent : « il n'y a aucun algo, shader, aucun son, aucune UI » (fil, 07:31).
4. **Le tri** gardait la réussite la plus courte, sans critère d'organisation (notes ; usine/rft/filtre.py:26 (main)).
5. **Le tour t1** : 272 tâches, 8 essais chacune, 2 176 essais dont 1 151 réussis (53 %). Sont écartées 99 tâches « acquises » (plus de 6 réussites sur 8) et 70 jamais résolues ; 103 tâches sont retenues, dont 10 écartées à l'export parce qu'elles reprenaient une tâche gelée (règle 4) ; restent 93 sessions, une par tâche (notes ; `bilan.json` et `registre.csv` de t1, Transcr. complète l. 5474-5498). Les 221 tâches gelées n'ont pas été jouées (E 50, F1 50, K3 50, K2 36, K1 12, S1 10, S2 7, D1 6) (notes). Sur le « 93 sur 575 » de laurent, voir 12.3.
6. **Le coût de t1** : 33,3 h de calcul, 55 s par essai en moyenne (médiane 36 s), 48 h du 6 octobre 09:28 au 8 octobre 09:43 ; E 118 s par essai et 17,6 h, K3 52 s et 9,6 h, K2 55 s et 4,5 h, tâches à un appel 4 à 8 s. Construction des générateurs et des juges : environ trois jours, du 3 au 5 octobre (notes).
7. **Les réécritures identiques** : seulement 5 écritures identiques sur 105 dans les données d'entraînement, contre 121 sur 233 en V2. Un rejeu avec et sans LoRA a été interrompu à la demande de laurent (« SURTOUT PAS », fil, 11:45). **Origine inconnue** (notes). laurent pense que « c'est dans le LoRA », puisque c'est « récurrent quel que soit l'environnement » (fil, 09:12) ; ce n'est pas établi.

Autres faits du dépôt et des documents qui pèsent sur t1 (non classés comme causes dans les notes) :

- 12 sessions sur 93 dépassent 16 384 jetons et sont tronquées à l'entraînement ; le filtre « plus courte » ne compte pas les résultats d'outils (ETAT.md:1019). Longueur des sessions : médiane 7 600 jetons, moyenne 10 200, maximum 70 200, environ 21 tours (Transcr. l. 1667-1674).
- Le LoRA a appris `read_file` et `write_file`, absents d'OpenCode ; c'est pourquoi laurent l'a jugé mauvais dans OpenCode (ETAT.md:1020 ; Béquille, point 10).
- Les données contiennent 91 `run_tests` mais seulement 10 `load_scene` (P: causes_campagne_11oct.md, §4).

## 8. Les règles d'architecture

### 8.1 La version vérifiée

`Règles1.md`, fourni par laurent, est la version vérifiée : 51 règles, dont 12 corrigées (ORG-01, ARC-03, ARC-05, ARC-06, ARC-11, DAT-05, SIM-02, SIM-03, SIM-08, SIM-09, SIM-10, COD-04), 21 confirmées et 18 choix de projet (notes). Elle est recopiée intégralement en annexe A. Le détail de la vérification (ce qui n'allait pas et la source de chaque correction) est dans Appr., sections 4 et 6. Leçon retenue : une règle reformulée n'est pas une règle vérifiée, et un juge bâti sur une règle fausse enseigne durablement la mauvaise habitude (Appr., §2).

### 8.2 Les huit points à trancher

laurent ne les a jamais tranchés. Le juge et le socle appliquent les réponses par défaut, plus GdUnit4, déjà utilisé par le juge (notes). Les questions et les réponses par défaut sont dans l'annexe A, section « Points à trancher » : multijoueur ou replays (supposé non) ; tempo des attaques (durées dans `5_data/`) ; format des données (`.tres` typés) ; version de Godot (4.7.2) ; outil de test (non choisi dans le document ; GdUnit4 dans le juge) ; jeu 2D ou 3D (exemples écrits pour la 2D) ; événements partagés (seulement ceux qui traversent les scènes) ; audio global (musique et volume seulement).

### 8.3 Deux points proposés à sa décision

- Ajouter les équivalents 3D dans ARC-03 et SIM-10 : leurs exemples sont écrits pour la 2D (`Sprite2D`, `AnimatedSprite2D`, `Area2D`), alors que Starfox, le socle et une partie de ses jeux sont en 3D (notes). Le juge, lui, cherche déjà les nœuds 2D et 3D (usine/regles/controles.py:18-21).
- Garder ou non `6_assets/` séparé des scènes : c'est un écart avec l'usage conseillé par Godot, qui range d'habitude les assets au plus près des scènes ; son propre document le relève (notes ; Appr., §7).

### 8.4 Le bloc fixe

Le bloc fixe en contexte ne contient que les cinq principes et le tableau des dossiers (notes ; godot/socle_jeu/AGENTS.md:1-19). Les 51 règles n'y entrent pas : elles sont jugées, ou rappelées au moment utile (Appr., §9, « Quatre précautions »).

### 8.5 Le juge de règles (branche de travail)

- Sans modèle (règle 2). `usine/regles/catalogue.py` décrit 31 règles avec leur nature (confirmée, corrigée, choix) ; 15 sont jugées mécaniquement : ORG-01, DOSSIERS, ARC-03, ARC-04, ARC-06, DAT-01, DAT-02, SIM-01, SIM-02, SIM-08, SIM-09, COD-01, COD-02, COD-04, QA-01 (usine/regles/catalogue.py:68-69). Trois se jugent sur la session : QA-03, QA-07, QA-08 (ligne 70). Les autres sont seulement rappelées dans les fiches.
- Contrôles par expressions régulières, fichier par fichier (usine/regles/controles.py:1-220) : syntaxe Godot 3 et connexion par chaîne (COD-04) ; déclarations, paramètres et retours typés, `UNTYPED_DECLARATION` en erreur dans `project.godot` (COD-02) ; nommage (COD-01) ; Resource sans `class_name` ou hors de `1_core` (DAT-02) ; `/root/` et `../` écrits en dur (ARC-06) ; priorité écrite en nombre (SIM-02) ; `create_timer` sans `false` (SIM-08) ; nœud visuel ou sonore dans la logique (ARC-03) ; `Input` ou `_input` dans la logique (ARC-04) ; `_process` dans la logique (SIM-01) ; hasard global dans la logique (SIM-09) ; tout nombre autre que 0 et 1 dans la logique de `2_sequence` et `3_entities` (DAT-01).
- Rangement et dépendances : `usine/structure/regles.py:14-35` reprend le tableau des dossiers sans exception (table `PERMIS`, `EXCEPTIONS` vide) : une entité ne dépend d'aucune autre ; `5_data` et `6_assets` ne contiennent aucun code ; `7_tests` en miroir (QA-01).
- Sortie : chaque écart est au format commun, `categorie` « regle » ou « structure », champ `regle`, message « SIM-08 : … ». `python -m usine.regles verifier <projet>`. Un projet sans plan numéroté (sans `1_core` et `3_entities`) n'est pas jugé : `applicable: false` (usine/regles/__init__.py:30-51 ; usine/structure/regles.py:72-74). Conséquence : sur Starfox tel quel, ce juge ne dit rien d'utile.
- Le document proposait `gdlint` pour COD-01 (Appr., §9) ; l'implémentation emploie des expressions régulières.

### 8.6 Les règles dans les trois moments

En permanence, les cinq principes et le tableau ; avant l'action, les règles des besoins cochés (minuterie : SIM-08, SIM-01 ; état : SIM-05 ; collision : SIM-10 ; son : ARC-09, ARC-03 ; effet visuel et animation : ARC-02, ARC-03 ; interface : ligne `4_ui/` et SIM-06 ; données : DAT-01 à DAT-05 ; caméra : ARC-02 ; sauvegarde : DAT-06, DAT-08) ; après l'action, le retour d'outil nomme la règle violée (Appr., §9). Sur la branche, `prepare_action` renvoie ces règles avec chaque fiche (ETAT.md:1115).

## 9. Ce qui est construit sur la branche de travail

Tout est dans le cloud, sur `claude/project-thread-12uh5s` ; rien n'est sur le PC (notes).

### 9.1 Avant le 11 octobre au soir : la béquille, points 1 à 9

- **Retour des outils** (`usine/retour/`) : une écriture identique au contenu actuel n'écrit rien et répond « aucun changement », avec le compte d'écritures identiques d'affilée (usine/retour/ecriture.py:8-33) ; après l'écriture d'un script, vérification de chaque classe et membre Godot dans `extension_api.json`, signatures officielles comprises ; après une erreur du moteur, la fiche du membre en cause est jointe (ETAT.md:1026-1059).
- **Socle de jeu** (`godot/socle_jeu`) : jeu 3D complet rangé selon le plan `0_autoload` à `7_tests` : titre, intro, niveau 1 jouable avec quatre drones posés à la main, fin ; `ORGANISATION.md` (rôles, qui connaît qui, conventions, sept modèles d'ajout avec l'exemple à imiter) et `AGENTS.md` (ETAT.md:1066).
- **`prepare_action`** (`usine/fiches`, 15 fiches) : Qwen déclare son but, le type d'ajout, ses fichiers, et coche ses besoins dans une liste fermée (minuterie, état, collision, son, effet visuel, animation, interface, données, caméra, sauvegarde ; situations : ennemi touché, mort d'un acteur, tir, apparition d'ennemis, fin de niveau). Il reçoit d'un coup où travailler, la chaîne de fichiers à imiter et une fiche par besoin en cinq rubriques : à considérer, API, exemple tiré du projet, pièges, voisins (usine/fiches/__init__.py:1-11 ; mcp_serveur/serveur.py:92-99).
- **`check_structure`** (`usine/structure/regles.py`, `verifier_projet`) et **tri de session** (`usine/structure/session.py`).
- **`capture_frames`** : le jeu tourne quelques secondes à 60 images par seconde et renvoie une grille d'images horodatées, avec pour chaque case ce que le journal `Trace` a noté (états, coups, score) ; il peut tenir des touches (`move_up:10-70`) (usine/retour/capture.py:1-9 ; ETAT.md:1069).
- **Vérification d'API dans `check_script`** (champ `vocabulaire`) et **exposition MCP** de tout cela (mcp_serveur/outils.py, serveur.py) (notes).
- Preuves : 330 tests verts après le point 1, puis 356 après les points 2 à 9 (ETAT.md:1042, 1095).

### 9.2 Le 11 octobre : les règles d'architecture

Contexte : laurent avait envoyé sans consigne le document « Apprentissages », sur ses règles d'architecture et leur usage pour le LoRA (fil, 07:56), puis précisé que c'était « juste une réflexion » (fil, 08:16 ; section 2.3). L'arrêt est arrivé trop tard ; laurent en est informé ; rien n'a été retiré, et il n'a pas demandé de le retirer (notes).

- **Juge des règles** : 15 règles mécaniques de la section 9 de son document, sans modèle, écarts nommés par identifiant (notes ; section 8.5).
- **Socle nettoyé** : 25 écarts ramenés à 0 (ARC-04 trois fois, ARC-06, COD-02 six fois, DAT-01 six fois, DOSSIERS six fois, SIM-01 deux fois, SIM-08) ; 31 tests verts (ETAT.md:1113, 1129). `EventBus` supprimé : le niveau écoute la vie des acteurs et met à jour `GameState` ; `AudioManager` ne fait plus que la musique et le volume ; durées et vies dans `5_data/game/game_rules.tres` ; `player_input.gd` lit le clavier ; `drone_view.gd` porte les effets du drone ; `AGENTS.md` réduit aux cinq principes et au tableau des dossiers (notes).
- **Fiches, `ORGANISATION.md` et `AGENTS.md` mis à jour** ; `check_structure` branché sur le juge des règles (notes ; mcp_serveur/outils.py:241-251).
- **`juger_tache`** : tout verdict d'un projet organisé porte `regles` (violations, `structure_ok`, `par_regle`) ; avec `juge.regles_cibles`, il échoue à l'étape « regles » tant qu'il reste un écart (usine/taches.py:155, 175-186).
- **124 tâches « nettoyer »** sur 10 règles, compétence K4 : neuf sortes de salissures (syntaxe Godot 3, type retiré, valeur de `5_data` en dur, `get_node("/root/…")`, `create_timer` sans `false`, priorité en nombre, `_physics_process` changé en `_process`, fonction en camelCase, script déplacé) (ETAT.md:1116). 10 sont validées par Godot, une par règle : refusées au départ, acceptées une fois propres ; 114 ne sont pas encore passées par Godot (notes).
- **Nouveau tri** : par tâche, la session qui passe les tests, le rangement et la santé de session, avec le moins de violations. Violations comptées : fichier modifié non déclaré (QA-03), tests annoncés verts sans avoir été lancés (QA-07), absence de compte rendu final (QA-08) (notes ; usine/rft/filtre.py:1-34 ; usine/rft/essais.py:157-172).
- **Suite complète** : 386 tests verts, 1 ignoré faute de `sqlite_vec` (notes ; ETAT.md:1140).
- Le détail est dans `ETAT.md:1105-1148` ; l'étape 24 de `VERIFIER_EN_LOCAL.md` permet de vérifier sur le PC (notes).

### 9.3 L'audit du socle avant nettoyage

Utile pour comprendre les règles (notes) : `AudioManager` ne jouait que des bruitages (ARC-09) ; `create_timer` sans `false` (SIM-08) ; invulnérabilité décomptée dans `_process` (SIM-01) ; ordre laissé à l'arbre (SIM-02) ; cascades de signaux (SIM-07) ; nombres en dur (DAT-01) ; table `PERMIS` de `check_structure` plus large que le tableau des dossiers ; la fiche minuterie donnait deux de ces violations comme exemples à imiter.

### 9.4 Ce qui manque

- ARC-03, ARC-04, SIM-09 et DAT-02 sont jugées mais n'ont pas de tâche « nettoyer » (notes ; ETAT.md:1142).
- 114 tâches « nettoyer » n'ont pas encore été jugées par Godot ; il faudrait les geler avec le reste si le gel est gardé (notes ; ETAT.md:1142).
- Les pièges des fiches sont écrits à la main ; ils devaient être tirés des 1 025 essais ratés de t1 (ETAT.md:1097).
- Faits relevés à la lecture du code, non testés :
  - Le tri de session exige la lecture de `ORGANISATION.md` ou `plan.md` avant la première écriture et des écritures dans les dossiers du plan (usine/structure/session.py:118-147). Appliqué tel quel à des tâches agentiques sur des projets non rangés (toutes les sources actuelles : `reference`, `survivor`, kits Kenney, paires E), il rejetterait toutes les sessions.
  - `python -m usine.rft exporter` relit `registre.csv` ; un registre ancien, comme celui de t1, vaut « 0 violation, contrôles tenus » (usine/rft/tour.py:33-36 ; usine/rft/__main__.py:79-90). Réexporter t1 ne le rejuge donc pas ; aucune commande ne recalcule le tri sur des sessions déjà enregistrées.
  - Le tri de session ne compte comme écritures que `write_file`, `write` et `edit` ; `apply_edits` n'est contrôlé ni pour le plan ni pour la répétition (usine/structure/session.py:24-27).
  - `capture_frames` renvoie une légende et le chemin de la grille, pas l'image elle-même (mcp_serveur/outils.py:262-268).

### 9.5 Vérifier sur le PC

Étapes 22 (environ 5 minutes), 23 (environ 10 minutes) et 24 (environ 15 minutes) de `VERIFIER_EN_LOCAL.md` (lignes 542-628) ; commandes en annexe B.3. Comment les lancer sur le PC sans perdre les corrections V2 est une question ouverte pour laurent (section 12.1, question 3).

## 10. Décisions de laurent (validées)

Liste des notes. Après chaque décision, ses mots dans le fil principal du 11 octobre, avec l'heure UTC.

1. **Tester en conditions réelles** (campagnes Starfox) plutôt que sur des tâches mises de côté pour des tests ; une seule campagne, avec LoRA (notes). Ses mots : « je m'en fous des tests, je teste en réel dans des conditions propres, comme cette série de Star Fox sous différents aspects » (07:23) ; « on ne fait qu'une campagne avec LoRA » (06:50). Le sort des 221 tâches déjà gelées n'est pas tranché pour autant (section 12.1, question 1).
2. **Garder les super-catégories** (les 5 domaines et les 8 compétences du tableau de 4.1) et les diviser en sous-catégories par sujet : gameplay, VFX, shaders, optimisation, gestion de la mémoire, UI, contrôle à la manette, audio, physique, graphisme 3D et 2D, procédural, plugins et leur usage, création de tests (notes). Ses mots : « on avait bien conservé les mêmes super-catégories [...] mais on les a divisées en sous-catégories capables d'enseigner les VFX, les shaders, la gestion de la mémoire, l'UI, le contrôle des manettes aussi, l'audio, et on a introduit la physique, le graphisme 3D, 2D, le procédural, la connaissance de certains plugins et comment les utiliser, la création des tests » (12:18). Il avait demandé à 07:35 d'employer la nomenclature de GameDevBench pour lister ce benchmark ; elle ne remplace pas ces catégories, et il l'a corrigé à 12:18.
3. **50 % de création depuis une description, 50 % de débogage**, sujet par sujet. Ses mots : « non, on va faire 50/50, c'est mieux comme ça, ça permet au LoRA d'apprendre la construction et le débogage » (13:00), après ce constat : « le LoRA qu'on construit, c'est un LoRA de débogage plus qu'un LoRA de codage » (12:55).
4. **Réflexes à apprendre** : tester systématiquement (`check_script`, puis `run_tests` ou `load_scene`, après chaque modification, via Godot et le MCP) ; faire plusieurs captures par phase ; ne pas répéter un travail déjà validé ; utiliser le RAG pour des suggestions ; vérifier le gameplay avant de passer à la requête suivante. Lui donner aussi une béquille. Ses mots : « il faut automatiser deux comportements dans le LoRA : plusieurs screenshots pour tester le comportement du jeu durant des phases, et le test systématique via la version Godot et le MCP » (11:54) ; « il devrait aussi s'assurer du fonctionnement du gameplay avant de passer à la requête suivante [...] on sait qu'on doit lui donner aussi une béquille » (12:46).
5. **Le plan d'organisation fourni en contexte doit primer** sur la formation. Ses mots : « il faudrait aussi lui enseigner qu'un plan d'organisation fourni dans le contexte prime sur sa formation » (08:17).
6. **Enseigner le gameplay** avec des boucles de test rétroactives sur des « vidéos », c'est-à-dire des suites de captures. Ses mots : « il faut absolument enseigner au LoRA le gameplay avec des boucles rétroactives de test sur des vidéos » (09:08).
7. **Jugement visuel** : une base de problèmes, avec des jeux créés pour ça (collision, caméra…). Ses mots : « pour le jugement visuel, on peut faire une base de données de problèmes avec des jeux spécifiquement créés pour ça... problème de collision, problème de caméra » (12:53).
8. **laurent crée 3 ou 4 jeux d'un seul niveau** qui mêlent les compétences ; il veut apprendre à Qwen à coder ces jeux morceau par morceau. Ses mots : « je suis en train de créer 3 ou 4 jeux d'un seul niveau qui mélangent les compétences, shader, etc. » (12:24) ; « on pourrait lui apprendre à coder les jeux d'exemple morceau par morceau, non ? » (13:11).
9. **Un RAG beaucoup mieux construit**, plus professionnel, avec des conseils de plugins et d'effets. Ses mots : « reconstruire un RAG beaucoup plus efficace et professionnel » (02:20) ; « je veux ajouter des conseils possibles de plugins ou de FX dans le prochain RAG » (06:50).
10. **Trouver une parade aux réécritures identiques**. Ses mots : « il faut trouver une parade à ça !! » (09:12). L'origine reste à établir (section 7, point 7).
11. **Optimisation et gameplay ajoutés à la liste des sujets**, à sa demande. Ses mots : « on a oublié l'optimisation » (12:22) ; « on a oublié le gameplay dans la liste » (12:25).

Décisions plus anciennes, consignées dans le dépôt :

- 6 octobre : « pour le moment on va utiliser Godot 4.7, on fera l'adaptation plus tard » (ETAT.md:1008).
- 9 octobre : ordre de la béquille, 1. retour des outils ; 2. socle propre et plan d'organisation ; 3. déclaration d'action et graphe ; 4. mesure par campagnes ; 5. entraînement (ETAT.md:1024). Les étapes 1 à 3 sont construites sur la branche, non fusionnée (section 9.1) ; l'étape 4 a eu lieu avec la campagne du 11 octobre et la V2 (section 6) ; l'étape 5, l'entraînement, reste à faire (sections 13 et 14).
- 4 et 5 octobre : spécification de la compétence E par laurent, seuils relatifs à la référence sauf les allocations (CLAUDE.md:82 ; usine/efficience/juge.py:3).

Positions exprimées par laurent le 8 octobre sur l'entraînement (Transcr., 18:46 et 18:47) : il a refusé de raccourcir les résultats d'outils et de découper les sessions longues, parce que le LoRA doit apprendre un cheminement et que les lectures font partie de ce que Qwen voit pour décider. L'entraînement t1 a donc gardé les sessions entières, quitte à tronquer la fin de 12 d'entre elles (Transcr. l. 1866-1878).

## 11. Propositions non validées : à faire confirmer par laurent avant d'agir

Aucune de ces propositions n'est décidée. Les présenter comme telles, une à une, et attendre sa réponse.

### 11.1 Ce que Qwen doit apprendre

- **Réflexes ajoutés** : écrire les verdicts et le compte rendu (QA-08) ; ranger selon le plan fourni ; juger chaque capture contre un résultat attendu écrit d'avance (notes).
- **Compétence longue** « réaliser une fonctionnalité de bout en bout dans un projet propre », déclinée par sujet, jugée par les tests, les règles, le gameplay, l'efficience et la santé de session ; exemple : ajouter un ennemi avec son effet et son son (notes).
- **Optimisation** : en faire un sujet en 3D aussi, et un critère du juge de la compétence longue (notes).

### 11.2 Les jeux de laurent découpés en étapes

Étapes : projet et plan, déplacement, caméra, tir, ennemis, collisions, effets, shader, son, interface, optimisation. Chaque étape est une tâche : départ à l'état de l'étape précédente, description et capture attendue, jamais le code. Juge : tests de l'étape, règles, non-régression des phases déjà construites. Des variantes par étape, pour éviter l'apprentissage par cœur ; des étapes assez petites pour être réussies ; une copie du projet à chaque étape terminée, jouable et testée. Conditions : passer le juge de règles à 100 % et un test par mécanisme. Format aligné sur `plan.md` et sur les étapes de la béquille (notes).

### 11.3 Création, diagnostic visuel, gameplay, rangement

- **Création** : retirer un morceau entier et le faire réécrire depuis une description et une image de référence ; demander des variantes plutôt que des copies ; difficulté progressive (dégradé de ciel, bruit, nuages animés, volumétriques) ; un RAG qui explique les techniques plutôt que du code tout fait (notes).
- **Diagnostic visuel** : injecter des défauts connus (caméra inversée ou trop loin, objet qui traverse un mur, vaisseau hors champ, HUD qui se chevauche, texture manquante, particules absentes, écran noir) dans des niveaux qui marchent et dans des scènes dédiées (arène de collisions) ; une courte suite d'images par phase, avec les positions ; verdict écrit comparé au défaut injecté, sans humain ; une moitié de captures saines ; tâche courte, qui peut devenir une compétence (notes). La page Béquille (point 8) proposait déjà deux compétences : juger la logique sur une séquence et juger la lisibilité, avec un défaut injecté comparé à l'étiquette.
- **Juge de gameplay** : entrées scriptées, captures par phase, mesures (position du vaisseau, ennemis, score, erreurs), comparaison au résultat attendu (notes).
- **Juge de rangement** qui lit le plan fourni au lieu d'une table fixe ; plans variés d'un exemple à l'autre ; tâches de conflit entre le plan fourni et l'habitude ; ne jamais retirer le plan du prompt d'entraînement (notes).

### 11.4 Génération, tri et volumes

- Générer avec Qwen de base (l'ancien LoRA n'écrit plus de texte) et la béquille complète ; 8 essais par tâche courte, 4 par tâche longue (notes).
- **Distillation du contexte** : retirer du prompt d'entraînement le guide et les règles détaillées, garder les cinq principes, le plan et les outils ; garder le texte, les résultats d'outils, le RAG et les captures (notes).
- **Volumes** : environ 1 000 sessions gardées et 1 000 à 2 000 paires DPO. Premier tour d'environ 400 tâches (un jeu étape par étape avec variantes, diagnostic visuel, les 124 « nettoyer », les cases utiles à Starfox : 3D, gameplay, VFX, shaders, interface, son), environ deux jours de calcul sur le PC au rythme de t1 ; étendre seulement là où il échoue. Sur RunPod, avec des requêtes en parallèle, beaucoup moins (notes).
- **Contrôle avant entraînement** : équilibre entre les cases, aucun appel d'outil cassé, 20 sessions tirées au hasard montrées à laurent (notes).
- L'usage des 221 tâches gelées, mesure ou entraînement, n'est pas une proposition arrêtée : c'est une question ouverte pour laurent, avec ses options (section 12.1, question 1).

### 11.5 Entraînement

- LoRA neuf depuis Qwen 3.8 de base ; t1 réexporté avec son texte et rejugé ; SFT (taux autour de 2e-4, une à trois époques, perte sur les réponses seulement, captures incluses, support des images à vérifier) ; campagne Starfox dans les conditions de la V2 avec une béquille réduite ; DPO (autour de 5e-6) ; deuxième tour où le nouveau LoRA regénère sur les tâches ratées et longues, puis réentraînement depuis la base ; GRPO plus tard (autour de 1e-5, Godot dans la boucle). Les taux viennent du document de laurent, qui cite TRL GRPOTrainer, PEFT et OpenPipe ART (notes ; Appr., §9).
- **Estimation d'amélioration donnée à laurent** : quasi certaine pour le retour du texte ; forte pour les réflexes de procédure ; moyenne pour les réécritures identiques et l'usage du RAG ; incertaine pour la justesse des verdicts visuels et les tâches longues. Le premier chiffre fiable viendra de la génération : la part des tâches réussies par Qwen de base avec la béquille (notes).

### 11.6 Harnais et niveaux de référence

- **Harnais** : vérifier après la dernière écriture, et annuler une écriture qui casse le lancement (notes).
- **Niveaux de référence** : partir des démos officielles de Godot (licence MIT) et d'assets CC0 (Kenney, Quaternius) ; esthétique calée sur des images de référence, et sur des images extraites de vidéos ; laurent valide chaque niveau en jouant. Genres proposés plus tôt : rail shooter 3D, plateforme 2D, action vue de dessus 2D avec vagues procédurales, troisième personne 3D, jeu de cartes, FPS (notes).

### 11.7 Autres propositions trouvées dans les documents, non validées

- Retirer les éditions refusées des données d'entraînement avant le prochain LoRA (P: causes_campagne_11oct.md, §2).
- DPO sur les 1 025 essais ratés de t1, appariés à une session réussie de la même tâche (ETAT.md:1142 ; Appr., §9, usage 3).
- Un « professeur », validé par les mêmes juges, si la boucle n'apprend que ce que Qwen réussit déjà parfois (Béquille, point 10).
- Exclue : la campagne sans LoRA conseillée par V2, §8 ; laurent n'en veut pas (section 2.2).

## 12. Points ouverts et inconnues

### 12.1 Questions à poser à laurent, avec leurs options

Ces questions demandent sa décision. Les options ne sont pas des décisions : les lui poser une à une, après celles de 8.3.

**Question 1. Les 221 tâches gelées : mesure ou entraînement ?**

- Faits : 221 tâches gelées, soit E 50, F1 50, K3 50, K2 36, K1 12, S1 10, S2 7, D1 6 (notes). La règle 4 les exclut de l'entraînement et du RAG (CLAUDE.md:53-55), et le code l'applique : `selectionner` refuse une tâche gelée (usine/rft/tour.py:78-79) et l'export écarte ses sessions (usine/rft/export.py:174-182). La mesure du dépôt repose sur elles (CLAUDE.md:136-143). laurent a décidé de tester en conditions réelles (décision 1) et a demandé : « on enlève beaucoup de réponses pour faire des tests [...] si on avait conservé ces tests, le résultat du LoRA aurait été meilleur ? » (fil, 07:23). Les 124 tâches « nettoyer » ne sont pas encore gelées (section 9.4).
- Option A : les garder gelées pour la mesure ; ses campagnes Starfox restent son test.
- Option B : les verser à l'entraînement, comme le proposaient les notes (« conséquence de la décision 1, à confirmer »). Il faut alors changer la règle 4 et le code, et la mesure chiffrée hors campagne disparaît.
- Option C : en verser une partie et garder un petit jeu gelé pour vérifier qu'aucune compétence ne recule.

**Question 2. `-ngl 99` dans sa ligne de lancement ?**

- Faits : sa ligne passe `-ngl 99` (Transcr. l. 2269) ; `CLAUDE.md:36` dit de ne jamais passer `-ngl`, parce que le build de l'époque refusait de démarrer ; le lanceur du dépôt n'écrit pas `-ngl` (ETAT.md:931 ; VERIFIER_EN_LOCAL.md:429).
- Option A : son build actuel accepte `-ngl 99` ; mettre `CLAUDE.md:36` à jour, avec son accord.
- Option B : retirer `-ngl 99` de sa ligne.
- D'ici sa réponse, ne toucher ni à sa ligne ni à `CLAUDE.md:36`.

**Question 3. Comment vérifier la branche sur le PC (étapes 22 à 24) ?**

- Faits : les trois étapes disent `git pull` (VERIFIER_EN_LOCAL.md:542-628). Le PC est sur `main`, avec les corrections V2 non commitées, et le travail est sur la branche `claude/project-thread-12uh5s` : un `git pull` sur `main` ne l'apporte pas (notes). La branche modifie `usine/rft/agent.py` (lignes 81-82 et 97-104), que M1 modifie aussi sur le PC : conflit possible. Les étapes 22 et 23 disent de s'arrêter si `usine\rft\agent.py` ou `mcp_serveur\outils.py` apparaissent en `M` (VERIFIER_EN_LOCAL.md:553, 580) ; l'étape 24 ne le rappelle pas.
- Option A : commiter les corrections V2 sur le PC, fusionner la branche en résolvant `agent.py` (garder les deux changements), puis lancer les étapes sans leurs `git pull`.
- Option B : extraire la branche dans un autre dossier du PC, par exemple avec `git worktree`, en y copiant `config.toml`, que git ne suit pas ; y lancer les étapes 22 à 24 sans toucher à la copie de travail V2, puis fusionner.
- Dans les deux cas, les commandes git exactes sont à préparer d'après `git status --short` et à vérifier (annexe B.3).

**Questions déjà posées ou à poser, sans réponse à ce jour** : la 2D et la 3D dans ARC-03 et SIM-10, et `6_assets/` (section 8.3) ; les huit points des règles (section 8.2) ; la compétence longue et les autres propositions (section 11).

### 12.2 Inconnues et travaux ouverts

D'après les notes :

- L'origine des réécritures identiques (section 7, point 7).
- À construire : le juge de gameplay, le juge de rangement paramétré par le plan, les tâches de diagnostic visuel, l'export qui garde le texte, les générateurs de création et de variantes.
- Le RAG, à reconstruire.
- Les jeux de référence de laurent : en cours.
- La vérification locale et la fusion de la branche de travail : en attente de laurent (section 12.1, question 3) ; les corrections V2 non commitées du PC doivent être préservées.
- Les huit points à trancher, dont la 2D et la 3D, et `6_assets/`.
- Le support des images de Qwen 3.8 dans LLaMA-Factory ; le parallélisme de séquence ; la configuration du dernier entraînement, à demander à laurent ; le contexte d'inférence de llama-server sur le PC, à mesurer.
- Le coût des images : environ un millier de jetons par image en 720p sur les Qwen récents, deux images par capture ; il faut des captures petites et choisies.

Éléments de réponse trouvés dans les documents, à confirmer :

- Configuration de t1 : le YAML du dépôt (section 4.7), adapté au pod avec `template: qwen3_8`, `logging_steps: 1`, `report_to: none` et des chemins `/workspace` (Transcr. l. 136-143) ; ce qui était actif et ce qui ne l'était pas est en 14.1.
- Images : le gabarit `qwen3_8` de LLaMA-Factory gère les images, et Qwen avec le LoRA lit une capture ; aucun entraînement avec images n'a été essayé sur cette configuration (Transcr. l. 3440).
- Contexte d'inférence : la ligne de lancement demande `-c 200000` (Transcr. l. 2269) ; ce qui tient réellement en mémoire n'est pas mesuré (à vérifier sur le PC).

Relevés dans le dépôt et les documents :

- **Harnais d'usage.** laurent travaille dans l'application OpenCode (CLAUDE.md:38) ; les campagnes passent par le harnais maison ; la page Béquille demande le même harnais à l'entraînement et à l'usage (point 10). Lequel sera le harnais d'usage n'est pas fixé. Le 8 octobre, laurent a dit : « si [ce harnais] ne peut pas être utilisé dans OpenCode, n'utilise pas OpenCode » (Transcr., 23:54).
- **Le tri de session et les projets non rangés** (section 9.4).
- **Aucune opération `apply_edits` pour ajouter une variable** (V2, §7).
- **Starfox n'a ni tests ni GdUnit4** : `run_tests` n'y peut rien vérifier tant qu'on n'en ajoute pas (P: causes_campagne_11oct.md, §4).

### 12.3 Deux décomptes non expliqués

- **« 93 sur 575 ».** Le chiffre vient de laurent : « les chemins de recherche ont été très difficilement sélectionnés ! 93 sur 575 » (Transcr., 8 octobre 18:46) ; `ETAT.md:1018` écrit « 93 sessions retenues sur 575 ». Le bilan de t1 donne 272 tâches, 2 176 essais (K3 656, E 536, F1 400, K2 296, K1 96, S1 96, S2 64, D1 32), 1 151 réussites, 99 tâches acquises, 70 à refaire, 103 retenues et 93 sessions exportées (Transcr. complète l. 5474-5498). Aucun de ces nombres ne vaut 575, et aucune source ne dit ce qu'il compte. Comme 575 n'est pas un multiple de 8, ce n'est pas le nombre d'essais d'un ensemble de tâches jouées 8 fois chacune ; ce serait plutôt un nombre de réussites, sur une partie des tâches ou des compétences. Piste, sur le PC et avec son accord : compter les réussites par compétence dans `registre.csv` de t1 (colonnes `competence` et `ok`) (à vérifier). Sinon, le demander à laurent.
- **« le pire des 4 ».** Ses mots : « le résultat est un échec... c'est le pire des 4 » (fil, 09:08) ; les notes écrivent « la pire des 4 » campagnes. Les sources décrivent cinq campagnes Starfox, toutes avec LoRA : trois dans la nuit du 8 au 9 octobre, celle du 11 octobre et la V2 (section 6.1). Le fil ne dit pas lesquelles il compte. Seul indice : à 04:50, il pensait que la campagne du 11 octobre avait échoué : « le test a échoué très vite » ; elle avait en fait tourné ses deux heures, et calé à partir de 1 h 17 (fil, 04:56). S'il ne la compte pas, les 4 seraient les trois de la nuit du 8 au 9 octobre et la V2, mais ce n'est qu'une hypothèse. À lui demander si ce décompte importe pour la suite.

## 13. Stratégie de constitution du dataset, pas à pas

### 13.1 Référence externe : GameDevBench

Dépôt public `waynchi/gamedevbench` : 333 tâches mais 130 consignes distinctes ; 4 catégories annoncées (2D Graphics & Animation, 3D Graphics & Animation, User Interface, Gameplay Logic), attribuées par GPT-5-mini puis relues, sans étiquette publiée par tâche. Classement fait à la main : 2D 157 tâches pour 34 consignes (33,3 % annoncé), 3D 32 pour 17 (26,7 % annoncé), UI 60 pour 21 (20,1 %), Gameplay Logic 84 pour 58 (19,8 %) ; seulement 45 tâches parlent de 3D. VFX : 63 tâches de particules, 24 de shaders, 21 de post-traitement ; audio 8 ; procédural aucune ; conventions de code aucune (notes ; P: gamedevbench_333_par_categorie.md). Ce benchmark sert à lire le domaine, pas à nommer nos catégories (décision 2).

### 13.2 Les étapes

Chaque étape porte son statut : **décidé** (section 10), **proposé** (section 11) ou **ouvert** (section 12).

1. **Fixer la grille.** Lignes : les sujets (gameplay, VFX, shaders, optimisation, gestion de la mémoire, UI, manette, audio, physique, graphisme 3D et 2D, procédural, plugins, création de tests) ; colonnes : les compétences des 5 domaines ; dans chaque case, moitié création depuis une description, moitié débogage. Statut : décidé (décisions 2, 3, 11). Ajouter une compétence longue « de bout en bout » : proposé.
2. **Partir de projets propres qui suivent le plan.** Le socle de la branche (0 écart) et les 3 ou 4 jeux d'un niveau que laurent crée (décidé, décision 8 ; en cours). Starfox ne convient pas tel quel : il a son dossier `scripts/` (section 16). Niveaux de référence à partir des démos Godot et d'assets CC0, validés par laurent en jouant : proposé.
3. **Préparer chaque jeu.** Le passer au juge de règles jusqu'à 0 écart, ajouter un test par mécanisme et des captures de référence, puis le découper en étapes, avec une copie jouable et testée par étape. Statut : proposé (11.2 ; section 15, étape 6).
4. **Écrire les générateurs.**
   - Création : morceau retiré à réécrire depuis une description et une image, variantes, difficulté progressive : proposé.
   - Débogage : les générateurs existants (mutation pour K3 et D1, masquage pour K1 et K2) et les 124 « nettoyer » (construits) ; bugs de gameplay injectés : proposé.
   - Diagnostic visuel, défauts injectés avec moitié de captures saines : décidé dans son principe (décision 7, « une base de problèmes avec des jeux créés pour ça »), modalités proposées (11.3).
   - Gameplay appris sur des suites de captures : décidé (décision 6) ; juge de gameplay : proposé.
5. **Juger sans modèle.** Tests, règles (construit), rangement selon le plan fourni (proposé), gameplay (proposé), efficience (existe pour E), santé de session (construit). Le plan fourni prime sur l'habitude (décidé, décision 5) : d'où les plans variés et les tâches de conflit (proposé).
6. **Générer les sessions.** Qwen de base avec la béquille complète, 8 essais par tâche courte et 4 par tâche longue, premier tour d'environ 400 tâches : proposé. Où : sur le llama-server de laurent avec son accord, ou sur RunPod (proposé ; section 15, étape 9). Les réflexes à faire apparaître dans les sessions (tester après chaque modification, plusieurs captures par phase, ne pas refaire un travail validé, RAG pour des suggestions, gameplay vérifié avant la suite) : décidé (décision 4).
7. **Trier.** Le tri de la branche (tests, rangement, santé de session, moins de violations) ; rejeter toute session avec une réécriture identique, une modification non testée ou sans vérification du gameplay (section 16). Statut : tri construit ; règles d'exclusion tirées des notes ; parade aux réécritures identiques à trouver (décidé, décision 10 ; moyen ouvert).
8. **Exporter.** Garder le texte (cause n° 1, section 7) ; garder le plan dans le prompt ; distillation du contexte : proposé.
9. **Contrôler avant d'entraîner.** Équilibre des cases, aucun appel d'outil cassé, 20 sessions au hasard montrées à laurent : proposé.
10. **Viser les volumes.** Environ 1 000 sessions et 1 000 à 2 000 paires DPO ; n'étendre que là où Qwen échoue : proposé.

## 14. Stratégie d'entraînement, pas à pas

### 14.1 Faits

- t1 : QLoRA rang 16 sur Qwen3.8-27B, LLaMA-Factory, H200, 2 époques, 24 pas, 2 h 04, perte 0,078 (ETAT.md:1019) ; 116 727 808 paramètres entraînables (Transcr. l. 1514, journal de LLaMA-Factory) ; environ 1,6 million de jetons sur les deux époques, à environ 190 jetons par seconde (Transcr. l. 1677-1678). La perte basse ne dit rien de la qualité : les sessions sont des productions de Qwen lui-même (Transcr. l. 2023).
- **Mémoire mesurée.** Avec `cutoff_len` 16 384, `nvidia-smi` affichait 126 747 MiB occupés sur les 143 771 MiB de la H200 (Transcr. l. 808, 1603), ce que la transcription arrondit à « 126 Go sur 143 » (Transcr. l. 1618). En Gio, c'est environ 124 sur 140 : les « 123 de VRAM » de laurent (fil, 07:19), comme les « 123 Go » sur une « H200 (141 Go) » des notes, désignent cette même mesure. Les poids en 4 bits pèsent environ 17 Go ; le reste est fait d'activations et de réserve de PyTorch, en proportion inconnue (Transcr. l. 1676, 1904, 1914).
- **Déjà employés pour t1** : base en 4 bits, c'est-à-dire QLoRA (usine/rft/export.py:114) ; gradient checkpointing (Transcr. complète l. 1912) ; attention par `torch SDPA` (Transcr. complète l. 1913).
- **Leviers pas encore employés, à essayer d'abord** : FlashAttention à la place de SDPA (notes ; compatibilité avec l'architecture hybride à vérifier) ; `flash-linear-attention` et `causal-conv1d`, dont l'absence faisait tourner les 48 couches d'attention linéaire dans un code de secours lent (Transcr. complète l. 1895 ; Transcr. l. 1677) ; un LoRA posé sur moins de modules que `lora_target: all` (Transcr. l. 1914) ; le noyau Liger, installé dans le gabarit RunPod mais non activé (Transcr. complète l. 518, 536 ; support de Qwen3.8 à vérifier).
- **Contexte plus long** (notes) : une B300 (288 Go) est envisagée, soit environ 38 000 jetons à réglages égaux si toute la mémoire croît avec la longueur (288 / 124 × 16 384), davantage puisque les poids, environ 17 Go, ne croissent pas. Une H200 tient 16 384 jetons avec ce réglage : c'est ce qu'a fait t1. Avec plusieurs cartes, DeepSpeed ZeRO-3 ou FSDP répartissent le modèle, pas une longue séquence ; il faut le parallélisme de séquence (Ulysses ou ring attention), dont le support est à vérifier dans la version de LLaMA-Factory. Le contexte d'inférence du PC de laurent fixe la vraie limite de longueur, à mesurer. laurent : « la B300 a 288 de VRAM... ça devrait suffire à de très longs chemins de résolution, non ? » (fil, 12:11).
- Sessions de t1 : médiane 7 600 jetons, moyenne 10 200, maximum 70 200, environ 21 tours ; 12 sur 93 dépassent 16 384 et sont tronquées (Transcr. l. 1667-1674 ; ETAT.md:1019). Garder entière la plus longue demanderait environ 70 000 jetons de contexte (Transcr. l. 1869).
- La page Béquille (point 10) visait des tâches courtes, une entité ou un état, pour tenir sous 16 384 jetons sans coupure, et un bloc fixe de 3 000 à 5 000 jetons (Béquille, points 7 et 10).

### 14.2 Les étapes

Toutes proposées (11.5), sauf mention.

1. **Réparer l'export** pour que le texte et les appels d'outils restent dans le même tour assistant ; vérifier sur un échantillon que les deux sont présents. Le moyen exact dépend de la version de LLaMA-Factory (format, gabarit `qwen3_8`) ; `sft.jsonl` garde déjà tout et peut servir de base (ETAT.md:948). Statut : correction nécessaire, établie par la cause n° 1 ; moyen ouvert.
2. **Réexporter t1 avec son texte et le rejuger** (proposé). Attention aux faits de la section 9.4 : le rejugement demande du code, et le tri de session rejetterait les tâches sur projets non rangés.
3. **Choisir la machine et la longueur** : mesurer d'abord le contexte d'inférence réel du PC, essayer les leviers de mémoire encore inemployés (14.1), puis régler `cutoff_len` et la carte (H200, B300 ou plusieurs cartes avec parallélisme de séquence) (notes ; ouvert).
4. **SFT d'un LoRA neuf depuis Qwen 3.8 de base** : taux autour de 2e-4, une à trois époques, perte sur les réponses seulement, captures incluses si le support des images est vérifié par un essai court (notes ; Transcr. l. 3440).
5. **Convertir en GGUF** : prévoir le cas des couches d'attention linéaire (`out_proj`) déjà rencontré, avec le lanceur `outils/convertir_lora_qwen38.py` du PC (Transcr. complète l. 4066), dont la ligne de commande est à vérifier (annexe B.6). Puis lancer avec le LoRA, avec l'accord de laurent.
6. **Campagne Starfox** dans les conditions de la V2, avec une béquille réduite (notes). C'est le test de laurent (décision 1) : une campagne, avec LoRA, comparée par `comparer_campagnes.py`.
7. **DPO**, taux autour de 5e-6, sur des paires réussite contre échec de la même tâche (notes ; Appr., §9).
8. **Deuxième tour** : le nouveau LoRA regénère sur les tâches ratées et longues, puis réentraînement depuis la base (notes).
9. **GRPO plus tard**, taux autour de 1e-5, Godot dans la boucle (notes). Le document de laurent conseille de le différer : coûteux en essais par tâche, et l'équipe Qwen y a vu son modèle tricher avec la récompense (Appr., §9).

## 15. Prochaines actions concrètes, dans l'ordre

Tout ce qui suit est une proposition (notes) : la présenter comme telle à laurent.

| N° | Action | Qui | Comment vérifier |
| --- | --- | --- | --- |
| 1 | Faire trancher, une question à la fois : la 2D et la 3D dans les règles (ARC-03, SIM-10), `6_assets/`, les trois questions de la section 12.1, la compétence longue, puis la liste de la section 11. | L'IA demande, laurent décide. | Sa réponse est recopiée mot pour mot dans la section 10 de ce document ; rien n'est construit avant. |
| 2 | Une fois la procédure choisie par laurent (section 12.1, question 3) : commiter les corrections V2 sur le PC, faire les étapes 22 à 24 de `VERIFIER_EN_LOCAL.md` et fusionner la branche de travail, dans l'ordre de l'option retenue. | laurent sur son PC, avec des commandes prêtes à coller fournies par l'IA, à vérifier sur place. | `git status --short` propre après le commit ; étape 24 conforme (pytest vert, `0 violation(s) {}`, `check_structure` OK) ; après la fusion, `tests\test_editions.py` toujours à 40 sur 40 et la suite complète verte ; M5 retiré de l'outil de campagne (section 5.5). |
| 3 | Corriger l'export pour garder le texte ; réexporter t1 et vérifier sur un échantillon que texte et appels d'outils sont présents. | L'IA écrit le code et les tests dans le cloud ; laurent lance le réexport sur le PC. | Les 179 tours mixtes de `sft.jsonl` gardent leur texte dans le fichier LLaMA-Factory ; 10 exemples relus à la main. |
| 4 | Paramétrer le juge de rangement par le plan fourni. | L'IA. | Tests avec plusieurs plans différents ; le socle reste à 0 écart. |
| 5 | Construire le juge de gameplay, d'abord sur le socle et Starfox. | L'IA ; laurent valide sur son PC. | Sur le socle, il retrouve les faits connus de la capture de l'étape 23 (`Drone3 : détruit, score +100`, puis `Player : touché -1, vie 4`) ; un défaut injecté (caméra inversée) est détecté. |
| 6 | Recevoir les jeux de laurent : les passer au juge de règles, ajouter tests et captures de référence, les découper en étapes. | laurent fournit et valide en jouant ; l'IA prépare. | `python -m usine.regles verifier <jeu>` donne 0 écart ; tests verts ; une copie jouable par étape. |
| 7 | Générateurs : création depuis description, variantes, diagnostic visuel, bugs de gameplay ; grille sujets par compétences, 50/50. | L'IA. | Le portillon accepte les tâches (départ rouge, référence verte 3 fois sur 3, mutants tués) ; tableau d'équilibre des cases. |
| 8 | RAG v2. | L'IA, avec les attentes de laurent (1.3). | Des requêtes tirées des campagnes réelles rendent une technique expliquée, un exemple vérifié et les pièges ; laurent juge. |
| 9 | Premier tour d'environ 400 tâches avec Qwen de base et la béquille, sur le llama-server de laurent avec son accord, ou sur RunPod. | laurent lance ou autorise. | `registre.csv` et `bilan.json` ; part des tâches réussies par case, qui est le premier chiffre fiable. |
| 10 | Tri, contrôle avec laurent, export ; SFT sur RunPod ; campagne Starfox ; DPO ; deuxième tour. | L'IA prépare, laurent valide et lance. | Contrôles de 11.4 ; la campagne comparée aux précédentes par `comparer_campagnes.py` ; le jugement de laurent. |

## 16. Pièges connus et interdits

D'après les notes :

- Ne pas fusionner la branche de travail sans l'accord de laurent ni la vérification locale ; ne pas écraser les corrections V2 non commitées du PC (`agent.py`, `editions.py`, `campagne_harnais.py`, tests).
- Pas d'alias dans `apply_edits` (décision de conception, V2, §3).
- Ne jamais laisser entrer dans le dataset une session avec réécriture identique, modification non testée, ou sans vérification du gameplay ; ne jamais retirer le texte à l'export ; ne jamais retirer le plan du prompt d'entraînement.
- Le harnais doit vérifier après la dernière écriture : la V2 a été cassée par sa dernière action.
- Partir d'un projet qui suit déjà le plan : Starfox a son propre dossier `scripts/`.
- Ne pas présenter une proposition comme une décision de laurent.

Relevés dans le dépôt et les documents :

- **`git pull` sur le PC** : ne pas suivre les étapes 22 à 24 à la lettre sur un PC resté sur `main` ; attendre la réponse de laurent à la question 3 de 12.1.
- **Un dossier de sortie de campagne neuf à chaque fois** : le harnais ne recopie pas le projet si le dossier contient déjà un `project.godot` (V2, §5).
- **Pas de campagne sans LoRA**, malgré V2, §8.
- **Pas de rejeu sur son llama-server** sans accord, même court.
- **Scripts GDScript de l'usine entièrement typés** : un projet qui met `UNTYPED_DECLARATION` en erreur l'applique aussi aux scripts lancés avec `-s` (ETAT.md:1148).
- **Une salissure ne touche jamais un commentaire**, sinon la tâche serait verte au départ (ETAT.md:1147).
- **Fins de ligne** : les empreintes portent sur les octets ; ne pas réécrire une tâche en CRLF sous Windows (ETAT.md:1348).
- **Import Godot sous Windows** : un plantage aléatoire (`0xC0000005`) a été vu une fois ; un verdict faux peut rester dans le cache (ETAT.md:1362).
- **Température** : à 0, N essais donnent N fois la même réponse ; les essais RFT sont à 0,7 avec graine plus numéro d'essai (ETAT.md:944, 1001 ; config.example.toml:82-83).
- **Ne pas tronquer les résultats d'outils ni découper les sessions** sans en reparler avec laurent (section 10, positions du 8 octobre).
- **`-ngl`** : ne modifier ni sa ligne de lancement ni `CLAUDE.md:36` avant sa réponse (section 12.1, question 2).

## 17. Glossaire

- **Béquille** : l'aide donnée à Qwen au bon moment, en permanence (plan, conventions, exemple), avant l'action (déclaration et fiches) et après l'action (retour d'outil qui dit ce qui s'est passé) (Béquille). Dans les campagnes, le guide AVANT / PENDANT / APRÈS de `PROMPT_BEQUILLE.md` (notes).
- **Usine** : le paquet `usine/` qui génère des tâches vérifiées, les juge sans modèle, fait jouer Qwen, trie et exporte les sessions (CLAUDE.md:5).
- **Socle** : `godot/socle_jeu`, jeu 3D complet rangé selon le plan, 0 écart au juge des règles, 31 tests (section 9).
- **Plan d'organisation, plan numéroté** : les huit dossiers `0_autoload` à `7_tests` et leur tableau de dépendances (annexe A, « Dossiers »).
- **Portillon** : les règles d'acceptation d'une tâche candidate (section 4.4).
- **Juge** : code déterministe, sans LLM, qui rend un verdict. Juge commun (tests), juge d'efficience (E), juge des règles (branche) ; juges de gameplay et de rangement par plan : proposés.
- **Verdict** : `{ok, etape, duree_s, erreurs: [{fichier, ligne, categorie, message}], tests: {total, passes, echecs}}`, plus `tache_id` (section 4.5).
- **Tâche** : dossier `tache.json`, `depart/`, `reference/`, `tests_caches/` (section 4.2).
- **Tâche gelée** : tâche tirée dans le jeu de test, exclue de l'entraînement et du RAG par la règle 4 (section 4.4).
- **Tâche acquise** : réussie plus de 6 fois sur 8 essais, donc non exportée (section 4.6).
- **À refaire** : tâche jamais réussie, entrée du tour suivant (`a_refaire.txt`).
- **Salissure, tâche « nettoyer »** : une violation mécanique d'une règle injectée dans le socle propre ; la tâche K4 consiste à la corriger sans changer le comportement, les tests restant verts et le juge des règles muet (usine/generateurs/salissures.py:1-21).
- **Session saine** : plan lu avant la première écriture, écritures dans les dossiers du plan, aucune écriture répétée à l'identique, un verdict écrit après chaque capture, aucun fichier écrit non déclaré à `prepare_action` (QA-03), aucun test annoncé vert sans `run_tests` réussi depuis la dernière écriture (QA-07) (usine/structure/session.py:1-13, 145-147).
- **Compte rendu QA-08** : en fin de tâche, dans l'ordre : fichiers créés et modifiés, responsabilité de chaque nouveau script, dépendances ajoutées, tests exécutés et leur résultat réel, problèmes non résolus, règles concernées (annexe A). Son absence compte comme une violation sans faire échouer la session.
- **RFT** (réglage fin par rejet) : faire jouer le modèle N fois par tâche, garder les essais que le juge valide, entraîner dessus (`usine/rft`).
- **SFT** : apprentissage supervisé sur les sessions retenues.
- **DPO** (Direct Preference Optimization) : apprend de paires « réponse préférée, réponse rejetée », sans modèle de récompense ni génération pendant l'entraînement (Appr., §9).
- **GRPO** : variante de PPO ; l'avantage de chaque réponse est calculé par rapport au groupe de réponses du même prompt ; le modèle apprend en ligne de ses propres générations (Appr., §9).
- **Distillation du contexte** : entraîner sans une partie du prompt (guide, règles détaillées) pour que le modèle adopte de lui-même le comportement que ce contexte produisait (proposition, 11.4).
- **Harnais** : le programme qui fait dialoguer Qwen avec les outils : agent maison (`usine/rft/agent.py`), harnais de campagne (`outils/campagne_harnais.py`, sur le PC), OpenCode.
- **Équipement** : le jeu d'outils offert par le harnais de campagne, par exemple `usine_rag` (section 5.2).
- **Campagne** : deux heures de travail libre de Qwen sur une copie de Starfox (section 5.1).
- **Tour** : une passe complète essais, tri, export ; t1 est le premier (`usine/rft/tour.py`).
- **LoRA t1** : `LORA_coding_godot-f16.gguf`, issu du tour t1.
- **M1 à M5** : les corrections V2 (section 5.5).
- **Fiche de compétence** : `skills/usine-*/SKILL.md`, mise dans le message système de l'agent maison.
- **Fiche de besoin ou de situation** : `usine/fiches/donnees/*.json`, rendue par `prepare_action`.
- **`prepare_action`, `check_structure`, `capture_frames`** : outils MCP de la branche (section 9.1).
- **`capture_ecran`** : outil du harnais de campagne qui joint deux PNG par capture (section 5.2).
- **« Vidéo »** (au sens de laurent) : une suite de captures (décision 6).
- **Empreinte** : SHA-256 du contenu d'une tâche.
- **Mutant, score de mutation** : version fautive de la référence ; part des mutants que les tests cachés font échouer (section 4.4).
- **RAG** : index de la documentation Godot 4.7 et des démos officielles qui compilent, en SQLite FTS5, interrogé par `search_docs` (`usine/rag`) ; à reconstruire (décision 9).
- **`vocab_lookup`, `extension_api.json`** : vérification d'une classe ou d'un membre Godot dans l'API exportée par le moteur.
- **sharegpt, `function_call`, `observation`** : format de conversation de LLaMA-Factory et ses tours d'appel d'outil et de résultat d'outil (section 4.7).
- **`cutoff_len`** : longueur maximale d'un exemple d'entraînement, en jetons ; au-delà, la fin est coupée.
- **QLoRA** : LoRA entraîné sur une base quantifiée en 4 bits.
- **GGUF, `mmproj`** : format des modèles et adaptateurs pour llama.cpp ; projecteur de vision de Qwen 3.8.
- **GdUnit4** : outil de test de Godot employé par le juge.

## Annexe A : les règles d'architecture complètes

Copie intégrale, sans aucune modification, du fichier `a59be4b8-R_gles1.md` fourni par laurent (141 lignes). Ses titres gardent leurs niveaux d'origine, et ses tirets longs sont ceux de l'original.

<!-- DEBUT ANNEXE A -->

# Règles d'architecture Godot

Oct 11, 2026 · @laurent

Ces règles sont obligatoires pour tout agent IA ou développeur du projet. Elles s'appliquent à l'intérieur des huit dossiers existants, sans en créer de nouveaux. Chaque règle porte un identifiant stable à citer dans les consignes et les comptes rendus. Chacune a été contrôlée contre la documentation de Godot et des sources professionnelles ; le détail est dans l'onglet Vérification.

## Principes

En cas de doute sur une règle, revenir à ces cinq principes, dans cet ordre.

1. **La simulation décide, la présentation montre.** Une animation peut donner le tempo d'une attaque ; elle n'en calcule jamais le résultat.
2. **Les valeurs vivent dans les données.** Aucun chiffre d'équilibrage dans un script ou une scène.
3. **L'ordre d'exécution est écrit, pas subi.** Quand deux systèmes dépendent l'un de l'autre, leur ordre est fixé par une priorité explicite.
4. **Les dépendances se déclarent.** Un objet reçoit ce dont il a besoin ; il ne va pas le chercher dans l'arbre ni dans un global.
5. **On résout le problème du jeu actuel.** Pas de généricité pour un futur projet, pas d'abstraction sans besoin démontré (YAGNI).

## Dossiers

Toute nouveauté entre dans l'un des huit dossiers selon sa responsabilité. Les dépendances vont du spécifique vers le générique, jamais l'inverse.

| Dossier | Contient | Peut dépendre de | Ne doit jamais |
| --- | --- | --- | --- |
| `0_autoload/` | Services globaux persistants : déroulement, état de partie, événements partagés, audio global, traces | `1_core/` | Héberger du combat ou un comportement local ; piloter directement des entités |
| `1_core/` | Mécanismes et contrats génériques : composants, types de Resource, table des priorités d'exécution, résolution de dégâts | Rien d'autre | Connaître un niveau, un boss, un personnage ou une arme en particulier |
| `2_sequence/` | Ordre des étapes et leur réalisation : cinématiques, menus, niveaux, leur ouverture et leur fermeture | Tous sauf `7_tests/` | Dupliquer le déroulement tenu par l'Autoload |
| `3_entities/` | Joueur, ennemis, boss, projectiles : logique propre et présentation, dans des scripts distincts | `1_core/`, `5_data/`, `6_assets/` | Dépendre d'une autre entité précise, de l'interface ou d'un niveau |
| `4_ui/` | HUD, interfaces superposées, composants d'interface | `1_core/`, `0_autoload/`, `6_assets/` | Décider d'une règle de gameplay ou modifier un état de simulation |
| `5_data/` | Paramètres de conception : caractéristiques, armes, vagues, réglages | Types définis dans `1_core/`, références vers `6_assets/` | Contenir de la logique ou un état de partie en cours |
| `6_assets/` | Modèles, textures, audio, shaders, matériaux, polices | Rien | Porter une décision de gameplay par son nom ou son rangement |
| `7_tests/` | Tests, en miroir des éléments testés | Tout | Être référencé par le code du jeu |

- **ORG-01 — Structure figée.** Aucun nouveau dossier à la racine de `res://` sans validation explicite. Seule exception : `addons/`, emplacement standard des plugins et des ressources tierces.
- **ORG-02 — Un seul déroulement.** L'Autoload conserve le contexte de partie et demande le lancement d'une étape ; `2_sequence/` définit et exécute cette étape. Jamais deux systèmes concurrents.
- **ORG-03 — Générique ou spécifique.** Le mécanisme de résolution des dégâts va dans `1_core/`, l'attaque d'un boss dans `3_entities/`, ses valeurs dans `5_data/`.
- **ORG-04 — Simulation et vue côte à côte.** La séparation se fait par scripts distincts dans le même dossier d'entité, pas par un dossier supplémentaire.
- **ORG-05 — Frontières explicites.** Entre dossiers, on passe par une API, une référence injectée, un signal ou un contrat défini.
- **ORG-06 — Pas de doublon.** Un mécanisme existant est réutilisé ou étendu, jamais recréé dans un autre dossier.

## Architecture

- **ARC-01 — Responsabilité unique.** Chaque script, composant et scène a une responsabilité principale, énonçable en une phrase. Interdit : le script monolithique qui mêle déplacement, combat, animation et interface.
- **ARC-02 — Simulation séparée de la présentation.** La simulation couvre règles, statistiques, dégâts, états, IA et temps de recharge. La présentation couvre sprites, animations, sons, particules, interface et caméra. La présentation lit l'état ou écoute des signaux ; elle ne décide d'aucun résultat.
- **ARC-03 — Aucun nœud visuel dans la logique.** Un script de simulation ne référence ni `Sprite2D`, ni `AnimatedSprite2D`, ni nœud audio ou de particules. Le tempo d'une attaque vient de durées définies dans `5_data/` ou d'une piste d'appel de méthode d'`AnimationPlayer` ; dans les deux cas, le calcul du résultat reste dans la logique.
- **ARC-04 — Les entrées sont des intentions.** Clavier, souris, manette et IA produisent des commandes (`move`, `attack`, `dash`) que la simulation consomme. La logique n'appelle pas `Input` directement.
- **ARC-05 — Composition plutôt qu'héritage.** Une entité assemble des composants (`HealthComponent`, `MovementComponent`, `AttackComponent`, `StatusEffectComponent`, `HitboxComponent`). Pas de hiérarchie d'héritage profonde. Un composant se remplace sans réécrire l'entité.
- **ARC-06 — Dépendances injectées.** Une dépendance extérieure à la scène est fournie par le parent : `@export` typé, méthode `setup()` ou signal qu'il connecte. Interdit : `get_node("/root/...")` et les chemins remontants `../..` écrits en dur. Les groupes restent permis pour s'adresser à un ensemble de nœuds (`call_group`, `get_nodes_in_group`).
- **ARC-07 — Appeler vers le bas, signaler vers le haut.** Un parent appelle les méthodes de ses enfants ; un enfant prévient par signal. À l'intérieur d'une scène, les accès `%NomUnique` sont autorisés.
- **ARC-08 — Dépendances vérifiées au démarrage.** Une dépendance obligatoire manquante provoque une erreur explicite dès `_ready()` ou `setup()`, pas un échec silencieux plus tard.
- **ARC-09 — Autoloads rares.** Un Autoload se justifie seulement s'il est global, persiste entre scènes et ne gère que ses propres données. Les bruitages restent dans la scène qui les émet. Tout ajout est signalé et justifié dans le compte rendu.
- **ARC-10 — Pas de manager par réflexe.** Interdit : un manager par fonctionnalité, un manager servant de base de données universelle, deux managers qui se référencent mutuellement. Un orchestrateur local à un niveau ou à un combat est autorisé et préféré.
- **ARC-11 — Un propriétaire par objet.** Le propriétaire initialise, active et détruit. Aucune référence conservée vers un nœud libéré. Godot supprime lui-même une connexion quand l'objet receveur est libéré : pas de déconnexion manuelle à écrire pour ce cas.
- **ARC-12 — Aucune abstraction prématurée.** Pas de framework maison, d'ECS personnalisé, de Gameplay Ability System complet ni de couche supplémentaire sans besoin actuel. Cette règle ne dispense ni des tests ni du nettoyage du code existant.

## Données

- **DAT-01 — Valeurs externalisées.** Dégâts, vitesse, santé, temps de recharge, durées, probabilités, récompenses, définitions d'armes, vagues et paramètres de génération vivent dans `5_data/`. Interdit : un nombre d'équilibrage écrit dans un script ou surchargé dans l'inspecteur d'une scène.
- **DAT-02 — Resources typées.** Chaque famille de données a une classe `Resource` avec `class_name` et champs `@export` typés (`EnemyDefinition`, `WeaponDefinition`). La classe est dans `1_core/`, les fichiers `.tres` dans `5_data/`. Jamais de classe interne (`class`) comme Resource : Godot ne la sérialise pas.
- **DAT-03 — Une seule source de vérité.** Une statistique existe à un seul endroit. Si un format externe (JSON, tableur) devient la référence, les Resources ne portent plus que les liens vers textures, sons et scènes.
- **DAT-04 — Définition immuable, état séparé.** `EnemyDefinition` porte santé maximale, vitesse et comportement initial. `EnemyState` porte santé actuelle, statuts et temps de recharge en cours. Interdit : écrire dans une Resource de définition pendant une partie.
- **DAT-05 — Resources partagées par défaut.** Un `.tres` chargé est le même objet pour tous ceux qui le chargent. `duplicate()` laisse partagés les tableaux, dictionnaires et sous-ressources imbriqués. Pour une copie indépendante, utiliser `duplicate_deep()` (Godot 4.5 et suivants) ; pour une copie par instance de scène, `resource_local_to_scene`. Le choix est explicite et commenté.
- **DAT-06 — Identifiants stables.** Chaque définition a un `id` unique en `snake_case`, jamais renommé une fois utilisé par une sauvegarde. Les références entre données passent par cet `id` ou par la Resource, jamais par un chemin de fichier écrit en dur.
- **DAT-07 — Validation au chargement.** Champs obligatoires, types, plages numériques, références croisées et identifiants dupliqués sont vérifiés au démarrage. Une donnée invalide produit une erreur nommée ; aucune valeur par défaut n'est substituée en silence.
- **DAT-08 — Sauvegarde logique et versionnée.** La sauvegarde contient l'état nécessaire pour reconstruire la partie (identifiants, progression, graine), pas l'arbre de scènes. Elle porte un numéro de version pour les migrations.

## Simulation

- **SIM-01 — Gameplay à pas fixe.** Tout ce qui dépend du temps et compte pour le résultat (déplacements, dégâts, temps de recharge, statuts) s'exécute dans `_physics_process(delta)`. `_process(delta)` est réservé au rendu, aux effets et aux animations purement visuelles. Si le mouvement saccade parce que l'affichage et le tick n'ont pas la même cadence, activer l'interpolation physique (2D depuis Godot 4.3, 3D depuis 4.4).
- **SIM-02 — Ordre fixé par priorité.** Godot traite les nœuds de même priorité dans l'ordre de l'arbre. Quand l'ordre entre systèmes compte, il est fixé par `process_physics_priority` (la plus petite valeur passe en premier), avec des valeurs nommées dans un seul fichier de `1_core/`. Ne pas compter sur la position d'un nœud dans l'arbre.
- **SIM-03 — Coordinateur en dernier recours.** Un coordinateur maison qui appelle `tick(delta)` sur chaque système n'est créé que si les priorités ne suffisent pas. Sa création est justifiée dans le compte rendu (ARC-12).
- **SIM-04 — Un seul écrivain par état.** Chaque donnée critique a un propriétaire identifié. Les autres systèmes demandent le changement (`apply_damage()`), ils n'écrivent pas le champ (`health -= 10`).
- **SIM-05 — Machine à états pour les comportements.** Les états exclusifs (`IDLE`, `MOVING`, `ATTACKING`, `STUNNED`, `DEAD`) sont une `enum` et une machine à états, pas des booléens `is_attacking`, `is_stunned`. Version hiérarchique seulement si la machine plate devient illisible.
- **SIM-06 — Les signaux annoncent des faits.** Signaux typés, nommés au passé (`health_changed`, `enemy_died`, `attack_completed`, `room_cleared`). Signal local d'abord ; le bus d'événements de `0_autoload/` seulement pour ce qui traverse réellement les scènes.
- **SIM-07 — Pas de logique en cascade de signaux.** Une étape critique du gameplay est un appel direct, jamais la conséquence d'une chaîne de signaux : un signal sert à réagir, pas à lancer.
- **SIM-08 — Pause définie.** Chaque système déclare son `process_mode`. Temps de recharge, effets et attaques s'arrêtent en pause. Une durée de gameplay passe par un nœud `Timer` réglé sur le tick physique (`process_callback`) ou par un décompte dans la logique. `get_tree().create_timer()` continue pendant la pause par défaut : lui passer `false` en second argument (`process_always`), ou ne pas l'utiliser pour le gameplay.
- **SIM-09 — Aléatoire maîtrisé là où il compte.** Génération de niveaux, butin et tout tirage qu'une graine doit pouvoir rejouer passent par un `RandomNumberGenerator` reçu en dépendance, graine enregistrée. Les fonctions globales (`randf()`, `randi()`, `pick_random()`) restent permises pour le cosmétique. Une même graine ne garantit pas la même suite d'une version de Godot à l'autre.
- **SIM-10 — Règles calculées sans nœud.** Le calcul des dégâts et des statuts est une fonction qui reçoit des valeurs (attaquant, cible, définition d'attaque) et rend un résultat ; elle se teste sans scène. La détection (`Area2D`, `move_and_slide()`) reste dans les composants de l'entité.

Ordre visé quand il compte (SIM-02), de la plus petite priorité à la plus grande :

1. Collecte des commandes du joueur et des agents.
2. Décisions de l'IA.
3. Déplacements.
4. Interactions et attaques.
5. Application des dégâts et des statuts.
6. Transitions d'états, puis émission des signaux.

Les chevauchements d'`Area2D` ne sont mis à jour qu'une fois par pas physique : un coup détecté par une zone arrive au tick qui suit le déplacement.

## Code

- **COD-01 — Nommage Godot.** Classes, nœuds et noms d'`enum` en `PascalCase` ; fonctions, variables, signaux et fichiers en `snake_case` ; constantes et valeurs d'`enum` en `CONSTANT_CASE` ; membres privés préfixés par `_`.
- **COD-02 — Typage statique.** Paramètres, retours, variables membres, `@export` et signaux sont typés. Tableaux et dictionnaires typés (`Array[EnemyDefinition]`), sans imbrication : `Array[Array[int]]` n'est pas supporté. L'avertissement `UNTYPED_DECLARATION`, à activer dans les réglages du projet, fait respecter la règle.
- **COD-03 — Interface publique minimale.** Chaque module documente en tête de script ses entrées, ses sorties, ses dépendances, les données qu'il possède et les signaux qu'il émet. Aucun accès aux membres `_privés` d'un autre script.
- **COD-04 — Version exacte.** Le code vise la version de Godot du projet et aucune autre. Interdit : la syntaxe de Godot 3 (`yield` au lieu de `await`, `onready` et `export` sans `@`, `KinematicBody2D`, `instance()`). Les signaux se connectent par `signal.connect(callable)` ; la forme par chaîne existe encore, mais la doc la déconseille.
- **COD-05 — Simple d'abord, mesuré ensuite.** Aucune optimisation sans mesure au profiler de Godot. Pas d'object pooling, de multithreading ni de structure de données exotique avant qu'un coût réel soit constaté.
- **COD-06 — Arbre et physique sur le thread principal.** Tout accès à l'arbre de scènes ou à la physique depuis un autre thread passe par `call_deferred()`.

## Qualité et agents IA

- **QA-01 — Tests de la logique.** Règles de combat, transitions d'états, chargement et validation des données, valeurs limites, signaux importants, création et destruction d'entités ont des tests dans `7_tests/`, en miroir du chemin testé.
- **QA-02 — Testable sans scène.** Un calcul de gameplay s'exécute sans charger de scène ni de graphismes. Les tests d'intégration tournent sous Godot en mode `--headless`.
- **QA-03 — Périmètre minimal.** Un agent ne modifie que les fichiers nécessaires à sa tâche.
- **QA-04 — Contrats partagés protégés.** Toute modification d'une interface utilisée par un autre module (signature, signal, champ de Resource) est annoncée avant d'être faite.
- **QA-05 — Interdits de l'agent.** Réécrire une architecture qui fonctionne ; dupliquer un système existant ; ajouter un global pour contourner un problème local ; supprimer une fonctionnalité pour en faciliter une autre ; créer un dossier racine.
- **QA-06 — Conflit signalé, pas contourné.** Si une demande impose de violer une règle, l'agent nomme la règle, propose l'option la moins risquée et attend une validation avant de toucher à un contrat d'architecture.
- **QA-07 — Aucun résultat inventé.** Un test n'est déclaré réussi que s'il a été exécuté ; la sortie réelle est jointe.

Compte rendu de fin de tâche (QA-08), dans cet ordre :

1. Fichiers créés et modifiés.
2. Responsabilité de chaque nouveau script ou composant.
3. Dépendances ajoutées ou modifiées, Autoloads compris.
4. Tests exécutés et leur résultat réel.
5. Problèmes non résolus.
6. Conséquences pour l'architecture et règles concernées, citées par identifiant.

Une fonctionnalité est terminée (QA-09) quand tout est coché :

- [ ] Elle remplit les critères demandés.
- [ ] La simulation ne référence aucun nœud de présentation (ARC-02, ARC-03).
- [ ] Aucune valeur d'équilibrage hors de `5_data/` (DAT-01).
- [ ] Toutes les dépendances sont injectées et vérifiées (ARC-06, ARC-08).
- [ ] Aucun Autoload ni état global ajouté sans justification (ARC-09).
- [ ] Aucun nouvel avertissement ni erreur de l'éditeur sans explication.
- [ ] Les tests concernés passent (QA-01, QA-07).
- [ ] Les systèmes existants fonctionnent toujours.

## Points à trancher

Huit décisions restent ouvertes. Les règles ci-dessus appliquent la réponse par défaut indiquée ; à confirmer ou corriger. Les deux premières pèsent le plus sur l'architecture.

| Question | Réponse appliquée par défaut | Règles touchées |
| --- | --- | --- |
| Multijoueur, replays ou parties rejouables par graine sont-ils prévus ? | Supposé non. Si oui, la séparation simulation / présentation et l'aléatoire injecté deviennent stricts dès le départ | ARC-02, ARC-03, SIM-09 |
| Tempo des attaques : durées dans `5_data/` ou pistes d'animation ? | Durées dans `5_data/`, testables sans scène ; la piste d'animation reste permise | ARC-03 |
| Format de référence des données : Resources `.tres` ou JSON ? | Resources `.tres` typées, éditables dans l'inspecteur | DAT-02, DAT-03 |
| Version exacte de Godot ? | Non fixée ; la dernière version stable est la 4.7.2 | COD-04, DAT-05, SIM-01 |
| Outil de test : GUT ou gdUnit4 ? | Non choisi ; les deux couvrent Godot 4.7 et s'installent dans `addons/` | ORG-01, QA-01, QA-02 |
| Jeu 2D ou 3D ? Le texte parle d'un roguelike 2D, mais `6_assets/` liste des modèles et des matériaux. | Exemples écrits pour la 2D ; les règles valent pour les deux | ARC-03, SIM-10 |
| Que met-on dans les « événements partagés » de `0_autoload/` ? | Uniquement les événements qui traversent les scènes (fin de salle, mort du joueur, changement d'étape) | SIM-06, ARC-09 |
| L'« audio global » de `0_autoload/` couvre-t-il les bruitages ? | Non : musique et réglages de volume seulement ; les bruitages restent dans leur scène | ARC-09 |

<!-- FIN ANNEXE A -->

## Annexe B : commandes utiles, avec leur source

Règle d'or : aucune de ces commandes ne se lance sur le PC de laurent ni sur son llama-server sans son accord explicite (section 2.3). Sur le PC, employer `py -3.12`, seul Python qui a le module `mcp` (V2, §5) ; les étapes anciennes de `VERIFIER_EN_LOCAL.md` écrivent `python`. Dans le cloud, `python` suffit.

### B.1 Lancer une campagne Starfox (PC de laurent, avec son accord)

Avant de lancer (V2, §5) :

1. llama-server tourne sur `http://127.0.0.1:8080` avec le LoRA. Contrôle : la page `http://127.0.0.1:8080/lora-adapters` doit montrer `LORA_coding_godot-f16.gguf` avec `"scale": 1.0`.
2. Personne d'autre n'utilise llama-server pendant les deux heures.
3. Le dossier de sortie n'existe pas encore : le harnais ne copie le projet de départ que si ce dossier ne contient pas déjà de `project.godot`. Prendre un nom neuf à chaque campagne.
4. Ne modifier ni `D:\constructeur-qwen-gamedev` ni `D:\GODOT\projet_starfox` pendant la campagne.

Lancement de la V2 (notes ; V2, §5) : double-clic sur `G:\QWEN-GODOt\LANCER_CAMPAGNE_GUIDE_V2.bat`, ou :

```bat
cd /d D:\constructeur-qwen-gamedev
py -3.12 outils\campagne_harnais.py D:\GODOT\projet_starfox "G:\QWEN-GODOt\starfox_harnais_RAG_bequille_V2" --equipement usine_rag --minutes 120 --prompt G:\QWEN-GODOt\PROMPT_BEQUILLE.md
```

C'est la ligne du 11 octobre avec un autre dossier de sortie (V2, §5). Pour une nouvelle campagne, changer le dossier de sortie (deuxième argument) et, si besoin, le prompt.

Suivre et récupérer (V2, §5) :

- Avancement en une ligne : `G:\QWEN-GODOt\_journaux\starfox_harnais_RAG_bequille_V2\etat.txt`. Pour la V2, le dossier de journaux porte le même nom que le dossier de sortie.
- Fin : le fichier `G:\QWEN-GODOt\_journaux\TERMINE_GUIDE_V2.txt` apparaît quand la campagne a été lancée par le `.bat`.
- Une fenêtre Godot s'ouvre quelques secondes à chaque capture ; la machine ne se met pas en veille pendant la campagne.
- Produits : le jeu modifié dans le dossier de sortie, à ouvrir dans Godot ; `journal.txt`, `bilan.json`, `sessions\` et `captures\` dans le dossier de journaux.

L'option `--sans-lora` existe : elle envoie le LoRA à l'échelle 0 à chaque demande (V2, §8). Ne pas l'employer : laurent ne veut pas de campagne sans LoRA (section 2.2).

Revenir au harnais d'avant les corrections : `outils\campagne_harnais.py.sauvegarde-20261011` (notes ; V2, §9).

### B.2 Comparer des campagnes

```bat
cd /d D:\constructeur-qwen-gamedev
py -3.12 outils\comparer_campagnes.py "G:\QWEN-GODOt\_journaux\starfox-avec harnais et avec RAG" "G:\QWEN-GODOt\_journaux\starfox_avec_harnais et avec RAG et avec guide AVANT PENDANT APRES" "G:\QWEN-GODOt\_journaux\starfox_harnais_RAG_bequille_V2"
```

Source : V2, §6. Ajouter en dernier argument le dossier de journaux de chaque nouvelle campagne. L'outil affiche un tableau Markdown, une colonne par campagne. Ne comparer que des chiffres produits par cet outil : il compte par exemple 37 écritures identiques le 11 octobre, là où un premier décompte en donnait 50. Pour connaître la raison exacte d'un refus, lire `journal.txt` autour de ce refus ; regarder aussi le jeu dans Godot et les images de `captures\` (V2, §6).

### B.3 Vérification locale : étapes 22, 23 et 24 (PC, avec l'accord de laurent)

**À lire avant de coller quoi que ce soit.** La façon de lancer ces étapes dépend de la réponse de laurent à la question 3 de la section 12.1 : les étapes disent `git pull`, ce qui n'apporte pas la branche sur un PC resté sur `main`, et `usine/rft/agent.py` risque un conflit avec M1 (usine/rft/agent.py:81-82, 97-104). Les étapes 22 et 23 demandent de s'arrêter si `usine\rft\agent.py` ou `mcp_serveur\outils.py` apparaissent en `M` (VERIFIER_EN_LOCAL.md:553, 580) ; l'étape 24 ne le rappelle pas. Les commandes git de la fusion ne figurent dans aucun document : les préparer d'après la sortie réelle de `git status --short`, et les vérifier sur place. Les commandes ci-dessous sont celles du dépôt, à lancer sans leurs `git pull` une fois la branche en place.

**Étape 22, retour des outils, environ 5 minutes** (VERIFIER_EN_LOCAL.md:542-565) :

```bat
cd /d D:\constructeur-qwen-gamedev
git status --short
```

Puis, si aucun des deux fichiers n'apparaît en `M` :

```bat
git pull
py -3.12 -m pytest -q tests\test_retour.py tests\test_mcp_serveur.py tests\test_rft.py
py -3.12 -m usine.retour verifier godot\survivor
py -3.12 -m usine.retour verifier D:\GODOT\projet_starfox
```

Attendu : pytest passe entièrement, sans aucun `skipped` dans `test_retour.py` ; `survivor` affiche `68 scripts, 0 problème(s)` ; `projet_starfox` liste les accès suspects des scripts écrits par Qwen, puis le total, et chaque ligne signalée doit être une vraie faute (membre inexistant dans Godot 4.7.2 ou mauvais nombre d'arguments). Une ligne fausse se signale dans le fil : c'est le vérificateur qu'on corrige.

**Étape 23, socle rangé, fiches et captures, environ 10 minutes** (VERIFIER_EN_LOCAL.md:567-593). Même `git status --short` et même précaution, puis :

```bat
git pull
py -3.12 -m pytest -q tests\test_fiches.py tests\test_structure.py tests\test_retour.py tests\test_mcp_serveur.py
py -3.12 -m usine.structure verifier godot\socle_jeu
py -3.12 -m usine.retour capturer godot\socle_jeu --scene res://2_sequence/levels/level_01/level_01.tscn --images 20,60,100,140,180,220,260,300 --touche move_up:10-70 --touche fire:40-300 --sortie %TEMP%\capture_socle
```

Attendu : pytest passe (une fenêtre de jeu s'ouvre et se ferme seule plusieurs fois) ; la structure rend `"ok": true` ; la capture donne une légende de 8 cases, avec vers la case 3 `Drone3 : détruit, score +100`, puis `Player : touché -1, vie 4`, puis 3, 2, 1. Sur la grille `%TEMP%\capture_socle\capture_….png`, le vaisseau bleu monte et tire, un drone rouge disparaît, et ses deux voisins descendent sur le vaisseau.

**Étape 24, règles d'architecture, environ 15 minutes** (VERIFIER_EN_LOCAL.md:595-628). Seulement quand rien d'autre n'occupe la machine :

```bat
cd /d D:\constructeur-qwen-gamedev
git status --short
git pull
py -3.12 -m pytest -q tests\test_regles.py tests\test_fiches.py tests\test_structure.py tests\test_rft.py
py -3.12 -m usine.regles verifier godot\socle_jeu
py -3.12 -m mcp_serveur.preuve
```

Attendu : pytest passe ; `usine.regles` affiche `0 violation(s) {}` ; dans la preuve MCP, `check_structure` reste `OK` et signale un projet sans plan numéroté.

Facultatif et long : chaque tâche est jugée quatre fois, environ 40 s par jugement, donc plusieurs heures pour les 124 tâches.

```bat
py -3.12 -m usine.generateurs produire --competences K4 --sortie %TEMP%\nettoyer
py -3.12 -m usine.juge modeles --dossier %TEMP%\nettoyer --travailleurs 4
```

Attendu : `124 tâches candidates`, puis `124/124 tâches conformes`, chaque tâche étant `FAIL` au départ et `PASS` en référence.

**Étape 21, le gel : ne pas la relancer sans décision de laurent.** Sa commande commence par `rmdir /s /q donnees\geles`, qui détruit le jeu gelé, définitif depuis l'entraînement de t1 (règle 4 ; VERIFIER_EN_LOCAL.md:520-540). Seules ses deux commandes de lecture sont sûres :

```bat
cd /d D:\constructeur-qwen-gamedev
python -c "import json; m = json.load(open(r'donnees\geles\manifeste.json', encoding='utf-8')); [print(c, len(v['taches']), 'complet' if v.get('complet') else 'incomplet') for c, v in sorted(m['competences'].items())]"
python -m usine.rag verifier
```

Attendu : une ligne par compétence avec son nombre de tâches gelées ; `verifier` finit par `fragments qui reprennent une tâche : 0`.

### B.4 Tests

Dans le cloud, sous Linux, avec Godot 4.7.2 headless installé par `bash outils/installer_godot_cloud.sh` (CLAUDE.md:25) et les dépendances de `requirements.txt` :

```bash
python -m pytest -q
python -m pytest -q tests/test_regles.py
python -m usine.regles verifier godot/socle_jeu
```

Attendu sur la branche : `386 passed, 1 skipped` en environ 17 minutes, le test ignoré faute de `sqlite_vec` (ETAT.md:1140) ; `29 passed` (ETAT.md:1130-1131) ; `0 violation(s) {}` (ETAT.md:1126-1127).

Sur le PC, tests des corrections V2 (V2, §4 ; ligne de commande reconstituée, à vérifier) :

```bat
cd /d D:\constructeur-qwen-gamedev
py -3.12 -m pytest -q tests\test_editions.py tests\test_rft.py tests\test_mesure.py
```

Attendu : 81 tests verts, dont 40 dans `test_editions.py`.

### B.5 Les commandes de l'usine

Chaque ligne vient de l'aide en tête du module cité. « (branche) » : n'existe que sur `claude/project-thread-12uh5s`.

| Commande | Rôle | Source |
| --- | --- | --- |
| `python -m usine.vocab construire [--json extension_api.json]` ; `python -m usine.vocab lookup CharacterBody2D [membre]` | Construire et interroger le vocabulaire Godot. | usine/vocab/__main__.py:3-4 |
| `python -m usine.juge run <projet>` ; `check <script.gd>` ; `scene <scene.tscn>` ; `tests <projet>` ; `tache <dossier_tache> [--version depart\|reference] [--candidat DOSSIER] [--repeter N]` ; `modeles [--dossier godot/taches_modeles] [--travailleurs N]` | Juger un projet, un script, une scène, une tâche. Verdict JSON sur la sortie standard, code 0 si `ok`. | usine/juge/__main__.py:3-10 |
| `python -m usine.projet describe <projet> [--json]` ; `apply <projet> <edits.json> [--sans-juge]` ; `demo` | Vue du projet et langage d'édition, tout ou rien. | usine/projet/__main__.py:3-10 |
| `python -m usine.generateurs produire [--graine 1] [--sortie DOSSIER] [--f1 40] [--e 120] [--travailleurs 4] [--sources …] [--competences …]` | Produire des tâches candidates. | usine/generateurs/__main__.py:3-5 |
| `python -m usine.portillon chaine [--graine 1] [--sortie donnees] [--travailleurs 4] [--f1 40] [--completer-gel] [--competences E …] [--e 120]` ; `evaluer <dossier_tache>` ; `comparer <rapport1.json> <rapport2.json>` | Chaîne complète : génération, portillon, gel. `--completer-gel` seulement avant le premier entraînement : t1 a déjà eu lieu. | usine/portillon/__main__.py:3-7 ; ETAT.md:1011 |
| `python -m usine.taches installer` ; `python -m usine.taches verifier [dossier]` | Installer les tâches modèles ; vérifier format et empreintes. | usine/taches.py:247-256 |
| `python -m usine.rag construire` ; `chercher "CharacterBody2D" [-n 5] [--source tout\|doc\|exemples]` ; `verifier` ; `vecteurs` | Construire, interroger et contrôler l'index de documentation ; `verifier` contrôle qu'aucune tâche gelée n'y entre. | usine/rag/__main__.py:3-14 |
| `python -m usine.rft tour --sortie donnees/rft/t1 [--competences ...] [--limite N] [--n-essais 4] [--harnais agent\|opencode] [--depuis donnees/rft/t0/a_refaire.txt]` | Un tour RFT : essais, tri, export, `bilan.json`. Reprend là où il a été coupé. | usine/rft/__main__.py:3-4 ; VERIFIER_EN_LOCAL.md:386 |
| `python -m usine.rft exporter --sortie donnees/rft/t1` | Refaire l'export d'un tour à partir de `registre.csv`, sans rejuger (section 9.4). | usine/rft/__main__.py:5, 80-90 |
| `python -m usine.rft gguf --adaptateur <dossier> --sortie <fichier.gguf>` ; `lanceur --sortie lancer_qwen_lora.bat --lora a.gguf` ; `preuve` | Conversion en GGUF, lanceur multi-LoRA, preuve cloud sur faux serveur. | usine/rft/__main__.py:6-8 |
| `python -m usine.mesure executer` ; `rapport` ; `regression` ; `simuler` ; `gamedevbench preparer\|lancer\|score` | La mesure du dépôt (section 4.9). | usine/mesure/__main__.py:3-8 |
| `python -m usine.capture proxy` ; `lister` | Proxy OpenAI-compatible qui enregistre les sessions d'OpenCode (port 8090). | usine/capture/__main__.py:3-7 ; VERIFIER_EN_LOCAL.md:269-289 |
| `python -m usine.regles verifier <projet> [res://fichier …]` (branche) | Juge des règles d'architecture. | usine/regles/__main__.py:1 |
| `python -m usine.structure verifier <projet>` (branche) | Rangement et dépendances (`check_structure`). | usine/structure/__main__.py:1 |
| `python -m usine.retour verifier <projet> [res://script.gd …]` ; `capturer <projet> --images 30,90,150 [--scene res://…] [--touche move_up:10-70] [--sortie dossier]` (branche) | Rapport de vocabulaire après écriture ; grille de captures avec le journal `Trace`. | usine/retour/__main__.py:1-2 |
| `python mcp_serveur/serveur.py [--projet <dossier>] [--godot <binaire>] [--index <dossier>]` | Le serveur MCP « usine-godot », en stdio. | mcp_serveur/serveur.py:1-8, 117-119 |
| `python -m mcp_serveur.preuve [--projet godot/reference]` | Un client MCP appelle chaque outil sur une copie jetable. | mcp_serveur/preuve.py:1-8 |
| `python outils\opencode_fusion.py <projet> --proxy [--fournisseur <id>]` | Déclare le serveur MCP, les fiches et le proxy dans l'`opencode.json` d'un projet, jamais dans la configuration globale. Sur une copie jetable. | VERIFIER_EN_LOCAL.md:257-267 |

### B.6 Entraîner, convertir, lancer

Procédure du dépôt (VERIFIER_EN_LOCAL.md:410-430) :

- Vérifier que `template` dans `qwen38_qlora_r16.yaml` est le nom du gabarit de Qwen3.8 dans la version de LLaMA-Factory employée. Pour t1 sur RunPod, c'était `qwen3_8` (Transcr. l. 139).
- `llamafactory-cli train donnees\rft\t1\export\llamafactory\qwen38_qlora_r16.yaml`
- Alternative Unsloth : `python donnees\rft\t1\export\unsloth\entrainer_unsloth.py donnees\rft\t1\export\unsloth\config_unsloth.json`

```bat
python -m usine.rft gguf --adaptateur donnees\rft\t1\export\lora_llamafactory --sortie D:\LLM\lora_godot_t1.gguf
python -m usine.rft lanceur --sortie lancer_qwen_lora.bat --lora D:\LLM\lora_godot_t1.gguf
```

Attendu : la conversion finit par `code 0` ; le `.bat` produit n'a pas de `-ngl` et porte `--reasoning off --reasoning-budget 0 --no-prefill-assistant`. Pour un LoRA de Qwen3.8 avec `lora_target: all`, le convertisseur de llama.cpp a planté sur `out_proj` ; laurent a sur son PC le lanceur `outils\convertir_lora_qwen38.py`, dont la ligne de commande n'est dans aucun document (Transcr. complète l. 4066) : à vérifier. laurent garde sa propre ligne de lancement de llama-server (section 3.2).

Sur RunPod, comme pour t1 (Transcr. l. 128-160) : préparer `donnees\rft\t1\export\runpod\` (`setup_runpod.sh`, le YAML adapté au pod, `dataset_info.json`, `usine_godot.jsonl`) ; dans RunPod, ouvrir Jupyter Lab, créer `/workspace/usine` et y déposer les quatre fichiers ; le modèle se télécharge sur le pod depuis `Qwen/Qwen3.8-27B`. Puis, dans un terminal du pod :

```bash
cd /workspace/usine && bash setup_runpod.sh
tail -f /workspace/usine/train.log
nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv && pgrep -af "llamafactory-cli train" && tail -c 200 /workspace/usine/train.log
```

La troisième ligne (Transcr. l. 1589, 1601) montre l'usage du GPU, le processus et la fin du journal. Le LoRA arrive dans `/workspace/usine/lora_llamafactory` : le télécharger par Jupyter, puis arrêter le pod, qui facture tant qu'il tourne (Transcr. l. 160). Le script est relançable et saute les étapes déjà faites (Transcr. l. 162).

### B.7 llama-server

- Ligne de lancement de laurent : section 3.2 (Transcr. l. 2269). Ne pas la modifier sans lui.
- LoRA chargé : `http://127.0.0.1:8080/lora-adapters` (V2, §5).
- Le dépôt sait demander un LoRA par requête avec le champ `lora` (`[{"id": 0, "scale": 1.0}]`) (CLAUDE.md:37).

### B.8 Lire le dépôt depuis le cloud

```bash
git clone --depth 1 https://github.com/zarathoustraLily/constructeur-qwen-gamedev
cd constructeur-qwen-gamedev
git fetch --depth 50 origin claude/project-thread-12uh5s
git log --oneline -8 FETCH_HEAD
git diff --stat main FETCH_HEAD
```

Au 11 octobre au soir : `main` au commit `4296a4e`, `FETCH_HEAD` au commit `83e8bc4` (section 3.4). Pour lire la branche sans toucher à la copie de travail : `git show FETCH_HEAD:ETAT.md`, ou `git archive FETCH_HEAD | tar -x -C <dossier vide>`.

### B.9 Le bloc des champs d'`apply_edits` (M3)

Texte que la correction M3 ajoute à la fin du message système du harnais de campagne, lu dans `usine/projet/EDITS_GODOT.md` (V2, §2) :

```text
Éditions d'apply_edits : une liste d'objets {"op": …} avec exactement ces champs (? = facultatif) :
- add_node : parent, nom, type ou instance, script?, proprietes?, groupes?
- del_node : noeud
- set_property : noeud, propriete, valeur
- attach_script : noeud, script, contenu?
- connect : source, signal, cible, methode, binds?, unbinds?, flags?
- disconnect : source, signal, cible, methode
- add_signal : script, signal, arguments? ([{"nom", "type"}] ou ["nom: Type"])
- add_function : script, code (une fonction complète)
- replace_function : script, fonction, corps ou code
- set_resource_value : ressource, propriete, valeur
Exemple : {"op": "replace_function", "script": "res://scripts/hero.gd", "fonction": "try_dash", "code": "func try_dash() -> void:\n\tpass"}
```
