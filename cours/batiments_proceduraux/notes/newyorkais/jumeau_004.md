## Le même pas, à Paris et à Tokyo

Les dossiers voisins `building_proceduraux_parisien_etape_004` et `building_proceduraux_tokyoiste_etape_004` font le même pas : à Paris, « Fenêtres à petits bois » ; à Tokyo, « Fenêtres coulissantes en aluminium ».

- **Ce qui ne change pas** : un rectangle par fenêtre, instancié dans un `MultiMesh`, et un shader qui lit la taille du rectangle dans `MODEL_MATRIX` et dessine le châssis par distances signées.
- **Ici, à New York** : une fenêtre à guillotine : deux châssis qui se rencontrent au milieu de la baie, celui du bas levé dans une fenêtre sur sept, des petits bois au choix ; 1 320 fenêtres, un seul appel de dessin.
- **À Paris** : une fenêtre à la française : deux vantaux ouvrants et leurs petits bois.
- **À Tokyo** : une fenêtre coulissante en aluminium : deux vantaux qui se croisent, sans petits bois.

Comparer la fonction qui dessine le châssis dans les trois shaders de fenêtre : mêmes briques (`rect`, distances, masques), autre dessin.
