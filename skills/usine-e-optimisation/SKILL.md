---
name: usine-e-optimisation
description: E — Optimisation stricte d'un jeu 2D : le rendre plus efficace sans changer ni son comportement ni son rendu. Quand des objets sont créés ou libérés pendant la partie, quand il y a trop de lots de dessin, ou quand le temps par image est trop élevé.
---

# E — Optimisation stricte : plus efficace, même comportement, même rendu.

**Quand l'utiliser** : quand la mesure montre des allocations d'objets dans la boucle de jeu, trop de lots de dessin, ou un temps par image trop élevé.

**Entrée** : le projet, la consigne et sa mesure (allocations après l'échauffement, lots de dessin), les tests du jeu.

**Sortie** : le code réécrit (`replace_function`, `add_function`, éditions de script) :
- allocations : aucune création (`new()`, `instantiate()`, `queue_free()`, objets `RefCounted`) dans `_process`/`_physics_process` ; une réserve d'objets créée au chargement, réutilisée (masquer ou afficher, réinitialiser) ;
- lots de dessin : textures et matériaux partagés au lieu d'un exemplaire par entité, atlas avec régions ;
- temps : pas de double boucle sur toutes les entités (grille de voisinage, tri) ; ne pas recalculer ce qui ne change pas ; garder les nœuds au lieu de les rechercher.

À ne jamais faire : baisser la résolution, retirer une lumière, un effet ou un élément affiché, changer `[display]` ou `[rendering]` dans `project.godot`, changer une couleur ou une texture. Garder les fonctions publiques que les tests appellent.

**Juge** : `run_tests` vert, puis `measure_efficiency` : 0 allocation après l'échauffement, lots de dessin au plus ceux de la référence (+5 %), temps au plus 1,15 fois celui de la référence. L'empreinte du rendu doit rester celle d'avant la modification : mesurer avant, puis après.

Outils du serveur MCP `usine-godot` (en Code Mode : `tools["usine-godot"].<outil>({...})`). Chemins en `res://`. Vérifier toute classe, propriété, signal ou méthode avec `vocab_lookup` avant de l'écrire ; chercher un exemple qui compile avec `search_docs(requete, source="exemples")`.
