# État de construction - Space Dracula

## Date : 2026-10-10

## Statut : Jeu jouable, 123 fiches .tres, boucle de jeu complète, A_TRADUIRE prêt (274 fichiers, 0 token original)

## Ce qui est fait

### 1. Analyse de la carte de données source
- [x] Lecture de `00_inventory.md`, `01_schemas.md`, `05_systems.md`
- [x] Lecture de `param_dictionary.json` (439 params)
- [x] Lecture de `props.jsonl` (3371 records)
- [x] Lecture de `graph.jsonl` (16706 nœuds)
- [x] Lecture de `identity_map.json` (160 entités)

### 2. Renommage Space Dracula
- [x] `MAPPING_SPACE_DRACULA.json` : 370 codes anonymisés (0 nom original)
- [x] `MAPPING_RENOMMAGE.json` : 160 entités mappées
- [x] Vérification : aucun token original dans les fiches v2

### 3. Fiches générées (JSON)
- [x] `FICHES_ENNEMIS_V2.json` : 61 ennemis (CRT-001 à CRT-061)
- [x] `FICHES_BOSSES_V2.json` : 7 bosses (ANO-001 à ANO-007), 96 attaques, 30 phases
- [x] `FICHES_ARMES_V2.json` : 34 armes (REL-001 à REL-034)
- [x] `FICHES_MINI_BOSSES_V2.json` : 12 mini-bosses (MIN-001 à MIN-012), 60 attaques
- [x] `FICHES_SALLES_V2.json` : 8 salles (SLA-01 à SLA-08), clés françaises

### 4. Conversion JSON → .tres Godot
- [x] 7 classes Resource (FicheHeros, FicheEnnemi, FicheBoss, FicheMiniBoss, FicheArme, FicheSalle, FicheOutil)
- [x] 61 fichiers `CRT-XXX.tres`
- [x] 7 fichiers `ANO-XXX.tres`
- [x] 34 fichiers `REL-XXX.tres`
- [x] 12 fichiers `MIN-XXX.tres`
- [x] 8 fichiers `SLA-XX.tres`
- [x] 1 fichier `HEROS.tres`
- [x] Total : 123 fichiers .tres
- [x] Format Godot 4.x correct avec `script = ExtResource("1")`

### 5. Outils Python
- [x] `tools/generer_fiches_v2.py` : génère ennemis + bosses
- [x] `tools/generer_fiches_armes.py` : génère les armes
- [x] `tools/generer_fiches_salles_v2.py` : génère les salles (8 fiches)
- [x] `tools/convertir_json_tres.py` : convertit JSON → .tres (123 fichiers)
- [x] `tools/verifier_tokens_sd.py` : vérifie l'absence de tokens originaux
- [x] `tools/verifier_tokens_final.py` : vérification complète A_TRADUIRE

### 6. Tests Godot headless
- [x] `L_TestOracles.gd` : 23 steps de combat, passe
- [x] `L_TestDegrats.gd` : 5 tests de dégâts, passent
- [x] `L_TestInvuln.gd` : i-frames fonctionnent
- [x] `L_TestDernierEffort.gd` : dernier effort fonctionne
- [x] `L_TestDirectorRun.gd` : run director fonctionne
- [x] `L_TestChargementFiches.gd` : toutes les 123 fiches .tres se chargent
- [x] Tous les 17 scripts .gd passent `--check-only`
- [x] Le projet se charge et se lance sans erreur (`--headless --quit`)

### 7. Boucle de jeu jouable
- [x] `BPC_HerosBase.gd` : mouvement, attaque, dash, stats
- [x] `BPC_EnnemiBase.gd` : aggro, poursuite, attaque, mort
- [x] `BPC_BossBase.gd` : phases, attaques, transitions
- [x] `BPC_SalleBase.gd` : spawn pondéré, cycle de vie
- [x] `BPC_Jeu.gd` : orchestration (héros, salle, caméra, HUD)
- [x] `BPC_CameraTopDown.gd` : suivi du héros
- [x] `BPC_HUD.gd` : barres PV / souffle
- [x] 8 scènes .tscn (Jeu, Heros, Ennemi, Boss, Salle, CameraTopDown, HUD, Projet)
- [x] `project.godot` : main_scene = Jeu.tscn, autoload BPC_Global

