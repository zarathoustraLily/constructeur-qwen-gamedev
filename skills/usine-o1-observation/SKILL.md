---
name: usine-o1-observation
description: O1 — Corriger un bug de gameplay en observant des parties. Quand le jeu se charge et ses tests passent, mais qu'il se comporte mal quand on y joue (il vole, traverse un obstacle, s'enfonce dans le sol, la caméra ne suit pas).
---

# O1 — Corriger un bug de gameplay en observant des parties.

**Quand l'utiliser** : quand le jeu se comporte mal en partie sans qu'aucun test ne dise pourquoi : un personnage qui vole, traverse un arbre, s'enfonce à moitié dans la route en tournant, une caméra qui le perd de vue ou le filme de face.

**Entrée** : le projet, et l'outil `play_sequence(sequence)`. Il joue une séquence scriptée sans fenêtre, à cadence fixe : avancer en zigzag, sauter, foncer sur un obstacle… Il rend :
- les règles de partie cassées, avec leur première image, la pire image et l'objet en cause (« le kart entre de 0,98 m dans small_palm.tscn (52.9, 3.2, -44.9) ») ;
- le parcours de l'acteur toutes les 30 images (position, appui sol/eau/air, vitesse).

**Sortie** : le plus petit changement qui fait tenir toutes les règles, dans le script ou la scène en cause.

- Observer d'abord, sans rien modifier : jouer toutes les séquences, noter quelles règles cassent, où et quand.
- Relier le symptôme à sa cause : une hauteur qui monte sans redescendre vient de la gravité ou du saut ; une traversée, d'une collision (calque, masque, forme désactivée) ; un enfouissement en virage, de l'inclinaison du modèle ; une caméra à contresens, de l'orientation qu'elle vise.
- Corriger la cause, pas la mesure : ne jamais déplacer un obstacle, une séquence ou un seuil.
- Rejouer les séquences après le changement : toutes les règles doivent tenir, et le parcours ne doit pas changer ailleurs.

**Juge** : le jeu se charge (import, scripts, scènes), puis les mêmes séquences sont rejouées. Le monde de vérité vient de la version de référence : une collision retirée reste visible pour le juge. Chaque règle doit tenir : gravité, hauteur, sous le sol, traversée, enfouissement, caméra. Le patch est plafonné à quelques lignes.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
