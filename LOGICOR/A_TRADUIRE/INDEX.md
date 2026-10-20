# A_TRADUIRE — Space Dracula

Tout ce qu'il faut pour construire le jeu Godot, dans un seul dossier.
215 fichiers, 0 token original.

## Structure (conforme R01-R08)

```
A_TRADUIRE/
├── INDEX.md                    ← ce fichier
├── SPEC.md                     ← référence complète (10 sections)
├── README.md                   ← instructions d'assemblage (8 étapes)
├── PLAN_CONSTRUCTION_GODOT.md  ← plan de construction en 10 étapes
├── ORGANOGRAPHE_COMPLET.md     ← organigramme du jeu
├── FOLDER_ORGANISATION.md      ← contrat R01-R08
├── PLAN_ORGANISATION.md        ← arborescence cible
├── MAPPING_SPACE_DRACULA.json  ← mapping anonymisé
├── MAPPING_RENOMMAGE.json      ← mapping ancien→nouveau
├── MAPPING_RENOMMAGE_ATTAQUES.json ← mapping attaques
│
├── 0_autoload/                 ← 2 fichiers
│   └── ...
├── 1_core/                     ← 10 fichiers
│   └── ...
├── 2_sequence/                 ← 8 fichiers
│   └── ...
├── 3_entities/                 ← 24 fichiers
│   └── ...
├── 4_ui/                       ← 2 fichiers
│   └── ...
├── 5_data/                     ← 159 fichiers
│   ├── FICHES_BOSSES_V2.json
│   ├── FICHES_ENNEMIS_V2.json
│   ├── FICHES_MINI_BOSSES_V2.json
│   ├── FICHES_SALLES_V2.json
│   ├── DONNEES_UI.json
│   ├── ICONES_UI.json
│   ├── DT_AttackRegistry.csv
│   ├── DT_BossRegistry.csv
│   ├── DT_EffectRegistry.csv
│   ├── DT_EnemyRegistry.csv
│   ├── ANO-*.tres (7 boss)
│   ├── CRT-*.tres (61 ennemis)
│   ├── MIN-*.tres (12 mini-boss)
│   ├── HEROS.tres
│   ├── SLA-*.tres (8 salles)
│   └── ...
├── 6_assets/                   ← 0 fichiers (à compléter)
└── 7_tests/                    ← 0 fichiers (à compléter)
```

## Statut

- **Anonymisation**: 0 token original (noms de personnages, biomes, attaques, effets)
- **Conformité R01-R08**: OUI
- **D+F=C**: OUI (D = données reformulées, F = instructions)

## Prochaines étapes

1. Compléter les fiches V2 avec toutes les colonnes de DT_AttackRegistry.csv
2. Générer les textures/modèles (6_assets/)
3. Ajouter les sons (6_assets/)
4. Créer les tests (7_tests/)
5. Construire le jeu Godot
