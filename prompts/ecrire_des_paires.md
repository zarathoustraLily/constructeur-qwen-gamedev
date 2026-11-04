# Écrire des paires d'entraînement pour le LoRA de Qwen (Godot 4.7.2)

Écrit le 2026-11-04 à la demande de laurent, pour qu'un autre modèle puisse ajouter des paires à celles qui existent.
Tout ce qui suit est lu dans le code ou dans les données du dépôt `D:\constructeur-qwen-gamedev` (branche
`claude/observation-visuelle`), avec le fichier et la ligne. En cas de doute, le code fait foi, puis `CLAUDE.md`.

---

## 0. L'essentiel en dix lignes

1. Une paire est une ligne JSON dans `donnees/paires/<famille>/paires*.jsonl` (§ 3). L'assembleur lit tous ces fichiers
   et en fait les deux jeux d'entraînement (§ 7).
2. Deux formats : **palier 1**, sans message système, 1 024 jetons au plus ; **palier 2**, avec le plan en message
   système, 2 048 au plus (§ 5).
3. Les jetons se comptent avec le tokenizer de Qwen 3.8 et son gabarit, jamais à la main (§ 6).
4. Chaque paire est **vérifiée de façon déterministe** par ce qui l'a produite : tests rouges puis verts, sortie réelle
   de Godot, outil rejoué (décision 18.1 de `CLAUDE.md`). L'assembleur ne vérifie **pas** le contenu : il ne regarde
   que la forme, les jetons, les doublons et les exclusions.
5. Donc **un modèle n'écrit jamais une paire à la main**. Il apporte de la matière que l'usine transforme en paires
   vérifiées : un cours nouveau, des pas de démarche, ou un générateur nouveau (§ 9). Règle 5 de `CLAUDE.md` :
   « Corriger le générateur, jamais la sortie ».
6. Ce qui manque aujourd'hui, c'est de la **création** (§ 2). Ajouter du débogage sans création aggrave l'écart ;
   ajouter de l'analyse ne sert presque à rien : elle est déjà en trop et l'assembleur la retire.
7. Rien ne se lance sur le PC de laurent sans son accord (§ 10).

---

## 1. Les règles qui ne se discutent pas

Toutes viennent des « Règles qui priment » de `CLAUDE.md` (décidées par laurent) ou des règles non négociables.

| Règle | Source |
| --- | --- |
| Chaque paire vérifiée de façon déterministe, jamais relâché pour gagner du volume. | décision 18.1 |
| Aucun LLM dans les juges ni les générateurs de vérité. | règle non négociable 2 |
| Toute classe, propriété, méthode ou signal Godot existe dans `extension_api.json` de 4.7.2. | règle 6, § 5.2 |
| Toute sortie de Godot citée est réelle, sur l'état exact du projet ; on n'en retire que lignes vides, lignes d'information et avertissements propres à la machine. | § 5.1 |
| Une réponse n'écrit jamais la sortie d'une commande : la sortie réelle arrive dans le message suivant (rôle `tool`). | § 7.2 |
| Une faute n'apparaît dans une réponse que comme le texte à remplacer. | § 7.3 |
| Jamais : une réécriture identique, une modification non testée, une modification sans vérification du gameplay. | § 3 |
| Les outils sont ceux d'OpenCode 2.0.6 (`shell`, `read`, `edit`, `write`, `execute`…), texte gardé. | décision 14, § 7.4 |
| Sans raisonnement : `enable_thinking: false` (le gabarit écrit un bloc de réflexion vide). | § 7.6 |
| Le partage 40/40/20 (création, débogage, analyse) se compte en jetons de réponse, par sujet. | décision 3, § 7.1 |
| Le débogage n'est jamais coupé ; on augmente les créations. | décision 21 |
| Une case n'écrase pas les autres : au plus 20 paires par réponse identique. | § 7.7, `assembler.py:37` |
| Avertissements de GDScript traités en erreurs, typage compris, dans les projets du plan. | § 5.3 |
| Godot 4.7.2. Godot 4.8 : seulement ses différences, plus tard, à la version stable. | décisions 12, 15, 19.7 |
| Aucun exemple mis de côté pour tester : tout va à l'entraînement. | décision 16 |

