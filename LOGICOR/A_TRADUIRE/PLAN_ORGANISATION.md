# Plan d'organisation Space Dracula — R01-R08

Date : 2026-10-10
273 fichiers (hors .godot/ et imported/), 0 token original.

## Arborescence cible

```
res://
├── project.godot                     ← exception R07 (technique)
│
├── 0_autoload/
│   └── bpc_global.gd                 ← état partie, signaux, navigation
│
├── 1_core/
│   ├── bpc_stats.gd                  ← PV, souffle, combo, i-frames
│   ├── bpc_degrats_pipeline.gd       ← pipeline de dégâts
│   ├── bpc_invuln.gd                 ← i-frames
│   ├── bpc_dernier_effort.gd         ← dernier effort
│   └── bpc_director_run.gd           ← run director (spawn pondéré)
│
├── 2_sequence/
│   ├── bpc_jeu.gd                    ← orchestration : héros, salle, caméra, HUD
│   ├── bpc_salle_base.gd             ← cycle de vie des salles, spawn
│   └── bpc_projet.gd                 ← scène racine, chargement du run
│
├── 3_entities/
│   ├── heros/
│   │   ├── heros.tscn                ← scène du héros
│   │   └── bpc_heros_base.gd         ← mouvement, attaque, dash
│   ├── ennemis/
│   │   ├── ennemi.tscn               ← scène de l'ennemi
│   │   ├── bpc_ennemi_base.gd        ← aggro, poursuite, attaque, mort
│   │   └── bpc_aggro_sense.gd        ← détection de cible
│   ├── bosses/
│   │   ├── boss.tscn                 ← scène du boss
│   │   ├── bpc_boss_base.gd          ← phases, attaques, transitions
│   │   ├── bpc_phase_manager.gd      ← arbre de décision des stades
│   │   └── bpc_weapon_manager.gd     ← gestion des armes du boss
│   └── camera/
│       ├── camera_top_down.tscn      ← scène de la caméra
│       └── bpc_camera_top_down.gd    ← suivi du héros
│
├── 4_ui/
│   ├── hud.tscn                      ← scène du HUD
│   └── bpc_hud.gd                    ← barres PV / souffle, notifications
│
├── 5_data/
│   ├── types/
│   │   ├── fiche_heros.gd            ← class_name FicheHeros
│   │   ├── fiche_ennemi.gd           ← class_name FicheEnnemi
│   │   ├── fiche_boss.gd             ← class_name FicheBoss
│   │   ├── fiche_mini_boss.gd        ← class_name FicheMiniBoss
│   │   ├── fiche_arme.gd             ← class_name FicheArme
│   │   ├── fiche_salle.gd            ← class_name FicheSalle
│   │   └── fiche_outil.gd            ← class_name FicheOutil
│   ├── fiches/
│   │   ├── heros.tres                ← fiche du héros
│   │   ├── crt-001.tres … crt-061.tres   (61 fiches ennemis)
│   │   ├── ano-001.tres … ano-007.tres   (7 fiches boss)
│   │   ├── min-001.tres … min-012.tres   (12 fiches mini-boss)
│   │   ├── rel-001.tres … rel-034.tres   (34 fiches armes)
│   │   └── sla-01.tres … sla-08.tres     (8 fiches salles)
│   ├── pools/
│   │   ├── spawn_pools_lvl01.json … spawn_pools_lvl08.json
│   │   └── encounter_profiles.json
│   ├── registres/
│   │   ├── dt_enemy_registry.csv
│   │   ├── dt_boss_registry.csv
│   │   ├── dt_attack_registry.csv
│   │   └── dt_effect_registry.csv
│   ├── ui/
│   │   ├── donnees_ui.json           ← formats texte, layout HUD, couleurs
│   │   └── icones_ui.json            ← 220 icônes anonymisées
│   └── mapping_space_dracula.json    ← 370 codes, 0 nom original
│
├── 6_assets/                         ← (à créer : textures, audio, modèles)
│
└── 7_tests/
    ├── bpc_aggro_sense.gd            ← (déplacé depuis 3_entities/ennemis/)
    └── l_test_oracles.gd             ← tests oracles
```

## Tableau : élément → chemin res:// → responsabilité → règle

