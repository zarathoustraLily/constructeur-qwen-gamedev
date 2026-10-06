# ETAT — journal de reprise

À mettre à jour à la fin de **chaque** session : ce qui est fait, la preuve de fin collée telle quelle, ce qui reste, les pièges rencontrés.

## Avancement

- [x] Session 1 — Vocabulaire, juge commun, projet de référence, 10 tâches
- [x] Session 2 — Traducteurs déterministes (scène ↔ spec, description du projet, éditions)
- [x] Session 3 — Usine à tâches, portillon, jeux gelés
- [x] Session 4 — RAG Godot, serveur MCP, fiches de compétences, enregistreur
- [x] Avant la session 5 — jeux sources supplémentaires (survivor, kits Kenney), gel à 4 sources (172 tâches)
- [x] Avant la session 5 — compétence E « optimisation stricte » (gel en attente de Godot 4.8 stable)
- [x] Session 5 — Boucle RFT (cloud : code et preuve ; vrai tour après le gel 4.8)
- [x] Session 6 — Mesure (cloud : code et preuve simulée ; mesure réelle après le premier LoRA et le gel 4.8)

## Bilan des 6 sessions (2026-10-05)

| Étape | État dans le cloud | Vérifié sur la machine de laurent |
| --- | --- | --- |
| Session 1 — vocabulaire, juge, projet de référence | fait | oui (étapes 1 à 5) |
| Session 2 — traducteurs déterministes | fait | oui (étapes 6 à 9) |
| Session 3 — usine à tâches, portillon, gel | fait ; le gel a été refait à 4 sources (172 tâches) | oui (étapes 10 et 11, remplacées par 17 b) |
| Session 4 — RAG, serveur MCP, fiches, enregistreur | fait | oui (étapes 12 à 16 ; 13 b facultative non lancée) |
| Avant la session 5 — jeux sources (survivor, Kenney) | fait | oui (17 a ; 17 b facultative non lancée) |
| Avant la session 5 — compétence E | fait, PR #6 fusionnée ; **gel en attente de Godot 4.8 stable** | oui (18 a, 2026-10-06) |
| Session 5 — boucle RFT | fait (code, preuve : mini-tour contre un faux serveur juste à 60 %, vrai juge) ; harnais OpenCode à confirmer | oui (19 a et 19 b, 2026-10-06) ; 19 c : pas de CLI OpenCode, harnais = agent maison |
| Session 6 — mesure | fait (code, preuve sur résultats simulés ; agentiques mesurées par l'agent maison) ; la mesure réelle attend le premier LoRA et le gel 4.8 | oui (20 a et 20 b, 2026-10-06) |

Ordre conseillé pour la suite :
1. migration vers Godot 4.8 stable et gel complet (section E) ;
2. premier tour RFT (`python -m usine.rft tour`), entraînement, GGUF, lanceur (19 d) ;
3. mesure réelle (`python -m usine.mesure executer`, puis `rapport`, puis `regression` après chaque tour).

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
- **Import Godot sous Windows** : le 2026-10-05, l'import de `godot\kenney_racing` a planté une fois (code `3221225477`, soit `0xC0000005`, violation d'accès), puis est passé au second essai sans changement. Non reproduit sous Linux. À surveiller dans une chaîne locale : un import qui plante donne un verdict faux pour cette copie, et le cache des verdicts le garde (un mutant « tué » par un plantage gonfle le score de mutation). Si cela se reproduit, le juge devra relancer un import qui plante avant de juger.
- **Coût du portillon** : environ 14 jugements par candidate (3 + 3 + jusqu'à 8 mutants), environ 20 s chacun sur 4 cœurs. 1re chaîne complète : 1 h 40. Le cache (`donnees/cache_juge`, clé = contenu jugé) rend les relances rapides.