Exclus de toute paire :
- le mot « Starfox » (`assembler.py:38`, rejeté) ;
- le texte des 221 tâches gelées (`usine/portillon/exclusion.py`, `texte_exclu` : 60 % de leurs fragments suffisent à rejeter) ;
- les sons TII (licence « No AI Training ») ;
- `F:\REVERSe\RECONSTRUCTION` : une copie d'un jeu commercial, rien n'en est tiré.

---

## 2. Ce qui existe et ce qui manque (assemblage du 2026-11-02 à 09:01)

Sources : `donnees/entrainement/controles_palier_1.json` et `controles_palier_2.json`, résumés dans
`D:\GODOT\PROJETS_DEMOS\PROJET_BOSS_ACTION_RPG\SUIVIS_PROGRESSION\PROMPT_REPRISE_PAIRES.md`, § 2.2 et 2.3.

| Format | Paires | Jetons | Jetons de réponse : création / débogage / analyse |
| --- | --- | --- | --- |
| palier 1 (1 024) | 18 444 | 12,6 M | 27,7 / 47,5 / 24,8 |
| palier 2 (2 048) | 11 879 | 19,4 M | 36,0 / 42,8 / 21,2 |

Il manque environ **1,27 M jetons de création** au total, 1,73 M sujet par sujet. Les plus gros trous, en jetons de
création, au palier 1 puis au palier 2 :

| Sujet | palier 1 | palier 2 |
| --- | --- | --- |
| procédural | 472 000 | 108 000 |
| gameplay | 323 000 | 104 000 |
| shaders | 254 000 | 117 000 |
| graphisme 3D | 138 000 | 16 000 |
| physique | 0 | 56 000 |
| UI | 26 000 | 32 000 |
| VFX | 27 000 | 36 000 |

Pourquoi : l'assembleur règle chaque sujet sur le plus grand de la création et du débogage (`assembler.py:87`). Une
paire de débogage de plus fait monter la création attendue ; une paire d'analyse de plus est retirée au partage
(3 999 analyses retirées au palier 1 le 2026-11-02).

La façon de combler la création attend la décision de laurent (`PROMPT_REPRISE_PAIRES.md`, § 2.4) : ajouter des tests
dans les cours, un autre juge déterministe, ou couper du débogage. Ne pas la trancher à sa place.

---

## 3. Le format exact d'une paire

Une ligne JSON par paire, UTF-8, fins de ligne `\n`, écrite avec `ensure_ascii=False` (`usine/paires/format.py:131`).
Exactement ces huit clés (`format.py:68`) :

| Clé | Type | Contenu |
| --- | --- | --- |
| `famille` | texte | le nom de la famille qui l'a produite (ex. `creation_bloc`, `demarche`, `voir_fluide`) |
| `sujet` | texte | un des 13 sujets du § 4, écrit exactement |
| `type` | texte | `création`, `débogage` ou `analyse` (`format.py:13`) |
| `messages` | liste | la conversation au format chat d'OpenAI (ci-dessous) |
| `images` | liste | chemins absolus de PNG, dans l'ordre des marques `<image>` ; `[]` sinon |
| `preuve` | objet | ce qui a vérifié la paire : commandes, codes de sortie, fichiers, cas rouges puis verts… |
| `jetons` | entier | jetons de toute la paire mise en forme (§ 6) |
| `jetons_reponse` | entier | jetons des seules réponses de l'assistant, appels d'outils compris (§ 6) |

### 3.1 Les messages

- Rôles : `system` (seulement en tête, et seulement le plan : § 5), `user`, `assistant`, `tool`.
- Le premier message après le plan éventuel est la demande (`user`).
- Le dernier est une réponse `assistant` **sans** appel d'outil (`format.py:83`).
- Chaque `content` est rogné (`strip()`) : le gabarit de Qwen 3.8 le fait, LLaMA-Factory non (`format.py:65`).
- Un appel d'outil s'écrit dans le message assistant qui le précède de son texte :

```json
{"role": "assistant", "content": "Avant d'écrire `chain`, je vérifie `Control.focus_neighbor_bottom` dans la documentation :",
 "tool_calls": [{"id": "rag_chain_2", "type": "function",
                 "function": {"name": "execute", "arguments": {"code": "return await tools[\"usine-godot\"].search_docs({ requete: \"Control.focus_neighbor_bottom\", n: 2 });"}}}]}
```

