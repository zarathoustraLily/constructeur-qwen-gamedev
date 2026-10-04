# ETAT — journal de reprise

À mettre à jour à la fin de **chaque** session : ce qui est fait, la preuve de fin collée telle quelle, ce qui reste, les pièges rencontrés.

## Avancement

- [x] Session 1 — Vocabulaire, juge commun, projet de référence, 10 tâches
- [ ] Session 2 — Traducteurs déterministes (scène ↔ spec, description du projet, éditions)
- [ ] Session 3 — Usine à tâches, portillon, jeux gelés
- [ ] Session 4 — RAG Godot, serveur MCP, fiches de compétences, enregistreur
- [ ] Session 5 — Boucle RFT
- [ ] Session 6 — Mesure

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

## Vérifications locales en attente

- [x] Session 1 — `VERIFIER_EN_LOCAL.md` : vocabulaire, juge sur `godot\reference`, 10 tâches, pytest, avec le Godot Windows de `config.toml`.

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
