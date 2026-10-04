# Vérifier en local (Windows 11, cmd.exe)

Ces commandes rejouent sur ta machine la preuve de fin de la session 1, avec ton Godot 4.7.2 Windows.
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

Attendu : `64 passed` et aucun `skipped` (si Godot est introuvable, les tests moteur apparaissent en `skipped`).

## Points que seul ce test sur ta machine peut confirmer

- Le Godot **Windows** console se lance avec un chemin absolu Windows vers les scripts du juge (`-s D:\...\usine\juge\gd\charger_scene.gd`). C'est vérifié sur Linux uniquement.
- Les journaux D1 versionnés ont été produits sous Linux. Sous Windows, les numéros de ligne et les catégories sont identiques ; seul le texte d'en-tête du moteur peut différer. Le test D1 ne lit que `reponse.json`, donc le verdict ne change pas.
- La coupure sur délai utilise `taskkill /F /T /PID <pid lancé par nous>` (testé par `tests\test_processus.py`).
