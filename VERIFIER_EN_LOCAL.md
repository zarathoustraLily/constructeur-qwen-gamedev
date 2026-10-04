# Vérifier en local (Windows 11, cmd.exe)

Ces commandes rejouent sur ta machine les preuves de fin des sessions 1 à 3, avec ton Godot 4.7.2 Windows.
Pour la session 2 seule : étapes 1 et 2 si ce n'est pas déjà fait, puis 7 à 9, puis 6.
Pour la session 3 seule : étape 6, puis 10 et 11 (l'étape 11 est longue : lance-la quand le PC peut tourner une à deux heures).
Côté machine, **c'est ce document qui fait foi**. Note le résultat dans `ETAT.md`, section « Vérifications locales en attente ».

## 0. Prérequis

- Python **3.11 ou plus récent** (`tomllib`). Vérifier : `python --version`.
- Le dépôt à jour (par exemple `D:\constructeur-qwen-gamedev`).

## 1. Configuration (une seule fois)

```bat
cd /d D:\constructeur-qwen-gamedev
copy config.example.toml config.toml
```

Ouvrir `config.toml` et vérifier `[godot].console` :

```toml
console = 'D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
```

Les valeurs `A_RENSEIGNER` des autres sections ne servent pas encore.

## 2. Dépendances Python (hors-ligne)

Sur le mini-PC connecté, une fois : `pip download -r requirements.txt -d wheelhouse`, puis copier `wheelhouse\` avec le dépôt.

```bat
python -m pip install --no-index --find-links wheelhouse -r requirements.txt
```

Attendu : `Successfully installed ... pytest-...` (ou « Requirement already satisfied »).

## 3. Vocabulaire

```bat
python -m usine.vocab construire
python -m usine.vocab lookup CharacterBody2D
```

Attendu :
- la première commande affiche le chemin de `donnees\vocab\godot_4.7.2.sqlite` ;
- la seconde commence par `CharacterBody2D (Godot 4.7.2)` puis `Héritage : CharacterBody2D → PhysicsBody2D → CollisionObject2D → Node2D → CanvasItem → Node → Object` ;
- on y trouve `Signaux (22)` avec `[CollisionObject2D] input_event(viewport: Node, event: InputEvent, shape_idx: int)` et `[Node] ready()` ;
- puis `Propriétés (62)` avec `[Node2D] global_position: Vector2`.

Si la version affichée n'est pas 4.7.2, c'est que `config.toml` pointe vers un autre Godot.

## 4. Juge sur le projet de référence

```bat
python -m usine.juge run godot\reference
echo %ERRORLEVEL%
```

Attendu (la durée varie) :

```
{
 "ok": true,
 "etape": "run_tests",
 "duree_s": ...,
 "erreurs": [],
 "tests": {
  "total": 37,
  "passes": 37,
  "echecs": []
 }
}
0
```

## 5. Les 10 tâches : FAIL sur depart, PASS sur reference, deux fois

```bat
python -m usine.taches installer
python -m usine.juge modeles --dossier donnees\taches --travailleurs 4
echo %ERRORLEVEL%
```

Attendu : dix lignes, toutes avec `FAIL` en départ, `PASS` en référence, `oui` pour stable et empreinte, `OUI` pour conforme ; puis `10/10 tâches conformes` et `0`. Les colonnes de tests attendues :

```
d1_001_identifiant_inconnu   FAIL @run_tests 0/3                PASS 3/3
d1_002_cible_nulle           FAIL @run_tests 0/3                PASS 3/3
k2_001_take_damage           FAIL @run_tests 28/37              PASS 37/37
k2_002_start_next_wave       FAIL @run_tests 33/37              PASS 37/37
k3_001_rayon_detection       FAIL @run_tests 36/37              PASS 37/37
k3_002_duree_dash            FAIL @run_tests 36/37              PASS 37/37
s1_001_heart_pickup          FAIL @run_tests 37/40              PASS 40/40
s1_002_spike_trap            FAIL @run_tests 37/41              PASS 41/41
s2_001_mort_du_fantome       FAIL @run_tests 34/38              PASS 38/38
s2_002_cycle_des_vagues      FAIL @run_tests 34/38              PASS 38/38
```

Compter quelques minutes (environ 15 s par jugement, 40 jugements).

Si `python -m usine.taches installer` signale une **empreinte invalide**, les fichiers ont probablement été convertis en CRLF (git `core.autocrlf`). Le dépôt a un `.gitattributes` qui force LF : refaire un `git checkout` propre, ou cloner avec `git -c core.autocrlf=false clone ...`.

## 6. Tests Python

```bat
python -m pytest -q
```

Attendu : `208 passed` et aucun `skipped` (si Godot est introuvable, les tests moteur apparaissent en `skipped`).

## 7. Session 2 — aller-retour des scènes (.tscn → spec → .tscn)

```bat
python -m usine.scene preuve
echo %ERRORLEVEL%
```

Attendu (une vingtaine de secondes) :

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
0
```

La colonne **Godot** compare ce que ton Godot Windows charge avant et après réécriture. Les lignes `[resauvée]` rejouent l'aller-retour sur les mêmes scènes réécrites par ton Godot lui-même (le format de l'éditeur). La colonne **= Godot** dit que les scènes générées par l'usine sont identiques, octet pour octet, à ce que Godot écrit.

