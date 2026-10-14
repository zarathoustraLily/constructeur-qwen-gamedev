## Le même pas, à Tokyo et à New York

Les dossiers voisins `building_proceduraux_tokyoiste_etape_008` et `building_proceduraux_newyorkais_etape_008` font le même pas : à Tokyo, « Auvent, acrotère, descentes d'eau » ; à New York, « Profils : chaperons, ailettes, marquise ».

- **Ce qui ne change pas** : un profil dessiné une fois, en deux dimensions, que l'outil de maillage fait glisser le long d'une ligne : `extrude()`.
- **Ici, à Paris** : des moulures de pierre, bandeaux et corniche, qui font passer l'immeuble de 1 928 à 9 400 triangles.
- **À Tokyo** : des tôles pliées et des tuyaux : auvent, couvertine, appuis de fenêtre, descentes d'eau. Tokyo se sert aussi de `sweep()`, pour le coude des descentes, et de `cone()`, pour les tuyaux.
- **À New York** : peu de profils, chacun à sa place : le chaperon de chaque parapet, un bandeau en gradins au-dessus du socle, et les ailettes verticales de la tour de 1961, posées là où le shader dessine les meneaux, par le même calcul que lui.

Comparer les trois scripts de profils : des listes de points, et rien d'autre. Un style se reconnaît à ses profils, et à leur sens : horizontaux sur la pierre, verticaux sur la tour de verre.
