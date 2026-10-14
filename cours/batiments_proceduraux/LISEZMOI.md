# Cours « bâtiments procéduraux » (Godot 4.7.2)

Trois immeubles procéduraux, construits pas à pas : un immeuble haussmannien (Paris), un petit
immeuble sur parcelle étroite (Tokyo), une tour de bureaux et son quartier (New York). Treize
étapes par ville : le mur, les shaders de matière, les fenêtres et la pièce derrière la vitre, les
niveaux, les balcons, les moulures, le toit, le rez-de-chaussée, la graine, la rue, les niveaux de
détail. Chaque étape est un projet Godot complet, rangé selon le plan d'organisation du dépôt.

Ce cours est la source de la base d'entraînement « bâtiments procéduraux » : `python -m usine.cours.base tout`
(générateur dans `usine/cours/base/`, sorties dans `donnees/cours/batiments_proceduraux/base/livraison/`).

## Contenu

| Dossier | Ce qu'il contient |
| --- | --- |
| `maitres/<ville>/` | Les fichiers maîtres : le code de toutes les étapes, balisé par étape (`#@ 4+`, `//@ 2-6`…) |
| `commun/` | Ce que les trois villes partagent : outil de maillage, fonctions de shader communes, visite des étapes, réglages du projet |
| `notes/<ville>/` | La note de chaque étape (`etape_NNN.md`, devenue le `README.md` du projet) et la comparaison avec la ville jumelle (`jumeau_NNN.md`) |
| `recherches/` | Les carnets de recherche de Tokyo et de New York : sources de métier lues, citations exactes |
| `manifeste.py` | Quel maître existe à quelle étape, les scènes et la visite de chaque étape |

## Fabriquer, juger, vérifier

```bat
python -m usine.cours fabriquer batiments_proceduraux
python -m usine.cours juger batiments_proceduraux
python -m usine.cours verifier batiments_proceduraux --travailleurs 2
```

- `fabriquer` écrit les 39 projets dans `donnees/cours/batiments_proceduraux/projets/` (ignoré par git).
  Règle 5 : une erreur se corrige dans les maîtres, jamais dans un projet fabriqué.
- `juger` passe le juge des règles d'architecture sur chaque projet : 0 écart attendu.
- `verifier` lance en plus Godot 4.7.2 sur chaque projet : import, analyse de chaque script (avertissements
  traités en erreurs), test de l'étape, une image en Compatibilité (les shaders ne se compilent qu'au rendu).
  `--sans-rendu` saute l'image.

## Règles que le cours suit

- **Rangement des décors procéduraux** (`CLAUDE.md`, « Règles qui priment », section 6) : générateurs `@tool` et
  scènes dans `6_assets/Mesh/Procedural/DECORS/Building/`, shaders dans `6_assets/Shader/Procedural/DECORS/Building/`,
  palettes et cotes dans `5_data/DECORS/Building/`, outils communs dans `1_core/procedural/` et
  `6_assets/Shader/Procedural/`, tests dans `7_tests/` en miroir.
- **Avertissements en erreurs** (section 5, règle 3) : le bloc `[debug]` de chaque `project.godot` met les
  avertissements de GDScript à 2, typage compris.
- **Tableaux et dictionnaires typés** (COD-02). Les lignes mêlées d'une table de données (`Array[Array]`) sont
  converties en type précis à l'endroit où on les lit : `PackedStringArray(Palette.SHOP_NAMES[i])`.
- **La visite des étapes suit le plan comme le reste** : la caméra libre ne lit pas le clavier
  (`1_core/camera/free_camera_input.gd` lui donne des intentions) et avance au pas de la physique ; les
  réglages de la visite (ciel, soleil, sol, cadrage, qualité) vivent dans `5_data/visit/visit_settings.tres`,
  avec leur classe `1_core/data/visit_settings.gd` ; la mesure du rendu est dans le bandeau (`4_ui`).

## Pièges relevés en route (Godot 4.7.2)

- Une constante `Array[PackedStringArray]` écrite en tableaux littéraux imbriqués, dans la palette de New York,
  passe l'analyse mais fait planter le moteur au test de l'étape (signal 11). Écrite avec
  `PackedStringArray([...])` par ligne, elle est refusée : « isn't a constant expression ». Un cas réduit à deux
  scripts ne plante pas : la cause exacte n'est pas isolée. Le cours garde donc `Array[Array]` et convertit à la
  lecture.
- Un test qui finit avec le code 0 peut contenir des « SCRIPT ERROR » : on lit chaque ligne (section 5, règle 5).
- Avec `--path`, Godot travaille depuis le dossier du projet : un chemin relatif passé à `--shot` est compté
  depuis là.
