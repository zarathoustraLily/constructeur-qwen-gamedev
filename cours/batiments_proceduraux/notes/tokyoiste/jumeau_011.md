## Le même pas, à Paris et à New York

Les dossiers voisins `building_proceduraux_parisien_etape_011` et `building_proceduraux_newyorkais_etape_011` font le même pas : à Paris, « La graine : un immeuble différent à chaque tirage » ; à New York, « La graine : une tour différente à chaque tirage ».

- **Ce qui ne change pas** : la graine : un seul nombre, fixé au début de la construction, des tirages toujours dans le même ordre, et un dé lancé même quand le choix est imposé.
- **Ici, à Tokyo** : la graine choisit aussi la matière de la façade (carrelage, béton brut ou enduit), avec un dé penché vers le carrelage, et décale les motifs des shaders.
- **À Paris** : la graine choisit les formes laissées au hasard, et un dé à part, à la graine dérivée, sert aux tirages ajoutés après coup.
- **À New York** : la graine choisit jusqu'à la famille de la tour (brique de 1916, verre de 1961 ou tout en verre), avec un dé penché vers la brique, puis ses proportions, toujours dans les bornes du règlement ; un dé à part sert aux boutiques, pour que la tour puisse refaire ses choix sans les déranger.

Comparer les fonctions `_pick()` et le début des trois `rebuild()` : la discipline des tirages est la même.
