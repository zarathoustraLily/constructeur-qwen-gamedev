# 5_data

Les paramètres de conception : ce qu'on règle sans toucher au code.

- `visit/visit_settings.tres` : les réglages de la visite des étapes (teintes du ciel, soleil,
  sol, cadrage de la caméra, mesure du rendu, qualités). Sa classe est `1_core/data/visit_settings.gd`.
  Ce sont des réglages de la visite, pas de l'immeuble.
- Au début, rien d'autre : les seuls réglages de l'immeuble sont ses variables exportées, qui
  vivent dans sa scène.
- Puis `DECORS/Building/…_palette.gd` (étape 006 à New York, 009 à Tokyo, 010 à Paris) : les
  listes où le hasard tire (noms d'enseigne, teintes), les règlements, puis les données de la rue.