| Élément | Chemin res:// | Responsabilité | Règle |
|---|---|---|---|
| `BPC_Global.gd` | `0_autoload/bpc_global.gd` | État partie, signaux partagés, navigation | R01, R02 |
| `BPC_Stats.gd` | `1_core/bpc_stats.gd` | PV, souffle, combo, i-frames, dernier effort | R02, R04 |
| `BPC_DegratsPipeline.gd` | `1_core/bpc_degrats_pipeline.gd` | Pipeline de dégâts générique | R02, R04 |
| `BPC_Invuln.gd` | `1_core/bpc_invuln.gd` | i-frames génériques | R02, R04 |
| `BPC_DernierEffort.gd` | `1_core/bpc_dernier_effort.gd` | Dernier effort (réduction dégâts) | R02, R04 |
| `BPC_DirectorRun.gd` | `1_core/bpc_director_run.gd` | Run director, spawn pondéré | R02, R04 |
| `BPC_Jeu.gd` | `2_sequence/bpc_jeu.gd` | Orchestration : héros, salle, caméra, HUD | R02, R05 |
| `BPC_SalleBase.gd` | `2_sequence/bpc_salle_base.gd` | Cycle de vie des salles, spawn | R02, R05 |
| `BPC_Projet.gd` | `2_sequence/bpc_projet.gd` | Scène racine, chargement du run | R02, R05 |
| `Heros.tscn` | `3_entities/heros/heros.tscn` | Scène du héros | R02, R03 |
| `BPC_HerosBase.gd` | `3_entities/heros/bpc_heros_base.gd` | Mouvement, attaque, dash | R02, R03 |
| `Ennemi.tscn` | `3_entities/ennemis/ennemi.tscn` | Scène de l'ennemi | R02, R03 |
| `BPC_EnnemiBase.gd` | `3_entities/ennemis/bpc_ennemi_base.gd` | Aggro, poursuite, attaque, mort | R02, R03 |
| `BPC_AggroSense.gd` | `3_entities/ennemis/bpc_aggro_sense.gd` | Détection de cible | R02, R03 |
| `Boss.tscn` | `3_entities/bosses/boss.tscn` | Scène du boss | R02, R03 |
| `BPC_BossBase.gd` | `3_entities/bosses/bpc_boss_base.gd` | Phases, attaques, transitions | R02, R03 |
| `BPC_PhaseManager.gd` | `3_entities/bosses/bpc_phase_manager.gd` | Arbre de décision des stades | R02, R03 |
| `BPC_WeaponManager.gd` | `3_entities/bosses/bpc_weapon_manager.gd` | Gestion des armes du boss | R02, R03 |
| `CameraTopDown.tscn` | `3_entities/camera/camera_top_down.tscn` | Scène de la caméra | R02, R03 |
| `BPC_CameraTopDown.gd` | `3_entities/camera/bpc_camera_top_down.gd` | Suivi du héros | R02, R03 |
| `HUD.tscn` | `4_ui/hud.tscn` | Scène du HUD | R02 |
| `BPC_HUD.gd` | `4_ui/bpc_hud.gd` | Barres PV / souffle, notifications | R02, R04 |
| `FicheHeros.gd` | `5_data/types/fiche_heros.gd` | Class_name FicheHeros | R02, R04 |
| `FicheEnnemi.gd` | `5_data/types/fiche_ennemi.gd` | Class_name FicheEnnemi | R02, R04 |
| `FicheBoss.gd` | `5_data/types/fiche_boss.gd` | Class_name FicheBoss | R02, R04 |
| `FicheMiniBoss.gd` | `5_data/types/fiche_mini_boss.gd` | Class_name FicheMiniBoss | R02, R04 |
| `FicheArme.gd` | `5_data/types/fiche_arme.gd` | Class_name FicheArme | R02, R04 |
| `FicheSalle.gd` | `5_data/types/fiche_salle.gd` | Class_name FicheSalle | R02, R04 |
| `FicheOutil.gd` | `5_data/types/fiche_outil.gd` | Class_name FicheOutil | R02, R04 |
| `HEROS.tres` | `5_data/fiches/heros.tres` | Fiche du héros | R02 |
| `CRT-001.tres … CRT-061.tres` | `5_data/fiches/crt-xxx.tres` | 61 fiches ennemis | R02 |
| `ANO-001.tres … ANO-007.tres` | `5_data/fiches/ano-xxx.tres` | 7 fiches boss | R02 |
| `MIN-001.tres … MIN-012.tres` | `5_data/fiches/min-xxx.tres` | 12 fiches mini-boss | R02 |
| `REL-001.tres … REL-034.tres` | `5_data/fiches/rel-xxx.tres` | 34 fiches armes | R02 |
| `SLA-01.tres … SLA-08.tres` | `5_data/fiches/sla-xx.tres` | 8 fiches salles | R02 |
| `SpawnPools_Lvl01.json … 08` | `5_data/pools/spawn_pools_lvl0x.json` | Pools de spawn par niveau | R02 |
| `EncounterProfiles.json` | `5_data/pools/encounter_profiles.json` | Profils de rencontre | R02 |
| `DT_EnemyRegistry.csv` | `5_data/registres/dt_enemy_registry.csv` | Registre des ennemis | R02 |
| `DT_BossRegistry.csv` | `5_data/registres/dt_boss_registry.csv` | Registre des bosses | R02 |
| `DT_AttackRegistry.csv` | `5_data/registres/dt_attack_registry.csv` | Registre des attaques | R02 |
| `DT_EffectRegistry.csv` | `5_data/registres/dt_effect_registry.csv` | Registre des effets | R02 |
| `DONNEES_UI.json` | `5_data/ui/donnees_ui.json` | Formats texte, layout HUD, couleurs | R02 |
| `ICONES_UI.json` | `5_data/ui/icones_ui.json` | 220 icônes anonymisées | R02 |
| `MAPPING_SPACE_DRACULA.json` | `5_data/mapping_space_dracula.json` | 370 codes anonymisés | R02 |
| `L_TestOracles.gd` | `7_tests/l_test_oracles.gd` | Tests oracles | R02, R07 |
| `FL_Enemy.gd` | — | OBSOLÈTE (remplacé par FicheEnnemi.gd) | — |
| `project.godot` | `project.godot` | Configuration Godot 4.7 | R07 |
| `INDEX.md`, `SPEC.md`, `README.md`, etc. | racine | Documents de référence | R07 |

