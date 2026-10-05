# Source : 01-survivor

- Dépôt : https://github.com/Brock-Chain/01-survivor, commit `f68cb14` (2026-08-04).
- Licence : MIT pour le code, l'art et la musique (`LICENSE`, `assets/ATTRIBUTION.md` : aucun asset tiers).
- Moteur : Godot 4.7.1 (standard, GDScript). Vérifié sous Godot 4.7.2.

## Retouches pour l'usine

- Retirés : l'addon GUT, `.claude/`, `audio_src/` (sources Strudel), `builds/`, `scenes/dev/` (bancs
  d'essai), les outils Python/PowerShell et les générateurs de `tools/` (seul `tools/ai_screenshot.gd`
  reste : c'est un autoload utilisé par `main.gd`), les notes de développement (BRIEF, CLAUDE,
  DECISIONS, TODO) et `export_presets.cfg`.
- Tests : les 14 suites GUT de `tests/unit/` portées vers GdUnit4 dans `tests/` par
  `outils/porter_gut.py` (traduction déterministe, assertion par assertion) ; seul
  `test_health.gd` (comptage d'un signal) a été porté à la main. 128 tests, comme l'original.
- `scenes/enemies/enemy.gd`, `boss.gd` : `_ready` sort tout de suite si `stats` est vide, pour
  que chaque scène se charge seule (juge `load_scene`). En jeu, `setup()` fournit toujours `stats`.
- Marque d'ordre d'octets (BOM) retirée de 5 scripts.
