"""Paires courtes du palier 1 (décision 19.1 ; RAPPORT_DE_SUIVI, voie B) : une famille par module.

Format commun d'une paire (`format.py`) : messages au format chat (sans plan quand l'exception de la section 3
s'applique), `famille`, `sujet`, `type` (création, débogage, analyse), `preuve` (ce qui a vérifié la paire), nombre
de jetons compté avec le tokenizer de Qwen 3.8 et son gabarit (règle 5.8). Sorties dans `donnees/paires/<famille>/`.

Familles :
- `camera` (étape A8) : situer la caméra et les objets d'une scène 3D, et corriger un cadrage faux, d'après la sortie
  de l'outil `voir_scene` ; chaque cas est vérifié par deux rendus (défaut, puis correction).
"""
