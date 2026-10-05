"""Compétence E, « optimisation stricte » : mesurer l'efficience d'un projet Godot et la juger.

Un projet E est jugé en deux temps (juge.py) :
  1. le juge commun (import, check_script, load_scene, run_tests avec les tests cachés) :
     le comportement doit rester celui de la référence ;
  2. l'étape « mesure_efficience » :
     - rendu intact, statique (rendu_intact.py : project.godot et nœuds de rendu des scènes)
       et à l'exécution (signature de ce qui serait affiché, comparée à la référence) ;
     - allocations d'objets après l'échauffement = 0 (seuil absolu) ;
     - lots de dessin ≤ référence × 1,05 (comptage structurel : les draw calls valent 0 en headless) ;
     - temps par image ≤ référence × 1,15, pour les tâches qui le déclarent (la seule mesure
       qui varie d'une exécution à l'autre).

Ce paquet vit hors de usine/juge exprès : la version du juge commun (empreinte de usine/juge)
entre dans la clé du cache des verdicts, et l'ajouter là aurait invalidé tous les verdicts déjà
calculés (le gel des 13 autres compétences). Les verdicts E ont leur propre clé
(mesure.version_efficience), qui inclut la version du juge commun.
"""