- `arguments` est un **objet**, jamais une chaîne JSON : le gabarit de Qwen 3.8 refuse une chaîne
  (`usine/cours/base/opencode.py:283`).
- Chaque appel reçoit son retour, dans l'ordre des appels : `{"role": "tool", "tool_call_id": "<id de l'appel>", "content": "<vraie sortie>"}`.
- Les `id` sont libres mais uniques dans la paire (ex. `demarche_<id du pas>_0`, `verif_show_volumes_40_1`).
- Le texte de la réponse qui précède un appel est gardé : sans lui, le LoRA t1 n'écrivait plus rien (`CLAUDE.md`, § 3).

### 3.2 Les formes les plus fréquentes (relevé du 2026-11-04 sur les 45 843 paires de `donnees/paires/`)

| Suite de messages | Paires |
| --- | --- |
| user, assistant | 31 212 |
| system, user, assistant | 6 363 |
| system, user, assistant + 2 appels, tool, tool, assistant | 4 937 |
| user, assistant + 2 appels, tool, tool, assistant | 1 074 |
| system, user, assistant + appel, tool, assistant | 835 |
| user, assistant + appel, tool, assistant | 715 |
| system, user, assistant + appel, tool, assistant + 2 appels, tool, tool, assistant | 490 |

Exemples complets à lire avant d'écrire un générateur : la première ligne de
`donnees/paires/lire_sortie/paires.jsonl` (analyse, palier 1), de `donnees/paires/debogage_boucle/paires.jsonl`
(débogage par `edit` puis `shell`, palier 2), de `donnees/paires/creation_bloc/paires_atelier.jsonl` (création jugée par
les tests), de `donnees/paires/rag/paires.jsonl` (`execute` du Code Mode) et de
`donnees/paires/voir_fluide/paires_g001.jsonl` (images).

### 3.3 Une paire avec images

```json
{"role": "user", "content": "<image> 0,02 s\n<image> 0,77 s\nJe veux ce résultat avec `WaveSolver`, […] Écris `build()`."}
```

avec `"images": ["D:/constructeur-qwen-gamedev/donnees/paires/voir_fluide/images/g001_vagues_000_00.png", "…_09.png"]`.
Autant de marques `<image>` que d'images (`format.py:18`). Les images sont rendues par Godot, la réponse est écrite
d'après la vérité du moteur ; jamais d'image jugée « à l'œil » (décision 19.3). Une séquence compte 5 images en
640 × 360, chacune avec son instant (décision 19.5).

---

## 4. Types et sujets

### 4.1 Les trois types

