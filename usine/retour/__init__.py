"""Retour des outils : dire à Qwen ce qui s'est vraiment passé après une action.

Point 1 de « La béquille de Qwen » (campagnes du 2026-10-09) : sans retour précis, Qwen
réécrit le même fichier jusqu'à 28 fois de suite et conclut à tort qu'une classe n'existe pas.
Tout est déterministe (règle 2) : le vocabulaire vient de `extension_api.json` (règle 6).

- `ecriture` : une écriture sans effet le dit, avec le nombre de répétitions d'affilée ;
- `verification` : après l'écriture d'un script, chaque classe et membre Godot utilisé est
  vérifié et sa signature officielle renvoyée ;
- `fiches` : après une erreur du moteur, la fiche du membre en cause est jointe.
"""

from usine.retour.ecriture import Ecritures
from usine.retour.fiches import fiches_pour_erreurs
from usine.retour.verification import IndexProjet, formater_rapport, verifier_script

__all__ = ["Ecritures", "IndexProjet", "fiches_pour_erreurs", "formater_rapport", "verifier_script"]
