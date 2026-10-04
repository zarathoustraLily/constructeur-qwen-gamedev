# ETAT — journal de reprise

À mettre à jour à la fin de **chaque** session : ce qui est fait, la preuve de fin collée telle quelle, ce qui reste, les pièges rencontrés.

## Avancement

- [x] Session 1 — Vocabulaire, juge commun, projet de référence, 10 tâches
- [x] Session 2 — Traducteurs déterministes (scène ↔ spec, description du projet, éditions)
- [x] Session 3 — Usine à tâches, portillon, jeux gelés
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

## Vérifications locales en attente

- [x] Session 1 — `VERIFIER_EN_LOCAL.md` : vocabulaire, juge sur `godot\reference`, 10 tâches, pytest, avec le Godot Windows de `config.toml`.
- [ ] Session 3 — `VERIFIER_EN_LOCAL.md` étapes 6, 10 et 11 (chaîne graine 1, `comparer` avec `preuves\rapport_chaine_graine1.json`).
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
- **Coût du portillon** : environ 14 jugements par candidate (3 + 3 + jusqu'à 8 mutants), environ 20 s chacun sur 4 cœurs. 1re chaîne complète : 1 h 40. Le cache (`donnees/cache_juge`, clé = contenu jugé) rend les relances rapides.
