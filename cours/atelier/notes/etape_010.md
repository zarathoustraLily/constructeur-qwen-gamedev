# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un jeu qui tient la distance : pas de création et de libération à chaque tir, pas de
ressource relue à chaque usage, pas d'objet gardé en vie par une liste ou un signal oublié.

Ce qu'on obtient : une réserve de projectiles réutilisés, un cache de ressources, une liste d'abonnés qui ne
retient personne, et des branchements de signaux sans doublon.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Les outils sont dans `1_core/memory/`, le projectile dans `3_entities/projectile/`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une réserve d'objets

Instancier une scène à chaque tir puis la libérer coûte des allocations, fragmente la mémoire et provoque des
à-coups. `1_core/memory/object_pool.gd` prépare des objets d'avance (`prewarm`) ; `acquire` en rend un, montré et
en marche (`process_mode` hérité) ; `release` le cache et l'arrête (`PROCESS_MODE_DISABLED`) sans le libérer. Au
maximum, la réserve refuse (null) plutôt que de grossir sans fin. Le projectile ne se libère jamais lui-même : il
annonce sa fin (`expired`), et sa réserve le range.

### 2. Un cache de ressources

`1_core/memory/resource_cache.gd` charge une ressource une fois (`ResourceLoader.load`) et rend ensuite la même
instance ; il compte ses succès et ses échecs, ne garde rien pour un chemin absent, et `clear` oublie tout d'un coup
(un changement de niveau) : ce que plus rien ne tient est libéré.

### 3. Des références faibles

Une liste ordinaire garde ses objets en vie. `1_core/memory/weak_listeners.gd` les tient par `weakref` : un nœud
libéré disparaît de la liste au prochain passage (`get_ref` rend null), sans erreur sur une instance déjà libérée
(`is_instance_valid`), et `notify` ne prévient que les vivants.

### 4. Des branchements sans doublon

Brancher deux fois le même `Callable` sur un signal l'appellerait deux fois (ou lèverait une erreur) ; un
branchement oublié garde sa cible en vie. `1_core/memory/connections.gd` : `connect_once` vérifie `is_connected`
avant de brancher, `disconnect_all` retire tout ce que `get_connections` liste.
