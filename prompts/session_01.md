# Session 1 — Vocabulaire, juge commun, projet de référence

Modèle conseillé : Opus 5.5. Lis d'abord `CLAUDE.md` et `ETAT.md`.

## Objectif

Poser les fondations dont dépendent les 13 compétences :

- le vocabulaire Godot exact ;
- un juge commun qui rend un verdict JSON ;
- un petit projet Godot de référence avec 10 tâches modèles.

## Livrables

1. **Squelette du dépôt** selon l'arborescence de `CLAUDE.md` : `requirements.txt`, `pytest` qui tourne, `config.example.toml` complété si besoin.
2. **`outils/installer_godot_cloud.sh`** : télécharge Godot 4.7.2 Linux headless dans `godot_bin/` (ignoré par git). En cas d'échec réseau, marquer les tests moteur `skip` et le noter dans `ETAT.md`.
3. **`usine/vocab`**
   - Lance `godot --headless --dump-extension-api`.
   - Charge `extension_api.json` dans SQLite : classes, héritage, méthodes avec arguments, signaux avec arguments, propriétés, énumérations, constantes.
   - Expose une CLI `python -m usine.vocab lookup CharacterBody2D` et une fonction `existe(classe, membre, genre)` qui suit l'héritage.
4. **`usine/juge`**
   - `check_script(chemin)` : `--check-only`.
   - `load_scene(chemin)` : script headless qui charge et instancie la scène, puis liste les nœuds, scripts et ressources manquants.
   - `run_tests(projet, filtre)` : GdUnit4 en ligne de commande, rapport JUnit parsé.
   - Les trois renvoient le verdict JSON du format commun, avec catégorisation des erreurs fréquentes.
   - Une CLI `python -m usine.juge run <projet>`.
5. **`godot/reference/`** : un petit jeu d'action 2D vu de dessus, autonome, en GDScript typé.
   - Héros (`CharacterBody2D`) : déplacement, dash avec i-frames.
   - Ennemi qui patrouille puis poursuit.
   - Composant de vie avec signaux.
   - Vagues d'ennemis, pièces, HUD.
   - Structure inspirée du `projet_hades` de l'utilisateur (hero, ghost, wave_spawner, hud, coin_pickup, game_state), mais écrite de zéro.
   - GdUnit4 dans `addons/` : choisir la version compatible avec Godot 4.7 et noter laquelle dans `ETAT.md`.
   - Des tests GdUnit4 couvrent les règles principales.
6. **10 tâches de départ** au format commun (`donnees/taches/...`, plus une copie versionnée dans `godot/taches_modeles/`).
   - Réparties sur au moins 5 compétences, dont K2, K3, S1, S2 et D1.
   - Écrites avec soin : ce sont les modèles que l'usine imitera.

## Contraintes

- Aucun LLM dans le juge.
- Aucun chemin en dur : tout passe par `config.toml`, ou par `godot_bin/` dans le cloud.
- Les tests cachés d'une tâche ne sont jamais dans `depart/`.

## Preuve de fin (à exécuter et coller dans ETAT.md)

- `python -m usine.juge run godot/reference` renvoie `ok: true`.
- Pour chacune des 10 tâches : FAIL sur `depart/`, PASS sur `reference/`, avec deux exécutions de suite qui donnent le même verdict et les mêmes tests.
- `python -m usine.vocab lookup CharacterBody2D` affiche les signaux et propriétés hérités.
- `pytest` est vert.

## À livrer aussi

`VERIFIER_EN_LOCAL.md` : les mêmes commandes en cmd.exe, avec le Godot Windows de `config.toml`, et le résultat attendu.

## Fin de session

Mettre à jour `ETAT.md`, puis committer et pousser.