## 8. Session 2 — vue du projet

```bat
python -m usine.projet describe godot\reference
```

Attendu : commence par

```
PROJET Reference Usine (Godot 4.7)
scène principale : res://scenes/main.tscn
autoloads : GameState = res://scripts/game_state.gd
ids : <scène>:<chemin du nœud> ; ressource interne : <id>#<propriété>

SCÈNE coin = res://scenes/coin.tscn
  coin  Area2D  script res://scripts/coin_pickup.gd
    coin:CollisionShape2D  CollisionShape2D  shape=CircleShape2D(radius=6.0)
```

et finit par la section `TESTS (lecture seule)` avec 7 fichiers (`res://tests/test_hero.gd (7 tests)`…).

## 9. Session 2 — éditions : démo PASS, éditions fausses refusées

```bat
python -m usine.projet demo
echo %ERRORLEVEL%
```

Attendu (moins d'une minute ; tout se passe dans une copie temporaire, `godot\reference` n'est pas touché) :

- `== demo_reference` : `"ok": true`, `"applique": true`, `"passes": 37`, deux empreintes **différentes**, puis le diff des 5 fichiers modifiés, puis `=> CONFORME` ;
- `== faux_id_reference` : `"etape": "validation"`, `"categorie": "id_inconnu"` (Coin9), deux empreintes **identiques**, `=> CONFORME` ;
- `== faux_juge_reference` : `"etape": "run_tests"`, `"passes": 35` avec `test_hud:test_libelle_pieces` et `test_main:test_hud_affiche_les_pieces` en échec, deux empreintes **identiques**, `=> CONFORME` ;
- puis `3/3 cas conformes` et `0`.

## 10. Session 3 — une proposition inventée et l'exclusion des jeux gelés

```bat
python -m usine.generateurs invention tests\donnees\invention_exemple.json --sortie %TEMP%\usine_inv
echo %ERRORLEVEL%
```

Attendu **avant** l'étape 11 (aucun gel sur ta machine) : `"ok": true` et un dossier `k3_inv_reference_exemple_fictif_add_coins_…`, puis `0`.

Attendu **après** l'étape 11 : `"ok": false` avec
`doublon_fragments : la proposition double la tâche gelée k3_reference_game_state_l12_operateur_arithmetique`, puis `1`.
C'est voulu : l'exemple fictif corrige la même ligne (`coins += amount`) qu'une tâche gelée, et l'exclusion s'applique aussi à l'invention.

## 11. Session 3 — chaîne complète : candidates, portillon, gel, tâches acceptées

Longue (dans le cloud, 4 cœurs : environ 1 h 40 sans cache). Les verdicts sont mis en cache dans `donnees\cache_juge` : une relance ne refait que ce qui manque.

```bat
python -m usine.portillon chaine --graine 1 --f1 80
echo %ERRORLEVEL%
python -m usine.portillon comparer donnees\portillon\rapport.json preuves\rapport_chaine_graine1.json
echo %ERRORLEVEL%
```

Attendu pour la chaîne : le tableau ci-dessous, puis `Doublons avec les jeux gelés dans taches/ : 0` et `0`.

```
compétence  candidates qualifiées  gelées acceptées  rejets
D1                   8          8       4         1  doublon_gele 3
F1                  80         80      40        40  —
K1                   8          8       4         4  —
K2                  30         27      13        14  depart_pas_rouge 2, score_mutation_insuffisant 1
K3                  72         72      36        36  —
S1                  10         10       5         5  —
S2                   9          9       4         5  —
TOTAL              217        214     106       105
```

Attendu pour `comparer` (rapport Windows contre rapport du cloud, versionné dans `preuves\`) : 7 lignes `identique`, `Résultat identique`, `0`.
Seule différence admissible : `acceptees_empreintes` sur des tâches `d1_…`, si l'en-tête du journal Godot Windows diffère de Linux. Si c'est le cas, note les ids concernés dans `ETAT.md`. Toute autre différence est un écart à signaler.

Si `donnees\geles\manifeste.json` existe déjà, il est **réutilisé** (le gel ne se refait jamais tout seul). Pour rejouer le tirage, supprime `donnees\geles` avant de lancer la chaîne.

## Points que seul ce test sur ta machine peut confirmer

- Le Godot **Windows** console se lance avec un chemin absolu Windows vers les scripts du juge (`-s D:\...\usine\juge\gd\charger_scene.gd`). C'est vérifié sur Linux uniquement.
- Les journaux D1 versionnés ont été produits sous Linux. Sous Windows, les numéros de ligne et les catégories sont identiques ; seul le texte d'en-tête du moteur peut différer. Le test D1 ne lit que `reponse.json`, donc le verdict ne change pas.
- Session 2 : le remplacement atomique `os.replace` sur NTFS, et le chargement par ton Godot Windows des scènes réécrites et resauvées (colonnes Godot et = Godot de l'étape 7).
- La coupure sur délai utilise `taskkill /F /T /PID <pid lancé par nous>` (testé par `tests\test_processus.py`).
- Session 3 : les mesures faites par Godot Windows (interfaces K1, état des scènes S1, mesures F1 en frames) donnent les mêmes vérités terrain que sous Linux, donc les mêmes empreintes (étape 11, `comparer`).
