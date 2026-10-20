"""Compétence O1, « corriger en observant » : jouer des parties scriptées et juger ce qui s'y passe.

Un bug de gameplay (le kart vole, traverse un arbre, s'enfonce dans la route en tournant, la caméra
regarde à contresens…) ne se voit pas forcément dans les tests unitaires : il se voit en jouant.
Ici, « regarder la partie » se fait par des mesures exactes, image par image, à cadence fixe :

  partie.py           lance gd/jouer_partie.gd (séquences scriptées, monde de vérité en fantôme),
                      évalue les règles en Python, résume une partie en texte pour l'agent ;
  juge.py             étape « observation » du verdict, après le juge commun (comme E) ;
  jeux/<jeu>.json     description d'un jeu : acteur, commandes, obstacles, séquences, seuils.

Par l'image (demande de laurent du 2026-10-20 : bâtiments procéduraux compris, Qwen regarde l'image) :

  visuel.py           rendu des vues (Compatibilité, fenêtre hors de l'écran), comparaison d'images par
                      Godot (gd/comparer_images.gd), écart décrit en mots ;
  juge_visuel.py      étape « observation_visuelle » : tests d'origine de l'étape, puis chaque vue
                      comparée à son image de référence.

Vérité terrain : le monde de vérité et les images de référence viennent du jeu ou de l'étape de
référence. Les seuils sont réglés pour que la référence passe (le portillon le vérifie pour chaque tâche).
Hors de portée : le son tel qu'on l'entend, le plaisir de jeu.
"""
