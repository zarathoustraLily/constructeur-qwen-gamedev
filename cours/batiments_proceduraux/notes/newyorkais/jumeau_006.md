## Le même pas, à Paris et à Tokyo

Les dossiers voisins `building_proceduraux_parisien_etape_006` et `building_proceduraux_tokyoiste_etape_006` font le même pas : à Paris, « Niveaux : soubassement, étage noble, dernier étage » ; à Tokyo, « Niveaux : commerce et étages ».

- **Ce qui ne change pas** : une description intermédiaire entre les variables et la géométrie : une fonction fabrique une liste (des niveaux, des gradins), une autre la monte, élément par élément.
- **Ici, à New York** : des gradins : le règlement de zonage de 1916, écrit en code, fait reculer la tour pour rester sous le plan incliné de chaque rue, jusqu'à la tour qui monte sans limite sur un quart du terrain. Personne ne dessine les gradins : ils sortent du règlement.
- **À Paris** : un soubassement, un étage noble, des étages courants, un dernier étage, une corniche ; un même shader de pierre donne plusieurs matières.
- **À Tokyo** : un rez-de-chaussée haut, des étages de bureaux, des logements, une cage d'escalier, un acrotère ; un même matériau de fenêtre donne plusieurs pièces, choisies par `INSTANCE_CUSTOM`.

Comparer les fonctions qui fabriquent la liste : c'est là, et seulement là, que vivent les règles de composition de chaque ville. À New York, c'est une règle d'urbanisme.
