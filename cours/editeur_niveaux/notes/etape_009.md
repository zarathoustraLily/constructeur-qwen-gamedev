# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Jusqu'ici, l'éditeur modifiait une salle qu'il ne savait pas enregistrer. On ferme la boucle :
choisir une salle, la modifier, l'enregistrer, et ne jamais perdre une modification par mégarde. Aucun nouveau
mécanisme : la coquille assemble le magasin (étape 2), le document (étape 3) et le catalogue (étape 4).

Ce qu'on obtient : en haut de la fenêtre, la liste des salles de `5_data/salles/`, « Enregistrer » (ou Ctrl+S) et
« Abandonner les modifications » ; le titre porte un astérisque tant que la salle a des modifications non enregistrées.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 ; déplacer un obstacle : le titre devient « Éditeur de niveaux · Le hangar * » ; Ctrl+S : l'astérisque part.
3. Choisir « soute.tres » dans la liste avec une modification en cours : la barre d'état le refuse et dit quoi faire.
4. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Enregistrer après deux contrôles

`save_room` prend une copie de la salle (`snapshot`), la vérifie face au catalogue (`room_errors`), puis la confie à
`RoomStore.save_room`, qui la valide à son tour et l'écrit de façon atomique. Ce n'est qu'après une écriture réussie que
le document note l'état enregistré (`mark_saved`) : si le disque refuse, la salle reste marquée modifiée, et la barre
d'état dit pourquoi (« Enregistrement impossible : … »).

### 2. Ne jamais perdre une modification

Changer de salle avec des modifications non enregistrées les perdrait. `open_room` le refuse et le dit
(`UNSAVED`) ; la liste revient à la salle ouverte (`_select_current`). Deux sorties, toutes deux explicites :
« Enregistrer », ou « Abandonner les modifications », qui rouvre la salle telle qu'elle est sur le disque
(`open_room(chemin, true)`). L'astérisque du titre suit `dirty_changed` : il apparaît au premier changement, disparaît à
l'enregistrement, et revient si l'on annule au-delà de l'état enregistré (étape 3).

### 3. La liste des salles

`refresh_rooms` lit le dossier des salles (`DirAccess.get_files_at`) et ne garde que les `.tres` qui ne commencent
pas par un point : le fichier voisin d'une écriture en cours (`.hangar.enregistrement.tres`, étape 2) n'y apparaît
jamais. Choisir une salle l'ouvre ; la liste est relue après chaque enregistrement.

### 4. Ctrl+S

`EditorShortcutsInput` ne sait pas enregistrer : il émet `save_requested`, et la coquille, qui connaît le magasin et le
catalogue, enregistre. Le bouton « Enregistrer » appelle la même fonction : une seule façon d'enregistrer, donc un seul
endroit où vérifier.

### 5. Des tests qui ne touchent pas aux salles du projet

Les tests de la coquille enregistrent : s'ils écrivaient dans `5_data/salles/`, chaque passage des tests modifierait
les salles du jeu. La coquille reçoit donc son dossier des salles par `rooms_dir` ; les tests y mettent une copie des
trois salles, dans `user://`, avant d'ajouter la coquille à l'arbre (`_ready` lit `rooms_dir` et `start_room`), et
l'effacent après.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5 : modifier, voir l'astérisque, Ctrl+S, le voir partir ; essayer de changer de salle avec une modification en
  cours.