## Dépendances principales

```
0_autoload/bpc_global.gd
  └── signaux → 2_sequence/bpc_jeu.gd

2_sequence/bpc_jeu.gd
  ├── charge → 3_entities/heros/heros.tscn
  ├── charge → 3_entities/ennemis/ennemi.tscn (via BPC_SalleBase)
  ├── charge → 3_entities/bosses/boss.tscn (via BPC_SalleBase)
  ├── charge → 4_ui/hud.tscn
  └── charge → 3_entities/camera/camera_top_down.tscn

2_sequence/bpc_salle_base.gd
  ├── lit → 5_data/fiches/sla-xx.tres
  ├── lit → 5_data/pools/spawn_pools_lvl0x.json
  ├── instancie → 3_entities/ennemis/ennemi.tscn
  └── instancie → 3_entities/bosses/boss.tscn

3_entities/heros/bpc_heros_base.gd
  ├── lit → 5_data/fiches/heros.tres
  └── utilise → 1_core/bpc_stats.gd

3_entities/ennemis/bpc_ennemi_base.gd
  ├── lit → 5_data/fiches/crt-xxx.tres
  ├── utilise → 1_core/bpc_stats.gd
  └── utilise → 3_entities/ennemis/bpc_aggro_sense.gd

3_entities/bosses/bpc_boss_base.gd
  ├── lit → 5_data/fiches/ano-xxx.tres
  ├── utilise → 1_core/bpc_stats.gd
  ├── utilise → 3_entities/bosses/bpc_phase_manager.gd
  └── utilise → 3_entities/bosses/bpc_weapon_manager.gd

4_ui/bpc_hud.gd
  └── lit → 3_entities/heros/bpc_heros_base.gd (stats)
```

## Conformité R01-R08

| Règle | Statut | Notes |
|---|---|---|
| R01 — Structure de référence | OK | 8 dossiers principaux, noms et responsabilités conservés |
| R02 — Classement par responsabilité | OK | Chaque fichier a un emplacement déterminé par son rôle |
| R03 — Propriété locale | OK | Scène + script + états restent ensemble (heros/, ennemis/, bosses/, camera/) |
| R04 — Frontières à respecter | OK | Classes de données dans 5_data/types/, mécanismes dans 1_core/ |
| R05 — Déroulement du jeu | OK | BPC_Jeu orchestre, BPC_SalleBase gère le cycle, pas de liste codée en dur |
| R06 — Dépendances | OK | 1_core/ ne dépend d'aucun autoload, les entités ne dépendent pas du HUD |
| R07 — Nommage, tests, exceptions | OK | snake_case, project.godot en racine, tests dans 7_tests/ |
| R08 — Gestion des ambiguïtés | OK | Aucun dossier fourre-tout, aucune exception inventée |

## Ambiguïtés signalées

Aucune. Tous les fichiers ont un emplacement justifiable.
