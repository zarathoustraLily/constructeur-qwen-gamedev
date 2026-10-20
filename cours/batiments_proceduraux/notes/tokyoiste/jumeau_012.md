## Le même pas, à Paris et à New York

Les dossiers voisins `building_proceduraux_parisien_etape_012` et `building_proceduraux_newyorkais_etape_012` font le même pas : à Paris, « La rue : parcelles, gabarit, régularité » ; à New York, « Le quartier : avenue, rues, deux règlements ».

- **Ce qui ne change pas** : le décor plus grand se sert du bâtiment comme d'une brique : il découpe des terrains, règle les variables de chaque bâtiment avant `add_child()`, et donne à chacun sa graine.
- **Ici, à Tokyo** : des interstices entre voisins, des hauteurs libres sous le gabarit oblique, des étages qui reculent, des poteaux électriques et leurs fils.
- **À Paris** : des immeubles mitoyens, une hauteur de façade fixée par la largeur de la voie, et des lignes de balcons qui filent d'un immeuble à l'autre (`regularity`).
- **À New York** : une avenue, des rues, des îlots de 200 pieds, deux rangs de terrains et une tour par terrain. Le quartier ne sait rien des règlements : chaque tour applique le sien, avec les rues qu'on lui donne.

Comparer les trois fonctions qui posent les bâtiments : à Paris et à Tokyo, la règle d'urbanisme y tient en quelques lignes ; à New York, en aucune, parce qu'elle est restée dans la tour.