| Type | Ce que la réponse fait | Comment c'est vérifié (familles actuelles) |
| --- | --- | --- |
| `création` | écrire du code d'après une description ou un contrat `##` : un corps de fonction, des lignes qui manquent, un cas de test, un shader, une scène | tests rouges sans le code, verts avec (`creation_bloc`, `creation_fonction`, `points`) ; un test qui échoue quand on vide le code (`creation_test`) ; empreinte du maillage (`creation_maillage`, `creation_morceau`) ; image rendue (`creation_shader`) ; scène rejouée (`voir_fluide`) |
| `débogage` | partir d'une vraie sortie en échec (analyse, exécution, test, shader, valeur fausse) et corriger au plus juste, puis relancer et lire la vraie sortie | la faute est injectée, la sortie est celle de Godot, la correction rend le code d'origine et la relance passe (`compilation`, `compilation_calcul`, `execution`, `debogage_boucle`, `faute_calcul`, `shader`) |
| `analyse` | lire une sortie, une image ou une session et conclure (verdict, erreur à traiter d'abord, échelle de temps, cause) sans corriger | la réponse attendue est connue d'avance (faute injectée, ligne « at: », instant de l'événement) (`lire_sortie`, `analyse_boucle`, `analyse_session`) |

Certaines familles produisent plusieurs types : `timing`, `situer_camera` et `lire_editeur` de l'analyse et du
débogage ; `voir_fluide` les trois ; `demarche` surtout de l'analyse (relevé du 2026-11-04 sur `donnees/paires/`).

### 4.2 Les 13 sujets, écrits exactement

`procédural`, `gameplay`, `shaders`, `physique`, `VFX`, `graphisme 3D`, `UI`, `création de tests`,
`contrôle à la manette`, `audio`, `optimisation`, `gestion de la mémoire`, `plugins et leur usage`.

C'est la liste des sujets présents dans les paires au 2026-11-04 ; elle suit la décision 2 de laurent. Un sujet mal
écrit (« Graphisme 3D », « interface ») devient une case à part, avec son propre partage. Le journal de démarche écrit
« Graphisme 3D » : `demarche.sujet()` le met en minuscule (`demarche.py:63`).

---

## 5. Les deux paliers

Le palier se lit sur le message système (`assembler.py:42`) :

| Palier | Message système | Plafond | Quand |
| --- | --- | --- | --- |
| 1 | aucun | 1 024 jetons | le plan ne joue aucun rôle : nom de Godot 3, type, erreur de shader, lecture d'une sortie, requête au RAG ; et la réponse ne contient aucune convention du plan (`CLAUDE.md`, § 3, exception « oui pour 1 ») |
| 2 | exactement le plan | 2 048 jetons, 2 040 avec des images | tout le reste |

- Le plan, c'est le bloc « EN PERMANENCE » de `godot/socle_jeu/AGENTS.md`, de son début jusqu'à `# AVANT CHAQUE ÉTAPE`,
  rogné : `usine.paires.format.plan()` (`format.py:103`). Un autre message système est rejeté.
- Une paire de plus de 1 024 jetons sans le plan est rejetée.
- Repère du journal de démarche pour « une convention du plan » : un dossier du plan cité (`\b[0-7]_[a-z]+/`,
  `demarche.py:43`) ; une telle paire va au palier 2.
- Les sessions longues (format complet d'OpenCode : son prompt et ses 12 outils, 13 351 jetons à eux seuls) sont un
  autre chemin, hors de ce document (décisions 19.2 et 22).

---

## 6. Les jetons

- Tokenizer : `ggml-vocab-qwen38.gguf` de laurent (`config.toml`, `[entrainement] vocab_qwen` :
  `E:\llama_models\qwen3.8\ggml-vocab-qwen38.gguf`, 248 320 jetons), chargé par `usine.cours.base.jetons.tokenizer()`.
  Jamais une estimation en caractères ; le `ggml-vocab-qwen35.gguf` des tests de llama.cpp est un autre vocabulaire
  (`CLAUDE.md`, § 5.8).
- Mise en forme : `usine.cours.base.opencode.rendre()`, traduction du gabarit du GGUF de Qwen 3.8, vérifiée contre lui
  par les tests :
  - `<|im_start|>system\n…<|im_end|>\n`, `<|im_start|>user\n…<|im_end|>\n` ;
  - chaque réponse : `<|im_start|>assistant\n<think>\n\n</think>\n\n` puis le texte, puis les appels sous la forme
    `<tool_call>\n<function=NOM>\n<parameter=CLÉ>\nVALEUR\n</parameter>\n</function>\n</tool_call>` ;
  - les retours d'outils, dans un tour `user`, chacun entre `<tool_response>\n` et `\n</tool_response>`.
- Une image : la marque `<image>` devient `<|vision_start|><|vision_end|>`, plus ses jetons d'image, chaque côté
  arrondi au multiple de 32 le plus proche : 640 × 360 → 20 × 11 = 220 jetons (`format.py:21`).
- `jetons` = `fmt.jetons(messages, images)` ; `jetons_reponse` = `fmt.jetons_reponse(messages)`. L'assembleur recompte
  `jetons` de toute façon (`assembler.py:125`) ; `jetons_reponse` est lu tel quel pour le partage : un faux compte
  fausse le 40/40/20.
- Ne jamais écrire ces nombres soi-même : construire la paire avec `fmt.paire(...)` (une demande, une réponse) ou
  `fmt.paire_tours(...)` (avec outils), qui les calculent.

---

## 7. Les outils et leurs retours, tels qu'OpenCode 2.0.6 les rend

Relevé sur les sessions réelles de laurent (`opencode.py:1-20`). Chemins Windows du projet chez laurent ; Godot appelé
par son chemin complet (aucun `godot` dans le PATH).

| Outil | Arguments | Retour exact |
| --- | --- | --- |
| `shell` | `{"command": "D:\\GODOT\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe --headless --path . …"}` | la sortie telle quelle, puis `\nCommand exited with code N.` ; `(no output)` si rien ; au-delà de 50 ko, pas d'exemple (OpenCode ne rend qu'un aperçu) |
| `read` | `{"path": …, "offset": a, "limit": n}` | `Read file <chemin>, lines a-b`, puis `n: ligne` ; `[Output truncated. Continue reading with offset: n]` s'il en reste |
| `edit` | `{"path": …, "oldString": …, "newString": …}` | `Edited <chemin relatif> (1 replacement)` ; `oldString` doit être unique dans le fichier (§ 5.7) |
| `write` | `{"path": …, "content": …}` | `Created file successfully: <chemin relatif>` ou `Wrote file successfully: <chemin relatif>` |
| `grep` | `{"pattern": …, "include": …}` | seulement `No matches found` : la forme avec résultats n'est pas relevée, on ne l'écrit pas |
| `execute` (Code Mode) | `{"code": "return await tools[\"usine-godot\"].search_docs({ requete: \"…\", n: N });"}` ou `.vocab_lookup({ classe: \"…\", membre: \"…\" })` | la sortie réelle de `mcp_serveur.outils.Outils`, rejouée |

Sortie de Godot : `opencode.sortie_godot()` retire les codes de couleur, la progression de l'import et les lignes
propres à la machine, et remet les chemins dans le dossier du projet chez laurent ; rien d'autre n'est raccourci
(décision 13).

---

## 8. Ce que fait l'assembleur, dans l'ordre

`python -m usine.paires assembler --palier 1`, puis `--palier 2`, depuis le dépôt (`assembler.py:110`) :

1. lit `donnees/paires/*/paires*.jsonl` (un fichier posé à la racine de `donnees/paires/` n'est **pas** lu) ;
2. recompte les jetons ;
3. place la paire dans son palier ou la rejette (§ 5) ;
4. rejette « Starfox », puis le texte des jeux gelés ;
5. rejette les doublons : même demande, même réponse finale et mêmes images, une fois retirées les durées de GdUnit4 ;
   la même question sur une autre image n'est pas un doublon (`assembler.py:62`) ;
6. rejette au-delà de 20 réponses finales identiques ;
7. fait le partage 40/40/20 dans chaque sujet, en jetons de réponse : création et débogage gardés entiers, l'analyse
   en trop retirée au hasard (graine 1) ; un sujet auquel manque un type est gardé entier et signalé ;
8. écrit `donnees/entrainement/palier_<N>.jsonl` (format sharegpt de LLaMA-Factory, `format.vers_llamafactory`),
   l'entrée de `dataset_info.json` et `controles_palier_<N>.json` (rejets par raison, trous par sujet, parts).

Après un apport : lire `controles_palier_<N>.json`, champs `rejets` et `trous`, puis refaire le bilan
(`SUIVIS_PROGRESSION\outils\paires\`, voir `PROMPT_REPRISE_PAIRES.md`, § 4).

---

## 9. Les trois façons d'apporter des paires

### 9.1 Un cours nouveau : la meilleure voie

Toutes les familles tournent sur un cours, et chaque paire en sort vérifiée. Un cours, c'est un jeu **original**
construit pas à pas (jamais la copie d'un jeu existant), rangé selon le plan.

Ce que contient `cours/<nom>/` (modèle : `cours/boss_action_rpg/`) :
- `manifeste.py` : `GENRE = "jeu"`, `PREFIXE`, `SOURCE` (clé de `[sources]` dans `config.toml`), `DERNIERE`,
  `ETAPES` (`{"piste", "titre"}` par étape), `EXTENSIONS`, `PRETES`, `FICHIERS` (chemin → plage de présence :
  `"all"`, `"N+"`, `"a-b"`, `"N"`) ;
- `maitres/` : le projet, fichiers balisés par plage d'étapes : `#@` dans les `.gd`, `//@` dans les shaders, `;@` dans
  les `.tscn`, `.tres`, `project.godot` (`usine/cours/jeu.py`). Une étape nouvelle ne change pas les précédentes ;
- les dossiers du plan (`0_autoload` à `7_tests`) et ses règles (`godot/socle_jeu/ORGANISATION.md`, juge :
  `usine/regles/catalogue.py:70`) ; `project.godot` avec les avertissements en erreurs ;
- des tests GdUnit4 dans `7_tests/`, en miroir du code : **ce sont eux qui jugent la création**. Plus une fonction est
  couverte par un test qui échoue sans elle, plus elle donne de paires de création (aujourd'hui, 2 103 lignes du boss et
  1 551 des bâtiments ne sont jugées par aucun test : `PROMPT_REPRISE_PAIRES.md`, § 2.3) ;
- `notes/etape_NNN.md` (jetons `{STEP}`, `{TITLE}`, `{TRACK}`, `{FILES_TABLE}`) et `demarche.json` (§ 9.2).

Pour le brancher : ajouter son nom à `COURS` dans `usine/paires/__main__.py:35` et `usine/paires/volume.py:21`, sa
source dans `[sources]` de `config.toml`. Puis, par étape, `python -m usine.cours fabriquer <nom> --etapes N`, `--import`
de Godot, tests verts lus ligne par ligne. Enfin les familles, une à la fois (elles partagent les projets d'étape) :

| Familles qui prennent `--cours <nom>` | Ce qu'elles font |
| --- | --- |
| `creation`, `bloc`, `points`, `test_cas` | création jugée par les tests de l'étape |
| `compilation`, `shader`, `execution`, `faute_calcul` | débogage sur une faute injectée |
| `creation_calcul` | création d'un shader de calcul `.glsl`, jugée sur la carte |
| `compilation_calcul` | débogage d'une erreur de glslang, sans carte ni fenêtre ; à ne pas relancer sans l'accord de laurent |
| `morceaux` | création jugée par le maillage (bâtiments) |

Puis `lecture`, `rag`, `debogage_boucle` et `analyse_sessions`, tirées des paires et des bases déjà produites, `demarche`,
tirée des journaux `demarche.json`, et l'assembleur. Options communes : `--etapes 1,2,3`, `--depuis N` (seulement les fichiers changés depuis l'étape N),
`--graine G`.

### 9.2 Des pas de démarche

Un pas est une décision réellement prise en construisant un cours ; l'usine le rejoue et en fait une paire à plusieurs
tours (`usine/paires/demarche.py`). Un pas, dans `cours/<nom>/demarche.json` (liste `pas`) :

```json
{"id": "e18_musique_en_boucle", "etape": 18, "sujet": "Audio", "type": "analyse",
 "situation": "La demande, telle qu'elle se pose à ce moment du travail.",
 "pensee": "Pourquoi on cherche, en une phrase, avant l'appel.",
 "outil": {"genre": "vocab", "classe": "AudioStreamWAV", "membre": "loop_mode"},
 "attendu": ["loop_mode: int"],
 "lecture": "Ce qu'on lit dans la sortie, avec la citation exacte : « propriété [AudioStreamWAV] loop_mode: int ».",
 "decision": "Ce qu'on décide, et comment c'est vérifié."}
```

Genres d'outil (`demarche.py:1-21`) :

| Genre | Champs | Outil rejoué |
| --- | --- | --- |
| `vocab` | `classe`, `membre` | `execute` : `vocab_lookup` |
| `rag` | `requete`, `n` | `execute` : `search_docs` |
| `lire` | `etape`, `fichier`, `debut`, `fin` | `read` sur le projet fabriqué de l'étape |
| `sonde` | `etape`, `script` (dans `cours/<nom>/sondes/`), `arguments` éventuels, `ecrit` | `write` si `ecrit`, puis `shell` : Godot sans fenêtre, 60 images/s ; doit finir par le code 0 |
| `plan` | `de`, `a` | `write` de `plan.md`, tiré des titres du manifeste |

Le pas est écarté si un fragment de `attendu` manque à la sortie rejouée, ou si une citation de `lecture` (entre « »)
n'y est pas mot pour mot (`demarche.py:145`). Puis `python -m usine.paires demarche` : le compte des écartés doit être
0, sinon corriger le pas, jamais la sortie.

### 9.3 Une famille nouvelle

Pour un genre de paire qui n'existe pas encore : un module `usine/paires/<famille>.py` qui produit ses paires à partir
d'exécutions réelles, avec `fmt.paire(...)` ou `fmt.paire_tours(...)`, les écrit par `fmt.ecrire(...)` dans
`fmt.dossier(<famille>)`, et se branche dans `usine/paires/__main__.py`, avec ses tests dans `tests/`. Modèles à imiter :
`creation_bloc` (`bloc.py`), `debogage_boucle.py`, `voir_fluide.py`. La vérité vient du moteur ou d'un outil rejoué,
jamais d'un modèle.

---

## 10. Sur le PC de laurent

- Rien ne se lance sur son PC ni sur son llama-server sans son accord, pas même un rejeu court (`CLAUDE.md`, § 1). On
  explique ce qu'on veut faire (dossiers, outils, durée) avant de demander.
- Godot sans fenêtre seulement (`--headless`) : une fenêtre lui prend la souris ; un rendu en fenêtre demande son accord
  (`usine/cours/base/godot.py` le refuse sans `USINE_FENETRES=1`).
- Tout Godot qui touche la carte passe par `usine/garde_carte.py` (par `usine/bureau_cache.py` ou
  `godot.tester_gdunit`) : un seul à la fois, la carte Intel (`--gpu-index 1`), rien sur la 5090 tant que ComfyUI ou
  llama-server tourne, arrêt après 3 plantages en 10 minutes (8 sur l'Intel). Ne pas relancer `faute_calcul` ni
  `compilation_calcul` sans son accord (écran bleu du 2026-11-01).
- Aucun entraînement tant que les paires ne sont pas finies (décision 20).
- Commits : ses seuls chemins, jamais `git add -A cours` ; les changements non commités de `cours/boss_action_rpg/`
  appartiennent à une autre session et attendent laurent.

---

## 11. Contrôler un fichier avant de le poser

Ce script vérifie la forme, les jetons et le palier d'un fichier de paires. Il ne vérifie pas le contenu : c'est le
rôle du générateur. Testé le 2026-11-04 : 0 faute sur 4 945 paires réelles (`demarche`, `voir_fluide` graine 1,
`debogage_boucle`, `rag`), et les quatre fautes d'une paire fausse écrite exprès relevées. À lancer depuis le dépôt :
`python controler_paires.py <fichier.jsonl> [...]`.

```python
"""Contrôle d'un fichier de paires : forme exacte, jetons recomptés, palier. Pas le contenu (la preuve)."""
import json
import sys
from pathlib import Path

sys.path.insert(0, ".")
from usine.cours.base import opencode  # noqa: E402
from usine.paires import assembler, format as fmt  # noqa: E402

SUJETS = {"procédural", "gameplay", "shaders", "physique", "VFX", "graphisme 3D", "UI", "création de tests",
          "contrôle à la manette", "audio", "optimisation", "gestion de la mémoire", "plugins et leur usage"}
OUTILS = {"shell", "read", "edit", "write", "execute", "grep"}
CLES = {"famille", "sujet", "type", "messages", "images", "preuve", "jetons", "jetons_reponse"}


def fautes(p: dict) -> list[str]:
    f = []
    if set(p) != CLES:
        f.append(f"clés : {sorted(set(p) ^ CLES)} en trop ou en moins")
        return f
    if p["type"] not in fmt.TYPES:
        f.append(f"type inconnu : {p['type']}")
    if p["sujet"] not in SUJETS:
        f.append(f"sujet inconnu : {p['sujet']}")
    if not isinstance(p["preuve"], dict) or not p["preuve"]:
        f.append("preuve vide")
    m = p["messages"]
    k = 1 if m and m[0]["role"] == "system" else 0
    if len(m) < k + 2 or m[k]["role"] != "user":
        f.append("la conversation doit commencer par la demande (user), après le plan éventuel")
    if m[-1]["role"] != "assistant" or m[-1].get("tool_calls"):
        f.append("la dernière réponse doit être un message assistant sans appel d'outil")
    attente: list[str] = []
    for i, x in enumerate(m):
        if x.get("content") != (x.get("content") or "").strip():
            f.append(f"message {i} non rogné (espaces ou retours en tête ou en fin)")
        if x["role"] == "assistant":
            if attente:
                f.append(f"message {i} : des appels attendent encore leur retour")
            for c in x.get("tool_calls") or []:
                if c.get("type") != "function" or c["function"]["name"] not in OUTILS:
                    f.append(f"message {i} : outil inconnu {c['function'].get('name')}")
                if not isinstance(c["function"]["arguments"], dict):
                    f.append(f"message {i} : arguments en chaîne (le gabarit veut un objet)")
                attente.append(c["id"])
        elif x["role"] == "tool":
            if not attente or x.get("tool_call_id") != attente[0]:
                f.append(f"message {i} : retour d'outil sans l'appel qui l'attend, dans l'ordre")
            else:
                attente.pop(0)
        elif x["role"] == "system" and i != 0:
            f.append(f"message {i} : message système ailleurs qu'en tête")
    marques = sum(x["content"].count(fmt.MARQUE_IMAGE) for x in m if x["role"] == "user")
    if marques != len(p["images"]):
        f.append(f"{marques} marques <image> pour {len(p['images'])} images")
    for chemin in p["images"]:
        if not Path(chemin).is_file():
            f.append(f"image absente : {chemin}")
    if assembler.STARFOX.search(json.dumps(m, ensure_ascii=False)):
        f.append("le mot Starfox (exclu)")
    if f:
        return f
    try:
        opencode.vers_sharegpt(m, [])
    except ValueError as e:
        f.append(f"export LLaMA-Factory impossible : {e}")
    recompte = fmt.jetons(m, p["images"])
    if recompte != p["jetons"]:
        f.append(f"jetons : {p['jetons']} écrits, {recompte} recomptés")
    if fmt.jetons_reponse(m) != p["jetons_reponse"]:
        f.append(f"jetons_reponse : {p['jetons_reponse']} écrits, {fmt.jetons_reponse(m)} recomptés")
    n, raison = assembler.palier(dict(p, jetons=recompte))
    if n is None:
        f.append(f"hors palier : {raison}")
    return f


for fichier in sys.argv[1:]:
    lignes = [l for l in Path(fichier).read_text(encoding="utf-8").splitlines() if l.strip()]
    mauvaises = 0
    for k, ligne in enumerate(lignes, 1):
        liste = fautes(json.loads(ligne))
        if liste:
            mauvaises += 1
            if mauvaises <= 5:
                print(f"{fichier}:{k} : " + " ; ".join(liste))
    print(f"{fichier} : {len(lignes)} paires, {mauvaises} en faute")
```

---

## 12. Prompt à donner à un autre modèle

> Tu vas apporter des paires d'entraînement au LoRA de Qwen pour Godot 4.7.2, dans le dépôt
> `D:\constructeur-qwen-gamedev` (branche `claude/observation-visuelle`). Lis d'abord, en entier,
> `prompts/ecrire_des_paires.md`, puis `CLAUDE.md` (les « Règles qui priment » l'emportent sur tout) et
> `D:\GODOT\PROJETS_DEMOS\PROJET_BOSS_ACTION_RPG\SUIVIS_PROGRESSION\PROMPT_REPRISE_PAIRES.md`.
> Tu n'écris aucune paire à la main : tu apportes un cours, des pas de démarche ou un générateur (§ 9), et ce sont les
> outils de l'usine qui produisent les paires, chacune vérifiée par le moteur ou par un outil rejoué. Ce qui manque, c'est
> de la création, surtout en procédural, gameplay, shaders et graphisme 3D (§ 2).
> Avant de lancer quoi que ce soit sur le PC de laurent, explique-lui ce que tu vas faire (dossiers, outils, durée) et
> attends son accord explicite. Godot sans fenêtre seulement, par la garde de la carte. Contrôle chaque fichier produit
> (§ 11), réassemble les deux paliers, lis `controles_palier_*.json`, tiens les journaux et committe tes seuls chemins.
> Réponds à laurent en français, court, la réponse d'abord, chaque affirmation sourcée.
