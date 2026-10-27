# ETAT — journal de reprise

À mettre à jour à la fin de **chaque** session : ce qui est fait, la preuve de fin collée telle quelle, ce qui reste, les pièges rencontrés.

## Avancement

- [x] Session 1 — Vocabulaire, juge commun, projet de référence, 10 tâches
- [x] Session 2 — Traducteurs déterministes (scène ↔ spec, description du projet, éditions)
- [x] Session 3 — Usine à tâches, portillon, jeux gelés
- [x] Session 4 — RAG Godot, serveur MCP, fiches de compétences, enregistreur
- [x] Avant la session 5 — jeux sources supplémentaires (survivor, kits Kenney), gel à 4 sources (172 tâches)
- [x] Avant la session 5 — compétence E « optimisation stricte »
- [ ] Gel complet sous Godot 4.7.2 (décision du 2026-10-06), avec E : `VERIFIER_EN_LOCAL.md` étape 21, une nuit sur la machine
- [x] Session 5 — Boucle RFT (cloud : code et preuve ; vrai tour après le gel 4.8)
- [x] Session 6 — Mesure (cloud : code et preuve simulée ; mesure réelle après le premier LoRA et le gel 4.8)
- [x] Béquille, point 1 — retour des outils (2026-10-11) : `VERIFIER_EN_LOCAL.md` étape 22
- [x] Béquille, points 2, 6, 9 — socle propre et jouable, plan d'organisation, juge de structure (2026-10-11) : étape 23
- [x] Béquille, points 3, 4, 5 — déclaration d'action (`prepare_action`), 15 fiches par besoin et par situation (2026-10-11) : étape 23
- [x] Béquille, point 8 — grille de captures horodatées et journal `Trace` (`capture_frames`) (2026-10-11) : étape 23
- [ ] Béquille — mesure : même campagne de deux heures, avec et sans chaque béquille
- [ ] Béquille — entraînement sur la démarche (harnais identique à l'usage)
- [x] Règles qui priment (mode d'emploi de laurent et passe « bâtiments procéduraux ») en tête de `CLAUDE.md` ; décors procéduraux admis par le juge des règles (2026-10-14) : étape 25
- [x] Cours « bâtiments procéduraux » (3 villes × 13 étapes) dans le dépôt, conforme au juge des règles et vérifié par Godot (2026-10-14) : étape 26
- [x] Générateur de la base « bâtiments procéduraux » dans le dépôt (création en plusieurs tours, règle 7.2) ; socle aux avertissements en erreurs (règle 5.3) (2026-10-14) : étape 27
- [x] Base convertie au format d'OpenCode, harnais d'usage (décision 14), jetons comptés avec le tokenizer de Qwen 3.8 (2026-10-15) : étape 28
- [x] Compétence O1 « corriger en observant » (2026-10-20, sur la machine : juge, générateur, outil play_sequence ; 10 tâches kart produites, portillon et premier essai de Qwen à lancer : étape 29)
- [x] Cours « kart » en 14 étapes de création, aux règles d'architecture (découpage accepté par laurent le 2026-10-20) : 14 étapes faites et vérifiées (2026-10-21)
- [x] Cours « roguelike » en 14 étapes de création, même démarche (découpage validé par laurent le 2026-10-21) : 14 étapes faites et vérifiées (2026-10-21)
- [x] Bases d'entraînement des cours du kart et du roguelike, au format d'OpenCode, 50/50 en jetons de réponse, contrôle strict des sorties de tests (2026-10-22)
- [ ] Apprendre à Qwen à chercher des références, tester le rendu et le gameplay, utiliser le RAG (priorité de laurent, « après le roguelike »)
- [ ] Protocole de la décision 18 : découpe point par point, 138 démos, RAG et O1 dans les données (décision 19 : 12 000 paires de 1 024 jetons et 10 000 de 2 048 sur la 5090, puis 3 000 sessions longues sur carte louée), puis RFT et RLVR
- [ ] Le plan manque dans les bases au format d'OpenCode : 0 exemple sur 203 (kart) et 0 sur 155 (roguelike) ; la conversion remplace le message système, et la session capturée le 2026-10-04 n'avait pas chargé `AGENTS.md`. Relever par une capture comment OpenCode transmet l'`AGENTS.md` d'un projet, puis corriger le générateur avec le bloc permanent du socle (règle de la section 3) ; vérifier la base des bâtiments
- [ ] Décision 19 : 2 000 paires d'images (1 024 jetons : reconnaître, comparer deux étapes, voulu ou défaut, relier au code) et 3 000 analyses de séquences d'images (2 048 jetons). Mémoire de la 5090 mesurée (5 images en 640 × 360 passent sous 2 048 jetons) ; reste à relever la transmission des images par OpenCode et la forme des positions dans les réponses
- [ ] Décision 3 passée à 40/40/20 (création, débogage, analyse) : les bases du kart et du roguelike sont au 50/50 sans analyse ; l'assembleur doit compter un troisième type, « analyse », à leur regénération
- [ ] Décision 19.7 : relever par la capture d'OpenCode la forme exacte d'un appel du Code Mode dans `execute` (requêtes au RAG et captures des paires courtes) ; à la sortie de Godot 4.8 stable, comparer les `extension_api.json` de 4.7.2 et 4.8 et compter les différences utiles
- [ ] Retirer les espaces de fin des messages : le gabarit de Qwen 3.8 les retire, LLaMA-Factory (`qwen3_5`) les garde (seule différence relevée entre les deux rendus, essai du 2026-10-22)

## Bilan des 6 sessions (2026-10-05)

| Étape | État dans le cloud | Vérifié sur la machine de laurent |
| --- | --- | --- |
| Session 1 — vocabulaire, juge, projet de référence | fait | oui (étapes 1 à 5) |
| Session 2 — traducteurs déterministes | fait | oui (étapes 6 à 9) |
| Session 3 — usine à tâches, portillon, gel | fait ; le gel a été refait à 4 sources (172 tâches) | oui (étapes 10 et 11, remplacées par 17 b) |
| Session 4 — RAG, serveur MCP, fiches, enregistreur | fait | oui (étapes 12 à 16 ; 13 b facultative non lancée) |
| Avant la session 5 — jeux sources (survivor, Kenney) | fait | oui (17 a ; 17 b facultative non lancée) |
| Avant la session 5 — compétence E | fait, PR #6 fusionnée ; gel avec les autres sous Godot 4.7.2 (étape 21) | oui (18 a, 2026-10-06) |
| Session 5 — boucle RFT | fait (code, preuve : mini-tour contre un faux serveur juste à 60 %, vrai juge) ; harnais OpenCode à confirmer | oui (19 a et 19 b, 2026-10-06) ; 19 c : pas de CLI OpenCode, harnais = agent maison |
| Session 6 — mesure | fait (code, preuve sur résultats simulés ; agentiques mesurées par l'agent maison) ; la mesure réelle attend le premier LoRA et le gel 4.8 | oui (20 a et 20 b, 2026-10-06) |

Ordre conseillé pour la suite (décision du 2026-10-06 : on reste sous Godot 4.7.2, la 4.8 viendra plus tard) :
1. gel complet sous Godot 4.7.2, E compris (étape 21) ;
2. compléter le gel (`--completer-gel`) avec de nouveaux jeux sources et les générateurs manquants (C1, C2, S3, K4, D2, F2), **avant** le premier entraînement, ou décider de figer tel quel ;
3. premier tour RFT (`python -m usine.rft tour`), entraînement, GGUF, lanceur (19 d) ;
4. mesure réelle (`python -m usine.mesure executer`, puis `rapport`, puis `regression` après chaque tour).

## Journal

### Session 1 — 2026-10-03 (branche `claude/session-01-fondations-nsj4vo`)

**Fait**

- Squelette du dépôt selon l'arborescence de `CLAUDE.md` ; `requirements.txt` (pytest seul, Python ≥ 3.11) ; `pytest.ini` ; `.gitattributes` (LF partout) ; section `[juge]` ajoutée à `config.example.toml`.
- `outils/installer_godot_cloud.sh` : Godot 4.7.2 Linux officiel dans `godot_bin/`, empreinte SHA-512 vérifiée contre `SHA512-SUMS.txt` de la release. **Le réseau l'a permis : aucun test moteur n'est en skip.**
- `usine/config.py` (config.toml, repli sur `godot_bin/`) et `usine/processus.py` (délai ; on ne tue que le groupe/arbre du PID lancé, règle 8).
- `usine/vocab` : `--dump-extension-api` → `donnees/vocab/godot_4.7.2.sqlite` (classes, héritage, méthodes + arguments + arité, signaux + arguments, propriétés, enums, constantes, types intégrés, `@GlobalScope`). `existe(classe, membre, genre)` suit l'héritage ; `arite()` prête pour S2. CLI `construire` / `lookup` (la base se construit seule au premier lookup).
- `usine/juge` : `check_script`, `load_scene`, `run_tests` → verdict au format commun ; `juger_projet` enchaîne import → check_script → load_scene → run_tests sur une **copie jetable**. Catégories : les 7 de départ + `missing_resource` (ajout compatible).
- `godot/reference/` : jeu d'action 2D vu de dessus en GDScript typé (hero + dash/i-frames, ghost patrouille/poursuite, health_component, wave_spawner, coin_pickup, hud, game_state en autoload, main). 37 tests GdUnit4.
- **GdUnit4 6.2.1** (MIT, sans son dossier `test/`) dans `godot/reference/addons/gdUnit4` : dernière version publiée, annoncée compatible 4.7/4.7.1, vérifiée ici sur 4.7.2. Le juge l'injecte dans les copies de travail qui n'en ont pas (les `depart/` des tâches n'embarquent pas l'addon).
- 10 tâches modèles (K2 ×2, K3 ×2, S1 ×2, S2 ×2, D1 ×2) générées par `outils/construire_taches_modeles.py` depuis `godot/reference/` → copie versionnée `godot/taches_modeles/`, installée dans `donnees/taches/` par `python -m usine.taches installer`. Les journaux K3/D1 sont produits en lançant vraiment Godot ; le générateur vérifie que la réponse D1 attendue figure dans le journal.

**Choix de format (extensions compatibles)**

- `reference/` est une **superposition** sur `depart/` (fichiers ajoutés ou remplacés).
- `tests_caches/` est copié dans `res://tests_juge/` au moment de juger, et seul ce dossier est exécuté.
- `tache.json` accepte un champ `juge` : `etapes` (D1 : `["run_tests"]`, le projet de départ étant volontairement cassé) et `patch_max_lignes` (K3 : 6).
- D1 : l'agent écrit `res://reponse.json` = `{"categorie", "fichier", "ligne"}`, lu par le test caché.
- S1 : en session 1 la sortie est la `.tscn` elle-même ; la spec JSON et son écrivain arrivent en session 2.
- `tests.echecs` nomme les tests `suite:test` (syntaxe de GdUnit4).
- Empreinte : SHA-256 de `tache.json` (sans `empreinte` ni `gelee`) et des octets des trois dossiers.

**Preuve de fin** (exécutée dans le cloud, Godot 4.7.2 Linux headless)

`python -m usine.juge run godot/reference`

```
{
 "ok": true,
 "etape": "run_tests",
 "duree_s": 14.801,
 "erreurs": [],
 "tests": {
  "total": 37,
  "passes": 37,
  "echecs": []
 }
}
code=0
```

`python -m usine.juge modeles --dossier donnees/taches --travailleurs 4` (chaque version jugée deux fois ; « stable » = mêmes verdict et tests, durée exclue)

```
tâche                        départ                             référence                  stable  empreinte  conforme
d1_001_identifiant_inconnu   FAIL @run_tests 0/3                PASS 3/3                   oui     oui        OUI
d1_002_cible_nulle           FAIL @run_tests 0/3                PASS 3/3                   oui     oui        OUI
k2_001_take_damage           FAIL @run_tests 28/37              PASS 37/37                 oui     oui        OUI
k2_002_start_next_wave       FAIL @run_tests 33/37              PASS 37/37                 oui     oui        OUI
k3_001_rayon_detection       FAIL @run_tests 36/37              PASS 37/37                 oui     oui        OUI
k3_002_duree_dash            FAIL @run_tests 36/37              PASS 37/37                 oui     oui        OUI
s1_001_heart_pickup          FAIL @run_tests 37/40              PASS 40/40                 oui     oui        OUI
s1_002_spike_trap            FAIL @run_tests 37/41              PASS 41/41                 oui     oui        OUI
s2_001_mort_du_fantome       FAIL @run_tests 34/38              PASS 38/38                 oui     oui        OUI
s2_002_cycle_des_vagues      FAIL @run_tests 34/38              PASS 38/38                 oui     oui        OUI

10/10 tâches conformes
code=0
```

`python -m usine.vocab lookup CharacterBody2D` (extrait)

```
CharacterBody2D (Godot 4.7.2)
Héritage : CharacterBody2D → PhysicsBody2D → CollisionObject2D → Node2D → CanvasItem → Node → Object

Signaux (22) :
  [CollisionObject2D] input_event(viewport: Node, event: InputEvent, shape_idx: int)
  [CollisionObject2D] mouse_entered()
  [CollisionObject2D] mouse_exited()
  [CollisionObject2D] mouse_shape_entered(shape_idx: int)
  [CollisionObject2D] mouse_shape_exited(shape_idx: int)
  [CanvasItem] draw()
  [CanvasItem] hidden()
  [CanvasItem] item_rect_changed()
  [CanvasItem] visibility_changed()
  [Node] child_entered_tree(node: Node)
  [Node] child_exiting_tree(node: Node)
  [Node] child_order_changed()
  [Node] editor_description_changed(node: Node)
  [Node] editor_state_changed()
  [Node] ready()
  [Node] renamed()
  [Node] replacing_by(node: Node)
  [Node] tree_entered()
  [Node] tree_exited()
  [Node] tree_exiting()
  [Object] property_list_changed()
  [Object] script_changed()

Propriétés (62) :
  [CharacterBody2D] floor_block_on_wall: bool
  [CharacterBody2D] floor_constant_speed: bool
  [...]
  [Node2D] global_position: Vector2
  [...]
code=0
```

`python -m pytest -q`

```
64 passed in 77.33s (0:01:17)
code=0
```

**Reste à faire**

- Exécuter `VERIFIER_EN_LOCAL.md` sur la machine Windows et noter le résultat ci-dessous.
- Session 2 : spec de scène JSON ↔ .tscn (S1 passera par l'écrivain), describe_project, apply_edits.

### Session 2 — 2026-10-04 (branche `claude/session-02-bcedxx`)

**Fait**

- `usine/scene/texte.py` : format texte Godot 4 sans LLM. Valeurs ↔ JSON typé (`{"Vector2": [x, y]}`, `{"ExtResource": "res://…"}`, repli `{"godot": "<brut>"}`), écrites comme Godot 4.7 (`6.0`, mais `Vector2(320, 180)`). Document `.tscn`/`.tres` découpé en sections **sans perte** : `texte()` rend les mêmes octets (LF ou CRLF), une édition ne réécrit que sa ligne ou sa section.
- `usine/scene/spec.py` + `SPEC_SCENE.md` : spec de scène JSON (nœuds, type ou instance, script, propriétés, groupes, ressources externes et internes, connexions avec flags/binds/unbinds, editables). `scene_read` / `scene_write` déterministes ; id dérivés : `ext_resource` = `<rang>_<h5(chemin)>`, `sub_resource` = `<Type>_<h5(scène::nom d'usage)>`, uid de scène dérivé du chemin (alphabet ResourceUID). `valider_spec` vérifie types, propriétés (natives, variables de script, dynamiques listées), forme des valeurs, scripts compatibles, signaux, méthodes et arité.
- `usine/scene/preuve.py` (`python -m usine.scene preuve`) : aller-retour sur les scènes d'un projet + 5 scènes générées (`exemples.py` : interface, 3D à ressources imbriquées, piège à binds/unbinds/flags, instances avec variables de script, HUD à metadata typées), contrôle indépendant par Godot (`gd/etat_scene.gd` compare le `SceneState` chargé avant/après). Seconde série sur les mêmes scènes **resauvées par Godot** (`gd/resauver_scene.gd`), pour éprouver le lecteur sur le format de l'éditeur ; les 5 scènes générées sont identiques, octet pour octet, à ce que Godot écrit (colonne `= Godot`).
- `usine/projet/gdscript.py` (lecture légère des déclarations de premier niveau, réindentation), `index.py` (index du projet, héritage des scripts, `Verificateur` natif + scripts).
- `usine/projet/decrire.py` : `describe_project` → texte compact et stable + table `ids` (id lisible `<scène>:<chemin>`, ressource interne `<id>#<propriété>`).
- `usine/projet/editions.py` + `EDITS_GODOT.md` : `apply_edits` avec les 10 opérations. Validation en mémoire (premier refus → rien n'est écrit), copie de travail jugée (import → check_script → load_scene → run_tests), puis `os.replace` fichier par fichier avec détection de conflit et restauration si un remplacement échoue. CLI `python -m usine.projet describe|apply|demo`.
- `VERIFIER_EN_LOCAL.md` : étapes 7 à 10 (dont un aller-retour en lecture seule sur `D:\GODOT\projet_*`).
- Tests : `test_scene_texte.py`, `test_scene_spec.py`, `test_gdscript.py`, `test_projet_decrire.py`, `test_editions.py` ; fixture `tests/donnees/sonde_godot472.tscn` (scène réellement sauvée par Godot 4.7.2 : `unique_id`, groupes, chaîne et dictionnaire multilignes).

**Choix**

- Format d'écriture relevé sur Godot 4.7.2 lui-même : plus de `load_steps`, `unique_id=` sur les nœuds (préservé s'il existe, jamais inventé), `groups` avant `instance`, connexions en bloc. Les `ext_resource` n'ont un `uid` que si la spec en donne un (un uid faux ferait avertir Godot).
- Propriétés d'un nœud écrites natives d'abord, puis `script`, puis variables du script et `metadata/` : c'est l'ordre de Godot, et une variable de script placée avant `script` serait ignorée au chargement. Il faut donc le vocabulaire pour écrire (ouvert par défaut).
- L'id d'une ressource interne dérive de son **nom d'usage** (`CollisionShape2D:shape`) et non du nom donné dans la spec : une scène écrite par `scene_write` redonne les mêmes octets dès la première relecture.
- Normalisation de l'aller-retour (`normaliser_tscn`, indépendante de l'écrivain) : retrait de `load_steps` et renumérotation des id dans l'ordre du fichier. Rien d'autre.
- `apply_edits` s'arrête au premier édit refusé (les suivants peuvent dépendre de lui). Les fichiers sont édités en place, jamais régénérés : seuls changent la zone éditée, la ligne vide qui sépare deux sections, et `load_steps` s'il existe.
- Catégories d'erreur ajoutées (compatibles) : `id_inconnu`, `vocab_inconnu`, `valeur_invalide`.

**Preuve de fin** (exécutée dans le cloud, Godot 4.7.2 Linux headless)

`python -m usine.scene preuve`

```
scène                                                normalisé  point fixe  Godot  load_scene  = Godot
res://scenes/coin.tscn                               oui        oui         oui    —           —
res://scenes/generees/arene_3d.tscn                  oui        oui         oui    oui         oui
res://scenes/generees/hud_complet.tscn               oui        oui         oui    oui         oui
res://scenes/generees/menu_pause.tscn                oui        oui         oui    oui         oui
res://scenes/generees/piege_zone.tscn                oui        oui         oui    oui         oui
res://scenes/generees/salle_pieces.tscn              oui        oui         oui    oui         oui
res://scenes/ghost.tscn                              oui        oui         oui    —           —
res://scenes/hero.tscn                               oui        oui         oui    —           —
res://scenes/hud.tscn                                oui        oui         oui    —           —
res://scenes/main.tscn                               oui        oui         oui    —           —
res://scenes/coin.tscn [resauvée]                    oui        oui         oui    —           —
res://scenes/generees/arene_3d.tscn [resauvée]       oui        oui         oui    —           —
res://scenes/generees/hud_complet.tscn [resauvée]    oui        oui         oui    —           —
res://scenes/generees/menu_pause.tscn [resauvée]     oui        oui         oui    —           —
res://scenes/generees/piege_zone.tscn [resauvée]     oui        oui         oui    —           —
res://scenes/generees/salle_pieces.tscn [resauvée]   oui        oui         oui    —           —
res://scenes/ghost.tscn [resauvée]                   oui        oui         oui    —           —
res://scenes/hero.tscn [resauvée]                    oui        oui         oui    —           —
res://scenes/hud.tscn [resauvée]                     oui        oui         oui    —           —
res://scenes/main.tscn [resauvée]                    oui        oui         oui    —           —

[resauvée] : la même scène après chargement puis ResourceSaver.save par Godot (format de l'éditeur)
20/20 scènes conformes (5 générées, 10 resauvées par Godot)
code=0
```

`python -m usine.projet demo` (extraits ; la sortie complète contient aussi le diff des 5 fichiers modifiés)

```
== demo_reference : Démonstration des 10 opérations sur godot/reference : un minuteur de bonus, une pièce déplacée, une supprimée, une collision élargie. Les 37 tests doivent rester verts.
{
 "ok": true,
 "applique": true,
 "etape": "run_tests",
 "erreurs": [],
 "tests": {
  "total": 37,
  "passes": 37,
  "echecs": []
 },
 "fichiers": [
  "res://scenes/coin.tscn",
  "res://scenes/main.tscn",
  "res://scripts/hud.gd",
  "res://scripts/main.gd",
  "res://scripts/minuteur_bonus.gd"
 ]
}
empreinte avant : fec2cb08a5d39232fff32c18765448c6ffa444e27bd831a7b0bce9c37a7a3ac3
empreinte après : b0e33044f185eaa6f8be2a3b4d2dde145cf9c6b0019e1a3701cca9fab2eccc71
[... diff ...]
=> CONFORME (appliqué, PASS attendu)

== faux_id_reference : Refus à la validation : le deuxième édit vise un nœud qui n'existe pas (Coin9). Rien ne doit être écrit, même pas le premier édit.
{
 "ok": false,
 "applique": false,
 "etape": "validation",
 "erreurs": [
  {
   "edit": 1,
   "op": "set_property",
   "fichier": "res://scenes/main.tscn",
   "ligne": null,
   "categorie": "id_inconnu",
   "message": "édit 1 (set_property) refusé : id inconnu : 'main:Coins/Coin9' (aucun nœud 'Coins/Coin9' dans res://scenes/main.tscn)"
  }
 ],
 "tests": {
  "total": 0,
  "passes": 0,
  "echecs": []
 },
 "fichiers": []
}
empreinte avant : b0e33044f185eaa6f8be2a3b4d2dde145cf9c6b0019e1a3701cca9fab2eccc71
empreinte après : b0e33044f185eaa6f8be2a3b4d2dde145cf9c6b0019e1a3701cca9fab2eccc71
=> CONFORME (refusé, projet intact attendu)

== faux_juge_reference : Refus par le juge : les éditions sont valides, mais le nouveau texte du HUD casse un test (« Pieces » sans accent). La copie de travail est jetée.
 "etape": "run_tests",
 "tests": {"total": 37, "passes": 35, "echecs": ["test_hud:test_libelle_pieces", "test_main:test_hud_affiche_les_pieces"]},
empreinte avant : b0e33044f185eaa6f8be2a3b4d2dde145cf9c6b0019e1a3701cca9fab2eccc71
empreinte après : b0e33044f185eaa6f8be2a3b4d2dde145cf9c6b0019e1a3701cca9fab2eccc71
=> CONFORME (refusé, projet intact attendu)

3/3 cas conformes
code=0
```

`python -m usine.projet describe godot/reference` (début)

```
PROJET Reference Usine (Godot 4.7)
scène principale : res://scenes/main.tscn
autoloads : GameState = res://scripts/game_state.gd
ids : <scène>:<chemin du nœud> ; ressource interne : <id>#<propriété>

SCÈNE coin = res://scenes/coin.tscn
  coin  Area2D  script res://scripts/coin_pickup.gd
    coin:CollisionShape2D  CollisionShape2D  shape=CircleShape2D(radius=6.0)
  connexion coin.body_entered → coin._on_body_entered

SCÈNE ghost = res://scenes/ghost.tscn
  ghost  CharacterBody2D  script res://scripts/ghost.gd  motion_mode=1
```

`python -m pytest -q`

```
174 passed in 163.06s (0:02:43)
code=0
```

**Reste à faire**

- Session 3 : faire passer les tâches S1 par la spec (l'agent rend une spec JSON, `scene_write` écrit la scène, `valider_spec` puis le juge) ; D2 s'appuie sur `describe_project` + `apply_edits`.
- Session 4 : exposer `describe_project`, `apply_edits`, `scene_write` et `valider_spec` dans le serveur MCP.


### Session 3 — 2026-10-04 (branche `claude/session-03-7wu8nc`)

**Fait**

- `usine/generateurs/` :
  - `operateurs.py` : 13 opérateurs de mutation sur GDScript (comparaison inversée, opérateur arithmétique, constante modifiée, chemin de nœud cassé, connexion supprimée, `await` retiré, mauvais type exporté, appel supprimé, condition niée, signal renommé, booléen inversé, méthode renommée, argument retiré) et sur `.tscn` (connexion supprimée, signal renommé, parent cassé). Chaînes et commentaires masqués avant toute recherche ; énumération déterministe.
  - `masquage.py` : K2 (corps d'une méthode vidé, contrat `##` gardé) et K1 (script retiré ; consigne = interface ; référence = squelette ; test caché = interface lue par réflexion). **Parseur** : celui de `usine/projet/gdscript.py` (blocs par indentation), pas gdtoolkit : sa grammaire suit Godot 4.x avec retard et il ajouterait `lark` au wheelhouse ; le masquage n'a besoin que des bornes des fonctions, et le juge reste l'autorité.
  - `mutation.py` : un mutant par ligne (graine), jugé une fois avec les tests du projet → K3 (tests rouges à `run_tests`, `journal_tests.json`, patch ≤ 6 lignes) ou D1 (le journal de lancement localise une erreur catégorisée exactement sur la ligne mutée).
  - `aller_retour.py` : S1 (scène → spec → consigne gabarit ; l'agent rend une spec écrite par `scene_write`) et S2 (une tâche par connexion retirée). Sources : les 5 scènes du projet + les 5 scènes générées de la session 2. Champ `consigne_a_ecrire: null` réservé à Qwen.
  - `inverse.py` (F1) : réglages du héros tirés sur une grille, mesurés par le moteur en frames (marche sur 30 images, images de dash, d'invulnérabilité, avant redash, distance du dash).
  - `mutants.py` : score de mutation d'un dossier de tests (critère C2) ; `score_mutation_tache` prend les mutants dans la zone que la référence change. CLI `python -m usine.generateurs mutants <projet> <tests>`.
  - `invention.py` : format `usine.invention/1` des propositions de Qwen, validation (schéma, chemins sûrs, tests hors de l'espace de l'agent, vocabulaire réel des `extends`/`type=`), exclusion des gelés. Exemple fictif : `tests/donnees/invention_exemple.json`.
  - `gabarits.py` : tests cachés et fonctions GDScript de mesure. **La même fonction** produit la vérité terrain (lancée par le générateur sur la référence) et la vérifie (dans le test caché).
- `usine/portillon/` : `regles.py` (départ rouge et référence verte 3/3, stabilité, score de mutation ≥ 50 %, raisons de rejet), `dedoublonnage.py` (empreinte + fragments de 6 jetons de la **réponse**, Jaccard ≥ 0,8), `gel.py` (tirage reproductible, manifeste), `exclusion.py` (tâche, session enregistrée, texte libre pour le RAG), `difficulte.py` (garder 1 à 6 réussites sur 8, pour la session 5), `chaine.py` + CLI `python -m usine.portillon chaine|evaluer|comparer`.
- `usine/juge/cache.py` : verdicts indexés par le contenu exact jugé (projet composé, tests cachés, étapes, version de Godot, numéro de répétition). `juger_tache(..., repetition=N)` l'utilise.
- `config.example.toml` : section `[portillon]`. `outils/construire_taches_modeles.py` importe désormais les gabarits D1/S2 partagés (texte identique, vérifié).
- Tests : `test_operateurs.py`, `test_generateurs.py`, `test_portillon.py`, `test_generateurs_godot.py` ; preuve versionnée `preuves/rapport_chaine_graine1.json`.

**Choix**

- **Gel** : min(50, ⌊0,5 × qualifiées⌋) par compétence. Avec un seul petit projet source, geler 50 tâches viderait l'entraînement ; la part de 0,5 en garde la moitié. Aucune compétence n'atteint encore 50 (`complet: false` dans le manifeste). Le manifeste n'est jamais réécrit ; `geler(..., completer=True)` ajoute sans retirer, à faire avant le premier entraînement.
- **Doublons** : on compare les réponses (zones que la référence change, avec 3 jetons de contexte), pas les consignes : les consignes D1/K3 sont des gabarits presque identiques. Conséquence voulue : 3 D1 sur des lignes `@onready` voisines du même fichier (même catégorie, ligne qui diffère de 1 ou 2) sont des doublons d'une D1 gelée.
- **Un mutant par ligne** pour K3/D1 : deux mutants d'une même ligne ont la même correction.
- **Score de mutation** sur au plus 8 mutants par tâche (tirage par graine et id). Critère « sans objet » si aucun mutant ne s'applique à la zone (D1 : la réponse est `reponse.json`).
- **F1** : `move_and_collide(velocity * dt)` à pas fixe, couches de collision à 0. `move_and_slide` hors d'une image physique prend le delta de rendu (dépend de l'horloge).
- Volume F1 porté à 80 tirages (`--f1 80`) : avec 40, la chaîne donnait 85 acceptées.

**Preuve de fin** (exécutée dans le cloud, Godot 4.7.2 Linux headless)

`python -m usine.portillon chaine --graine 1 --f1 80` (verdicts de la 1re passe à 40 tirages F1 relus dans le cache)

```
== 1. Production des candidates
masquage K2          30 tâches     0 écartés  (0 s)
masquage K1           8 tâches     0 écartés  (49 s)
aller-retour S1      10 tâches     0 écartés  (61 s)
aller-retour S2       9 tâches     0 écartés  (0 s)
inverse F1           80 tâches     0 écartés  (7 s)
mutation K3/D1       80 tâches    66 écartés  (46 s)
== 2. Portillon (217 candidates, 3 répétitions, seuil mutants 50%, 8 mutants max par tâche)
[...]
compétence  candidates qualifiées  gelées acceptées  rejets
D1                   8          8       4         1  doublon_gele 3
F1                  80         80      40        40  —
K1                   8          8       4         4  —
K2                  30         27      13        14  depart_pas_rouge 2, score_mutation_insuffisant 1
K3                  72         72      36        36  —
S1                  10         10       5         5  —
S2                   9          9       4         5  —
TOTAL              217        214     106       105

Rejets du portillon par raison : depart_pas_rouge 2, doublon_gele 3, score_mutation_insuffisant 1
Écartés à la génération : d1_journal_sans_erreur_localisee 15, k3_tests_non_executes 23, mutant_survivant 28
Acceptées : 105 sur 7 compétences (D1, F1, K1, K2, K3, S1, S2)
Doublons avec les jeux gelés dans taches/ : 0
Verdicts relus dans le cache : 1052
Durée : 2822 s
```

Résultat identique avec la même graine (seconde chaîne complète dans un autre dossier, même cache de verdicts) :

```
python -m usine.portillon chaine --graine 1 --f1 80 --sortie /tmp/claude-0/run2   → Durée : 203 s
python -m usine.portillon comparer donnees/portillon/rapport.json /tmp/claude-0/run2/portillon/rapport.json
acceptees                  identique
acceptees_empreintes       identique
gelees                     identique
rejets_par_raison          identique
competences                identique
ecartes_a_la_generation    identique
doublons_avec_geles        identique
Résultat identique
cmp donnees/geles/manifeste.json /tmp/claude-0/run2/geles/manifeste.json   → manifestes identiques
```

Ce que prouve la seconde passe : génération (217 empreintes), tirage du gel et exclusion sont déterministes. Les verdicts, eux, viennent du cache ; leur stabilité est prouvée par la règle 3/3 de la première passe.

Score de mutation : 199 tâches avec mutants applicables, score moyen 0,86, 94 à 100 %. Rejets détaillés : `k2_…_ghost__physics_process` et `k2_…_hero__physics_process` (aucun test n'appelle `_physics_process` : départ vert), `k2_…_health_component_reset` (0/1 mutant tué).

Invention, exclusion en action : l'exemple fictif est refusé une fois le gel fait, car il corrige la même ligne qu'une K3 gelée :

```
python -m usine.generateurs invention tests/donnees/invention_exemple.json
"doublon_fragments : la proposition double la tâche gelée k3_reference_game_state_l12_operateur_arithmetique"
```

`python -m pytest -q`

```
208 passed in 200.49s (0:03:20)
```

**Volumes atteignables par compétence** (projet `godot/reference` seul)

| Compétence | Qualifiées | Limite | Pour monter |
| --- | --- | --- | --- |
| K3 | 72 | une par ligne mutable tuée par les tests | plus de projets testés |
| F1 | 80 (illimité) | grille de 4 paramètres du héros | autres mesures (fantôme, projets 3D) |
| K2 | 27 | une par méthode testée | plus de projets |
| S1 | 10 | une par scène | scènes des nouveaux projets |
| S2 | 9 | une par connexion | idem |
| K1 | 8 | un par script | idem |
| D1 | 8 (5 après doublons) | erreurs localisées sur la ligne mutée | opérateurs qui produisent des erreurs moteur |
| C1, C2, S3, K4, D2, F2 | 0 | pas de générateur dans cette session | sessions suivantes ; C2 a déjà son critère (`mutants.py`) |

Pour atteindre 50 tâches gelées par compétence, il faut d'autres projets sources propres et testés (laurent prévoit un ou deux jeux, dont de la 3D) : les générateurs prennent n'importe quel projet testé en paramètre `source`.

**Reste à faire**

- Exécuter `VERIFIER_EN_LOCAL.md` étapes 6, 10 et 11 sur la machine Windows.
- Session 4 : appliquer `Exclusion.texte_exclu` à l'index RAG ; exposer `describe_project`, `apply_edits`, `scene_write`, `valider_spec` en MCP.
- Session 5 : `Exclusion.session_exclue` sur l'export SFT ; `difficulte.filtrer` sur les essais de Qwen.

### Session 4 — 2026-10-04 (branche `claude/session-04-0nbove`)

**Fait**

- `usine/rag/` :
  - `rst.py` : lecture du rst de godot-docs (branche 4.7, révision `9adca4c`), sans dépendance. Référence des classes : une vue d'ensemble (héritage, résumé, Description), puis un fragment par membre (méthode, propriété, signal, énumération, constante…). Les tableaux récapitulatifs sont sautés (`vocab_lookup` les donne). Guides (`getting_started/`, `tutorials/`) : un fragment par section. Le C# est retiré des onglets de code.
  - `exemples.py` (demande de laurent, 2026-10-04) : le code des démos officielles `godot-demo-projects` au tag `4.7-6ad6167` (MIT) sert d'exemples vérifiés. 130 projets retenus : tous ceux du tag sauf `mono/` (C#) et l'annexe de laurent (`misc/os_test`, `mobile/android_iap`). Chaque projet est copié, importé, puis chaque script est compilé par Godot 4.7.2 (`gd/verifier_scripts.gd`). Seuls les scripts qui compilent entrent dans l'index. Le rapport `donnees/rag/verification_demos.json` garde l'empreinte SHA-256 de chaque script : il n'est refait que si un script change, et un script modifié depuis sa vérification est écarté.
  - `index.py` : SQLite FTS5 (`porter unicode61`). Recherche exacte d'abord : `Classe`, `Classe.membre` (héritage compris), `membre` seul, et dans une phrase les mots qui sont des classes (casse exacte) ; puis BM25 avec le titre pondéré ×8. Avec `source="tout"`, la moitié des places revient d'abord aux exemples vérifiés ; `source="doc"` ou `"exemples"` filtre. Chaque fragment passe par `Exclusion.texte_exclu` à la construction ; `verifier` relit tout l'index.
  - `vecteurs.py` : sqlite-vec en option (`[rag].vecteurs = false`), plongements par `/v1/embeddings` du llama-server local. Hors `requirements.txt`.
  - CLI `python -m usine.rag construire|chercher|verifier|vecteurs`.
- `usine/portillon/exclusion.py` : `Exclusion.depuis_taches(dossier)`, un contrôle sur toutes les tâches d'un dossier (sur-ensemble du gel).
- `mcp_serveur/` : serveur MCP `usine-godot` (SDK officiel `mcp`, FastMCP, stdio), 9 outils, 2 880 caractères de déclaration. Écritures (`scene_write`, `apply_edits`) : copie jugée, puis remplacement atomique. Juges (`check_script`, `load_scene`, `run_tests`) : sur une copie jetable. Les chemins sont limités au projet. Les outils tournent sur un seul fil dédié (connexions SQLite stables, boucle stdio libre). Preuve : `python -m mcp_serveur.preuve`.
- `skills/` : 13 fiches `usine-<id>-<nom>/SKILL.md` (en-tête `name`, `description`), avec quand s'en servir, entrée, sortie et juge.
- `outils/opencode_fusion.py` : ajoute `mcp.usine-godot` et `skills.paths` au `opencode.json` du projet. Avec `--proxy`, ajoute aussi la surcharge `provider.<id>.options.baseURL` vers le proxy (fournisseur détecté dans la config globale, lue seulement). Sauvegarde avant écriture, JSONC refusé, `--retirer`.
- `usine/capture/` : proxy (bibliothèque standard seule), enregistreur (sessions JSONL au format de `CLAUDE.md` + journal brut par jour), faux serveur, preuve, `lister` (outils de l'usine appelés, directement ou par le Code Mode).
- `requirements.txt` : `mcp`. `config.example.toml` : `[chemins].demos_godot`, section `[rag]`. `CLAUDE.md` : ligne `rag/` de l'arborescence.
- `VERIFIER_EN_LOCAL.md` : étapes 12 à 16 (environ 15 minutes ; seule l'étape 13 b est longue, et facultative).
- Tests : `test_rag.py`, `test_capture.py`, `test_opencode_fusion.py`, `test_mcp_serveur.py`.

**Choix**

- Exemples vérifiés = démos officielles 4.7 : décision de laurent, plutôt qu'un tri des extraits de la doc. « Vérifié » veut dire « compile sous Godot 4.7.2 » (chargé et instanciable), pas « exécuté ». La doc reste indexée pour l'API ; ses extraits de code ne sont pas vérifiés.
- La déclaration « 4.7 » d'une démo ne suffit pas : `2d/tween/main.gd` ne compile pas sous 4.7.2 (Parse Error ligne 77, lambda sur plusieurs lignes) ; `misc/2.5d/addons/node25d/.broken-gdscripts/Basis25D.gd` est cassé exprès. Ce sont les 2 scripts écartés.
- Vérification sur une copie : l'import de Godot réécrit des fichiers de la démo (`3d/material_testers/models/godot_ball.res` à la première passe).
- `[rag].demos_exclues` retire un projet entier : une démo qui deviendrait source de tâches gelées doit sortir du RAG (règle 4).
- Capture : une session est la conversation qui partage le plus long début avec la requête (messages hors `system`), à condition que la requête ait plus de messages qu'elle. Le prompt système peut changer d'un tour à l'autre sans couper la session ; la même demande dans une nouvelle conversation ouvre une autre session ; une requête annexe (titre) ne capte pas la conversation. `tache_id`, `competence`, `verdict_final` restent `null` à la capture.
- Proxy : contenu relayé tel quel, dans les deux sens ; seuls les en-têtes saut à saut (`Connection`, `Transfer-Encoding`, `Host`, `Expect`…) sont recalculés. Le flux SSE est réécrit morceau par morceau.
- `valider_spec` n'est pas un outil à part : `scene_write` valide la spec avant d'écrire et renvoie les erreurs au format du verdict.
- MCP : le serveur reçoit `--projet` (écrit par la fusion), sinon le dossier courant. `timeout` 120 000 ms, comme l'entrée `godot-ai`.
- Contrôle d'exclusion dans le cloud : la chaîne de la session 3, relancée en fond, avançait trop lentement à côté de la vérification des démos (20 candidates sur 217 en 25 min). Je l'ai arrêtée. Le contrôle porte sur les 217 tâches candidates (`donnees/candidats`), dont le gel est tiré : c'est plus large que le gel.

**Preuve de fin** (exécutée dans le cloud, Godot 4.7.2 Linux headless)

`python -m usine.rag construire --docs <godot-docs 4.7> --demos <godot-demo-projects 4.7-6ad6167>` (fin ; la vérification affiche une ligne par projet)

```
2d/tween                                      0/1 scripts compilent  (6.5 s)
misc/2.5d                                     13/14 scripts compilent  (5.0 s)
[… 128 autres projets, tous n/n …]
index : /home/claude/constructeur-qwen-gamedev/donnees/rag/godot_docs.sqlite
pages : 1510   fragments : 27681   durée : 3.1 s
démos : 130 projets, 446 scripts qui compilent indexés, 2 écartés ; projets retirés : aucun
gel : aucun manifeste (rien à exclure)
fragments exclus (solution gelée) : 0
code=0
```

`python -m usine.rag chercher CharacterBody2D -n 5`

```
1. [exact] CharacterBody2D  (classes/class_characterbody2d.rst)
2. [texte] networking/multiplayer_bomber › rock.gd  (demos/networking/multiplayer_bomber/rock.gd)
3. [texte] 2d/navigation › character.gd  (demos/2d/navigation/character.gd)
4. [texte] Using CharacterBody2D/3D › Examples  (tutorials/physics/using_character_body_2d.rst)
5. [texte] CharacterBody2D.get_position_delta  (classes/class_characterbody2d.rst)
code=0
```

`python -m usine.rag verifier --taches donnees/candidats --temoin godot/reference` (aucune reprise des 217 tâches candidates ; le témoin montre que le détecteur reconnaît bien les réponses dans le projet source)

```
index : /home/claude/constructeur-qwen-gamedev/donnees/rag/godot_docs.sqlite (27681 fragments, révision godot-docs 9adca4c1c72917bfe1b7be3108abed5ce26696a6)
tâches contrôlées : 217 (toutes celles de donnees/candidats)
fragments qui reprennent une tâche : 0
témoin positif : 28/93 fragments des scripts de godot/reference reconnus comme réponses
code=0
```

`python -m usine.capture preuve`

```
GET /v1/models                     relayé
POST chat/completions #1 (SSE)     requête =  réponse 2561 octets = script  type =  1er morceau à 0.00 s / 0.61 s
POST chat/completions #2 (JSON)    requête =  réponse 382 octets = script  type =
POST chat/completions #3 (SSE)     requête =  réponse 1051 octets = script  type =  1er morceau à 0.00 s / 0.36 s
sessions enregistrées : 1
session : 3 échanges, 7 messages, en-tête tache_id/competence/verdict_final : oui
appels d'outils : usine-godot_scene_write → usine-godot_run_tests
arguments de scene_write recomposés depuis le flux : identiques
dernier message : {"role": "assistant", "content": "Le piège est ajouté ; les 37 tests passent. ✓"}
CONFORME
code=0
```

`python -m mcp_serveur.preuve`

```
list_tools        OK   9 outils, 2880 caractères déclarés
vocab_lookup      OK     0.0 s  signal [Area2D] body_entered(body: Node2D)
search_docs       OK     0.0 s  1er : CharacterBody2D  (classes/class_characterbody2d.rst)
scene_read        OK     0.0 s  racine Coin (Area2D)
scene_write       OK     5.1 s  écrite, load_scene ok
describe_project  OK     0.0 s  144 lignes, piece2 présente
apply_edits       OK    14.1 s  appliqué, tests 37/37
check_script      OK     5.0 s  ok
load_scene        OK     4.8 s  ok
run_tests         OK     6.6 s  37/37 tests verts
apply_edits       OK     0.0 s  refusé à la validation, projet intact
check_script      OK     0.0 s  chemin hors du projet refusé
12/12 contrôles conformes
code=0
```

`python -m pytest -q`

```
237 passed in 164.61s (0:02:44)
code=0
```

**Reste à faire**

- ~~Exécuter `VERIFIER_EN_LOCAL.md` étapes 12 à 16 sur la machine Windows.~~ Fait le 2026-10-04, conforme (voir « Vérifications locales en attente »). Seule l'étape 13 b, facultative, n'a pas été lancée.
- Avant la session 5, une fois le gel complété avec les jeux de laurent : retirer du RAG toute démo devenue source (`[rag].demos_exclues`), reconstruire l'index, puis `python -m usine.rag verifier` (il échoue si le manifeste du gel a changé depuis la construction).
- Session 5 : renseigner `tache_id`/`competence`/`verdict_final` des sessions capturées, `Exclusion.session_exclue` sur l'export SFT.
- Non fait : contrôle des extraits de code de la doc contre `extension_api.json` (laurent a préféré les démos).

**Pièges**

- Les arguments d'un appel d'outil arrivent en JSON échappé (`tools[\"usine-godot\"].run_tests`) : la détection du Code Mode le gère.
- La vérification des démos et la chaîne du portillon se disputent les 4 cœurs : ne pas les lancer ensemble.

### Avant la session 5 — jeux sources supplémentaires — 2026-10-04 (branche `claude/project-thread-4m421r`)

Décision de laurent (fil « Jeux open source Godot 4.7 ») : brancher 01-survivor et les deux starter kits 3D de Kenney comme projets sources, puis refaire le gel avant tout entraînement.

**Fait**

- Trois projets sources dans `godot/`, chacun avec un `SOURCE.md` (origine, commit, licence, retouches) :
  - `godot/survivor/` : 01-survivor de Brock-Chain (commit `f68cb14`, MIT pour code, art et musique), bullet heaven 2D. Ses 14 suites GUT sont portées vers GdUnit4 (128 tests), par `outils/porter_gut.py` sauf `test_health.gd` (à la main).
  - `godot/kenney_platformer/` et `godot/kenney_racing/` : Starter Kit 3D Platformer et Starter Kit Racing de Kenney (code MIT, assets CC0). Ils n'avaient aucun test : 29 et 22 tests GdUnit4 écrits ici.
  - Retouches minimales, marquées `# usine :` : gardes `if stats == null` / `if view:` / `if target:` pour que chaque scène se charge seule ; BOM retiré de 5 scripts de survivor.
- `outils/porter_gut.py` : traduction déterministe GUT → GdUnit4, assertion par assertion. Il refuse ce qu'il ne sait pas traduire (`watch_signals`, `double`…), avec la ligne.
- `usine/socle.py` : les fichiers non textuels d'une source (sons, images, `.glb`, `.import`) ne sont plus copiés dans chaque tâche. Le `depart/` porte un fichier `.usine_socle` qui nomme le socle (`<source>-<12 car. d'empreinte>`, dans `donnees/socles/`, reconstruit depuis `godot/` au besoin). `preparer_copie` le pose sous la copie de travail sans rien écraser ; un socle modifié est refusé. `godot/reference` n'a pas de socle : ses tâches gardent leur forme.
- Juge :
  - `verifier_lot.gd` : un seul lancement de Godot vérifie tous les scripts, puis toutes les scènes. Le lot n'est qu'un raccourci ; en cas d'erreur, `check_script`/`load_scene` refont le détail élément par élément.
  - Classes globales chargées de la base vers les dérivées avant toute vérification (`charger_script.gd`, `charger_scene.gd`) : un script dérivé chargé seul produisait de fausses erreurs de dépendance cyclique.
  - Seconde compilation avec autoloads : déclenchée quel que soit le code de sortie (`--check-only` sort en 0 malgré une erreur), et aussi pour un autoload utilisé à travers un autre script (« Failed to compile depended scripts », « Could not resolve class »).
  - Bruit : les fuites signalées à la sortie (« leaked / in use / exist at exit » : Ogg, RID…) ne sont plus des erreurs.
  - Scènes importées (`.glb`, `.gltf`, `.fbx`…) : racine `Node3D` pour la vue du projet et la spec.
- Usine multi-source :
  - `usine/generateurs/sources.py` : registre `SOURCES` (reference, survivor, kenney_platformer, kenney_racing), plafonds par générateur et par source, ciblage, F1 sur reference seulement.
  - Ciblage : K1, K2 et les mutations ne visent que les fichiers couverts par les tests de la source (`fichiers_testes` : class_name, autoloads, chemins `res://`, scènes incluses). Une méthode non testée ne donne pas de tâche jugeable.
  - Échantillonnage reproductible sous plafond (`echantillon`, clé = source + générateur + graine).
  - `produire`, `chaine`, les CLI des générateurs et du portillon prennent `--sources`. `chaine --completer-gel` complète un manifeste existant sans retirer une tâche déjà gelée.
- Chaîne : une tâche modèle (installée à la main, origine hors générateur) qui double une tâche gelée est retirée de `taches/` et nommée dans le rapport (`modeles_retires`). C'était l'écart de laurent sur la session 3 (`k2_001_take_damage`, `s2_001_mort_du_fantome`).
- Journaux D1 : le bilan de fuites que Godot écrit en quittant (« ObjectDB instances were leaked at exit », « resources still in use at exit ») est retiré du journal (`commun.sans_bilan_de_sortie`). Il variait d'un lancement à l'autre : le rejeu de la chaîne a donné une empreinte différente pour `d1_kenney_racing_vehicle_l10_chemin_noeud_casse`. Le gel a été refait après la correction.
- Rapport de la chaîne : nouvelle clé `gelees_empreintes` (id → empreinte de chaque tâche gelée), comparée par `comparer`. Avant, `comparer` ne voyait que les ids gelés, et l'écart ci-dessus lui avait échappé. `comparer` liste aussi les ids qui diffèrent.
- Relecture adversariale du code de la PR (5 relecteurs indépendants, chaque constat reproduit ou réfuté par un second) : 31 constats, 14 confirmés, tous corrigés, avec un test qui échouait avant le correctif :
  - lot : une erreur affichée hors d'un élément (le `_ready` ou le `_exit_tree` d'un autoload) passait inaperçue ; elle fait maintenant tout revoir un par un ;
  - second avis de `check_script` : il effaçait toutes les erreurs dès que le script était instanciable ; une erreur d'exécution située dans le script (initialiseur statique) reste maintenant une erreur ;
  - `load_scene` ne précharge plus que les classes globales que la scène atteint (dépendances, classes nommées dans ses scripts, leurs bases) : une classe cassée sans rapport ne fait plus échouer la scène ; l'UID d'une dépendance passe avant son chemin texte, comme dans Godot ;
  - cache des verdicts : la clé porte la version du juge (empreinte de `usine/juge`, du socle et de GdUnit4), pour qu'un juge modifié ne relise jamais les verdicts de l'ancien ;
  - **Windows** : `sorted()` sur des `Path` y ignore la casse ; l'ordre des fichiers, donc le nom des socles et l'empreinte des 61 tâches des nouvelles sources, aurait changé. Tous les tris de chemins se font par composants relatifs (ordre Linux inchangé : 0 empreinte modifiée sur les 171 tâches du gel d'alors) ;
  - exclusion (règle 4) : une correction par suppression (`>=` → `>`) ne laissait aucun fragment de réponse ; une copie renommée d'une tâche gelée passait l'exclusion. Le contexte autour du point supprimé compte maintenant ;
  - tests portés de survivor : `append_failure_message` au lieu d'`override_failure_message`, pour que le journal d'un test rouge garde « attendu / obtenu » (entrée K3) ;
  - S1 : un modèle importé (`.glb`) a le type `PackedScene` ; ids : deux fichiers homonymes (`power_up.gd` ×2 dans survivor) reçoivent des ids distincts, et `produire` refuse des ids en double ;
  - `VERIFIER_EN_LOCAL.md` : l'étape 11 (chaîne à une source) est remplacée par l'étape 17 b.
- `tests/test_sources.py` (21 tests) ; 4 tests moteur de plus dans `tests/test_juge_godot.py`. `preuves/rapport_chaine_multi_graine1.json`. `VERIFIER_EN_LOCAL.md` : étape 17.

**Choix**

- **Le gel de la session 3 (106 tâches) est remplacé** par un gel à 4 sources (172 tâches). Aucun entraînement n'a eu lieu, la règle 4 tient. Le tirage de `godot/reference` diffère de celui de la session 3, parce que le juge a changé.
- Plafonds par source : sans eux, survivor (76 scripts) aurait noyé les autres sources. Les plafonds de K1 suivent le nombre de scripts testés.
- Les démos du RAG ne sont pas des sources : rien à retirer de l'index (`[rag].demos_exclues` reste vide).
- F1 reste sur `godot/reference` : il lui faut une fonction de mesure par jeu (vitesse du héros en frames). Les jeux 3D n'en ont pas encore.
- S1 sur les kits Kenney reste limité : propriétés de stockage `_data`/`_surfaces`, exports `node_paths` et ressources typées personnalisées ne passent pas encore dans la spec (`spec_invalide` 8, écartées à la génération).

**Preuve de fin** (cloud, Godot 4.7.2 Linux headless, 4 cœurs)

`python -m usine.portillon chaine --graine 1 --f1 100 --travailleurs 4` (fin ; gel refait **sans cache** après la relecture, puisque la version du juge entre dans la clé du cache)

```
compétence  candidates qualifiées  gelées acceptées  rejets
D1                  12         12       6         2  doublon_gele 4
F1                 100        100      50        50  —
K1                  29         24      12        12  reference_pas_verte 4, score_mutation_insuffisant 1
K2                 102         74      37        37  depart_pas_rouge 14, score_mutation_insuffisant 14
K3                 136        134      50        83  doublon_gele 1, score_mutation_insuffisant 2
S1                  21         21      10        11  —
S2                  14         14       7         6  doublon_gele 1
TOTAL              414        379     172       201

Rejets du portillon par raison : depart_pas_rouge 14, doublon_gele 6, reference_pas_verte 4, score_mutation_insuffisant 17
Écartés à la génération : d1_journal_sans_erreur_localisee 28, fonction_sur_une_ligne 2, k3_tests_non_executes 40, mutant_survivant 157, script_sans_methode 1, spec_invalide 8
Acceptées : 201 sur 7 compétences (D1, F1, K1, K2, K3, S1, S2)
Doublons avec les jeux gelés dans taches/ : 0
Verdicts relus dans le cache : 792
Durée : 12679 s
```

Tâches gelées par source : reference 110 (D1 3, F1 50, K1 5, K2 13, K3 29, S1 6, S2 4), survivor 23 (K1 2, K2 12, K3 7, S1 2), kenney_platformer 26 (D1 1, K1 5, K2 9, K3 7, S1 2, S2 2), kenney_racing 13 (D1 2, K2 3, K3 7, S2 1).

Rejeu complet dans un autre dossier de sortie (production refaite, Godot relancé pour les journaux et les mesures ; verdicts du portillon relus dans le cache, clé = contenu jugé), puis comparaison :

`python -m usine.portillon chaine --graine 1 --f1 100 --travailleurs 4 --sortie <autre dossier>` (même tableau, `Verdicts relus dans le cache : 2406`, `Durée : 651 s`), puis `python -m usine.portillon comparer donnees/portillon/rapport.json <autre dossier>/portillon/rapport.json`, `cmp` des manifestes et `diff -r` des dossiers `geles/`

```
acceptees                  identique
acceptees_empreintes       identique
gelees                     identique
gelees_empreintes          identique
rejets_par_raison          identique
competences                identique
ecartes_a_la_generation    identique
doublons_avec_geles        identique
Résultat identique
code=0
manifestes identiques
gels identiques octet pour octet
```

`python -m pytest -q`

```
SKIPPED [1] tests/test_rag.py:223: could not import 'sqlite_vec': No module named 'sqlite_vec'
261 passed, 1 skipped in 259.24s (0:04:19)
```

**Reste à faire**

- Avant la session 5 (décision de laurent, 2026-10-04) : construire la compétence E « optimisation stricte » d'après sa spec et geler ses tâches, dans une étape à part. Mesures déjà faites sous Godot 4.7.2 headless : les draw calls valent toujours 0 (plan B de la spec : comptage dans la scène) ; `OBJECT_COUNT` ne voit pas une création + une libération par image, alors que le compteur d'allocations lu dans `get_instance_id() >> 24` d'un objet témoin donne 1 sans churn et 121 avec, à l'identique.

- Exécuter `VERIFIER_EN_LOCAL.md` étape 17 sur Windows (quelques minutes ; la chaîne complète y est facultative).
- Session 5 : tout espace d'essai passe par `preparer_copie` (sinon les sons et modèles du socle manquent) ; l'export SFT doit garder le marqueur `.usine_socle` tel quel.
- Plus tard : F1 sur les jeux 3D (fonction de mesure par jeu), S1 pour les propriétés de stockage des kits Kenney, C2/F2/D2/S3 toujours sans générateur.

**Pièges**

- `--check-only` sort en code 0 même quand le script ne compile pas : ne jamais se fier au code de sortie, seulement aux lignes d'erreur.
- Un script `class_name` dérivé chargé seul, avant sa base, donne des erreurs de dépendance cyclique qui n'existent pas en jeu : charger les classes globales de la base vers les dérivées.
- Les sons Ogg encore joués à la sortie et les RID non libérés écrivent « leaked at exit » : bruit, pas erreur.
- Un BOM UTF-8 en tête de script casse nos lecteurs : il est retiré à l'import d'une source.
- Les `.uid` sont ignorés par git : ils n'entrent ni dans les tâches ni dans le socle (sinon l'empreinte du socle change d'une machine à l'autre).
- Godot écrit un bilan de fuites à la sortie qui n'est pas reproductible (nombre d'objets encore vivants) : tout texte de Godot qui entre dans une tâche doit en être nettoyé.
- `comparer` sur les seuls ids gelés ne prouve pas le déterminisme : comparer aussi les empreintes, ou `diff -r` des dossiers `geles/`.
- `rsync` n'existe pas dans le conteneur : `tar` pour copier en excluant.

### Avant la session 5 — compétence E « optimisation stricte » — 2026-10-05 (branche `claude/competence-e-optimisation-opoyoo`)

Décision de laurent (2026-10-04) : construire la compétence E d'après sa spec, dans une étape à part. Puis, le 2026-10-05 : **ne rien geler**. Le gel (les 4 jeux sources et E) attend Godot 4.8 stable.

**Fait**

- `usine/efficience/` : le juge d'efficience, hors de `usine/juge`. Ce dossier n'a pas été touché, pour ne pas invalider le cache des verdicts : la version du juge commun entre dans sa clé, et les verdicts E ont leur propre clé (`mesure.version_efficience`), qui inclut cette version.
  - `gd/mesurer_efficience.gd` : mesure headless (`--fixed-fps 60`). Allocations : compteur de l'ObjectDB, lu dans les bits hauts de l'id d'un objet témoin à la fin de l'échauffement puis à la fin de la fenêtre. Lots de dessin : comptés dans l'arbre de la scène, médiane sur la fenêtre. Signature de ce qui serait affiché aux images de contrôle. Temps par image (`Time.get_ticks_usec`), médiane.
  - `rendu_intact.py` : contrôle statique du rendu (`project.godot` et nœuds de rendu des scènes).
  - `juge.py` : le juge commun d'abord (comportement : tests cachés verts), puis l'étape `mesure_efficience`. Seuils : 0 allocation après l'échauffement ; lots ≤ référence × 1,05 ; temps ≤ référence × 1,15 (médianes de 3 exécutions alternées, mesurées au moment de juger, seulement pour les tâches qui le déclarent) ; rendu identique à la référence. Nouvelles catégories d'erreur : `efficience_allocations`, `efficience_draw_calls`, `efficience_temps`, `rendu_degrade`.
- `usine/generateurs/efficience.py` : paires départ naïf / référence optimisée, 10 variantes en 3 familles.
  - allocations : `tir`, `eclats`, `vagues`, `objets` ;
  - lots : `textures`, `materiaux`, `atlas` ;
  - temps : `voisins`, `carte`, `chemins`.

  À la génération, chaque paire est vérifiée : même comportement (`etat()` identique octet pour octet aux images de contrôle) ; même rendu (signature et réglages) ; départ mesurablement pire sur le critère de sa famille (temps : au moins 3 × la référence). Les identifiants sont renommés d'une paire à l'autre pour éviter les doublons. `tache.json` porte `mesure_efficience` : les réglages et la vérité terrain déterministe (lots, allocations). Le temps n'y est jamais écrit : il dépend de la machine.
- Branchement :
  - `taches.juger_tache` et `mutants` (les mutants E sont jugés par le juge d'efficience) ;
  - `regles` : raisons `efficience_*` et `rendu_degrade`, qui servent aussi au tri des essais de la session 5 ;
  - options `--competences` et `--e` dans `produire` et `chaine` ;
  - outil MCP `measure_efficiency`, fiche `skills/usine-e-optimisation`, CLAUDE.md (14 compétences).
- Session précédente (37d90ba) : une paire vérifiée par variante ; une tâche E passée au portillon 3 fois sur 3, avec 8 mutants tués sur 8.
- Cette session : `tests/test_mcp_serveur.py` attend 13/13 contrôles (le 13e est `measure_efficiency`) ; même correction dans `VERIFIER_EN_LOCAL.md`, étape 14. Nouvelle étape 18.

**Choix**

- **Rien n'est gelé.** Le gel à 4 sources (172 tâches) de la section précédente reste le seul gel de référence. La chaîne E de la preuve écrit son gel dans `/tmp` : ce n'est qu'une démonstration.
- Les draw calls valent toujours 0 en headless : les lots sont comptés dans l'arbre (plan B de la spec). Un lot est une suite d'éléments consécutifs dans l'ordre de dessin qui partagent texture et matériau.
- Allocations : `OBJECT_COUNT` ne voit pas une création suivie d'une libération dans la même image. Le compteur de l'ObjectDB, lui, voit chaque création.
- Le temps est la seule mesure qui varie d'une exécution à l'autre. Il est toujours relatif à la référence, mesurée sur la même machine au moment de juger, et n'entre jamais dans une empreinte. Une référence jugée contre elle-même a un rapport de 1 par définition.
- Aucune référence n'utilise MultiMesh : son rendu n'est pas vérifiable en headless (voir Pièges).
- Les jeux E sont écrits par le générateur, pas pris dans les jeux sources : la paire naïf / optimisé y est construite et prouvée équivalente.

**Preuve de fin** (cloud, Godot 4.7.2 Linux headless, 4 cœurs)

`python -m pytest -q tests/test_efficience.py`

```
....................                                                     [100%]
20 passed in 404.04s (0:06:44)
```

`python -m pytest -q --deselect tests/test_efficience.py` (le reste de la suite, lancé à part pendant la chaîne ; avec les 20 tests ci-dessus : 281 passed, 1 skipped)

```
SKIPPED [1] tests/test_rag.py:223: could not import 'sqlite_vec': No module named 'sqlite_vec'
261 passed, 1 skipped, 20 deselected in 568.91s (0:09:28)
```

`python -m usine.portillon chaine --competences E --e 10 --sortie /tmp/e10`

```
== 1. Production des candidates
-- sans source (jeux écrits par le générateur)
efficience E         10 tâches     0 écartés  (213 s)
== 2. Portillon (10 candidates, 3 répétitions, seuil mutants 50%, 8 mutants max par tâche)
== 3. Gel
== 4. Exclusion des jeux gelés et écriture des tâches acceptées

compétence  candidates qualifiées  gelées acceptées  rejets
E                   10         10       5         5  —
TOTAL               10         10       5         5

Rejets du portillon par raison : aucun
Écartés à la génération : aucun
Acceptées : 5 sur 1 compétences (E)
Doublons avec les jeux gelés dans taches/ : 0
Verdicts relus dans le cache : 0
Durée : 1493 s
```

Rejeu : `python -m usine.portillon chaine --competences E --e 10 --sortie /tmp/e10b` (même tableau, `Verdicts relus dans le cache : 60`, `Durée : 177 s` ; production refaite, Godot relancé pour les mesures de génération). Puis `python -m usine.portillon comparer /tmp/e10/portillon/rapport.json /tmp/e10b/portillon/rapport.json`, `cmp` des manifestes et `diff -r` des dossiers `geles/`

```
acceptees                  identique
acceptees_empreintes       identique
gelees                     identique
gelees_empreintes          identique
rejets_par_raison          identique
competences                identique
ecartes_a_la_generation    identique
doublons_avec_geles        identique
Résultat identique
code=0
manifestes identiques
gels identiques octet pour octet
```

La première chaîne a tourné en même temps que pytest (4 cœurs partagés) : ses 1493 s sont un majorant.

`python -m mcp_serveur.preuve --index <index minimal>` : le conteneur n'a pas l'index complet de la documentation (sans lui, `search_docs` échoue : « index de documentation absent »). L'index minimal est celui de `test_preuve_mcp` (une classe, `tests/donnees/rag/class_characterbody2d.rst`). Sur la machine de laurent, l'index complet existe (étape 13).

```
list_tools        OK   10 outils, 3289 caractères déclarés
vocab_lookup      OK     0.1 s  signal [Area2D] body_entered(body: Node2D)
search_docs       OK     0.0 s  1er : CharacterBody2D  (classes/class_characterbody2d.rst)
scene_read        OK     0.0 s  racine Coin (Area2D)
scene_write       OK    13.2 s  écrite, load_scene ok
describe_project  OK     0.0 s  144 lignes, piece2 présente
apply_edits       OK    26.0 s  appliqué, tests 37/37
check_script      OK    10.6 s  ok
load_scene        OK    13.2 s  ok
run_tests         OK    18.6 s  37/37 tests verts
measure_efficiency OK    13.6 s  0 allocations, 3 lots
apply_edits       OK     0.0 s  refusé à la validation, projet intact
check_script      OK     0.0 s  chemin hors du projet refusé
13/13 contrôles conformes
code=0
```

**Reste à faire**

- Exécuter `VERIFIER_EN_LOCAL.md` étape 18 sous Windows (moins de 15 min).
- **Migration vers Godot 4.8 stable**, avant tout gel (décision de laurent) :
  - vocabulaire : régénérer `extension_api.json` et la base SQLite (`usine/vocab`) ;
  - juge et GdUnit4 : la version de GdUnit4 pour 4.8, les filtres de bruit, l'écriture des `.tscn` (`unique_id`, ordre des propriétés), puis les tests moteur ;
  - les 4 jeux sources (`godot/reference`, `survivor`, `kenney_platformer`, `kenney_racing`) : leurs tests doivent rester verts sous 4.8 ;
  - RAG : la documentation et les démos officielles 4.8 (`[rag]` dans `config.toml`) ;
  - gel complet : les 4 jeux sources et E, en une seule chaîne (3 h et plus), puis le rejeu et `comparer` ;
  - mesures E à refaire sous 4.8 : le compteur d'allocations lu dans l'id d'objet, les draw calls toujours à 0 en headless ? le MultiMesh toujours illisible ?
- Session 5 : les verdicts E refusés donnent leurs raisons (`efficience_*`, `rendu_degrade`) au tri des essais.

**Pièges**

- **MultiMesh illisible en headless** : le serveur de rendu factice ne garde pas les données d'instances (`get_instance_transform_2d` rend l'identité, `buffer` est vide). On ne peut pas prouver qu'un MultiMesh dessine la même chose que des sprites. Il entre dans la signature sous une forme opaque, donc un candidat qui remplace des sprites par un MultiMesh échoue à la comparaison de rendu. Aucune référence n'en utilise.
- **`quit()` dans `_initialize` ne rend pas la main** : on ne peut pas tout faire dans `_initialize` puis quitter. La simulation, la mesure et le `quit()` final se font dans `_process` (`mesurer_efficience.gd`, `SCRIPT_ETAT` du générateur).
- **`_ready` n'a lieu qu'à la première image dans un script `-s`** : un jeu ajouté à l'arbre pendant `_initialize` n'est pas encore prêt. La simulation et les mesures commencent dans le premier `_process`.
- **Les `PackedArray` se copient à l'affectation** : `var t := grille[c]; t.append(x)` modifie une copie. Il faut remplacer la case (`grille[c] = …`), sinon la référence optimisée n'a pas le même comportement que le départ. Ces tableaux ne sont pas des objets : rien n'est compté dans l'ObjectDB.
- `OBJECT_COUNT` ne voit pas une création suivie d'une libération dans la même image. Il faut compter avec l'id d'un objet témoin.

### Session 6 — Mesure — 2026-10-05 (branche `claude/competence-e-optimisation-xbhw0j`)

Faite après la compétence E (PR #6 fusionnée), puis complétée après la session 5 (même branche) : les compétences agentiques sont mesurées par l'agent maison. La mesure réelle attend le premier LoRA et le gel sous Godot 4.8.

**Fait**

- `usine/mesure/` :
  - `stats.py` : score au premier essai, intervalle de Wilson à 95 %, règle de victoire, non-régression ;
  - `client.py` : client de chat sans dépendance (urllib). Pour llama-server, il envoie `response_format` (schéma JSON) et le champ `lora` par requête ; il parle aussi le protocole Messages, pour la frontière ;
  - `reponses.py` : compétences en un appel (D1, F1, K1, S1, S2) : schéma de la réponse, contexte montré au modèle, et traducteur déterministe réponse → copie de `depart/`, que juge ensuite le juge de la tâche. Les traducteurs :
    - D1 : `reponse.json` ;
    - F1 : les `@export` de `hero.gd` ;
    - K1 : le script à son chemin ;
    - S1 : `valider_spec` puis `scene_write` ;
    - S2 : `preparer_edits` (le moteur d'`apply_edits`) ;
  - `executer.py` : les 4 configurations sur les jeux gelés (empreintes vérifiées contre le manifeste). Résultats en JSONL, une ligne par (tour, configuration, tâche), synchronisée sur disque, avec reprise après coupure. `juger-reponses` note des réponses collectées ailleurs (la frontière) ;
  - `rapport.py` : `rapport_mesure.md` et `.csv`, une ligne pour chacune des 14 compétences (les 4 scores, la frontière sans et avec RAG, le verdict et son motif), et le tableau de non-régression ;
  - `simulation.py` : résultats simulés pour la preuve ;
  - `frontiere.py` : la référence frontière, voir Choix ;
  - `gamedevbench.py` : l'adaptateur GameDevBench, voir Choix ;
  - CLI `python -m usine.mesure executer|juger-reponses|rapport|regression|simuler|gamedevbench`.
- `config.example.toml` : sections `[mesure]`, `[frontiere]` (désactivée) et `[gamedevbench]`.
- `tests/test_mesure.py` (25 tests, dont un de bout en bout avec Godot : deux tâches D1 modèles, un faux serveur OpenAI-compatible, le vrai juge GdUnit4).
- `preuves/mesure_simulee/` : le rapport simulé (md et csv), reproductible octet pour octet par `python -m usine.mesure simuler`.
- `VERIFIER_EN_LOCAL.md` : étape 20 (20 b : mesure réelle des 4 configurations sur F1, avec la durée d'un appel).

**Choix**

- **Règle de victoire** (`stats.verdict`), écrite noir sur blanc :
  - « au-delà de l'intervalle » : la borne basse de LoRA + RAG est **strictement** au-dessus de la borne haute de base + RAG. Des intervalles qui se touchent ou se chevauchent donnent une égalité ;
  - « atteint ou dépasse la frontière » : taux de LoRA + RAG ≥ taux de la frontière **avec RAG**, en fractions exactes ;
  - frontière absente : pas de victoire. Le résultat est une égalité de motif « frontière non mesurée », puisque les deux conditions sont exigées ensemble ;
  - défaite : LoRA + RAG sous base + RAG au-delà de l'intervalle. Tout le reste est une égalité, avec son motif.
- **Non-régression** : une compétence recule si sa nouvelle borne haute est sous l'ancienne borne basse. Une baisse dans l'intervalle est signalée sans bloquer. Une compétence absente du nouveau tour bloque aussi.
- **Même prompt, même schéma, même budget** pour les 4 configurations : un appel par tâche, température 0, graine fixe, `max_jetons` commun, jamais de relance. Les configurations `_rag` ajoutent les extraits de `search_docs` (requête = la consigne). La configuration de base envoie l'échelle 0 pour chaque adaptateur déclaré, car llama-server applique un LoRA chargé à son échelle par défaut.
- **Compétences agentiques** (K2, K3, E…) : une session de l'agent maison de la session 5 par tâche et par configuration. Le budget de pas est le même pour les quatre. Sans RAG, `search_docs` est retiré ; avec RAG, l'outil est présent et les extraits sont ajoutés à la tâche. La session est gardée dans `<résultats>.sessions/`, et `--sans-agentiques` les exclut.
- **Frontière** : `python -m usine.mesure.frontiere`. Elle ne tourne que si `[frontiere] active = true` **et** si `--appel-externe` est passé. Aucun module ne l'importe (vérifié par un test). Elle ne fait que **collecter** les réponses, sur le mini-PC en ligne ; elles sont jugées hors-ligne sur la machine, avec exactement le même prompt que Qwen.
- **GameDevBench** :
  - le dépôt est public (`waynchi/gamedevbench`, Apache 2.0) : 333 tâches, Godot 4.4.1 exact, un solveur OpenCode intégré, `final_results.json` et `results/leaderboard.csv` (meilleur pass@1 : 69,97 %) ;
  - le dépôt ne donne **aucune catégorie par tâche** : le sous-ensemble « logique de gameplay » demande une liste d'ids (`--ids`), et seul le score sur les 333 tâches est comparable au classement ;
  - l'adaptateur ne réécrit pas leur harness. Il vérifie le dépôt et Godot 4.4.1, décompresse les archives (sans bash), écrit la liste des tâches, lance leur runner et lit le score (Wilson et classement publié).

**Preuve de fin** (cloud, Godot 4.7.2 Linux headless)

`python -m usine.mesure simuler --dossier preuves/mesure_simulee` (résultats simulés : aucun modèle n'a tourné)

```
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
```

Non-régression entre ce tour et un second tour simulé où D1 recule (`python -m usine.mesure regression <t0> <t1>`)

```
Non-régression (LoRA + RAG) :

compétence                       ancien                      nouveau  statut
D1         80,0 % [67,0 ; 88,8] (40/50) 40,0 % [27,6 ; 53,8] (20/50)  recul  ← BLOQUANT
E          20,0 % [11,2 ; 33,0] (10/50) 20,0 % [11,2 ; 33,0] (10/50)  stable
F1         66,0 % [52,2 ; 77,6] (33/50) 66,0 % [52,2 ; 77,6] (33/50)  stable
K1         70,0 % [56,2 ; 80,9] (35/50) 70,0 % [56,2 ; 80,9] (35/50)  stable
K2         44,0 % [31,2 ; 57,7] (22/50) 44,0 % [31,2 ; 57,7] (22/50)  stable
K3         68,0 % [54,2 ; 79,2] (34/50) 68,0 % [54,2 ; 79,2] (34/50)  stable
S1         88,0 % [76,2 ; 94,4] (44/50) 88,0 % [76,2 ; 94,4] (44/50)  stable
S2         36,0 % [24,1 ; 49,9] (18/50) 36,0 % [24,1 ; 49,9] (18/50)  stable

RECUL : D1
code=1
```

Même tour contre lui-même : `Aucune compétence ne recule.`, code 0.

Cas limites de la règle de victoire (`tests/test_mesure.py`) :
- intervalles qui se touchent (borne basse = borne haute) ;
- intervalles qui se chevauchent ;
- frontière absente et frontière à n = 0 ;
- frontière atteinte à égalité de taux (40/50 contre 32/40) ;
- sous la frontière ;
- défaite ;
- baisse dans l'intervalle (pas une défaite) ;
- configuration non mesurée.

`python -m pytest -q`

```
SKIPPED [1] tests/test_rag.py:223: could not import 'sqlite_vec': No module named 'sqlite_vec'
306 passed, 1 skipped in 452.78s (0:07:32)
```

`python -m pytest -q tests/test_mesure.py` (après le dernier correctif du client)

```
25 passed in 23.18s
```

**Reste à faire**

- Mesure réelle : après le premier LoRA (session 5) et le gel sous Godot 4.8 stable (voir la section E).
- `VERIFIER_EN_LOCAL.md` étapes 20 a et 20 b. La durée d'un appel recale l'hypothèse de 15 s du document de conception.
- GameDevBench : obtenir la liste des tâches « Gameplay Logic » si laurent veut ce sous-ensemble. Le runner officiel n'a pas été essayé sous Windows.

**Pièges**

- **llama-server applique un LoRA chargé à son échelle par défaut** : une requête sans champ `lora` n'est pas « la base ». La configuration de base envoie l'échelle 0 explicitement.
- **Mode strict des schémas OpenAI** : il refuse un objet libre (la spec S1, les éditions S2). Le client n'envoie donc pas `strict`, ce que llama-server ignore de toute façon.
- **urllib met en forme les noms d'en-têtes** (`X-api-key`) : un faux serveur doit les comparer sans tenir compte de la casse.
- **Plusieurs tours dans un même fichier de résultats** : sans `--tour`, `rapport` refuse, sinon n serait gonflé.
- **Ligne JSONL tronquée par une coupure** : elle est ignorée à la lecture, et l'essai est refait à la reprise.

### Session 5 — Boucle RFT — 2026-10-05 (branche `claude/competence-e-optimisation-xbhw0j`, faite après la session 6)

**Fait**

- `usine/rft/` : un pipeline de production de données, pas un orchestrateur autour de Qwen à l'usage (règle 1).
  - `essais.py` : Qwen résout chaque tâche N fois, le juge note chaque essai, et la session est enregistrée au format commun : en-tête `{tache_id, competence, verdict_final, …}`, puis un message par ligne, dans `sessions/<tâche>/essai_<n>.jsonl`, écrit de façon atomique.
    - Compétences en un appel (D1, F1, K1, S1, S2) : appel direct à llama-server, sortie contrainte par le schéma JSON de la compétence, LoRA choisi par requête (`lora`). Les schémas et les traducteurs réponse → projet sont ceux de la mesure (`usine/mesure/reponses.py`).
    - Compétences agentiques : sur une copie de travail de `depart/`, socle posé. Les tests cachés ne sont copiés qu'au jugement.
  - `agent.py` : l'agent minimal maison, deuxième harnais et repli d'OpenCode. Il a les mêmes outils que le serveur MCP (définitions lues sur le serveur FastMCP, implémentation `mcp_serveur.outils`), plus `list_files`, `read_file` et `write_file`, limités au projet. La fiche de la compétence est dans le message système, et un budget de pas fixe s'applique.
  - `opencode.py` : OpenCode non interactif, `opencode run --format json --dir <copie> --model … "<consigne>"`, la forme du solveur OpenCode de GameDevBench. Le proxy de capture tourne en processus sur un port libre, devant llama-server ; un `opencode.json` de projet est fusionné dans la copie (serveur MCP, fiches, baseURL du proxy), puis retiré avant le jugement. **À confirmer par laurent** : VERIFIER 19 c.
  - `filtre.py` : la solution réussie la plus courte (production du modèle), à égalité le plus petit n° d'essai. Les tâches jamais réussies vont dans `a_refaire.txt`, l'entrée du tour suivant (`--depuis`). Le filtre de difficulté prévu depuis la session 3 (`usine/portillon/difficulte.py`) est maintenant branché : sur N = 8 essais, une tâche réussie plus de 6 fois est « acquise » (`acquises.txt`) et n'est pas exportée.
  - `export.py` :
    - `sft.jsonl` : messages au format chat OpenAI, outils en JSON ;
    - le format sharegpt de LLaMA-Factory (`human` / `gpt` / `function_call` / `observation`) avec `dataset_info.json` ;
    - `qwen38_qlora_r16.yaml` : QLoRA rang 16, 4 bits, `packing: false`, `neat_packing: false`, `train_on_prompt: false` ; seules des clés tirées des exemples de LLaMA-Factory ;
    - Unsloth : `config_unsloth.json` et `entrainer_unsloth.py` (`train_on_responses_only`, `packing=False`) ;
    - la perte ne porte que sur les messages assistant ;
    - règle 4 : une session d'une tâche gelée, ou dont le texte reprend les fragments d'une tâche gelée, est écartée ; `tour` refuse aussi d'essayer une tâche gelée.
  - `gguf.py` :
    - la commande `convert_lora_to_gguf.py --base … --outfile … --outtype f16 <adaptateur>` ;
    - le lanceur `.bat` llama-server : un `--lora` par adaptateur, ids en commentaire, `--reasoning off --reasoning-budget 0 --no-prefill-assistant` ;
    - `-ngl` refusé ; fins de ligne CRLF, `chcp 65001`.
  - `tour.py` : essais → filtre → export. `registre.csv` est réécrit de façon atomique après **chaque** tâche : une tâche finie n'est jamais refaite, une tâche coupée est refaite en entier.
  - `preuve.py` et CLI `python -m usine.rft tour|exporter|gguf|lanceur|preuve`.
- Mesure (session 6) complétée : les compétences agentiques sont maintenant mesurées par l'agent maison. Sans RAG, `search_docs` est retiré ; avec RAG, l'outil est présent et les extraits sont ajoutés à la tâche. Les sessions sont gardées à côté des résultats, et `--sans-agentiques` les exclut.
- `usine/mesure/client.py` : outils (`tools`) et message assistant complet (`tool_calls`).
- **Générateur corrigé (règle 5)** : la consigne D1 (`gabarits.CONSIGNE_D1`) affichait `{{"categorie": …}}`. Les accolades étaient doublées comme pour un `.format()` qui n'a jamais lieu, et Qwen voyait ce texte faux dans toutes les tâches D1. Le correctif est dans le gabarit, et les tâches modèles sont régénérées par `outils/construire_taches_modeles.py` : seules les deux `tache.json` D1 changent (consigne et empreinte), les huit autres sortent identiques octet pour octet. Toutes les empreintes D1 changent donc ; rien n'est gelé en ce moment.
- `config.example.toml` : `[rft]` ; `[opencode]` (cli, fournisseur, modèle, délai) ; `[mesure] max_pas`.
- `tests/test_rft.py` (14 tests). L'un fait passer le harnais OpenCode par un faux CLI qui traverse le **vrai** proxy de capture ; un autre rejoue la preuve avec Godot. `tests/test_mesure.py` : un test de plus pour la mesure agentique.
- `preuves/rft_mini_tour/` : registre, retenus, `a_refaire.txt`, bilan et données exportées du mini-tour.
- `VERIFIER_EN_LOCAL.md` : étape 19 (19 b : vrai mini-tour sur 20 tâches en un appel, avec le temps par essai). La mesure devient l'étape 20.

**Choix**

- **N essais différents** : en un appel, température 0,7 et graine + n° d'essai (`[rft]`). À température 0, les N réponses seraient identiques. La mesure, elle, reste à température 0 et à un seul essai.
- **N = 8 essais, tâche gardée de 1 à 6 réussites** : ce sont les valeurs par défaut du filtre de difficulté écrit à la session 3. La preuve cloud travaille à 3 essais, sans plafond, pour rester courte.
- **Harnais agentique par défaut : l'agent maison.** Il tourne sans OpenCode et dans le cloud, avec les mêmes outils et les mêmes fiches. Le harnais OpenCode est prêt, mais attend la réponse de laurent (19 c).
- **« Plus courte »** = la production du modèle, pas la conversation entière : les résultats d'outils ne comptent pas, car ils ne sont pas appris.
- **Sharegpt** : un message assistant qui porte un texte et des appels d'outils perd son texte : le tour `function_call` de LLaMA-Factory ne porte que les appels. Plusieurs résultats d'outils successifs forment un seul tour `observation`. Le format `sft.jsonl` (Unsloth) garde tout.
- **Gabarit LLaMA-Factory** : `template: qwen3`, à vérifier sur la machine (le nom du gabarit de Qwen3.8 dépend de la version). Les noms d'arguments d'Unsloth et de TRL sont aussi à vérifier : ils n'ont pas pu être exécutés ici.

**Preuve de fin** (cloud, Godot 4.7.2 Linux headless)

`python -m usine.rft preuve`. Le mini-tour porte sur les 2 tâches D1 modèles et 3 tâches F1 tirées par le générateur inverse, 3 essais chacune. Le faux serveur OpenAI-compatible est juste quand sha256(« tâche:graine ») mod 100 < 60. Le vrai juge GdUnit4 note chaque essai. Une coupure est simulée après 7 appels, puis le tour reprend.

```
d1_001_identifiant_inconnu                         essai 0  NON run_tests       5.1 s
d1_001_identifiant_inconnu                         essai 1  OK  run_tests       5.3 s
d1_001_identifiant_inconnu                         essai 2  OK  run_tests       5.3 s
d1_002_cible_nulle                                 essai 0  OK  run_tests       5.4 s
d1_002_cible_nulle                                 essai 1  OK  run_tests       5.2 s
d1_002_cible_nulle                                 essai 2  OK  run_tests       5.3 s
f1_reference_hero_speed120p0_dash_speed860p0_dash_duration0p06_dash_cooldown1p25 essai 0  OK  run_tests       8.1 s
-- coupure simulée après 7 appels
f1_reference_hero_speed120p0_dash_speed860p0_dash_duration0p06_dash_cooldown1p25 essai 0  OK  run_tests       8.4 s
f1_reference_hero_speed120p0_dash_speed860p0_dash_duration0p06_dash_cooldown1p25 essai 1  OK  run_tests       8.3 s
f1_reference_hero_speed120p0_dash_speed860p0_dash_duration0p06_dash_cooldown1p25 essai 2  OK  run_tests       8.1 s
f1_reference_hero_speed220p0_dash_speed620p0_dash_duration0p3_dash_cooldown0p85 essai 0  NON run_tests       8.3 s
f1_reference_hero_speed220p0_dash_speed620p0_dash_duration0p3_dash_cooldown0p85 essai 1  NON run_tests       7.9 s
f1_reference_hero_speed220p0_dash_speed620p0_dash_duration0p3_dash_cooldown0p85 essai 2  NON run_tests       7.8 s
f1_reference_hero_speed250p0_dash_speed540p0_dash_duration0p21_dash_cooldown1p1 essai 0  NON run_tests       7.7 s
f1_reference_hero_speed250p0_dash_speed540p0_dash_duration0p21_dash_cooldown1p1 essai 1  NON run_tests       7.7 s
f1_reference_hero_speed250p0_dash_speed540p0_dash_duration0p21_dash_cooldown1p1 essai 2  NON run_tests       7.4 s
5 tâches × 3 essais ; coupure après 2 tâches finies ; 9 appels à la reprise
Retenues : 3 (attendu : 3) ; à refaire : ['f1_reference_hero_speed220p0_dash_speed620p0_dash_duration0p3_dash_cooldown0p85', 'f1_reference_hero_speed250p0_dash_speed540p0_dash_duration0p21_dash_cooldown1p1']
Export : {'exportees': 3, 'par_competence': {'D1': 2, 'F1': 1}, 'ecartees': {}}
OK    solutions gardées = tâches avec au moins un essai juste
OK    chaque essai noté juste par le juge l'est par le serveur
OK    registre complet, sans doublon
OK    reprise : seuls les essais manquants sont refaits
OK    export : JSONL et configurations valides
OK    export : une session par solution gardée
OK    tâches jamais réussies → a_refaire.txt
CONFORME
```

`python -m pytest -q`

```
SKIPPED [1] tests/test_rag.py:223: could not import 'sqlite_vec': No module named 'sqlite_vec'
321 passed, 1 skipped in 519.49s (0:08:39)
```

**Reste à faire**

- Fait le 2026-10-06 : 19 a et 19 b conformes ; 19 c, pas de CLI OpenCode, le harnais reste l'agent maison.
- Le premier vrai tour, puis l'entraînement (19 d), après le gel complet sous Godot 4.8 : les tâches d'entraînement doivent être tirées **après** le gel, pour que l'exclusion de la règle 4 porte sur le gel définitif.
- Ensuite, la mesure (étape 20) et `regression` après chaque tour.

**Pièges**

- **À température 0, N essais = N fois la même réponse** : il faut faire varier la graine *et* une température > 0.
- **Un message assistant qui porte un texte et des appels d'outils** n'a pas d'équivalent dans le tour `function_call` de LLaMA-Factory.
- **Le harnais OpenCode écrit un `opencode.json` dans la copie de travail** : il faut le retirer avant le jugement, sinon il entrerait dans la solution.
- **Un CLI externe ne laisse pas choisir la graine** : en mode OpenCode, les N essais ne diffèrent que par l'aléa du serveur.

### Décision du 2026-10-06 — on reste sous Godot 4.7.2

laurent : « pour le moment on va utiliser Godot 4.7, on fera l'adaptation plus tard ». Cette décision remplace celle du 2026-10-05, qui faisait attendre le gel à Godot 4.8 stable (encore en snapshot dev 4, sortie prévue au quatrième trimestre 2026).

- **Le gel se fait maintenant, sous 4.7.2, E compris** : `VERIFIER_EN_LOCAL.md` étape 21, une nuit sur la machine. Par défaut, la chaîne produit 120 candidates E, dont 50 gelées au plus.
- **Couverture du gel** : seules F1 et K3 atteignent 50 tâches gelées (dernier gel cloud : D1 6, K1 12, K2 37, S1 10, S2 7). C1, C2, S3, K4, D2 et F2 n'ont pas encore de générateur. Un gel se complète par `chaine --completer-gel`, sans rien retirer, mais **seulement avant le premier entraînement** (`usine/portillon/gel.py`, règle 4). Avant d'entraîner, il faut donc soit ajouter des sources et des générateurs puis compléter le gel, soit décider de figer le gel tel quel.
- **Migration vers 4.8, plus tard** : le gel 4.7.2 ne pourra pas être retiré après un entraînement (règle 4). La migration devra rejuger les tâches gelées sous 4.8 et réparer leurs générateurs au besoin (règle 5). Ce n'est pas un nouveau tirage.

### Hors dépôt, du 2026-10-06 au 2026-10-10 (d'après les conversations fournies par laurent le 2026-10-11)

Rien de ceci n'est sur GitHub : le travail a été fait dans `D:\constructeur-qwen-gamedev` sur la machine.

- Gel complet fait sous 4.7.2 (221 tâches gelées citées), tour t1 : 93 sessions retenues sur 575, toutes produites par l'agent maison (`"harnais": "agent"`).
- Premier LoRA : QLoRA rang 16, LLaMA-Factory sur RunPod (H200), 2 époques, 24 pas, 2 h 04, perte 0,078. 12 sessions sur 93 dépassent 16 384 jetons et sont tronquées (le filtre « plus courte » ne compte pas les résultats d'outils). Converti en `LORA_coding_godot-f16.gguf` (233 Mo), chargé par llama-server.
- Jugé « mauvais » dans OpenCode par laurent : il a appris `read_file`/`write_file`, absents d'OpenCode. Ajouts locaux : `outils/harnais_maison.py` (consigne libre, sans et avec LoRA), outil de capture d'écran, outils de campagne.
- Trois campagnes de 2 h sur starfox (2026-10-09, `G:\QWEN-GODOt`) : 0 erreur moteur ; 57 % des écritures identiques à la précédente (séries jusqu'à 28) ; `search_docs` appelé 4 fois ; ≈ 70 éditions refusées par campagne outillée ; 381 captures, aucune commentée ; structure laissée à plat.
- Mesure du cache de llama-server : bloc fixe de 13 507 jetons en tête, 7,6 s au premier envoi, 0,3 s ensuite.

Nouveau cap (`donnees\bequille_qwen.html` sur la machine, « La béquille de Qwen ») : ne pas rendre Qwen plus savant, lui donner la bonne information au bon moment (en permanence, avant l'action, après l'action), puis entraîner la démarche. Ordre décidé par laurent : 1. retour des outils ; 2. socle propre et plan d'organisation ; 3. déclaration d'action et graphe ; 4. mesure par campagnes ; 5. entraînement.

### Béquille, point 1 — retour des outils — 2026-10-11 (branche `claude/project-thread-12uh5s`)

**Fait**

- `usine/retour/` (déterministe, vocabulaire de `extension_api.json`) :
  - `ecriture.Ecritures` : une écriture identique au contenu actuel n'écrit rien et répond « aucun changement », avec le compte d'écritures identiques d'affilée ;
  - `verification.verifier_script` : types écrits inconnus ; accès `x.membre` quand le type de `x` est sûr (variable ou paramètre typé, `T.new()`, `as T`, classe nommée) ; arité des méthodes Godot ; signature officielle de chaque membre reconnu. Silence volontaire quand l'accès peut être dynamique (membre d'une classe dérivée, ou déclaré par un script du projet) ;
  - `fiches.fiches_pour_erreurs` : lit les messages de Godot (`not found in base self`, `GDScriptNativeClass`, `Nonexistent function`, `Invalid access`…) ou, à défaut, la ligne en cause ; renvoie signature, membres proches et extrait de doc (index du RAG s'il existe).
- Branchements : `write_file` de l'agent maison ; `check_script` du serveur MCP (champ `vocabulaire`, donc utilisable depuis OpenCode, dont l'outil d'écriture ne se modifie pas) ; `check_script`, `load_scene`, `run_tests` (champ `fiches`). Descriptions MCP mises à jour.
- `python -m usine.retour verifier <projet>` pour voir le retour sur un projet.
- Repris sur cette branche le commit 933949b (décision du gel sous 4.7.2, étape 21), resté hors de `main`.

**Pourquoi le vérificateur est utile** : `godot --check-only` laisse passer `m.set_surface_overide_material()` ou `p.left_to_rightx = 0.5` sur une variable typée (appel non sûr, résolu à l'exécution). Il ne voit que les appels nus et les classes nommées.

**Preuve**

Cloud, Godot 4.7.2 Linux headless. `python -m pytest -q tests/` : `330 passed, 1 skipped` (sqlite_vec absent). Puis, sur l'état final :

```
$ python -m pytest -q tests/test_retour.py tests/test_mcp_serveur.py tests/test_rft.py
24 passed in 230.21s (0:03:50)
# Faux positifs : tous les scripts des 14 projets Godot du dépôt (référence, survivor, Kenney, tâches modèles)
projets 14 fichiers 252 accès vérifiés 2776 problèmes 0
# Rappel : pour chaque membre Godot reconnu, une faute de frappe injectée (« membre » → « membrex »)
mutations 623 détectées 596
$ python -m usine.retour verifier godot/survivor
68 scripts, 0 problème(s)
```

**Reste à faire** : point 2 (socle propre). Le harnais maison local devra passer par `usine.rft.agent.Boite` pour bénéficier du retour.

**Pièges**

- Un membre absent d'une classe Godot n'est signalé que s'il n'existe dans aucune classe dérivée ni aucun script du projet : `var n: Node` puis `n.position` est un accès dynamique valide.
- Le vérificateur ne suit pas les types à travers les appels (`get_node()`, retours de fonctions) : il se tait plutôt que de deviner.

### Béquille, points 2 à 9 — socle, fiches, captures — 2026-10-11 (branche `claude/project-thread-12uh5s`)

**Fait**

- `godot/socle_jeu/` : jeu complet rangé selon le plan numéroté 0_autoload … 7_tests (titre, intro, niveau 1 jouable avec quatre drones posés à la main, fin), `ORGANISATION.md` (rôles, « qui connaît qui », conventions, 7 modèles d'ajout avec l'exemple à imiter), `AGENTS.md` (le bloc permanent et les règles avant/après donnés à laurent, avec `prepare_action` et `capture_frames` nommés). 22 tests GdUnit4.
- `usine/structure/` : juge de structure (rangement, noms, class_name, dépendances entre dossiers) → outil MCP `check_structure` ; tri des sessions (plan lu avant d'écrire, écritures hors plan, écritures répétées, captures sans verdict écrit).
- `usine/fiches/` : 10 besoins et 5 situations en JSON, cinq rubriques (à considérer, où travailler, API, exemples, pièges) plus les voisins ; outil MCP `prepare_action(but, type_action, fichiers, besoins, situations)`. Chaque nom d'API est vérifié dans `extension_api.json` par les tests ; chaque exemple est extrait d'un vrai fichier (projet d'abord, sinon socle).
- `0_autoload/capture.gd` + `usine/retour/capture.py` : grille d'images aux numéros demandés (`--fixed-fps 60`), légende par case avec les lignes du journal `Trace`, touches tenues (`--capture-press=move_up:10-70`) ; posé dans la copie si le projet ne l'a pas. Outil MCP `capture_frames`, commande `python -m usine.retour capturer`.
- `Trace` : temps de jeu (images physiques / cadence) au lieu du temps réel, et branchement des nœuds déjà présents au démarrage (la scène principale entre dans l'arbre avant son `_ready` : aucun état ni coup n'était noté en jeu réel).
- La première capture a montré un écran noir : caméra et vaisseau tournés à l'envers (`Transform3D(1,0,0, 0,0,-1, 0,1,0)` regarde vers le haut). Corrigé dans `level_base.tscn` et `player.tscn`.

**Preuve**

Cloud, Godot 4.7.2 Linux, Xvfb pour la capture.

```
$ python -m pytest -q tests/test_fiches.py tests/test_structure.py tests/test_retour.py -m "not godot"
29 passed
$ python -c "Outils(Path('godot/socle_jeu')).run_tests()"   # 7_tests du socle
{"ok":true,"etape":"run_tests","tests":{"total":22,"passes":22,"echecs":[]}}
$ python -m usine.structure verifier godot/socle_jeu
"ok": true
$ python -m mcp_serveur.preuve
prepare_action    OK     0.0 s  fiches etat et minuterie rendues
capture_frames    OK     8.2 s  grille capture_….png : 2 cases, 4 par li
15/16 contrôles conformes   # search_docs : pas d'index de doc par défaut dans le cloud ; le test pytest lui en donne un
$ capture du niveau 1, touches move_up:10-70 et fire:40-300
case 3 (ligne 1, colonne 3) : image 100, 1.67 s de jeu
    1.60 s Drone3 : détruit, score +100
case 5 (ligne 2, colonne 1) : image 180, 3.00 s de jeu
    2.40 s Player : touché -1, vie 4
```

Suite complète, `python -m pytest -q` : `356 passed, 1 skipped in 821.74s` (sqlite_vec absent). Le tri « captures sans verdict » a été ajouté pendant ce passage ; `tests/test_structure.py` refait après : `6 passed`.

**Reste à faire** : étape 23 sur la machine ; brancher `capture_ecran` de `campagne_harnais.py` (hors dépôt) sur `usine.retour.capture` ; pièges des fiches tirés des 1 025 essais ratés de t1 (`donnees/rft/t1`, sur la machine) : ceux d'aujourd'hui sont écrits à la main. Puis point 4 de l'ordre de laurent : la mesure par campagnes, avec et sans béquille.

**Pièges**

- En headless, `RenderingServer.frame_post_draw` n'arrive jamais : la capture n'attend que si un écran existe, et écrit alors la légende sans image.
- Dans le cloud, la capture passe par `xvfb-run` et `--rendering-method gl_compatibility` (llvmpipe).
- Les drones attendent tant que le joueur est hors de leur portée : une capture sans touche montre une scène immobile, c'est normal.

### Règles d'architecture de laurent — juge, socle propre, salissures, tri — 2026-10-11 (branche `claude/project-thread-12uh5s`)

Source : le document de laurent du 2026-10-11 (51 règles, section 9 « Utiliser ces règles pour entraîner le LoRA »). Choix par défaut, ceux du document : audio global = musique et volume, durées dans 5_data, `.tres` typés, Godot 4.7.2, ni multijoueur ni replays, GdUnit4. Pas de fusion dans main avant que la campagne V2 soit jugée.

**Fait**

- `usine/regles/` : juge des règles sans modèle (règle 2). `catalogue.py` : 31 règles avec leur nature (confirmée, corrigée, choix) ; 15 jugées mécaniquement (ORG-01, DOSSIERS, ARC-03, ARC-04, ARC-06, DAT-01, DAT-02, SIM-01, SIM-02, SIM-08, SIM-09, COD-01, COD-02, COD-04, QA-01), 3 sur la session (QA-03, QA-07, QA-08), les autres seulement rappelées. Chaque écart est au format commun, `categorie` « regle » ou « structure », message « ID : … ». `python -m usine.regles verifier <projet>`. Un projet sans plan numéroté n'est pas jugé (`applicable: false`).
- `usine/structure/regles.py` : le tableau des dépendances du document (2_sequence → tout sauf 7_tests, 4_ui → 0_autoload/1_core/6_assets, …), sans exception ; une entité ne dépend d'aucune autre entité ; identifiants de règle sur chaque écart.
- Le socle avait 25 écarts (ARC-04 ×3, ARC-06, COD-02 ×6, DAT-01 ×6, DOSSIERS ×6, SIM-01 ×2, SIM-08) ; il en a 0. Changements : plus d'`EventBus` (le niveau écoute la vie des acteurs et appelle `GameState`) ; `AudioManager` ne fait que la musique et le volume (ARC-09) ; `GameRules` (vies, durées d'intro, de fin et de fin de niveau) dans `5_data/game/` ; `ProcessOrder` (1_core) pour les priorités ; `player_input.gd` seul lit `Input`, `drone_view.gd` porte les effets ; chaque entité reçoit ses dépendances du niveau par `setup()` ; décomptes dans `_physics_process` ; `UNTYPED_DECLARATION` en erreur ; `7_tests` en miroir exact, 31 tests.
- `ORGANISATION.md` et `AGENTS.md` réécrits sur le document : le bloc permanent ne garde que les cinq principes et le tableau des dossiers (section 9) ; « après chaque action » ajoute `check_structure` et le compte rendu.
- `check_structure` (MCP) rend le juge des règles ; `prepare_action` rappelle les règles de chaque besoin coché (champ `regles` des 15 fiches, table de la section 9). Fiches et chaînes des 7 modèles mises au nouveau socle.
- `usine/generateurs/salissures.py` : tâches K4 « nettoyer » (section 9, usage 2). Neuf sortes de salissures sur le socle : syntaxe Godot 3, type retiré, valeur de 5_data en dur, `get_node("/root/…")`, `create_timer` sans `false`, priorité en nombre, `_physics_process` → `_process`, fonction en camelCase, script déplacé (hors plan ou dans 5_data). 124 candidates sur 10 règles, chacune validée : le projet sali viole la règle visée et elle seule. Tests cachés = `7_tests` du socle. Ajoutées à `python -m usine.generateurs produire` (compétence K4).
- `juger_tache` : tout verdict d'un projet organisé porte `regles` (violations, structure_ok, par_regle) ; `juge.regles_cibles` fait échouer à l'étape « regles » tant qu'il reste un écart ; `reference_retire` retire les fichiers déplacés en composant la référence.
- Tri : `verifier_session` relève QA-03 (fichier écrit non déclaré à `prepare_action`), QA-07 (tests annoncés verts sans `run_tests` réussi depuis la dernière écriture), QA-08 (compte rendu final absent ; compte, n'élimine pas). `essais.trier` additionne projet et session ; le registre gagne `violations`, `structure_ok`, `session_ok` ; `filtre.retenir` garde, par tâche, l'essai réussi, rangé et sain qui a le moins de violations, puis le plus court. Un registre ancien vaut 0 violation.
- Trouvé en route : les scripts GDScript du juge (`charger_scene.gd`, `charger_script.gd`, `verifier_lot.gd`, `etat_scene.gd`, `mesurer_efficience.gd`) ne compilaient pas dans un projet qui met `UNTYPED_DECLARATION` en erreur : typés. Et `charger_scene.gd` attendait jusqu'au délai quand la scène se libère à sa première image : il termine et le note (`liberee_avant_description`). La balle du socle reste immobile tant qu'elle n'est pas lancée.

**Preuve**

Cloud, Godot 4.7.2 Linux.

```
$ python -m usine.regles verifier godot/socle_jeu
0 violation(s) {}
$ python -c "Outils(Path('godot/socle_jeu')).run_tests()"
{"ok":true,"tests":{"total":31,"passes":31,"echecs":[]}}
$ python -m pytest -q tests/test_regles.py
29 passed
$ verifier_modeles sur une salissure par règle (10 tâches, 4 travailleurs, 5 min 12 s)
k4_nettoyer_arc_06_root_boot FAIL @regles 31/31        PASS 31/31  oui oui OUI
k4_nettoyer_cod_02_var_health_component FAIL @check_script 0/0  PASS 31/31  oui oui OUI
k4_nettoyer_sim_01_process_health_component FAIL @regles 31/31  PASS 31/31  oui oui OUI
…
10/10 tâches conformes
```

Suite complète, `python -m pytest -q` : `386 passed, 1 skipped in 1002.36s` (sqlite_vec absent).

**Reste à faire** : étape 24 sur la machine, après la campagne V2 ; geler les K4 « nettoyer » avec le reste (le portillon les juge comme les autres) ; ARC-03, ARC-04, SIM-09 et DAT-02 sont jugées mais n'ont pas encore de salissure (aucune injection naturelle qui garde le comportement) ; DPO sur les 1 025 essais ratés de t1, en option (section 9, usage 3).

**Pièges**

- Les tests cachés d'une tâche « nettoyer » ne voient pas une salissure qui garde le comportement (SIM-01 passe 31/31) : c'est le juge des règles qui la fait échouer, d'où `regles_cibles`.
- Une salissure ne touche jamais un commentaire : sinon la « violation » n'existe pas pour le juge et la tâche serait verte au départ.
- Un projet qui met `UNTYPED_DECLARATION` en erreur s'applique aussi aux scripts lancés avec `-s` ; tout nouveau script GDScript de l'usine doit être entièrement typé (y compris les variables de `for` sur un tableau non typé et les paramètres des lambdas).

### Règles qui priment et décors procéduraux — 2026-10-14 (branche `claude/regles-batiments-proceduraux`)

Source : demande de laurent du 2026-10-14, « modifie le dépôt pour que tes règles à toi avec celles du projet "poursuivre le projet de laurent" s'imposent au dépôt ». Son mode d'emploi n'est pas versé tel quel (dépôt public, détails personnels) : seules ses règles sont reprises.

**Fait**

- `CLAUDE.md` commence par « Règles qui priment », qui l'emportent sur le reste du fichier, le code et les documents : 1. travailler avec laurent ; 2. ses 13 décisions ; 3. pièges et interdits ; 4. points ouverts ; 5. vérification (8 règles de la passe « bâtiments procéduraux ») ; 6. rangement des décors procéduraux ; 7. données d'entraînement (7 règles). Chaque point dit s'il est décidé, proposé ou ouvert.
- Le reste de `CLAUDE.md` est mis d'accord : règle 4 « Jeux gelés : on n'en crée plus » (décision 1), les 221 tâches gelées restant exclues tant que laurent n'a pas décidé ; le harnais d'usage est un point ouvert ; la mesure ne se lance que si laurent la demande ; la grille compétence × sujet, moitié création, moitié débogage, en jetons de réponse.
- Juge des règles : table `DECORS` de `usine/structure/regles.py`. `6_assets/Mesh/Procedural/` peut contenir du code qui dépend de `1_core/` et `5_data/` ; `5_data/DECORS/` peut contenir des scripts de constantes, sans dépendance. Ailleurs, `5_data/` et `6_assets/` restent sans code. `verifier_fichiers` (fiches de `prepare_action`) et le texte de DOSSIERS (`usine/regles/catalogue.py`) suivent.
- Socle : une ligne dans `AGENTS.md`, une puce dans `ORGANISATION.md`.
- Tests : `test_decors_proceduraux` (un générateur qui charge `1_core/procedural/` et `5_data/DECORS/` passe ; un script dans `6_assets/materials/` et un décor qui charge `4_ui/` échouent) et `test_decor_procedural_dans_le_plan`.
- `VERIFIER_EN_LOCAL.md` : étape 25.

**Preuve**

Cloud, Godot 4.7.2 Linux, Python 3.13.16, pytest 9.1.1.

```
$ python -m pytest -q tests/test_structure.py tests/test_fiches.py tests/test_regles.py
56 passed in 1.91s
$ python -m usine.regles verifier godot/socle_jeu
0 violation(s) {}
$ juge des règles sur les 39 étapes du cours « bâtiments procéduraux » (cumulé)
Écarts dans les fichiers enseignés (39 étapes, cumulés) : {'COD-02': 142}
Écarts dans l'outillage du cours : {'ARC-04': 546, 'SIM-01': 39, 'DAT-01': 3465, 'COD-02': 227, 'ORG-01': 39}
```

Avant la table `DECORS`, les fichiers enseignés comptaient aussi 188 écarts DOSSIERS ; il n'en reste aucun. Les 142 COD-02 (tableaux et dictionnaires non typés) sont une règle du projet qui reste : c'est le cours qui se corrige.

Suite complète, `python -m pytest -q --ignore=tests/test_mcp_serveur.py` : `5 failed, 379 passed, 2 skipped in 585.45s`. Les 5 échecs (`test_mesure`, `test_retour`, 3 de `test_rft`) sont `ModuleNotFoundError: No module named 'mcp'` : le SDK MCP manque dans le cloud, le proxy refuse PyPI (403).

**Reste à faire** : laurent relit et corrige « Règles qui priment » ; le cours et le générateur de sa base dans le dépôt, avec ses collections typées (COD-02) et son outillage de visite rangé ou laissé hors des sources ; étape 25 sur la machine, hors campagne.

**Pièges**

- Le juge ne distingue pas un générateur `@tool` d'un script de jeu : sans la table `DECORS`, tout script de `5_data/` ou `6_assets/` est un écart DOSSIERS.
- `pkill -f` dans le cloud tue aussi le shell qui le lance : tuer par numéro de processus.

### Cours « bâtiments procéduraux » dans le dépôt — 2026-10-14 (branche `claude/regles-batiments-proceduraux`)

Source : demande de laurent du 2026-10-14 (« intègre ta solution […] dans le dépôt », avec les règles qui priment).

**Fait**

- `cours/batiments_proceduraux/` : les maîtres balisés des trois villes, les fichiers communs, les notes d'étape, les carnets de recherche de Tokyo et de New York, le manifeste.
- `usine/cours/` : `fabriquer.py` (un projet Godot par étape, dans `donnees/cours/batiments_proceduraux/projets/`), `verifier.py` (juge des règles, puis Godot : import, analyse de chaque script, tests de l'étape, une image en Compatibilité), et `python -m usine.cours fabriquer|juger|verifier`. Avant tout changement de contenu, `fabriquer.py` redonnait les 39 projets du cours à l'identique (808 fichiers, `diff -rq` vide).
- Le cours suit les règles du dépôt. Écarts du juge cumulés sur les 39 étapes, avant : fichiers enseignés COD-02 142 ; outillage de visite ARC-04 546, SIM-01 39, DAT-01 3 465, COD-02 227, ORG-01 39. Après : 0.
  - avertissements de GDScript à 2 dans le `project.godot` de chaque étape (règle 5.3) ;
  - la note de l'étape devient le `README.md` du projet (ORG-01) ;
  - tableaux et dictionnaires typés (COD-02) : empreinte des variables par l'`Array[Dictionary]` de l'API, `Dictionary[String, Variant]` pour les réglages d'un shader, lignes de palette converties à la lecture (`PackedStringArray(...)`, `PackedColorArray(...)`), cases de l'outil de maillage créées avec leur type complet, tableaux parallèles au lieu de paires ;
  - caméra libre : `free_camera_input.gd` lit clavier et souris et donne des intentions, la caméra avance dans `_physics_process` (ARC-04, SIM-01) ;
  - visite : tous ses chiffres dans `5_data/visit/visit_settings.tres` (classe `VisitSettings` dans `1_core/data/`, avec `id` et `validate()`), la mesure du rendu dans le bandeau de `4_ui` (DAT-01, DAT-02).
- Comportement inchangé : les 146 lignes de sortie des tests des 39 étapes (triangles, gabarits, niveaux de détail) sont identiques avant et après ; les images de Paris 013, New York 012 et Tokyo 005 sont identiques au pixel près.
- `tests/test_cours.py` (6 tests, dont un avec Godot) ; `CLAUDE.md` (arborescence) ; `VERIFIER_EN_LOCAL.md` étape 26.

**Preuve**

Cloud, Godot 4.7.2 Linux.

```
$ python -m usine.cours juger batiments_proceduraux
…
building_proceduraux_newyorkais_etape_013 : 0 écart(s) {}
39 projets, 0 écart(s)
$ python -m usine.cours verifier batiments_proceduraux --travailleurs 2
…
39/39 projets vérifiés sans erreur ; bilan : /home/claude/constructeur-qwen-gamedev/donnees/cours/batiments_proceduraux/verification.json
$ python -m pytest -q tests/test_cours.py
6 passed in 27.32s
```

**Reste à faire** : le générateur de la base dans le dépôt (règle 7.2 : création en plusieurs tours) ; conversion au format d'OpenCode (décision 14) ; étape 26 sur la machine.

**Pièges**

- Godot 4.7.2 : une constante `Array[PackedStringArray]` écrite en tableaux littéraux imbriqués (palette de New York) passe l'analyse mais plante le moteur au test de l'étape (signal 11) ; écrite avec `PackedStringArray([...])`, elle est refusée (« isn't a constant expression »). Un cas réduit à deux scripts ne plante pas. Garder `Array[Array]` et convertir à la lecture.
- Un essai rapide qui ne lisait que la ligne de bilan d'un test a manqué des « SCRIPT ERROR » (règle 5.5) ; le vérificateur, lui, lit chaque ligne.
- `--shot=<chemin relatif>` : avec `--path`, Godot compte le chemin depuis le dossier du projet.
- `Dictionary` et `Dictionary[Variant, Variant]` sont le même type (référence de GDScript). Une boucle `for x: Dictionary[String, Variant] in …` sur les dictionnaires non typés de l'API ne contrôle rien (`is_typed()` faux), alors qu'une affectation directe échoue à l'exécution : ne pas s'y fier.

### Générateur de la base « bâtiments procéduraux » et socle aux avertissements en erreurs — 2026-10-14 (branche `claude/regles-batiments-proceduraux`)

Source : demandes de laurent du 2026-10-14 (« intègre ta solution […] dans le dépôt », puis « continue ») ; règles qui priment 5.1, 5.3, 7.2 et 7.5.

**Fait**

- `usine/cours/base/` : le générateur de la base, repris de la passe « bâtiments procéduraux » et branché sur le dépôt. Il part des 39 projets que fabrique `usine.cours`, lit ses chemins dans `config.toml` (`[chemins] docs_godot` et `source_godot`, `[entrainement] vocab_qwen` et, facultatif, `vocab_qwen2`) et lance Godot par `usine.processus.executer` (règle 8) : `python -m usine.cours.base generer|assembler|tout`. Sorties dans `donnees/cours/batiments_proceduraux/base/` (ignoré par git).
- Règle 7.2 : les exemples de création sont en plusieurs tours. Une commande par tour (import, analyse de chaque script modifié, test de l'étape, image en Compatibilité quand un shader change) ; sa sortie réelle, avec son code de sortie, arrive dans le tour « user » suivant ; le dernier tour vérifie, corrige et rend compte. Avant, la réponse de création citait elle-même les sorties de Godot.
- Règle 5.1 : chaque commande montrée est celle qui a tourné, arguments compris ; l'exécutable s'y appelle `godot` et le `xvfb-run` propre au cloud n'y figure pas. Le rendu montré jusqu'ici omettait `--shot` et `--quit-after` : lancé tel quel chez laurent, il aurait ouvert la visite sans jamais quitter. Il enregistre maintenant son image dans `.godot/rendu.png` et quitte ; sa ligne `capture: … erreur=0` reste dans la sortie et entre dans la vérification. L'import ne garde plus seulement ses lignes d'erreur, ce qui aurait ôté à une erreur sa ligne `at:` : seuls ses codes de couleur et sa progression sont retirés.
- Contrôles de l'assemblage (`assembler.py`) : rôles alternés ; chaque commande demandée a sa sortie, et la bonne, dans le tour suivant ; aucune réponse n'écrit de sortie (7.2) ; consignes d'édition rejouées à la lettre (5.7) ; extraits de shader confrontés à leurs `#include` (5.6) ; aucun exemple au-delà de 32 768 jetons (7.5), comptés avec le tokenizer de Qwen 3.5 lu dans le GGUF de llama.cpp (5.8), bloc de réflexion vide hors des jetons de réponse (7.6).
- Socle (`godot/socle_jeu`) aux avertissements en erreurs (5.3) : bloc `[debug]` complet, et cinq retouches. Division entière explicite (`capture.gd`) ; deux ternaires dont les deux branches sont maintenant des `String` (`trace.gd`, `debug_overlay.gd`) ; le paramètre `target` de `Drone.setup`, qui masquait la méthode `target()`, renommé `chased` ; des `@warning_ignore` commentés sur le signal de `State`, émis par les états dérivés, et sur les `await runner.simulate_frames` des tests (`GdUnitSceneRunner` déclare `simulate_frames` abstraite, sans corps ; `GdUnitSceneRunnerImpl` attend les images).
- `CLAUDE.md` : règle 5.3 précisée (elle vaut pour le socle et le cours ; les jeux sources des 221 tâches gelées gardent leurs réglages, leur sort étant ouvert) ; arborescence (`usine/cours/base/`). `config.example.toml` : les trois chemins.
- Tests : `tests/test_cours_base.py` (9 tests, sans Godot) et `test_le_socle_traite_aussi_les_avertissements_en_erreurs` dans `tests/test_cours.py` ; `VERIFIER_EN_LOCAL.md` étape 27.

**Preuve**

Cloud, Godot 4.7.2 Linux, Python 3.13.16.

```
$ python -m usine.regles verifier godot/socle_jeu
0 violation(s) {}
$ python -m usine.juge run godot/socle_jeu --filtre res://7_tests
{"ok": true, "etape": "run_tests", "duree_s": 18.594, "erreurs": [], "tests": {"total": 31, "passes": 31, "echecs": []}}
$ (témoin : copie du socle, `var x = 1` ajouté à 1_core/process_order.gd) python -m usine.juge run <copie> --filtre res://7_tests
False check_script
res://1_core/process_order.gd 18 parse_error Parse Error: Variable "x" has no static type. (Warning treated as error.)
$ python -m usine.cours.base.jetons …/models/ggml-vocab-qwen35.gguf verifier
qwen35 : 50/50 chaînes de test identiques à la sortie de référence
$ python -m usine.cours.base.jetons …/models/ggml-vocab-qwen2.gguf verifier
qwen2 : 46/46 chaînes de test identiques à la sortie de référence
$ python -m pytest -q tests/test_cours.py tests/test_cours_base.py tests/test_regles.py tests/test_fiches.py
65 passed in 42.82s
$ python -m pytest -q tests/test_cours.py tests/test_cours_base.py
16 passed in 39.40s
$ python -m usine.cours.base tout --refaire --travailleurs 2 --docs … --source-godot … --vocab …/ggml-vocab-qwen35.gguf --vocab-qwen2 …/ggml-vocab-qwen2.gguf
parisien 001 : 1 création(s) (7404 jetons de réponse), 5 session(s) (6750), 20 s
…
newyorkais 013 : 1 création(s) (22081 jetons de réponse), 15 session(s) (21558), 122 s
…
problèmes : 0
```

Une première génération complète (de 21 h 48 à 22 h 09) avait aussi donné `problèmes : 0`, mais à la relecture, le rendu montré n'était pas la commande lancée (voir plus haut). La base ci-dessous vient du générateur corrigé : 17 min 41 s avec 2 travailleurs, assemblage compris. Les chiffres viennent de `controles.json` :

- 357 exemples : 39 de création (15,1 tours en moyenne, 24 au plus) et 318 sessions de débogage (934 erreurs corrigées, 9,2 tours en moyenne, 18 au plus) ;
- jetons de réponse : 459 073 pour la création, 452 352 pour le débogage (50,4 % et 49,6 %). Selon l'étape, le débogage pèse de 0,82 fois la création (`tokyoiste-004`) à 1,21 fois (`parisien-004`), médiane 0,98 ;
- 1 824 606 jetons de Qwen en tout. Le plus long exemple, `newyorkais-007-creation`, en compte 31 660 (1 108 sous 32 768) ; aucun ne dépasse 32 768. Les tokenizers qwen35 et qwen2 donnent le même total : leurs deux fichiers ont 151 936 jetons et 151 387 fusions ;
- consignes rejouées : 39 étapes, aucune consigne ambiguë, aucun fichier différent ;
- 65 sessions écartées pendant la génération : 36 pour une erreur imprévue, 27 dont des erreurs restaient invisibles pour Godot, 2 dont aucune commande ne voyait les erreurs.

Suite complète, `python -m pytest -q --ignore=tests/test_mcp_serveur.py` : `5 failed, 395 passed, 2 skipped in 829.29s`. Ce sont les mêmes 5 échecs qu'à l'étape 25 : `ModuleNotFoundError: No module named 'mcp'`, le SDK MCP n'étant pas installable dans le cloud.

**Reste à faire** : convertir la base au format d'OpenCode (décision 14, règle 7.4) à partir d'une session réelle enregistrée par le proxy de capture (fichier demandé à laurent) ; étape 27 sur la machine, hors campagne ; laurent décide de l'emploi de la base.

**Pièges**

- Une commande montrée raccourcie n'est plus celle qui a tourné : sans `--shot` ni `--quit-after`, le rendu ne quitte pas.
- `--check-only -s` lancé seul sur un script du socle échoue : « Identifier not found: GameState » (autoload) et « Could not find base class "GdUnitTestSuite" » (GdUnit4 n'est copié que par le juge). Analyser le socle par `python -m usine.juge run`.
- Avec tous les avertissements à 2, `await runner.simulate_frames(...)` déclenche REDUNDANT_AWAIT (méthode abstraite dans `GdUnitSceneRunner`), mais l'`await` reste indispensable.

### Base au format d'OpenCode — 2026-10-15 (branche `claude/regles-batiments-proceduraux`)

Source : décision 14 de laurent (le harnais d'usage est OpenCode) et règle 7.4. Ses réponses du 2026-10-15 : prompt système « OpenCode en entier » ; chemin de Godot « Je ne sais pas » (il vient donc de `D:\GODOT\AGENTS.md`) ; forme des retours d'édition : « Tes sessions OpenCode passées » ; vocabulaire de Qwen 3.8 : « Oui, dans qwen3.8 ».

**Relevé sur la machine de laurent** (lecture seule, dossiers ouverts avec son accord ; une seule écriture, le vocabulaire ci-dessous) :
- la session `donnees\sessions\20261004-190325_13780ad518f3.jsonl`, capturée par le proxy de l'usine : prompt système d'OpenCode 2.0.6 et ses 12 outils (`edit`, `execute`, `glob`, `grep`, `question`, `read`, `shell`, `skill`, `subagent`, `webfetch`, `websearch`, `write`) ; les outils de l'usine y passent par `execute` (Code Mode) ;
- la base `opencode.db` de ses sessions : forme exacte des retours de `shell`, `read`, `edit`, `write` et `grep`. Qwen y lance Godot par PowerShell : lignes en CRLF, progression de l'import en français ;
- `D:\GODOT\AGENTS.md` : chemin complet de la console Godot, lecture par plages, `plan.md` à cocher. Ce fichier n'était pas dans le prompt de la session capturée : les exemples n'ont pas de `plan.md` ;
- `E:\llama_models\qwen3.8\Qwen3.8-27B-UD-Q4_K_XL--vraimodel.gguf` (Unsloth) : tokenizer (pré-découpage qwen35, 248 320 jetons, 247 587 fusions) et gabarit de chat. Le vocabulaire seul en est extrait dans `E:\llama_models\qwen3.8\ggml-vocab-qwen38.gguf`.

**Constat** : le `models/ggml-vocab-qwen35.gguf` de llama.cpp, employé jusqu'ici pour compter (règle 5.8), n'est pas le vocabulaire de Qwen 3.8 : 151 936 jetons. Les comptes de l'étape 27 venaient donc d'un autre vocabulaire. La règle 5.8 de `CLAUDE.md` le précise désormais : tokenizer et gabarit lus dans le GGUF de Qwen 3.8.

**Fait**
- `usine/cours/base/opencode.py` : le format d'OpenCode.
  - Prompt système de la session de référence ; seules changent ses lignes d'environnement : dossier de travail (le projet de l'étape chez laurent) et identifiant de session, propre à chaque exemple.
  - Les 12 outils, définitions comprises. Les réponses lisent par plages (`read`), remplacent un passage unique (`edit`), créent un fichier (`write`), lancent Godot par son chemin complet (`shell`) et cherchent (`grep`).
  - Retours aux formes relevées, sans rien inventer : une forme non relevée (un `grep` qui trouve, une sortie de plus de 50 ko qu'OpenCode tronquerait) écarte l'exemple. Sorties de Godot entières (décision 13), sauf couleurs, progression de l'import et lignes propres à la machine (règle 5.1).
  - Rendu par le gabarit de Qwen 3.8 : portage du Jinja du GGUF, identique au caractère près (test). Jetons comptés sur ce texte, jetons spéciaux compris.
- Création et débogage convertis (`creation.py`, `sessions.py`) : le texte de chaque réponse reste devant ses appels (section 3) ; la demande de création ne cite plus le code, la réponse le lit ; chaque `edit` cite un passage que la réponse a lu.
- Découpe des étapes trop longues. Le prompt d'OpenCode et ses outils prennent 13 375 jetons par exemple : 17 étapes ne tiennent plus en un exemple.
  - Chaque découpe est d'abord estimée sans Godot, avec les sorties de l'état final de l'étape ; Godot ne tourne que sur une découpe dont l'estimation tient. La découpe aux jetons estimés (le moins de parties possible) passe avant les budgets de caractères.
  - Défauts de la découpe, trouvés sur newyorkais 007 et 010 et corrigés. Ils étaient sans effet sur la base de l'étape 27, où aucune étape n'était découpée.
    - Rangement des changements (`ordonner.py`) : une locale retirée puis refaite plus bas reste avec sa redéclaration et ses emplois ; un `x.rect` de GDScript n'est plus lié à la fonction `rect` d'un shader ; une fonction privée peut précéder son premier appel (seules une variable privée et un signal avertissent) ; un `#include` ajouté reste avec le retrait des déclarations qu'il remplace ; `const int ROOM_OFFICE = 0;` d'un shader n'est plus lu comme la constante « int » de GDScript ; une signature changée sur sa deuxième ligne est vue (`room_view`).
    - `empaqueter` perdait une partie et en doublait une autre : `parties[-2] += parties.pop()` lit sa cible avant le `pop`, puis l'écrit un rang trop haut.
    - Les consignes et les extraits d'une partie viennent des changements entre ses deux états : les places de l'étape entière sont fausses dans un état intermédiaire.
  - Une partie annonce les points de la note qu'elle fait : un point dont le titre nomme un fichier reçoit ses changements (« Le fichier commun `procedural_commun.gdshaderinc` »), et un morceau du test rattaché par défaut au dernier point ne l'annonce plus.
- Sorties de Godot gardées par empreinte d'état (`godot.py`) : un même état ne repasse pas par Godot ; la sortie gardée porte une marque à la place du chemin du projet, remise au chemin du dossier où l'état revient.
- Export (`exporter.py`) : `base_batiments_proceduraux.jsonl` (format chat d'OpenAI, comme OpenCode l'envoie ; arguments en objets, le gabarit de Qwen 3.8 refuse une chaîne), version sharegpt pour LLaMA-Factory (appels écrits dans la réponse `gpt`, retours dans le tour `human` qui suit : un tour `function_call` perdrait le texte de la réponse), `dataset_info.json` sans colonne `tools`.
- Contrôles de l'assemblage (`assembler.py`), en plus de ceux de l'étape 27 : prompt d'OpenCode adapté au projet ; chaque appel a son retour ; outils et arguments conformes aux définitions d'OpenCode ; Godot par son chemin complet ; retours aux formes relevées ; aucune réponse n'écrit de sortie (7.2) ; aucun passage cité par `edit` sans avoir été lu ; jetons recomptés ; 32 768 au plus (7.5) ; aller-retour sharegpt identique au texte du gabarit ; appels `edit` et `write` rejoués comme OpenCode les applique.
- `config.example.toml` : `[opencode] session_reference` et `dossier_cours` ; `[entrainement] vocab_qwen` désigne le GGUF de Qwen 3.8. `jetons.py` lit un GGUF de modèle en continu (seul l'en-tête est lu) ; ses anciens comptes au format neutre sont retirés ; `croiser` compare ses jetons, exemple par exemple, à ceux de `llama-tokenize`.
- Tests : `tests/test_cours_opencode.py` (8 tests, dont le rendu comparé au gabarit du GGUF, `tests/donnees/qwen38_gabarit_chat.jinja`) ; `tests/test_cours_base.py` passe de 9 à 17 tests. `CLAUDE.md` (règle 5.8, arborescence) ; `VERIFIER_EN_LOCAL.md` étape 28.

**Preuve**

Cloud, Godot 4.7.2 Linux, Python 3.13.

```
$ python -m pytest -q tests/test_cours_base.py tests/test_cours_opencode.py tests/test_regles.py tests/test_fiches.py
74 passed in 8.63s
$ python -m usine.cours.base tout --refaire --travailleurs 2 --docs … --source-godot … --vocab …/ggml-vocab-qwen38.gguf --opencode-session …/20261004-190325_13780ad518f3.jsonl --opencode-godot 'D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --opencode-dossier 'D:\GODOT\projet_enseingement\001_Batiments proceduraux'
parisien 001 : 1 création(s) (7657 jetons de réponse), 4 session(s) (8430), 20 s
  parisien 002 : 1 partie(s), 40571 jetons estimés au plus : trop long, découpe suivante
parisien 002 : 2 création(s) (23042 jetons de réponse), 12 session(s) (23749), 61 s
…
  newyorkais 013 : 1 partie(s), 71069 jetons estimés au plus : trop long, découpe suivante
newyorkais 013 : 5 création(s) (44560 jetons de réponse), 20 session(s) (44425), 190 s
…
problèmes : 0
```

Jetons croisés avec llama.cpp (`llama-tokenize` construit dans le cloud au commit `fd55cb9`, sur le vocabulaire extrait du GGUF de laurent) :

```
$ python -m usine.cours.base.jetons …/ggml-vocab-qwen38.gguf croiser …/llama-tokenize …/base_batiments_proceduraux.jsonl
pré-découpage : qwen35 | jetons : 248320 | fusions : 247587
374/374 exemples identiques jeton pour jeton à llama-tokenize
```

Les 7 385 242 jetons de la base sont ceux de llama.cpp, un à un.

Suite complète, `python -m pytest -q --ignore=tests/test_mcp_serveur.py` : `5 failed, 411 passed, 2 skipped in 741.78s`. Ce sont les mêmes 5 échecs qu'aux étapes 25 et 27 : `ModuleNotFoundError: No module named 'mcp'`, le SDK MCP n'étant pas installable dans le cloud. `python -m pytest -q tests/test_cours.py` : `7 passed`.

Chiffres de `controles.json` (20 min 48 s avec 2 travailleurs, assemblage compris ; aucune partie refusée par Godot) :
- 374 exemples : 70 de création (17 étapes découpées ; 51,3 messages en moyenne, 86 au plus) et 304 sessions de débogage (891 erreurs corrigées ; 21,1 messages en moyenne, 40 au plus) ;
- jetons de réponse : 681 466 pour la création, 680 999 pour le débogage (50,0 % chacun). Selon l'étape, le débogage pèse de 0,86 fois la création (`parisien-004`) à 1,12 fois (`tokyoiste-001`), médiane 1,00 ;
- 7 385 242 jetons de Qwen 3.8 en tout, dont 13 375 par exemple pour le prompt d'OpenCode et ses outils. Le plus long exemple, `newyorkais-005-creation`, en compte 31 715 (1 053 sous 32 768) ; aucun ne dépasse 32 768 ;
- appels d'outils : `edit` 1 909, `shell` 1 492, `read` 1 256, `grep` 291, `write` 47 ;
- rejoués : les consignes neutres des 39 étapes (aucune ambiguë, aucun fichier différent) ; les appels `edit` et `write` des 39 étapes et des 304 sessions, comme OpenCode les applique (aucune différence) ;
- 70 sessions écartées pendant la génération : 35 pour une erreur imprévue, 27 dont des erreurs restaient invisibles pour Godot, 6 dont une sortie de Godot dépassait 50 ko (OpenCode n'en aurait rendu qu'un aperçu), 2 dont aucune commande ne voyait les erreurs.

**Reste à faire**
- `VERIFIER_EN_LOCAL.md` étape 28 sur la machine, hors campagne ; laurent décide de l'emploi de la base (grille de la décision 3 ; règle 7.7 : une case n'écrase pas les autres).
- `usine/rft/export.py` contredit la section 3 et les règles 7.4 et 7.6 : un tour `function_call` de LLaMA-Factory perd le texte de la réponse, les arguments restent des chaînes (le gabarit de Qwen 3.8 les refuse), le gabarit est `qwen3` sans `enable_thinking: false`, et les outils de l'agent maison ne sont pas convertis en ceux d'OpenCode. À corriger avant tout entraînement sur des sessions capturées ; `usine/cours/base/opencode.py` en donne le format.

**Pièges**
- `parties[-2] += parties.pop()` : Python lit la cible avant le `pop`, puis l'écrit un rang trop haut. Écrire le `pop` d'abord.
- Dans une expression régulière à alternatives, la forme `const NOM` de GDScript attrape le `const int NOM` des shaders : tester la forme des shaders d'abord.
- Une signature peut tenir sur deux lignes : comparer la signature entière, parenthèses refermées.
- `models/ggml-vocab-qwen35.gguf` de llama.cpp n'est pas le vocabulaire de Qwen 3.8 (151 936 jetons contre 248 320) : compter avec le GGUF du modèle.
- Le gabarit de Qwen 3.8 refuse des arguments d'appel en chaîne JSON (forme d'OpenAI) : les convertir en objets avant de l'appliquer. Son `tojson` est celui de transformers : `json.dumps(…, ensure_ascii=False)`, accents gardés.
- Un tour `function_call` de LLaMA-Factory perd le texte qui précède l'appel : écrire les appels dans le tour `gpt`, comme le gabarit les écrit.
- Une sortie de Godot gardée contient le chemin du dossier où elle a tourné : la garder avec une marque à sa place.
- OpenCode n'avait pas chargé `D:\GODOT\AGENTS.md` dans la session capturée.

### Fusion dans `main` — 2026-10-15

Source : demande de laurent du 2026-10-15 (« ok passe la en main »), après l'ouverture de la PR #9.

- La branche de travail (PR #8, « Béquille, point 1 : retour des outils ») et la passe « bâtiments procéduraux » (PR #9, empilée sur #8) sont fusionnées dans `main`, par des commits de fusion comme les PR précédentes.
- La fusion vient avant les vérifications locales des étapes 22 à 28 : laurent l'a demandée ainsi. Ces étapes restent à faire sur sa machine, hors campagne, en partant de `main` (`VERIFIER_EN_LOCAL.md`, étape 25 mise à jour).
- Avant le `git pull` de `main`, laurent commite ses corrections V2 non commitées (section 3 des règles qui priment).
### Compétence O1 « corriger en observant » — 2026-10-20 (machine de laurent, commité sur `main`, fusionné avec la PR #8 et la PR #9)

Demande de laurent : que Qwen apprenne à corriger un bug de gameplay en *regardant la partie*, comme on juge son propre jeu (« le kart vole, il traverse un arbre, il est à moitié enseveli dans la route quand il tourne »). Les tests unitaires vérifient des règles une par une ; personne ne regardait une partie entière. « Regarder » se fait ici par des mesures exactes, image par image, à cadence fixe, sans fenêtre et sans LLM (règle 2).

**Fait**

- `usine/observation/` (hors de `usine/juge`, comme E : le cache des verdicts communs reste valide) :
  - `gd/jouer_partie.gd` : joue des séquences scriptées sur des parties neuves, dans un seul lancement de Godot (`--fixed-fps 60`). Commandes tenues, alternées, événements (le saut passe par `_input()` : un vrai `InputEventAction`), pilote automatique vers l'obstacle le plus proche (demi-tour sur place d'abord). Enregistre, image par image : position, appui (sol, eau, air), vitesses, hauteur au-dessus de la surface, profondeur sous le sol, pénétration dans les obstacles, enfouissement du bas visible (carrosserie, roues), caméra (dans le champ, sous le sol, regard dans le sens de la marche). Mode `monde` : écrit le **monde de vérité**, les formes de collision de la référence, posées ensuite en fantôme sur les calques 20 (sol) et 21 (obstacles). Une collision retirée par le bug reste donc visible pour le juge.
  - `partie.py` : lancement, monde de vérité, **règles évaluées en Python** (gravité, hauteur, sous le sol, traversée, enfouissement, caméra, caméra derrière), marges, résumé en texte pour l'agent.
  - `juge.py` : étape `observation` après le juge commun ; catégories `partie_<règle>` ; clé de cache propre (`partie.version_observation`).
  - `jeux/kart.json` : description du kart (acteur, commandes, obstacles, 4 séquences, seuils réglés sur le jeu intact, 8 bugs modèles, 4 fichiers de gameplay pour les mutants).
- Générateur `usine/generateurs/observation.py` : bugs modèles, puis mutants des scripts de gameplay (opérateurs de l'usine, un par ligne, 40 au plus) ; un candidat est gardé s'il casse au moins une règle de partie (vérité par construction). Écartés : `jeu_casse`, `invisible_en_partie`. Tâche : départ muté, référence = fichier d'origine, `tests_caches/observation/` (description et monde), juge = import, check_script, load_scene, puis observation ; patch plafonné à 4 lignes.
- Source `kart` (`usine/generateurs/sources.py`) : le projet vit hors du dépôt, déclaré dans `[sources]` de `config.toml` (`config.chemin_source`) ; il ne donne que des tâches O1 (`generateurs=frozenset()`, `observation="kart"`). `produire` saute une source absente de la machine.
- Socle (`usine/socle.py`, `commun.lire_projet`) : les extensions tierces suivent le projet (seul GdUnit4, injecté par le juge, reste exclu) ; les dossiers `.gdignore` sont exclus ; le socle prend le nom de la source. Les quatre sources du dépôt n'en sont pas changées (seul dossier `.gdignore` : dans GdUnit4, déjà exclu) : mêmes fichiers, mêmes empreintes.
- Portillon : le matériel d'observation tient lieu de tests cachés ; un départ qui échoue avant l'étape observation est refusé (`depart_hors_observation`) ; les mutants de la zone corrigée sont jugés avec l'observation (`mutants.score_mutation_tache`).
- Outil MCP `play_sequence` : déclaré seulement avec `--observation <dossier>` (tâches O1) ; transmis par `essais` à l'agent maison et à OpenCode (`opencode_fusion.commande_mcp`), et par la mesure. Fiche `skills/usine-o1-observation`. CLAUDE.md : 15 compétences, O1 décrite.
- Projet kart (`D:\GODOT\PROJETS_DEMOS\PROJET_KART_RANGE`, son `ORGANISATION.md` à jour) : 19 fichiers cassés et inutilisés sortis dans `PROJET_KART_RANGE_hors_jeu/` ; trois scènes rendues sûres quand on les ouvre seules ; import sur un seul fil (voir pièges). 143 tests GdUnit4 verts, trajectoire de conduite identique à l'origine.

**Preuve**

Huit bugs injectés à la main dans une copie du kart, quatre séquences ; jeu intact : aucune faute.

| Bug injecté | Ce que dit la trace |
| --- | --- |
| Gravité nulle (le kart vole) | `saut` : gravité dès l'image 74 ; hauteur : 19,1 m au-dessus de la surface |
| Saut à 40 m/s (il s'envole) | `saut` : hauteur, 44,9 m au-dessus de la surface |
| Palmier sans calque (il traverse un arbre) | `palmier` : traversée dès l'image 428, 0,98 m dans small_palm.tscn (52.9, 3.2, -44.9) |
| Rocher sans collision | `rocher` : traversée dès l'image 239, 0,66 m dans rock.tscn (-14.5, 2.5, 4.0) |
| Roulis × 12 (à moitié enseveli en tournant) | `rocher` : carrosserie 0,17 m sous le sol ; `palmier` : roues 0,48 m sous le sol |
| Modèle 35 cm trop bas | `palmier` : roues 0,52 m sous le sol, 607 images |
| Kart sans collision au sol | `palmier` : 8,36 m sous le sol ; caméra 4 m sous le sol |
| Caméra à contresens | `virages` : la caméra regarde à contresens de la marche dès l'image 121 |

Déterminisme : deux lots identiques ; chaque séquence seule = la même dans le lot (après un échauffement de 10 images et l'ajout de chaque partie à la fin d'une image). Quatre séquences : 13 s ; monde de vérité : 1,3 s.

Juge de l'usine : `juger_tache` sur une tâche générée (palmier sans collision) : départ `FAIL@observation`, « séquence « palmier », traversée : 11 images, dès l'image 428 ; pire à l'image 433 : le kart entre de 0,98 m dans small_palm.tscn (52.9, 3.2, -44.9) », trois fois identique ; référence `PASS@observation` (42 s).

```
python -m pytest -q tests/test_observation.py        → 20 passed (dont l'intégration Godot : génération + juge)
python -m pytest -q                                  → 346 passed, 1 skipped (sqlite_vec absent), 14 min 26
```

Production réelle (`python -m usine.generateurs produire --sources kart --competences O1 --sortie donnees/candidats_o1`, 943 s) : **10 tâches, 38 écartés**. Les 8 bugs modèles donnent tous une tâche ; sur 40 mutants des scripts de gameplay, 2 sont visibles en partie (`camera_controller.gd:78`, renommage : la caméra ne se replace plus derrière le kart ; `kart.gd:277`, opérateur : le kart monte trop haut), 34 sont invisibles dans les 4 séquences (dérapage, frein, marche arrière, figures : non joués), 4 cassent le jeu (relèvent de K3).

```
observation O1       10 tâches    38 écartés  (943 s)
```

**Reste à faire**

1. Passer les candidates O1 au portillon (`python -m usine.portillon evaluer donnees/candidats_o1/O1/<id>`, `VERIFIER_EN_LOCAL.md` étape 29) : environ 10 min par tâche (3 + 3 jugements, puis 8 mutants), soit quelques heures  ; puis geler un jeu O1 avec les autres (gel sous Godot 4.7.2, décision du 2026-10-06, étape 21).
2. Un premier essai de Qwen sur une tâche O1 avec l'agent maison (`play_sequence` déclaré), pour vérifier que l'outil est utilisable et que le juge est réussissable dans le budget de pas.
3. Le juge ne lance pas encore les tests du kart (ils sont dans `7_tests/`, le juge commun cherche `res://tests_juge`) : un correctif qui casse une règle non observée peut passer. Le plafond de 4 lignes limite ce risque. À faire : copier les tests du jeu comme tests cachés.
4. Séquences plus variées pour le kart (dérapage, frein, marche arrière, figures sur terre, plaque de boost, boîte à objets, bombe) : seuls 2 mutants sur 40 sont visibles avec les 4 séquences actuelles.
5. Autres jeux : écrire leur `jeux/<jeu>.json` (acteur, séquences, seuils réglés sur la référence). Seuils relatifs à la référence plutôt qu'absolus si un jeu le demande.
6. Shaders (décidé par laurent, après ce branchement) : Godot sans fenêtre compile les `.gdshader` et signale l'erreur avec sa ligne (vérifié) ; `.gdshaderinc` et `.glsl` sont aujourd'hui dans le socle (non modifiables par l'agent) et devront passer en texte.
7. Hors de portée : l'aspect visuel, le son tel qu'on l'entend (le kart n'a d'ailleurs aucun son), le plaisir de jeu.

**Pièges**

- **Plantage de l'import (code 3221225477) : cause trouvée.** Godot importe en parallèle par défaut ; l'import d'un shader de calcul (`tire_marks_shader.glsl`) plante alors environ une fois sur onze. Avec `[editor] import/use_multiple_threads=false` dans `project.godot` : 0 plantage sur 40 imports (11 s → 16 s par import). Réglé dans le kart. Le plantage relevé sur `kenney_racing` le 2026-10-05 a sans doute la même cause : à essayer avant tout ajout de reprise dans le juge.
- **Le juge charge chaque scène seule** (`load_scene`) : une scène qui suppose un parent (kart) ou une caméra plante. Pour une source, rendre ces scènes sûres quand elles sont ouvertes seules, sans changer le jeu.
- **`Input.action_press` n'envoie pas d'événement** : un jeu qui lit une commande dans `_input()` (le saut du kart) ne la voit pas. `jouer_partie.gd` envoie un `InputEventAction` pressé puis relâché.
- **Une touche relâchée puis pressée dans la même image** est à la fois « tout juste pressée » et « tout juste relâchée » : un test qui simule un dérapage doit attendre une image neuve.
- **Ajouter une partie au milieu d'un pas de physique** lui donne un affichage de plus avant sa première physique : la trace diffère de celle d'une partie seule. `jouer_partie.gd` ajoute la partie suivante à la fin d'une image, et n'enregistre qu'après 10 images d'échauffement (la suspension se pose).
- **Taille des tâches O1** : 18,7 Mo chacune (texte du kart et monde de vérité) ; les binaires sont dans le socle `kart-…`.

### Kart en mode strict (règle 5.3) — 2026-10-20 (choix A de laurent)

Question posée à laurent : la règle 5.3 (avertissements de GDScript = erreurs) vaut « pour les projets qui suivent le plan » ; le kart rangé suit le plan mais son code d'origine n'était pas typé (84 variables sans type dans 17 scripts). Réponse : « a », appliquer la règle.

**Fait**

- Projet kart : bloc `[debug]` de `godot/socle_jeu/project.godot` (28 avertissements à 2) ; 25 scripts typés, environ 170 corrections (la compilation stricte d'une copie en listait 172), sans changer aucun calcul (divisions entières voulues écrites `int(… / 8.0) + 1`, paramètre `position` renommé `point` dans `ProceduralFish._set_fin()`). `ORGANISATION.md` du kart : section « Code typé ».
- `usine/observation/gd/jouer_partie.gd` typé lui aussi : un script lancé par `-s` hérite des réglages d'avertissements du projet observé ; sans cela, O1 ne pouvait pas observer un projet strict (12 erreurs de compilation).

**Preuve** (projet rangé, après typage)

```
import : code 0 ; compilation stricte des 56 scripts : 0 erreur
GdUnit4 (7_tests, --fixed-fps 60) : 143 test cases | 0 errors | 0 failures
documentation ## : TOTAL 0 manque
traces des 4 séquences, comparées à celles d'avant le typage : virages, rocher, palmier, saut identiques
juge de l'usine (import, check_script, load_scene) : ok
```

Tâches O1 régénérées sur le kart strict : mêmes 10 tâches (8 bugs modèles, 2 mutants : `camera_controller.gd:79`, une ligne plus bas qu'avant le typage, et `kart.gd:277`), 38 écartés (34 invisibles en partie, 4 jeu cassé).

```
observation O1       10 tâches    38 écartés  (931 s)
```

**Piège**

- **Un script `-s` hérite des avertissements du projet** : tout script d'outil de l'usine lancé sur un projet strict (socle, cours, kart) doit lui-même être typé, sinon il ne compile pas et l'outil échoue sans rapport avec le candidat.

### O1 par l'image : bâtiments procéduraux — 2026-10-20 (branche `claude/observation-visuelle`)

Demande de laurent : « tu lui apprends à corriger en observant, c'est primordial, et c'est la même chose pour les bâtiments procéduraux : il faut que tu inclues cette vérification visuelle et la correction ». Ses choix (questions du 2026-10-20) : Qwen regarde « l'image elle-même » ; rendus « hors de l'écran » ; ordre « bâtiments, kart, roguelike ».

**Fait**
- `usine/observation/visuel.py` : rendu des vues en Compatibilité (960×540), fenêtre placée en `-6000,-6000` ; comparaison d'images par Godot (`gd/comparer_images.gd`, `Image.get_data`, sans dépendance Python : Pillow n'est pas dans `requirements.txt`) ; écart décrit en mots (part de l'image, zone, plus sombre ou plus claire).
- `usine/observation/juge_visuel.py` : étape `observation_visuelle`. Les tests d'origine de l'étape sont remis par-dessus le candidat (règle 3), lancés, puis chaque vue (jour, nuit, soleil rasant) est comparée à son image de référence. Catégories d'erreur `image` et `rendu`. Branchée dans `usine/taches.py`, le portillon (`depart_hors_observation` vaut aussi pour cette étape) et le score de mutation (les shaders entrent dans la zone de la référence).
- `usine/generateurs/operateurs.py` : opérateurs de shader (commentaires `//` et `/* */` masqués) : constante, opération, comparaison, composantes permutées, arguments de `mix`/`step`/`smoothstep` échangés, `1.0 - x` retiré, sortie du fragment retirée (`ALBEDO`, `NORMAL_MAP`…).
- `usine/generateurs/observation_visuelle.py` : un mutant d'un shader, d'un générateur de maillage, d'une palette ou de l'outil de maillage commun devient une tâche s'il passe le rendu sans erreur, se voit (au moins une vue change sur 1,5 % de l'image) et laisse passer les tests de l'étape. Seuil relevé de 0,5 % à 1,5 % après examen des images : à 1,1 % (des pièces un peu plus sombres la nuit), le défaut ne se voyait pas sans l'image de référence.
- `usine/generateurs/commun.py` : `ecrire_tache` écrit aussi du binaire (images de référence du juge).
- `tests/test_observation_visuelle.py` (16 tests), `CLAUDE.md` (O1), `VERIFIER_EN_LOCAL.md` étape 30.

**Preuve** (machine de laurent, Windows 11, Godot 4.7.2)

```
rendu visible et rendu hors de l'écran (parisien 005) : identiques octet pour octet
python -m pytest -q tests/test_observation_visuelle.py : 16 passed
suites touchées (-m "not godot") : 135 passed, 1 skipped (sqlite_vec absent) ; (-m godot) : 2 passed
juger_tache o1v_parisien_005_pierre_216_arguments_echanges_0 : départ FAIL@observation_visuelle
  (« vue « jour » : 16 % de l'image diffère de la référence, au centre (zone plus sombre) »), référence PASS
python -m usine.portillon evaluer …o1v_newyorkais_002_brique_87_arguments_echanges_0 : acceptée
  (départ FAIL@observation_visuelle ×3, référence PASS ×3, mutants 1/1)
production, 39 étapes, --par-projet 4 --essais 30 (8 h 43 → 9 h 43) : TOTAL : 146 tâche(s), 654 candidat(s) écarté(s)
  écartés : invisible (la grande majorité), erreur_au_rendu, vu_par_les_tests (2)
  opérateurs des 146 tâches : sortie_retiree 32, operateur_arithmetique 18, condition_niee 17,
  arguments_echanges 16, constante_modifiee 16, composantes_permutees 14, un_moins_retire 12,
  appel_supprime 11, booleen_inverse 5, comparaison_inversee 5
```

**Reste à faire**
- Relever la forme des images dans OpenCode (`VERIFIER_EN_LOCAL.md` 30 d, avec laurent) : aucune session capturée n'en contient. Ensuite : sessions de débogage visuel dans la base du cours (regarder, lire le code, corriger, regarder de nouveau).
- Portillon sur les 146 tâches (environ 2 min par tâche).
- Kart puis roguelike en cours par étapes, avec leur observation : découpage du kart accepté par laurent (« oui vas y ») ; suite dans l'entrée suivante.

**Pièges**
- Les identifiants des tâches qui mutent le générateur principal répètent le nom de l'étape (`o1v_newyorkais_002_building_proceduraux_newyorkais_etape_002_133_…`) : sans effet sur le juge.
- Un défaut visuel peut ne se voir que dans une vue (de nuit, sous un soleil rasant) : les trois vues sont rendues pour chaque candidat.

### Cours « kart » par étapes — 2026-10-20 (branche `claude/observation-visuelle`)

Demande de laurent : « pour qwen tu restructures le projet de kart en étapes de création, pour qu'il apprenne à coder le contrôle des manettes du kart, l'herbe, des VFX et des shaders, et tu fais exactement la même chose avec le jeu rogue like ». Ses choix : le cours suit ses règles d'architecture comme les bâtiments (« Oui, comme les bâtiments ») ; découpage en 14 étapes accepté (« oui vas y »).

**Fait**
- `usine/cours/jeu.py` : fabricant des cours « de jeu ». Les maîtres ont la forme du projet, balisés `#@`, `//@` ou `;@` selon le fichier. Les ressources viennent du jeu source rangé (`[sources]` de config.toml), de proche en proche (res://, uid://, .mtl, .gltf). Une étape qui désigne un maître absent est refusée. `tests/test_cours_jeu.py` (6 tests).
- `cours/kart/` : manifeste (14 étapes, `PRETES` = 1 à 14), maîtres, notes `etape_001.md` à `etape_014.md` (README de chaque projet). Étapes :
  1. contrôles clavier et manette (adaptateur `KartInput`, vibration) ;
  2. le kart (réglages en taux par seconde dans `5_data`) ;
  3. la caméra qui suit ;
  4. l'île (terrain, piste, shaders triplanaire et stylisé) ;
  5. le décor stylisé et le vent global ;
  6. l'herbe (semis en blocs MultiMesh, `GameState`) ;
  7. flotter (mer calme, capteurs, corps flottants, kart sur l'eau) ;
  8. la mer FFT, avec repli en mer calme sans RenderingDevice ;
  9. vagues d'impact et écume (`WaterWaves`, sillage du kart réglé dans `5_data`) ;
  10. dérapage, turbo et figures, puis leurs effets : étincelles, traînées, marques de pneus, gerbes d'eau, fantôme ;
  11. pluie et éclair (`Weather` à graine, paramètres globaux `rain_intensity` et `rain_wetness`) ;
  12. poissons procéduraux (bancs à graine) ;
  13. objets : boîte à objets, réserve à poids, inventaire et son affichage, bombe et explosion, plaque de boost ;
  14. le chef d'orchestre, l'autoload `GameFlow`, seul à charger les scènes (contrat `Step`, `sequence.tres`, `boot.tscn` qui lui remet la séquence) ; pause et remappage des contrôles.
- Corrections du kart d'origine, toutes vues ou mesurées :
  - lecture d'image hors de l'image (`ImageSampling`) ;
  - capteur d'eau qui croyait le kart dans l'eau sur tout sol à hauteur 0 ;
  - masque de l'île lu en noir au-delà de 480 m (la physique disait « eau plate », le shader montrait la houle) ;
  - rampe orientée à l'envers, caméra de travers au départ ;
  - paramètres de matériau sans uniform (traces, pluie) dans les étapes où leur shader ne les a pas encore ;
  - marques de pneus invisibles : le rayon des roues, long comme la suspension au repos (0,5 m), ne touchait plus le sol quand elle se détendait ; 0,7 m dès l'étape 2 (vu par des rendus A/B et des traces des rayons) ;
  - houle FFT, météo, éclair, poissons et objets tirés sans graine : graines exposées, pour que deux rendus soient identiques (juge visuel) ;
  - fantôme : ses paramètres d'instance dépassaient la réserve en Compatibilité ; un matériau par fantôme ;
  - réserve d'objets dont tous les poids sont nuls : elle tirait le dernier objet ; elle ne rend plus rien ;
  - `GameFlow` qui rejouait une étape : la nouvelle était posée avant le départ de l'ancienne, et Godot la renommait (`@StepA@9`) ; l'ancienne quitte l'arbre d'abord ;
  - l'autoload préchargeait `2_sequence/sequence.tres` (refusé par le juge des règles : 0_autoload ne connaît que 1_core) ; c'est `2_sequence/boot.tscn` qui lui remet la séquence, comme dans le socle.
- `usine/cours/verifier.py` :
  - contrôle `parametres_orphelins` (paramètre de matériau sans uniform dans son shader : 0 sur les 39 projets des bâtiments) ;
  - pour les cours de jeu, une seconde image en Compatibilité (règle 5.4), par `capturer(..., compatibilite=True)`.

**Preuve** (machine de laurent, Windows 11, Godot 4.7.2 ; 2026-10-21, une passe : `python -m usine.cours verifier kart --etapes 1 2 3 4 5 6 7 8 9 10 11 12 13 14 --travailleurs 1`, environ 14 min ; bilan dans `donnees/cours/kart/verification.json`)

```
kart_etape_001 : ok   18 test cases | 0 errors | 0 failures   rendu Forward+ et Compatibilité sans erreur
kart_etape_002 : ok   46 test cases | 0 errors | 0 failures   idem
kart_etape_003 : ok   61 test cases | 0 errors | 0 failures   idem
kart_etape_004 : ok   66 test cases | 0 errors | 0 failures   idem
kart_etape_005 : ok   71 test cases | 0 errors | 0 failures   idem
kart_etape_006 : ok   87 test cases | 0 errors | 0 failures   idem
kart_etape_007 : ok  117 test cases | 0 errors | 0 failures   idem
kart_etape_008 : ok  123 test cases | 0 errors | 0 failures   idem
kart_etape_009 : ok  135 test cases | 0 errors | 0 failures   idem
kart_etape_010 : ok  163 test cases | 0 errors | 0 failures   idem
kart_etape_011 : ok  177 test cases | 0 errors | 0 failures   idem
kart_etape_012 : ok  187 test cases | 0 errors | 0 failures   idem
kart_etape_013 : ok  210 test cases | 0 errors | 0 failures   idem
kart_etape_014 : ok  234 test cases | 0 errors | 0 failures   idem (jeu lancé par boot.tscn : GameFlow charge l'île)
14/14 projets vérifiés sans erreur
juge des règles : 0 écart à chaque étape ; matériaux : 0 paramètre orphelin ; GdUnit : 0 flaky, 0 skipped, 0 orphans
python -m pytest -q tests/test_cours_jeu.py tests/test_cours.py : 13 passed
```

Vu au rendu (images A/B hors de l'écran, `usine.retour.capture.capturer`) : l'herbe qui s'écarte sous le kart ; le reflet de la mer calme ; la houle FFT et son repli ; l'écume du sillage ; étincelles de dérapage, fantôme, marques de pneus ; pluie, ronds dans l'eau, éclair ; bancs de poissons ; ramassage d'une boîte, case d'inventaire, lancer de bombe, explosion ; jeu complet lancé par `boot.tscn`.

**Reste à faire**
- Le roguelike, même démarche : fait (entrée suivante).
- O1 par l'image pour les étapes du kart. Défauts vus pendant la fabrication, candidats au générateur :
  - herbe sans `player_position` : l'herbe traverse le kart ;
  - normale de la mer calme sans `VIEW_MATRIX` : plus de reflet, mer uniforme ;
  - marques de pneus à `mark_strength` nulle ;
  - écume à `foam_amount` nulle.
- Base d'entraînement du cours du kart (création et débogage), au format d'OpenCode.

**Pièges**
- Sans fenêtre, le moteur ne garde ni les paramètres globaux de shader (`global_shader_parameter_get` rend Nil) ni les transformations d'un MultiMesh : on teste ce qu'on lui envoie (GameState, `chunk_transforms`).
- `RenderingServer.get_rendering_device()` vaut null en Compatibilité et sans fenêtre : tout ce qui calcule sur la carte graphique doit prévoir un repli.
- En Compatibilité, 341 instances à paramètres d'instance dépassent la réserve du moteur de rendu (« Maximum items supported by this hardware is: 4096 »).
- Un `metadata/_custom_type_script = "uid://…"` dans un .tres ou un .tscn fait recopier le script d'origine par le fabricant : après un renommage, l'écrire en chemin res://.
- Le chemin de sortie de `capturer` doit être absolu : Godot travaille depuis le dossier du projet.
- Balises des maîtres : un bloc (`;@ 14+`) court jusqu'à la balise suivante et avale les lignes communes placées avant elle ; une balise `all` mal placée fait fuir une ligne dans les étapes antérieures. Le fabricant refuse une étape qui désigne un fichier absent, mais une variable en trop passe sans bruit : comparer les étapes refabriquées aux étapes vérifiées.
- `physics_frame` part avant que les nœuds ne jouent leur image physique : attendre trois images avant de lire un capteur (bombe dans l'eau).
- Dans un test GdUnit, une variable nommée `before` masque une fonction de `GdUnitTestSuite` (avertissement `shadowed_*`, donc erreur).
- Un test qui change la scène courante (GameFlow) pose une scène jetable avant et rend la scène d'origine après.

### Cours « roguelike » par étapes — 2026-10-21 (branche `claude/observation-visuelle`)

Demande de laurent : « tu fais exactement la même chose avec le jeu rogue like » que pour le kart. Découpage en 14 étapes validé le 2026-10-21 (« Oui, vas-y »), avec trois choix : les cinq VisualShader deviennent du code (« Oui, en .gdshader ») ; le jeu démarre sur le premier niveau de l'ordre tiré (« Oui, premier niveau tiré ») ; à la manette, on vise au stick droit, et au repos vers où l'on marche (« Stick droit, sinon direction de marche »).

**Fait**
- `cours/roguelike/` : manifeste (14 étapes, `PRETES` = 1 à 14), maîtres, notes `etape_001.md` à `etape_014.md`. Source : le roguelike GameDev.tv rangé (`[sources]` roguelike de config.toml). Étapes :
  1. contrôles clavier, souris et manette (adaptateur `PlayerInput`, vibration) ;
  2. le joueur : machine à états (`State`, `StateMachine`), course et chute ;
  3. l'animation : arbre d'animation, pas, arme en main ;
  4. le niveau de test : GridMap, limite du monde, caméra qui tremble ;
  5. l'esquive : état, recharge, shader de traînée (`dash.gdshader`), son ;
  6. le combat : coups enchaînés, santé, recul, effet de lame ;
  7. ennemis au corps à corps : états, navigation, écho de défaite (`defeat_echo.gdshader`) ;
  8. ennemis à distance : boule de feu, impact, `fire.gdshader` ;
  9. retour des coups : chiffres de dégâts, barres de santé, teinte rouge ;
  10. la vague : apparitions à graine, courbe de difficulté, sortie (`spawn_point.gdshader`) ;
  11. trois niveaux sur un modèle commun, éclairage VoxelGI ;
  12. le chef d'orchestre `GameFlow` (ordre tiré à graine, fondus, héros gardé hors de l'arbre) et `GameState` ;
  13. la boutique d'améliorations entre deux niveaux (`background_material.gdshader`) ;
  14. la pause et le menu des contrôles : liaisons par appareil, sauvegardées en codes avec une version, remises au démarrage.
- Les cinq shaders réécrits en code donnent les mêmes pixels que les VisualShader d'origine (rendus A/B : 0 pixel d'écart ; le feu sur des quads fixes, les particules GPU ne se rejouant pas au pixel près ; le fond de la boutique de 0,5 à 20 s).
- Écarts avec le jeu d'origine, vus ou mesurés :
  - hasard sans graine (vague, errance par `map_get_random_point`, ordre des niveaux, boutique) : graines exposées, pour que deux parties et deux rendus soient identiques ;
  - le jeu démarrait toujours sur `level_2`, hors de l'ordre tiré ;
  - à la manette, la boutique ne se choisissait pas : aucun focus, et `ui_accept` n'a aucun bouton de manette dans Godot 4.7.2 ;
  - l'autoload connaissait la séquence, les améliorations et la courbe de difficulté (refusé par le juge des règles) : `boot.tscn` remet la séquence, le reste est rangé dans `2_sequence` et `5_data` ;
  - ni pause ni menu des contrôles : ajoutés à l'étape 14, sur le modèle du kart.
- Règle ajoutée pour les rendus : la souris ne vise qu'après un vrai déplacement (`relative` non nul) ; une fenêtre hors de l'écran reçoit au démarrage un mouvement à déplacement nul.
- `godot/socle_jeu/0_autoload/capture.gd` : avant de quitter, les lecteurs audio sont vidés (`stream = null`) et la capture attend 3 × 30 ms de temps réel ; sans cela, un son joué à la sortie fuyait (« resources still in use at exit »).
- `config.toml`, `config.example.toml` : `roguelike` dans `[sources]` ; `tests/test_cours_jeu.py` porte sur les deux cours.

**Preuve** (machine de laurent, Windows 11, Godot 4.7.2 ; 2026-10-21, une passe : `python -m usine.cours verifier roguelike --travailleurs 1` ; bilan dans `donnees/cours/roguelike/verification.json`)

```
roguelike_etape_001 : ok    24 test cases | 0 errors | 0 failures   rendu Forward+ et Compatibilité sans erreur
roguelike_etape_002 : ok    35 test cases | 0 errors | 0 failures   idem
roguelike_etape_003 : ok    39 test cases | 0 errors | 0 failures   idem
roguelike_etape_004 : ok    45 test cases | 0 errors | 0 failures   idem
roguelike_etape_005 : ok    51 test cases | 0 errors | 0 failures   idem
roguelike_etape_006 : ok    76 test cases | 0 errors | 0 failures   idem
roguelike_etape_007 : ok    84 test cases | 0 errors | 0 failures   idem
roguelike_etape_008 : ok    92 test cases | 0 errors | 0 failures   idem
roguelike_etape_009 : ok   103 test cases | 0 errors | 0 failures   idem
roguelike_etape_010 : ok   110 test cases | 0 errors | 0 failures   idem
roguelike_etape_011 : ok   107 test cases | 0 errors | 0 failures   idem (main.tscn et ses tests s'arrêtent à l'étape 10 : les niveaux prennent le relais)
roguelike_etape_012 : ok   123 test cases | 0 errors | 0 failures   idem
roguelike_etape_013 : ok   137 test cases | 0 errors | 0 failures   idem
roguelike_etape_014 : ok   166 test cases | 0 errors | 0 failures   idem (jeu lancé par boot.tscn)
14/14 projets vérifiés sans erreur
juge des règles : 0 écart à chaque étape ; matériaux : 0 paramètre orphelin ; GdUnit : 0 flaky, 0 skipped, 0 orphans
sortie brute de GdUnit, étape 14 : seules lignes ERROR, le débogueur distant du vérificateur (port 0) et trois push_error attendus par leurs tests
python -m pytest -q tests/test_cours_jeu.py tests/test_cours.py : 14 passed
```

Vu au rendu (hors de l'écran, `usine.retour.capture.capturer`) : contrôles, course et chute, animation, niveau et fosse, traînée de l'esquive (Forward+ et Compatibilité), enchaînement avec l'effet de lame, combat et écho de défaite, boules de feu, barres de santé et chiffres de dégâts avec la teinte, la vague, les trois niveaux (VoxelGI : 465 602 pixels changent avec et sans), le fondu depuis `boot.tscn`, la boutique, le menu de pause et le menu des commandes (sur la machine de laurent, les places W A S D s'affichent Z Q S D : clavier AZERTY).

**Reste à faire**
- La priorité de laurent, choisie « après le roguelike » : apprendre à Qwen à chercher des références, tester le rendu et le gameplay comme pendant cette fabrication (rendus A/B, captures, parties rejouées) et utiliser le RAG. Point ouvert : avec ou sans bibliothèque locale de photos.
- L'outil de capture appuie par `Input.action_press`, qui ne crée aucun événement : un menu qui écoute `_input` (la pause) ne s'ouvre pas en capture. Le changer en `Input.parse_input_event` touche au socle : à proposer à laurent.
- O1 par l'image pour les étapes du kart et du roguelike ; bases d'entraînement des deux cours, au format d'OpenCode.

**Pièges**
- Une référence de classe croisée (`Enemy` ↔ `EnemyState`) fait fuir des ressources à l'import de l'éditeur (« resources still in use at exit ») : typer l'un des deux côtés par la classe mère.
- Un enfant est prêt avant son parent : une vue (`_view.gd`) attend `owner.ready` avant de lire les composants `@onready` du personnage.
- Hors de l'arbre, `free()` et pas `queue_free()` : GdUnit compte un orphelin par nœud laissé jusqu'à la fin de l'image.
- Les particules GPU ne se rejouent pas au pixel près, même à graine fixe : comparer un shader de particules sur des quads fixes.
- La carte de navigation ne répond pas avant sa première synchronisation (« navigation map query failed because it was made before first map synchronization ») : attendre `map_get_iteration_id() > 0`.
- Un nœud hors de l'arbre n'est dans aucun groupe que l'arbre connaisse (`get_first_node_in_group`).
- Navigation au stick : l'interface ne bouge le focus qu'à l'image où `Input` voit l'action s'enfoncer ; dans un test, un stick passe par `Input.parse_input_event` puis `Input.flush_buffered_events`, un bouton peut passer par `Viewport.push_input`.
- Sans fenêtre, `DisplayServer.keyboard_get_keycode_from_physical` lève une erreur (aucune disposition de clavier) : tester `keyboard_get_layout_count() > 0` d'abord.
- `4_ui` ne connaît pas `5_data` (juge des règles) : un menu reçoit ses réglages de la scène qui le pose.
- Dans les tests, des variables locales nommées `before` ou `name` masquent `GdUnitTestSuite` et `Node` : la suite ne compile plus (erreur revenue trois fois).
- Un `await` devant `assert_error(...)` est redondant (`redundant_await`, donc erreur).

### Bases d'entraînement des cours de jeu — 2026-10-22 (branche `claude/observation-visuelle`)

Demande de laurent : étendre la base « 50 % création, 50 % débogage » aux cours du kart et du roguelike (« oui vas y »).
Décisions du jour dans CLAUDE.md : un seul LoRA pour 4.7.2 et 4.8 (15), aucun exemple mis de côté pour tester (16),
combler les trous de la grille par du débogage (17), protocole d'entraînement tiré des travaux lus (18).

**Fait**
- `usine/cours/base/profil.py` : ce qui change pour un cours de jeu.
  - Tests : les suites GdUnit4 que l'étape crée ou modifie, à la dernière partie, sans `-d --remote-debug`, avec
    `-rc 1`.
  - Analyse : `--check-only` ne charge pas les autoloads (« Identifier not found: GameFlow » sur un script juste) ;
    un script qui en emploie un, même par ce qu'il charge, est vérifié par les tests. Détection vérifiée contre
    Godot sur les 95 scripts du roguelike 014.
  - Rendu : la scène principale ou celle qui charge le shader, 60 images en Compatibilité, fenêtre hors de l'écran.
  - Enseigné : le code, les scènes et ressources texte de taille raisonnable, `project.godot` ; donnés : les très
    gros fichiers.
  - Lignes bénignes du moteur, lues et expliquées par la réponse : « Parameter "material" is null » du moteur de
    rendu factice, « … only available when using the Forward+ renderer » en Compatibilité.
- `chemins.configurer(cours=…)`, `--cours` en ligne de commande, dossiers Windows `[opencode].dossier_kart` et
  `dossier_roguelike` (choix de laurent : « 002_Kart et 003_Roguelike »).
- Découpe (`ordonner.py`) : une scène ou ressource reste entière ; un script qui cherche un nœud (`$Nom`) passe après
  la scène qui le déclare ; un morceau qui emploie une classe globale nouvelle passe après sa déclaration.
- Erreurs posées (`mutations.py`) : variables, paramètres et types de retour sans type (référence de
  `ProjectSettings` 4.7.2, `untyped_declaration`) ; noms de Godot 3 des classes 3D et des shaders (table
  `renames_map_3_to_4.cpp` 4.7.2) ; `float` écrit `int` dans un shader ; sessions faites seulement de shaders ;
  réserve d'erreurs élargie aux autres fichiers du projet quand l'étape n'en offre plus assez.
- Contrôle strict (règle 5.5) : GdUnit4 finit en code 0 malgré des lignes ERROR/WARNING du jeu. Générateur et
  vérificateur les comptent, sauf celles qu'une suite attend (`is_push_error`, `is_push_warning`). Défauts ainsi
  trouvés dans les cours, corrigés dans les maîtres :
  - kart 014 : 78 erreurs « Not supported by this display server » par passage du menu des commandes sans
    fenêtre ;
  - kart 012-014 : avertissement des poissons provoqué sans être vérifié ;
  - roguelike 010 : requête de navigation avant la première synchronisation de la carte ;
  - roguelike : sons qui jouent encore à la sortie (« ObjectDB instances were leaked at exit ») ; crochet de
    session GdUnit4 `7_tests/1_core/silence_audio.gd`, dans les deux cours.
- Machine de laurent : sources de Godot 4.7.2 (`D:\sources\godot-4.7.2`, extraction partielle au commit
  ed1daf0bf du binaire), vocabulaire de Qwen 3.8 (`E:\llama_models\qwen3.8\ggml-vocab-qwen38.gguf`, 248 320
  jetons), Godot 4.8-beta1 installé à côté (`D:\GODOT\Godot_v4.8-beta1_win64.exe\`, SHA-512 vérifiée).

- Essai de mémoire sur la 5090 (demande de laurent, décision 19) : QLoRA rang 16 de Qwen 3.8 27B (`G:\llm_lora_trainer\qwen38_27b`, 4 bits, `template: qwen3_5`, `enable_thinking: false`), une paire de création de 2 043 jetons (même longueur comptée par LLaMA-Factory que par notre tokenizer), 12 pas d'un exemple : passé, pic de 31 940 Mio sur 32 607 dont 5 519 déjà pris par les applications ouvertes, 266 jetons/s. Environnement `G:\llm_lora_trainerenv` : LLaMA-Factory 0.9.5, transformers 5.6.0, torch 2.11.0+cu128, sans `flash-linear-attention`, `causal-conv1d` ni Liger. Fichiers : `donnees/essais/memoire_2048/`.
- Même essai avec une séquence de 8 images (vue de jour de la tour new-yorkaise, étapes 001 à 008, rendus O1 réduits à 480 × 270), le plan et 12 pas : passé, 1 865 jetons dont 960 d'images (120 par image, mesuré), pic de 30 937 Mio sur 32 607 dont 3 498 déjà pris (Blender fermé), 266 jetons/s ; tour de vision et projecteur gelés. Fichiers : `donnees/essais/memoire_images/`.
- Même séquence en 640 × 360 (`cutoff_len` 3 072 pour l'essai) : 2 665 jetons dont 1 760 d'images (220 par image), pic de 32 029 Mio sur 32 607, **24 jetons/s** au lieu de 266 (pas de 84 à 125 s) : la carte est pleine et l'entraînement devient inutilisable sans planter. Sur la 5090, la limite pratique est d'environ 2 048 jetons, images comprises. Fichiers : `donnees/essais/memoire_images_640/`.
- 5 images en 640 × 360 (décision 19.5), le plan, `cutoff_len` 2 048 : passé, 1 999 jetons dont 1 100 d'images, pic de 29 902 Mio sur 32 607 dont 2 013 déjà pris, 284 jetons/s (6 à 7 s par pas). Fichiers : `donnees/essais/memoire_images_640_x5/`.

- Plugins (décision 9, demande de laurent : « aller verifier sur internet les plugin considere en octobre 2026 pour godot comme excellents pour les lister les etelecharger les aznallyser ») : 21 retenus d'après awesome-godot et « Best Godot Plugins in 2026 » (ziva.sh, 2026-06-03), versions lues par l'API de GitHub, téléchargés depuis les dépôts officiels dans `donnees/plugins/archives/` (131 Mo, adresse et SHA-256 dans `releve.json`). Analyse sans exécution (`donnees/plugins/extraits/analyse.json`) : 18 en GDScript, 3 natifs (LimboAI, Debug Draw 3D, Terrain3D) ; appels réseau et processus seulement dans les modules de mise à jour et le lanceur de GdUnit4. Chargés dans un projet vide de Godot 4.7.2 (éditeur sans fenêtre, `donnees/plugins/essais/`) : 16 sans erreur (Phantom Camera une fois son autoload posé) ; ProtonScatter 4.0 (2023) ne compile plus (`scatter.gd:240`, « Not all code paths return a value »), sa branche main oui, avec des icônes non importées sans fenêtre ; SmartShape2D fuit à la fermeture de l'éditeur. Les 3 natifs (accord de laurent : « oui ») se chargent et enregistrent leurs classes dans 4.7.2 (`ClassDB.class_exists` : BTPlayer, LimboHSM, LimboState, BehaviorTree, DebugDraw3D, DebugDraw2D, Terrain3D, Terrain3DData), sans erreur ; Terrain3D fuit à la fermeture de l'éditeur. En 4.7.2, `debug/gdscript/warnings/directory_rules` exclut `res://addons` par défaut : nos avertissements stricts ne touchent pas les plugins.
- Fiches de plugins pour le RAG : `rag/plugins/plugins.toml` (manifeste : dépôt, version, archive et SHA-256, dossiers de l'addon, autoloads), `rag/plugins/<id>/fiche.md` et `exemple/exemple.gd`, vérifiés par `python -m usine.rag.plugins verifier` (projet de travail dans `donnees/plugins/travail/`, bloc `[debug]` du socle, import puis exemple à 60 images/s, marque « EXEMPLE VERIFIE », aucune erreur ni avertissement). Première fiche : Phantom Camera, vérifiée 3 fois sur 3. Godot 4.7.2 plante parfois en sortant de `--import` (0xC0000005, sans message) : le vérificateur relance une fois.
- RAG (décision 9, « ameliore le RAG poru qu'il soit complet ») :
  - banc `python -m usine.rag banc` (`usine/rag/banc.py`) : 87 demandes en français tirées des points des notes des cours, chacune avec au moins une classe citée et vérifiée dans `extension_api.json` ; trouvée si l'un des 5 premiers résultats est sa page (référence) ou un fragment qui l'emploie (utile) ; les fragments du même cours ne comptent pas ;
  - glossaire français-anglais (`usine/rag/glossaire.py`, table fixe) : mots vides retirés, chaque notion cherchée avec ses équivalents anglais et ses classes Godot, au plus deux pages de classe données par le glossaire ;
  - nos sources (`usine/rag/nos_sources.py`) : 485 points des notes, le code vérifié du dernier projet de chaque cours (1 924 fragments), les fiches de plugins ; index reconstruit : 30 100 fragments, 0 repris d'une tâche gelée ; l'index précédent est gardé dans `donnees/rag/godot_docs_avant_2026-10-22.sqlite` ;
  - mesure, hors même cours : page attendue 6/87 → 14/87, fragment utile 11/87 → 30/87.
- Fiches de plugins : les 21 sont écrites et vérifiées (`python -m usine.rag.plugins verifier` : 21/21, 2026-10-26).
  18 avec un exemple qui tourne dans Godot 4.7.2 (Debug Draw 3D fenêtre hors de l'écran), 3 outils d'éditeur
  (Signal Lens, Shader Warm-Up, GdUnit4) vérifiés plugin activé dans l'éditeur sans fenêtre (`verification =
  "editeur"`). Pièges réels relevés en les testant, entre autres : Beehave écrit une erreur par image sans
  débogueur et ne cohabite pas avec LimboAI (« Class "Blackboard" hides a native class ») ; GLoot et Dialogue
  Manager fuient à la sortie (cache statique ; ressource rangée dans ses propres lignes) ; Input Helper ne signale
  jamais le changement d'appareil sans fenêtre (images dessinées à 0) ; Maaack's Scene Loader relit la scène par
  `load` au lieu de `load_threaded_get`, et une demande de chargement sur fil jamais récupérée fuit à la sortie (vrai
  sans le plugin) ; à `Engine.time_scale = 0`, `_physics_process` tourne encore avec un delta nul ; ProtonScatter
  4.0 ne compile plus, sa branche main oui, sans son dossier `demos/` (fichier .blend). Messages propres à un
  plugin : `sorties_connues` du manifeste (texte exact ou motif « re: »), chacun expliqué dans sa fiche.
- Index du RAG reconstruit avec les 21 fiches : 30 291 fragments ; banc hors même cours : 14/87 et 30/87.
- Godot 4.8 (décision 19.7, accord de laurent : « ok fai_s ca ») : `extension_api.json` de la 4.8-beta1 extrait
  (`donnees/vocab/extension_api_4.8-beta1.json`, Godot v4.8.beta1.official.4d10419ca) et comparé à celui de 4.7.2 par
  `python -m usine.vocab difference` (`usine/vocab/difference.py`) : 339 différences ; 22 dans l'API de l'éditeur ;
  31 sans effet pour GDScript (11 valeurs `…_MAX`, 16 indications de type de l'inspecteur, 4 signatures à
  pointeurs) ; restent **287 différences utiles** : 276 ajouts (31 classes dont `Line3D`, `Trail3D`, les résultats
  typés des requêtes physiques `Physics…Result2D/3D` ; 165 méthodes ; 35 propriétés ; 1 singleton,
  `TextureStreaming`), 10 changements dont 7 compatibles (arguments facultatifs ajoutés), 1 retrait
  (`AnimationNodeBlendSpace2D.triangles`). 33 concernent la réalité virtuelle (OpenXR). À 6 paires par différence :
  1 722 paires (1 524 hors réalité virtuelle), sous le plafond de 10 % des 22 000 paires courtes. À refaire sur la
  version stable avant de générer.
- Catalogue d'effets du RAG (étape R1 du suivi ; remarque de laurent : « pourquoi ne sais tu pas qu'on devais
  preparer le RAG pour les shaders etc ??? ») :
  - `rag/effets/effets.toml` (titre, usage, pièges) et `rag/effets/<id>/exemple/` (shaders et `exemple.gd`) ;
    `python -m usine.rag.effets verifier` rend chaque exemple en Compatibilité, fenêtre hors de l'écran, lit ses
    pixels, puis réécrit la fiche : shaders et fonctions de pilotage recopiés des fichiers que Godot vient de faire
    tourner, mesure tirée de la ligne écrite par l'exemple. Chaque fonction de pilotage est appelée par l'exemple
    (test) ; chaque piège est mesuré, cité (godot-docs 4.7, référence des classes) ou marqué « non mesuré ici ».
  - 6/6 : flash d'impact (rouge → blanc → rouge en 0,25 s), dissolution (part disparue 0 / 0,25 / 1 ; 1 appel de
    dessin sphère dissoute, 0 une fois libérée), contour (0 / 18 / 0 pixels sombres), bouclier de Fresnel (centre au
    fond, bord à 0,97 ; lueur 4,9 → 8,1 pendant un coup → 4,9), vignette de dégâts, pixelisation.
  - 5 de plus (2026-10-26), 11/11 : eau stylisée (figée, 0 point changé en 20 images ; animée, 753 ; crête/creux
    0,21 de luminance), vent dans l'herbe (0 pixel changé sans vent ; avec, 2 335 en haut du brin, 0 au pied :
    `UV.y` vaut 0 en haut d'un `QuadMesh`), particules d'impact (`GPUParticles3D`, salve unique : 0 / 598 / 0 pixels
    orange, 666 à la seconde salve relancée par `restart()`), nombres de dégâts (`Label3D` qui monte de la ligne 380
    à 316 et s'efface, puis libéré), traînée (`Line2D` de 30 points, pleine près de l'objet, pâle à l'arrière).
    Trois n'ont pas de fichier shader : le test n'en exige plus.
  - Défaut trouvé en vérifiant : la pixelisation lisait chaque bloc au bord de son premier pixel, et le filtre
    « nearest » y prenait parfois le voisin (222 changements au lieu de 223 avec des blocs de 1) ; elle lit
    maintenant le centre du pixel (+ 0,5).
  - RAG : fiches indexées en genre « effet » (24 sections), leur code une seule fois en genre « exemple » (6
    shaders, `exemple.gd` par fonction). Le découpage des fiches ignore désormais les `## ` des blocs de code
    (commentaires de documentation GDScript : la fiche de GdUnit4 en avait un). Les 5 premiers résultats donnent la
    fiche pour 5 demandes d'effets sur 6 ; « faire flasher un ennemi en blanc quand il est touché » remonte la vue
    d'ennemi du roguelike.
- Outil `voir_scene` (étape A7 du suivi ; accord de laurent : « Oui, construis ») : voir la scène 3D comme dans
  l'éditeur. Origine : un vrai débogage du roguelike de laurent
  (`F:\GODOT_APPRENTISSAGE_ROGUE\QWEN_TEST_VERSION\_backup_avant_fix_camera`) : `ShakeCamera3D` à 12 m au-dessus du
  joueur, sans rotation, donc visée vers -Z (référence des classes, `Node3D.look_at` : « the -Z axis (camera
  forward) ») ; image 3D vide, HUD visible ; Qwen a multiplié captures et scripts de fenêtre. La correction incline
  `CameraRoot` de -55° et recule la caméra de 20 m ; deux autres défauts corrigés en même temps : modèle couché
  (`PlayerRoot` tourné de -90° autour de X), `shadow_bias` négatif.
  - `usine/retour/vues.py` et `usine/retour/gd/vues_scene.gd` (autoload posé dans une copie ; rendu fenêtre hors de
    l'écran, Compatibilité) : vue du jeu à l'image N (HUD compris) ; vues d'observation dessus, côté, face, 3/4,
    cadrées sur la scène, avec le champ de la caméra du jeu (jaune), la boîte de chaque objet (verte dans le champ,
    rouge hors champ), axes, grille à y = 0, noms ; planche titrée composée par Godot ; carte en texte : caméra
    (position, visée en mots, projection), chaque objet et le plan du champ qui l'exclut (proche, lointain, gauche,
    haut, droite, bas, couche exclue par `cull_mask`), autres caméras, lumières, objets cachés, carte vue de dessus en
    caractères. Outil MCP `voir_scene` ; compté parmi les captures du juge de sessions.
  - Sur une copie du projet de laurent remise à l'état d'avant la correction : « regarde vers (0, 0, -1) (à
    l'horizontale) ; 12 objets visibles, 0 dans le champ », tous « HORS CHAMP : bas » ; le corps du joueur mesure
    0,7 m de haut pour 1,2 m de long, tête à côté du corps : le modèle couché se lit aussi. Sur le projet corrigé :
    « 55° vers le bas », 12/12 dans le champ, position à l'écran de chacun. Les ERROR de fuite à la sortie viennent du
    jeu lui-même (lancé seul 60 images : 143 objets non libérés, ressources de rendu), pas de l'outil.
- Famille de paires « situer la caméra et les objets » (étape A8 ; premier module de `usine/paires/`, format commun
  dans `usine/paires/format.py`, jetons comptés avec le tokenizer de Qwen 3.8 et son gabarit) :
  `python -m usine.paires camera --niveaux N --graine G` (`usine/paires/camera.py`). Niveaux générés d'après une
  graine (sol, 2 ou 3 objets, joueur, pivot et caméra ; vue de dessus orthographique inclinée ou perspective) ; le
  niveau sain doit tout montrer à `voir_scene`, sinon il est rejeté ; 13 défauts posés chacun par une seule édition du
  `.tscn` (inclinaison absente = le bug réel, visée vers le haut, caméra sous le sol, `far` trop court, `near` trop
  loin, champ orthographique ou `fov` trop étroit, `cull_mask` sans la couche, autre caméra courante, modèle couché,
  objet sous le sol, objet caché, objet derrière la caméra) ; chaque scène fautive est rendue et doit montrer le
  symptôme dans les mesures du moteur, sinon le cas est rejeté ; la correction est l'édition inverse (rendu sain).
  Paires sans plan (exception de la section 3), 1 024 jetons au plus : analyse d'un niveau sain, diagnostic d'un cas
  fautif (analyse), correction avec le texte à remplacer (débogage).
  - Nombre décidé par laurent le 2026-10-27 (« ok pour 1 et 2 ») : 300 paires de 1 024 jetons.
    `python -m usine.paires camera --niveaux 20 --paires 300` : 13 niveaux complets, 162 cas, 0 rejeté ; 311 paires
    (149 débogage, 162 analyse ; 64 % et 36 % des jetons de réponse), 793 jetons en moyenne, 1 017 au plus,
    aucune écartée ; 26 paires par défaut commun, 12 à 14 pour les défauts propres à un style. On s'arrête au niveau
    qui atteint la cible, sans couper le dernier : chaque défaut pèse autant. Tests du module et de `voir_scene`
    avec Godot : 14 passés.
  - Ce que la mesure a corrigé : avec 4 objets de décor, 22 paires sur 336 dépassaient 1 024 jetons, toutes de
    débogage et pour trois défauts au long extrait (autre caméra courante, modèle couché, objet derrière la caméra) :
    ces défauts tombaient à 18-21 paires au lieu de 28. Le générateur pose maintenant 2 ou 3 objets (la sortie de
    `voir_scene` n'est pas raccourcie, décision 13) et la cause « objet derrière » ne répète plus la position de la
    caméra, déjà dans la ligne qui la précède. Le bilan compte les paires écartées par défaut.
  - Ligne ajoutée dans `godot/socle_jeu/AGENTS.md` (APRÈS CHAQUE ACTION, accord du 2026-10-27) : « Si la 3D ne
    s'affiche pas ou qu'un objet manque : voir_scene avant toute autre capture. » Hors du bloc permanent.
  - Ce que la vérification a corrigé : sur un pivot sans rotation, la caméra reculée le long de son axe se retrouve
    au ras du sol et voit tout ; le défaut reproduit donc le bug réel (caméra en hauteur, sans rotation), réservé à
    la vue de dessus (en perspective, une caméra à l'horizontale voit encore le niveau en bas de l'image, mesuré) ;
    inverser l'inclinaison du pivot mettait la caméra sous le sol, d'où le niveau est dans le champ mais caché (l'outil
    ne calcule pas l'occultation) : le défaut tourne la caméra elle-même vers le haut.
  - `voir_scene` corrigé : un objet du mauvais côté du plan proche est dit « derrière la caméra » ou « plus près que
    near », sans la liste des autres plans. **Piège mesuré** : `Camera3D.is_position_behind()` compare au plan
    proche, pas à la caméra : avec `near = 60`, un objet 20 m devant la caméra est « behind » (la référence des
    classes dit seulement « behind the camera ») ; l'outil calcule le côté par la direction de visée.
- Catalogue de morceaux de code (étape R2 du suivi) : `rag/morceaux/morceaux.toml` et `rag/morceaux/<id>/exemple/`,
  vérifiés par `python -m usine.rag.morceaux verifier` (sans fenêtre, comportement mesuré). Mécanique commune aux
  effets et aux morceaux : `usine/rag/catalogue.py` ; le code d'un morceau garde son chemin du plan dans le projet de
  vérification (`res://3_entities/robot/…`) et les fichiers du socle qu'il emploie y sont copiés ; un extrait de
  `project.godot` (actions, noms de couches) entre dans le projet et dans la fiche. 9/9 :
  - état « étourdi » avec la `StateMachine` du socle : 30 images pour 0,5 s, 90 avec 60 images de pause ;
    **piège mesuré** : un décompte `float` comparé à 0 seul dure 31 images (reste infime au-dessus de 0), 30 avec
    `is_zero_approx` (l'état `player_dash` du socle emploie `<= 0.0` : une image de plus quand la durée tombe juste
    sur un multiple de 1/60 ; le socle n'est pas modifié) ;
  - caméra qui suit sa cible (`1 - exp(-smoothing × delta)`) : même position à 30 et 120 images/s ; lissage naïf
    3,349 m contre 3,601 m ;
  - inventaire à piles (25 potions → 10, 10, 5 ; reste rendu ; empilement par `id`, `duplicate()` compris) ;
  - génération par graine (même graine, même grotte ; générateur réemployé : autre grotte ; `Vector2i / int`
    déclenche l'avertissement de division entière) ; terrain par bruit (`SurfaceTool`, normale moyenne +Y 0,88) ;
  - vision d'un ennemi (portée, cône, `intersect_ray`) : **mon hypothèse était fausse**, le mur posé arrête le rayon
    tout de suite, sans attendre une image de physique (mesuré, moteur par défaut) ;
  - zone de ramassage (couches et masques dans la scène ; ramassée après 2 images de physique) ; réglages
    sauvegardés (`ConfigFile`, absent → `ERR_FILE_NOT_FOUND`, abîmé → `ERR_PARSE_ERROR` et une ERROR du moteur,
    gardée comme sortie connue) ; manette (stick et croix dans les actions, zone morte 0,2 : 0,15 → 0, 0,6 → 0,5,
    diagonale de longueur 1).
  - interface (11/11) : barre de vie qui écoute le `HealthComponent` du socle (10 → 8,5 à mi-glissement → 7 ; deux
    coups rapprochés → 1) ; menu de fin de partie à la manette (focus vide avant `open()`, croix bas ×2 → « Quitter »,
    ×3 → y reste, A et Entrée valident ; A et B ajoutés à `ui_accept` et `ui_cancel` avec leurs touches).
- Jeu de données `arunsrajan/godot-docs-dataset` (Hugging Face, étudié à la demande de laurent, 2026-10-26) :
  24 631 paires question/réponse au format Alpaca tirées de godot-docs, branche 4.7 de développement, questions sur
  gabarits, réponses = texte de la doc (85 % de référence des classes), sans vérification ni outils. Pas pour
  l'entraînement (règles 18.1, 7.4, 5.2, 7.7 ; même source que notre RAG). Banc de recherche du RAG (accord de
  laurent : « je te donne l'accord ») :
  - CSV téléchargé dans `donnees/rag/hf_godot_docs/` (révision `341723dec465…`, 15 704 187 octets, SHA-256
    `049f8226…`, vérifié à chaque lecture) ; `python -m usine.rag banc-docs` (`usine/rag/banc_docs.py`) : 24 213
    couples page#ancre en trois groupes (membre, classe, guide) ; couverture (page et ancre présentes dans l'index,
    ancres converties comme `docutils.nodes.make_id`) et recherche sur 1 000 questions par groupe, toujours les
    mêmes (page attendue, puis fragment de l'ancre, dans les 5 premiers résultats) ;
  - deux défauts trouvés et corrigés : les pages `OS` et `IP` n'avaient **aucun membre** dans l'index (titre de
    deux lettres souligné de deux caractères, non reconnu : la classe s'appelait « Description ») ; un membre d'un
    seul mot (`enabled`, velocity) n'était jamais trouvé exactement : il l'est maintenant entre accents graves, ou
    dans une requête de 4 mots au plus s'il appartient à la classe nommée (dans une phrase, « mesh » ou
    « animation » prenaient la place des guides : mesuré, puis écarté) ;
  - pages ajoutées à l'index : `about/`, `community/`, `engine_details/` file_formats (format `.tscn`), engine_api
    (GDExtension), architecture ; restent hors index 223 lignes de pages pour contributeurs du moteur (compiler,
    éditeur, écrire la référence) ; index : 1 553 pages, 30 945 fragments ;
  - mesure (5 premiers résultats, source « tout ») : membres couverts 17 618 → 17 710/17 710, trouvés précisément
    970/1 000 ; classes 652/652 ; guides couverts 3 104 → 3 421/3 644, page trouvée 820/905, section 729/905. Sur
    le même échantillon de 200 avant/après : membres 186/198 → 194/200, classes 128/131 → 131/131, guides 157/169 et
    140/169 inchangés. Banc en français inchangé (14/87 et 31/87 hors même cours ; 54/87 hors même étape).

**Preuve** (machine de laurent, Windows 11, Godot 4.7.2, 2026-10-22)

```
python -m usine.cours verifier roguelike --travailleurs 1   : 14/14 projets vérifiés sans erreur (contrôle strict)
python -m usine.cours verifier kart --travailleurs 1        : 14/14 projets vérifiés sans erreur (contrôle strict, seul sur la machine)
python -m usine.cours.base assembler --cours roguelike      : problèmes : 0
  155 exemples (28 créations, 127 sessions, 334 erreurs corrigées) ; 3 162 139 jetons de Qwen 3.8, dont 479 382 de réponse ;
  création 50,6 % des jetons de réponse ; débogage/création par étape 0,66 à 1,07, médiane 1,01 ; plus long 31 443 ;
  consignes neutres et éditions d'OpenCode rejouées : 0 différence
python -m usine.cours.base assembler --cours kart           : problèmes : 0
  203 exemples (38 créations, 165 sessions, 476 erreurs corrigées) ; 4 176 339 jetons, dont 663 052 de réponse ;
  création 49,8 % ; débogage/création par étape 0,97 à 1,06, médiane 1,01 ; plus long 31 439 ; rejouées : 0 différence
python -m pytest -q tests/test_cours_base_jeu.py tests/test_cours_base.py tests/test_cours_opencode.py tests/test_cours_jeu.py tests/test_cours.py : 50 passed
python -m usine.cours verifier batiments_proceduraux --travailleurs 1 : 39/39 projets vérifiés sans erreur (cours des bâtiments inchangé par ce travail, vérifié avec le vérificateur actuel)
```

**Preuve du catalogue d'effets** (machine de laurent, Windows 11, Godot 4.7.2, 2026-10-26)

```
python -m usine.rag.effets verifier : 6/6 exemples vérifiés, leurs fiches réécrites
python -m usine.rag construire      : effets {'effets': 6, 'sections': 24, 'shaders': 6} ; fragments exclus (solution gelée) : 0
python -m usine.rag banc            : 87 demandes ; page de référence 14, fragment utile 54 (hors même étape)
banc.mesurer(tout_le_cours=True)    : page 14/87, utiles 31/87 (référence du suivi : 14/87 et 30/87) : pas de recul
python -m pytest -q tests/test_rag_effets.py tests/test_rag_nos_sources.py tests/test_rag_plugins.py tests/test_rag.py : 29 passed, 1 skipped (sqlite_vec absent)
python -m usine.rag construire      : pages : 1553   fragments : 30945 ; fragments exclus (solution gelée) : 0
python -m usine.rag banc-docs       : membre : couverture ancres 17710/17710 ; recherche page 1000/1000, précis 970/1000
                                      classe : couverture pages 2859/2859, ancres 1851/2859 ; recherche 652/652
                                      guide : couverture pages 3421/3644, ancres 3356/3644 ; recherche page 820/905, précis 729/905
python -m pytest -q tests/test_mcp_serveur.py tests/test_rag*.py : 37 passed, 1 skipped (sqlite_vec absent)
python -m usine.rag.effets verifier eau_stylisee vent_herbe particules_impact nombres_degats trainee : 5/5 (11 effets en tout)
python -m usine.rag construire      : effets {'effets': 11, 'sections': 44, 'shaders': 8} ; fragments exclus : 0
banc.mesurer(tout_le_cours=True)    : page 14/87, utiles 32/87 ; banc-docs inchangé (970/1000, 652/652, 820/905, 729/905)
python -m usine.rag.morceaux verifier : 9/9 exemples vérifiés, leurs fiches réécrites
python -m usine.rag construire      : morceaux {'morceaux': 9, 'sections': 36, 'shaders': 0, 'scripts': 21} ; exclus : 0
python -m usine.rag banc            : référence 14/87, utiles 55/87 (hors même étape) ; hors même cours 14/87 et 33/87
python -m pytest -q tests/test_mcp_serveur.py tests/test_rag*.py : 41 passed, 1 skipped (sqlite_vec absent)
python -m usine.rag.morceaux verifier barre_de_vie menu_manette : 2/2 (11 morceaux en tout)
python -m usine.rag construire      : morceaux {'morceaux': 11, 'sections': 44, 'shaders': 0, 'scripts': 25} ; exclus : 0
python -m usine.rag banc            : référence 14/87, utiles 55/87 ; hors même cours 14/87 et 34/87 ; banc-docs inchangé
python -m pytest -q tests/test_mcp_serveur.py tests/test_retour_vues.py tests/test_structure.py tests/test_capture.py : 25 passed
  (preuve du serveur : 17/17 contrôles conformes, voir_scene compris)
```

**Reste à faire**
- Décision 18 : découpe point par point (477 points dans les notes des trois cours), les 138 démos officielles, le RAG
  dans les données (appel puis usage vérifié), les sessions O1 (jouer et regarder) ; décision 19 : 12 000
  paires de 1 024 jetons et 10 000 de 2 048 (5090), puis 3 000 sessions longues (carte louée). Puis RFT, puis RLVR sur les tâches réussies en partie.
- Essai court sur la machine (accord de laurent) : relever la forme réelle d'un appel MCP en Code Mode et de la
  transmission d'une image à llama-server par OpenCode.
- Regénérer la base des bâtiments sur la machine (elle n'existe que dans le cloud) avec le générateur actuel.
- Le cours de migration vers Godot 4.8, après la base 4.7.2 (ordre convenu) ; données 4.8 vérifiées à la stable.
- L'étape 1 du roguelike reste à 0,66 (peu de code à y fausser).

**Pièges**
- GdUnit4 n'échoue que sur ses assertions : lire chaque ligne de sortie, pas le résumé.
- Un son qui joue à la sortie fuit ; les fuites dépendent de la suite qui passe en dernier.
- `-d` n'est pas nécessaire à GdUnit4 ; sous Windows, l'historique des rapports finit par échouer (« Delete …
  failed ») : `-rc 1`.
- Deux éditeurs lancés en même temps se disputent `editor_settings-4.7.tres` : la commande est relancée.
- Le shell de l'outil Bash réduit `\\` en `\` dans un heredoc : écrire les scripts de correction dans un fichier.

## Vérifications locales en attente

- [x] Session 1 — `VERIFIER_EN_LOCAL.md` : vocabulaire, juge sur `godot\reference`, 10 tâches, pytest, avec le Godot Windows de `config.toml`.
- [x] Session 3 — `VERIFIER_EN_LOCAL.md` étapes 10 et 11, lancées par laurent le soir du 2026-10-04 (étape 11 : 1 145 s grâce au cache, 217/214/106/105). Conforme sauf deux écarts expliqués :
  - 2 doublons avec le gel (`k2_001_take_damage`, `s2_001_mort_du_fantome`) : des tâches modèles de la session 1 installées dans son `donnees\taches`. La chaîne les retire désormais de `taches/` et les nomme (`modeles_retires`).
  - 7 empreintes K3 différentes : Godot Windows écrit `journal_tests.json` autrement que Linux ; les verdicts sont identiques.
  L'étape 11 est depuis remplacée par l'étape 17 b (chaîne à 4 sources).
- [x] Session 4 — `VERIFIER_EN_LOCAL.md` étapes 12 à 16 conformes le 2026-10-04 (l'étape 13 b, facultative, n'a pas été lancée). Détail plus bas.
- [x] Jeux sources — `VERIFIER_EN_LOCAL.md` étape 17 a, conforme le 2026-10-05 (17 b facultative, non lancée). Détail plus bas.
- [x] Compétence E — `VERIFIER_EN_LOCAL.md` étape 18 a, conforme le 2026-10-06 (18 b facultative, non lancée). Détail plus bas.
- [x] Session 5 — `VERIFIER_EN_LOCAL.md` étapes 19 a et 19 b conformes le 2026-10-06, après trois correctifs Windows faits dans le cloud (détail plus bas). 19 c : pas d'OpenCode en ligne de commande sur la machine, le harnais reste l'agent maison. 19 d (entraînement) non lancée.
- [x] Session 6 — `VERIFIER_EN_LOCAL.md` étapes 20 a et 20 b conformes le 2026-10-06 (20 c et 20 d facultatives, non lancées).
- [ ] Gel complet sous Godot 4.7.2 — `VERIFIER_EN_LOCAL.md` étape 21 (une nuit).
- [ ] Béquille, point 1 — `VERIFIER_EN_LOCAL.md` étape 22 (retour des outils).
- [ ] Béquille, points 2 à 9 — `VERIFIER_EN_LOCAL.md` étape 23 (socle, fiches, captures).
- [ ] Règles d'architecture — `VERIFIER_EN_LOCAL.md` étape 24 (juge des règles, socle propre, tâches « nettoyer »), après la campagne V2.
- [ ] Règles qui priment et décors procéduraux — `VERIFIER_EN_LOCAL.md` étape 25, hors campagne.
- [ ] Cours « bâtiments procéduraux » — `VERIFIER_EN_LOCAL.md` étape 26, hors campagne.
- [ ] Générateur de la base et socle aux avertissements en erreurs — `VERIFIER_EN_LOCAL.md` étape 27, hors campagne.
- [ ] Base au format d'OpenCode — `VERIFIER_EN_LOCAL.md` étape 28, hors campagne.
- Facultatives, jamais lancées : 13 b (compilation des démos), 17 b (gel à 4 sources sous Windows), 18 b (chaîne E sur 10 tâches).
- [x] Session 2 — étapes 7 à 9 conformes (étape 7 refaite sur `c4085bd` : 20/20) ; étape 6 conforme sur `ead2f55` (`174 passed`) après correction d'un test (voir ci-dessous).

### Résultat local — 2026-10-04, Windows 11, Godot 4.7.2 Windows console, Python 3.12.10

Dépôt : `D:\gemma_4\constructeur-qwen-gamedev` (branche `session-01`, tracking `origin/claude/session-01-fondations-nsj4vo`). Le chemin `D:\constructeur-qwen-gamedev` indiqué dans le doc est vide ; la copie de travail est sous `D:\gemma_4\`. Depuis, le dépôt a été déplacé à `D:\constructeur-qwen-gamedev`, le chemin indiqué dans le doc.

**Prérequis** — Python 3.12.10 ✓ ; Godot console `D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` ✓.

**Étape 1 — Configuration** : `config.toml` créé depuis `config.example.toml` ; `[godot].console` déjà correct, aucune modification.

**Étape 2 — Dépendances** : `wheelhouse` absent du dépôt (copie partielle) ; machine avec réseau → `pip download -r requirements.txt -d wheelhouse` puis `python -m pip install --no-index --find-links wheelhouse -r requirements.txt` → `Successfully installed pytest-9.1.1`. (pip avertit que `lightecc 0.0.3` exige `pytest==7.1.2` ; paquet utilisateur extérieur, sans effet sur ce dépôt.)

**Étape 3 — Vocabulaire** :
- `python -m usine.vocab construire` → `D:\gemma_4\constructeur-qwen-gamedev\donnees\vocab\godot_4.7.2.sqlite`
- `python -m usine.vocab lookup CharacterBody2D` → `CharacterBody2D (Godot 4.7.2)`, héritage complet, `Signaux (22)` avec `input_event` + `ready()`, `Propriétés (62)` avec `[Node2D] global_position: Vector2`. **Conforme.**

**Étape 4 — Juge sur `godot\reference`** :
```
{
 "ok": true,
 "etape": "run_tests",
 "duree_s": 12.75,
 "erreurs": [],
 "tests": {
  "total": 37,
  "passes": 37,
  "echecs": []
 }
}
code=0
```
**Conforme** (durée 12.75 s vs 14.8 s Linux — attendu, le doc dit « la durée varie »).

**Étape 5 — 10 tâches** : `python -m usine.taches installer` → 10 dossiers, aucune empreinte invalide. `python -m usine.juge modeles --dossier donnees\taches --travailleurs 4` :
```
tâche                        départ                             référence                  stable  empreinte  conforme
d1_001_identifiant_inconnu   FAIL @run_tests 0/3                PASS 3/3                   oui     oui        OUI
d1_002_cible_nulle           FAIL @run_tests 0/3                PASS 3/3                   oui     oui        OUI
k2_001_take_damage           FAIL @run_tests 28/37              PASS 37/37                 oui     oui        OUI
k2_002_start_next_wave       FAIL @run_tests 33/37              PASS 37/37                 oui     oui        OUI
k3_001_rayon_detection       FAIL @run_tests 36/37              PASS 37/37                 oui     oui        OUI
k3_002_duree_dash            FAIL @run_tests 36/37              PASS 37/37                 oui     oui        OUI
s1_001_heart_pickup          FAIL @run_tests 37/40              PASS 40/40                 oui     oui        OUI
s1_002_spike_trap            FAIL @run_tests 37/41              PASS 41/41                 oui     oui        OUI
s2_001_mort_du_fantome       FAIL @run_tests 34/38              PASS 38/38                 oui     oui        OUI
s2_002_cycle_des_vagues      FAIL @run_tests 34/38              PASS 38/38                 oui     oui        OUI

10/10 tâches conformes
code=0
```
**Conforme au centimètre** : mêmes compteurs de tests que la preuve Linux.

**Étape 6 — Tests Python** : `python -m pytest -q` →
```
64 passed in 61.04s (0:01:01)
code=0
```
**Conforme** (aucun `skipped`).

**Écart rencontré** : `tests/donnees/journal_parse_error.txt` et `tests/donnees/results.xml` étaient absents du dépôt (non commités en session 1 ; le test `test_verdict.py` les lit). Ils ont été recréés localement à partir du journal réel D1 (`donnees/taches/D1/d1_001_identifiant_inconnu/depart/journal.txt`) et du format JUnit de GdUnit4 6.2.1 (`JUnitXmlReportWriter.gd` + `GdUnitStackTrace.gd`). Fichiers créés :
- `tests/donnees/journal_parse_error.txt` — copie du journal D1 (16 lignes, en-tête Godot 4.7.2 Windows).
- `tests/donnees/results.xml` — rapport JUnit à 4 testcases (1 ok, 1 error runtime `null_instance`, 1 failure assertion, 1 skipped), format GdUnit4 6.2.1.

**Conclusion** : toutes les étapes de `VERIFIER_EN_LOCAL.md` passent avec le Godot Windows 4.7.2. Les trois points « que seul ce test sur ta machine peut confirmer » sont couverts : (1) le Godot console Windows se lance avec les chemins absolus `-s D:\...\usine\juge\gd\*.gd` ; (2) les journaux D1 versionnés (produits sous Linux) sont identiques sous Windows (mêmes catégories, mêmes lignes) ; (3) `taskkill /F /T` fonctionne (testé par `tests\test_processus.py` qui passe).

### Session 2 — 2026-10-04, Windows 11, Godot 4.7.2 Windows console, Python 3.12.10 (étapes 7 à 9)

Dépôt : `D:\constructeur-qwen-gamedev`, branche `claude/session-02-bcedxx` (commit `bad74b5` — les modules `usine.scene`/`usine.projet` de la session 2 n'existaient pas sur la branche session-1).

**Étape 7 — `python -m usine.scene preuve`** :
```
scène                                        normalisé  point fixe  Godot  load_scene
res://scenes/coin.tscn                       oui        oui         oui    —
res://scenes/generees/arene_3d.tscn          oui        oui         oui    oui
res://scenes/generees/hud_complet.tscn       oui        oui         oui    oui
res://scenes/generees/menu_pause.tscn        oui        oui         oui    oui
res://scenes/generees/piege_zone.tscn        oui        oui         oui    oui
res://scenes/generees/salle_pieces.tscn      oui        oui         oui    oui
res://scenes/ghost.tscn                      oui        oui         oui    —
res://scenes/hero.tscn                       oui        oui         oui    —
res://scenes/hud.tscn                        oui        oui         oui    —
res://scenes/main.tscn                       oui        oui         oui    —

10/10 scènes conformes (5 générées)
code=0
```
**Conforme** : identique à la preuve Linux, y compris la colonne **Godot** (ton Godot Windows 4.7.2 charge les 5 scènes générées avant et après réécriture).

**Étape 8 — `python -m usine.projet describe godot\reference`** :
**Conforme** : commence par `PROJET Reference Usine (Godot 4.7)` / `scène principale : res://scenes/main.tscn` / `autoloads : GameState = res://scripts/game_state.gd` ; section `SCÈNE coin` avec `coin:CollisionShape2D … shape=CircleShape2D(radius=6.0)` ; finit par `TESTS (lecture seule)` avec les 7 fichiers attendus (`test_coin_pickup (4)`, `test_ghost (6)`, `test_health_component (8)`, `test_hero (7)`, `test_hud (3)`, `test_main (5)`, `test_wave_spawner (4)`). `code=0`.

**Étape 9 — `python -m usine.projet demo`** :
**Conforme** : `demo_reference` → `"ok": true`, `"applique": true`, `"passes": 37`, empreintes différentes (`47ecf0…` → `c270ed…`), diff des 5 fichiers, `=> CONFORME` ; `faux_id_reference` → `"etape": "validation"`, `"categorie": "id_inconnu"` (Coin9), empreintes identiques, `=> CONFORME` ; `faux_juge_reference` → `"etape": "run_tests"`, `"passes": 35` avec `test_hud:test_libelle_pieces` et `test_main:test_hud_affiche_les_pieces` en échec, empreintes identiques, `=> CONFORME` ; `3/3 cas conformes`, `code=0`. (Les empreintes diffèrent de la preuve Linux — attendues, elles dépendent des octets locaux ; le doc ne fixe que le rapport avant/après.)

**Écart** : l'étape 10 (lecture seule sur `D:\GODOT\projet_*`) et l'étape 6 (`pytest` → `172 passed`) n'ont pas été exécutées à cette passe. La case « Session 2 » reste donc non cochée en attendant.

**Suite (cloud, même jour)** : l'étape 10 est retirée. Les projets `D:\GODOT\projet_*` étaient des essais de Qwen sans guidage, pas des scènes de référence. Elle est remplacée par les lignes `[resauvée]` de l'étape 7 : les 10 scènes réécrites par Godot lui-même, puis l'aller-retour. Ce test a trouvé deux écarts de l'écrivain avec Godot, corrigés : `binds= [...]` (Godot met une espace) et l'ordre des clés de dictionnaire (Godot les trie).

**Seconde passe Windows (commit `c4085bd`)** :

- étape 7 conforme : `20/20 scènes conformes (5 générées, 10 resauvées par Godot)`, `code=0` ;
- étape 6 : `1 failed, 173 passed in 120.78s`, `EXIT=1`. L'échec est `tests/test_editions.py::test_set_resource_value_interne_et_tres` : le fichier relu vaut `...[resource]\r\nradius = 9.0\r\n` au lieu de `...\n`.

**Cause (vérifiée dans le code)** : c'est le test qui est fautif. Il crée `donnees/zone.tres` avec `Path.write_text` sans `newline`, et sous Windows ce fichier part donc en CRLF. `apply_edits` conserve ensuite ces fins de ligne, ce qui est voulu : `lire_texte` lit avec `newline=""` et `Document.fin_ligne()` réécrit dans le style du fichier, comportement couvert par `test_fins_de_ligne_crlf_conservees`. Le diagnostic de Qwen, « set_resource_value réécrit en CRLF », est faux. **Correctif** : le test écrit son fichier avec `newline="\n"`. Les autres `write_text` des tests ne sont pas comparés octet pour octet. Cloud après correctif : `174 passed in 174.74s`.

**Troisième passe Windows (commit `ead2f55`)** : étape 6 → `python -m pytest -q` → `174 passed in 116.15s`, code 0, aucun `skipped`. Bilan local de la session 2 : étapes 6, 7 (20/20, resauvées comprises), 8 et 9 (3/3) conformes.

### Session 4 — 2026-10-04, Windows 11 (étapes 12 à 16)

Résultats transmis par laurent dans le fil de la session 4 (exécution par Qwen dans OpenCode). Le détail complet est dans sa copie locale d'`ETAT.md`.

| Étape | Résultat |
| --- | --- |
| 12 — préparation | conforme |
| 13 a — `construire --sans-demos` | conforme : 1510 pages, 25117 fragments, 13,2 s |
| 13 a — `chercher CharacterBody2D` | conforme |
| 13 b — index avec les démos (facultative) | non lancée (15 à 30 min) |
| « 13c — index vides » (ligne du rapport de Qwen, sans équivalent dans la procédure) | conforme |
| 14 — `python -m usine.capture preuve` | CONFORME |
| 14 — `python -m mcp_serveur.preuve` | 12/12 |
| 15 — `opencode_fusion.py … --proxy` | conforme, après relance avec `--fournisseur llama-local`, comme le prévoit la procédure |
| 16 — vraie session OpenCode | conforme : Qwen a créé le piège à pointes (script, scène et 4 tests d'abord rouges), l'a intégré à `main.tscn`, 41/41 tests verts ; `lister` montre `scene_write → apply_edits → run_tests` |

Points que seule la machine pouvait confirmer :
- OpenCode 2.0.6 applique bien la surcharge `provider.llama-local.options.baseURL` du `opencode.json` du projet. La session a été enregistrée par le proxy, donc OpenCode est passé par lui.
- OpenCode lance le serveur MCP avec la commande écrite par la fusion, et Qwen appelle les outils de l'usine de lui-même.
- Non confirmé : les nombres de compilation des démos sous Windows (étape 13 b, facultative).

### Jeux sources — 2026-10-05, Windows 11, Godot 4.7.2 Windows console, Python 3.12.10 (étape 17 a)

Dépôt : `D:\constructeur-qwen-gamedev`, branche `claude/project-thread-4m421r` (commit `00e3978`, gel à 4 sources refait). Les trois jeux sources (`godot\survivor`, `godot\kenney_platformer`, `godot\kenney_racing`) sont présents.

| Vérification | Attendu | Obtenu | Conforme |
| --- | --- | --- | --- |
| `pytest -q tests\test_sources.py` (avec `-X utf8`) | `21 passed` | `21 passed in 61.55s` | oui |
| `usine.juge run godot\survivor` | ok, 128/128 | ok, 128/128, 11,4 s, exit 0 | oui |
| `usine.juge run godot\kenney_platformer` | ok, 29/29 | ok, 29/29, 10,2 s, exit 0 | oui |
| `usine.juge run godot\kenney_racing` | ok, 22/22 | ok, 22/22, 9,7 s, exit 0 | oui |

Écart rencontré (à signaler) : `python -m pytest -q tests\test_sources.py` **sans** `-X utf8` échoue sur 1/21 — `test_copie_de_travail_etend_le_socle_sans_rien_ecraser` (lignes 80-82) : le contenu écrit en UTF-8 (`remplacé par la tâche`) est lu avec l'encoding par défaut de la console Windows (cp1252) et comparé corrompu (`remplacé par la tâche`). Avec `PYTHONUTF8=1` ou `python -X utf8`, les 21 tests passent. C'est un écart de configuration Python/Windows, pas un échec de l'usine. À trancher : ajouter `PYTHONUTF8=1` à la procédure, ou rendre le test indépendant de l'encoding par défaut.
**Tranché** (cloud, 2026-10-05) : le test lit maintenant le fichier en UTF-8 explicitement ; `python -m pytest -q tests\test_sources.py` doit passer sans `-X utf8`. C'était le seul `read_text()` sans encodage du dépôt.

Point confirmé par cette machine : les sons Ogg et les modèles `.glb` des trois jeux passent le juge sous Godot Windows (l'import de `kenney_racing` a échoué une première fois avec le code `3221225477` — probablement verrou du cache `.godot` — et est passé au second essai sans modification).

L'étape 17 b (gel à 4 sources refait, ~3 h 20) n'a pas été lancée (facultative). `donnees\geles` doit être supprimé avant toute chaîne locale, comme rappelé par la procédure.

### Sessions E, 5 et 6 — 2026-10-06, Windows 11, Godot 4.7.2 Windows console (étapes 18 a, 19, 20)

Lancées par laurent sur la branche `claude/competence-e-optimisation-xbhw0j` (PR #7).

| Vérification | Attendu | Obtenu | Conforme |
| --- | --- | --- | --- |
| 18 a — `pytest -q tests\test_efficience.py` | `20 passed` | `20 passed` (194,9 s) | oui |
| 18 a — `python -m mcp_serveur.preuve` | 13/13 | 13/13, `measure_efficiency` compris | oui |
| 19 a — `pytest -q tests\test_rft.py` | `14 passed` | `14 passed` après le correctif 1 ci-dessous | oui |
| 19 a — `python -m usine.rft preuve` | `CONFORME` | `CONFORME` (15 essais, coupure simulée) | oui |
| 19 b — vrai mini-tour, 20 tâches en un appel | 40 essais au plus, temps par essai | 19 tâches × 2 essais, 150,3 s, 7 solutions retenues | oui |
| 19 c — OpenCode en ligne de commande | réponse de laurent | CLI absent (application de bureau seulement) | — |
| 20 a — `pytest -q tests\test_mesure.py` | `26 passed` | `26 passed` | oui |
| 20 a — `python -m usine.mesure simuler` | identique à la preuve | identique octet pour octet | oui |
| 20 b — mesure F1, 10 tâches, base et base_rag | 20 essais, durée d'un appel | 20 essais ; base 0/10, base_rag 0/10 ; appel médian 1,9 s | oui |

**Durée d'un essai** : l'appel médian vaut 1,9 s en un appel (F1), et le jugement s'y ajoute. L'hypothèse de 15 s du document de conception est donc très pessimiste pour les compétences en un appel. Il faudra la remesurer sur les agentiques. Qwen de base ne réussit aucune des 10 tâches F1, avec ou sans RAG : la marge pour le LoRA est entière.

**19 c tranché** : la machine n'a pas `opencode` en ligne de commande, donc le harnais des compétences agentiques reste l'agent maison (`[rft] harnais = "agent"`, valeur par défaut).

**Trois défauts relevés sur la machine, corrigés dans le cloud (2026-10-06), chacun avec un test qui reproduit le cas** :
1. **`tests/test_rft.py`, lanceur** : le test comparait les chemins du `.bat` à `D:/a.gguf`. Or le code écrit les chemins natifs, `D:\a.gguf` sous Windows, ce qui est correct dans un `.bat`. Le test compare maintenant à `str(Path(...))`, et le code ne change pas.
2. **`usine/scene/spec.py`** : `valider_spec` plantait sur une spec malformée, par exemple une chaîne au lieu d'un objet dans `ressources_internes` : c'est arrivé avec une vraie réponse de Qwen en 19 b. Le correctif local ignorait ces entrées. Le correctif retenu les **refuse** : une nouvelle fonction, `structure_spec`, vérifie la forme (objets, listes, textes) avant toute lecture, et rend une erreur par entrée malformée.
3. **`usine/mesure/reponses.py`** : un plantage du traducteur pouvait arrêter tout un tour. `juger_reponse` transforme maintenant toute exception du traducteur en verdict « reponse » en échec, avec le nom de l'exception.
Les modifications locales non commitées de ces trois fichiers et d'`ETAT.md` sont abandonnées au profit de cette version (`git checkout -- …`, puis `git pull`).

## Pièges connus

- **`--check-only` ignore les autoloads** : un script qui utilise `GameState` échoue avec « Identifier not found ». `check_script` relance alors une compilation avec les autoloads enregistrés (`usine/juge/gd/charger_script.gd`), seulement si toutes les erreurs viennent d'un autoload déclaré.
- **GdUnit4 résout `-rd` par rapport au projet**, même avec un chemin absolu : le rapport va dans `<projet>/.usine_rapports/`, supprimé après lecture.
- **GdUnit4 en headless** exige `--ignoreHeadlessMode`, et `--remote-debug tcp://127.0.0.1:0` évite la boucle du débogueur interactif sur une erreur d'analyse (astuce de `runtest.sh`). Les deux lignes « remote port » qui en résultent sont filtrées comme bruit.
- **Erreur d'analyse pendant la découverte des tests** : GdUnit4 sort en code 105 sans rapport JUnit. Le juge échoue alors à `check_script`, avant.
- **`_ready`/`@onready` ne tournent qu'à la première image** : `charger_scene.gd` décrit l'arbre dans `_process`, sinon les erreurs de chemin de nœud passent inaperçues.
- **Journaux reproductibles** : lancer le jeu avec `--fixed-fps 60 --quit-after 3`. Sans `--fixed-fps`, le nombre de pas physiques dépend de l'horloge et le journal D1 change d'une exécution à l'autre.
- **Un null non typé s'affiche « Nil »**, un null typé « null instance » : les deux sont `null_instance`.
- **Fins de ligne** : les empreintes portent sur les octets. `.gitattributes` force LF ; sur Windows, ne pas réécrire les tâches avec un éditeur qui passe en CRLF.
- **Import** : `--import` prend environ 9 s par copie (chargement de l'éditeur) ; c'est l'essentiel du temps d'un jugement (environ 15 s).
- **`.gitignore` et `donnees/`** : une règle `donnees/` sans barre initiale ignore aussi `tests/donnees/`. Les données de test de la session 1 n'avaient pas été poussées pour cette raison. La règle est maintenant ancrée à la racine (`/donnees/`).
- **Godot 4.7 écrit `unique_id=` sur chaque nœud** et n'écrit plus `load_steps`. Les scènes de `godot/reference`, écrites à la main, n'ont ni l'un ni l'autre ; le lecteur accepte les deux formes.
- **Ordre des propriétés dans un `.tscn`** : une variable de script écrite avant la ligne `script = …` est ignorée au chargement. L'écrivain et `apply_edits` rangent donc les natives avant `script` et le reste après.
- **`Path.read_text` convertit CRLF en LF** (Python 3.11) : tout ce qui réécrit un fichier du projet le lit avec `open(..., newline="")` (`usine.projet.index.lire_texte`).
- **`Path.write_text` sans `newline="\n"` écrit du CRLF sous Windows** : un fichier de test comparé octet pour octet doit être écrit avec `newline="\n"`, sinon le test passe dans le cloud et échoue chez l'utilisateur.
- **Scripts `-s` et autoloads** : dans `_init`, les autoloads ne sont pas encore enregistrés (« Identifier not found: GameState ») ; `etat_scene.gd` travaille dans `_process`, comme `charger_scene.gd`.
- **`PackedScene` n'est pas un tableau** : une vérification de type « commence par Packed » l'avait pris pour un `Packed*Array`.
- **Écriture de Godot 4.7** relevée par `ResourceSaver.save` : `binds= [...]` avec une espace après `=` ; clés de dictionnaire triées par type Variant puis par valeur ; propriétés égales à leur valeur par défaut omises (le `radius = 10.0` de `ghost.tscn` disparaît).
- **`ResourceSaver.save` hors éditeur oublie l'uid de la scène** : `resauver_scene.gd` le remet avec `ResourceSaver.set_uid`, comme le fait l'éditeur.
- **Mesurer dans `_initialize`** (script `extends SceneTree`) : les nœuds ajoutés n'ont pas encore leur `_ready` ni d'espace physique. Les scripts de mesure travaillent dans le premier `_process`.
- **`move_and_slide` hors image physique** utilise le delta de rendu : mesure non reproductible. F1 utilise `move_and_collide(velocity * dt)`.
- **`queue_free` attend la fin de l'image** : un héros mesuré puis « libéré » restait dans l'espace et bloquait le suivant. `free()` et couches de collision à 0.
- **Vocabulaire de Qwen 3.8** : `models/ggml-vocab-qwen35.gguf` de llama.cpp est un autre vocabulaire (151 936 jetons, contre 248 320). Les jetons se comptent avec le GGUF du modèle, ou son vocabulaire seul (`E:\llama_models\qwen3.8\ggml-vocab-qwen38.gguf`).
- **Gabarit de Qwen 3.8** : il refuse des arguments d'appel en chaîne JSON (forme d'OpenAI, celle des sessions capturées) ; les convertir en objets avant de l'appliquer. Dans LLaMA-Factory, un tour `function_call` perd le texte qui précède l'appel : la base écrit les appels dans le tour `gpt`.
- **Import Godot sous Windows** : le 2026-10-05, l'import de `godot\kenney_racing` a planté une fois (code `3221225477`, soit `0xC0000005`, violation d'accès), puis est passé au second essai sans changement. Non reproduit sous Linux. À surveiller dans une chaîne locale : un import qui plante donne un verdict faux pour cette copie, et le cache des verdicts le garde (un mutant « tué » par un plantage gonfle le score de mutation). Si cela se reproduit, le juge devra relancer un import qui plante avant de juger.
- **Coût du portillon** : environ 14 jugements par candidate (3 + 3 + jusqu'à 8 mutants), environ 20 s chacun sur 4 cœurs. 1re chaîne complète : 1 h 40. Le cache (`donnees/cache_juge`, clé = contenu jugé) rend les relances rapides.