### 8. A_TRADUIRE — dossier prêt à traduire
- [x] 274 fichiers (hors .godot/ et imported/)
- [x] SPEC.md (10 sections), README.md (8 étapes), PLAN_CONSTRUCTION_GODOT.md (10 étapes)
- [x] ORGANOGRAPHE_COMPLET.md (1300 lignes)
- [x] FOLDER_ORGANISATION.md (contrat R01-R08)
- [x] PLAN_ORGANISATION.md (plan détaillé : arborescence cible, tableau, dépendances, conformité)
- [x] 7 fiches V2 (clés françaises), 123 .tres, 4 CSV, 9 JSON données
- [x] 17 scripts .gd, 8 scènes .tscn, 1 autoload
- [x] DONNEES_UI.json : 15 formats texte, 8 polices, 13 sections HUD, 14 couleurs
- [x] ICONES_UI.json : 220 icônes anonymisées
- [x] INDEX.md : structure + correspondance R01-R08
- [x] 0 token original

### 9. Corrections de la revue critique
- [x] BPC_Global.gd : écrit (était vide, 8 octets)
- [x] FicheSalle.gd / BPC_SalleBase.gd : props alignées
- [x] Clés spawn : BPC_SalleBase accepte `ref/poids/elite` ET `Ref/Weight/Elite`
- [x] BPC_BossBase : lit `IA.AnnonceDuree` (point), sépare annonce/tir/récupération
- [x] FL_Enemy.gd : marqué OBSOLÈTE (remplacé par FicheEnnemi.gd)
- [x] BPC_HUD.gd : lit `fiche.vie_max` via `heros.stats.fiche`
- [x] BPC_PhaseManager.gd : `AVANcER` → `AVANCER` (typo)
- [x] ANO-005.tres : `MegaLeap` → `MegaSaut`
- [x] ICONES_UI.json : `kiss_of_styx` → `kiss_13_small`
- [x] Suppression 62 fichiers `.translation` et `.import` dans `donnees/`
- [x] Suppression `donnees_gd/` (doublon de `donnees/`)

## Structure finale

```
LOGICOR/
├── project.godot              # Configuration Godot 4.7
├── ETAT_CONSTRUCTION.md       # Ce fichier
├── PLAN_CONSTRUCTION_GODOT.md # Le plan de construction
├── A_TRADUIRE/                # 274 fichiers — dossier prêt à traduire
│   ├── INDEX.md
│   ├── SPEC.md
│   ├── README.md
│   ├── PLAN_CONSTRUCTION_GODOT.md
│   ├── ORGANOGRAPHE_COMPLET.md
│   ├── FOLDER_ORGANISATION.md
│   ├── PLAN_ORGANISATION.md
│   ├── project.godot
│   ├── fiches/ (7 JSON)
│   ├── donnees/ (123 .tres + 7 .gd + 15 JSON/CSV)
│   ├── acteurs/ (7 .gd)
│   ├── systemes/ (5 .gd)
│   ├── adversaires/ (4 .gd)
│   ├── ui/ (1 .gd)
│   ├── scenes/ (8 .tscn)
│   └── autoload/ (1 .gd)
├── acteurs/                   # 7 scripts Godot
├── adversaires/               # 5 scripts Godot (IA)
├── donnees/                   # 130 fichiers (123 .tres + 7 .gd + données)
├── ia_adversaire/             # 7 docs de conception
├── preuves/                   # 6 scripts de test
├── space_dracula/             # 18 fichiers (données brutes)
├── systemes/                  # 5 scripts Godot
└── tools/                     # 27 scripts Python
```

## Prochaines étapes

### 1. Textures et modèles
- [ ] Textures 2D pour les ennemis (CRT-001 à CRT-061)
- [ ] Textures 2D pour les bosses (ANO-001 à ANO-007)
- [ ] Texture du héros
- [ ] Textures des salles (fond, murs, portes)

### 2. Sons
- [ ] Sons d'attaque, de dégâts, de mort
- [ ] Musique de fond

### 3. Tests de gameplay
- [ ] Test de combat complet avec les fiches chargées
- [ ] Test de la génération de run avec les salles

### 4. FICHES_HEROS_V2.json
- [ ] Fiche du héros en JSON V2 (clé française)

## Documents de référence

- `A_TRADUIRE/ORGANOGRAPHE_COMPLET.md` : Organigramme complet du jeu
- `A_TRADUIRE/SPEC.md` : Référence complète (10 sections)
- `A_TRADUIRE/FOLDER_ORGANISATION.md` : Contrat R01-R08
- `A_TRADUIRE/PLAN_ORGANISATION.md` : Plan d'organisation détaillé
