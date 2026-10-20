"""Compare des campagnes de outils/campagne_harnais.py à partir de leurs journaux (sessions/*.jsonl).

    py -3.12 outils/comparer_campagnes.py <dossier de journaux> [<dossier de journaux> ...]

Chaque dossier est celui d'une campagne (il contient bilan.json et sessions/). Affiche un tableau
Markdown, une colonne par campagne, avec les mêmes mesures calculées de la même façon.
"""

from __future__ import annotations

import collections
import hashlib
import json
import sys
from pathlib import Path
from typing import Any


def mesurer(journaux: Path) -> dict[str, Any]:
    bilan = json.loads((journaux / "bilan.json").read_text(encoding="utf-8"))
    appels: collections.Counter[str] = collections.Counter()
    c: collections.Counter[str] = collections.Counter()
    dernier_contenu: dict[str, str] = {}                  # sur toute la campagne : une session reprend où l'autre a fini
    for fichier in sorted((journaux / "sessions").glob("*.jsonl")):
        messages = [json.loads(l) for l in fichier.read_text(encoding="utf-8").splitlines()][1:]
        resultats = {m["tool_call_id"]: str(m.get("content")) for m in messages if m.get("role") == "tool"}
        for rang, m in enumerate(messages):
            if m.get("role") == "user" and isinstance(m.get("content"), list):         # message d'images d'une capture
                c["captures_montrees"] += 1
                suivant = messages[rang + 1] if rang + 1 < len(messages) else {}
                c["verdicts_apres_capture"] += bool(str(suivant.get("content") or "").strip())
            if m.get("role") != "assistant":
                continue
            c["texte"] += bool(str(m.get("content") or "").strip())
            for appel in m.get("tool_calls") or []:
                nom, brut = appel["function"]["name"], appel["function"]["arguments"]
                resultat = resultats.get(appel["id"], "")
                appels[nom] += 1
                try:
                    arguments = json.loads(brut or "{}")
                except json.JSONDecodeError:
                    c["reponses_coupees"] += 1
                    continue
                if "arguments_illisibles" in arguments:                               # appel coupé puis neutralisé
                    c["reponses_coupees"] += 1
                    continue
                if nom == "write_file":
                    chemin = str(arguments.get("chemin"))
                    empreinte = hashlib.sha1(str(arguments.get("contenu")).encode("utf-8")).hexdigest()
                    identique = dernier_contenu.get(chemin) == empreinte
                    c["ecritures_identiques"] += identique
                    c["aucun_changement_signale"] += resultat.startswith("Aucun changement")
                    dernier_contenu[chemin] = empreinte
                elif nom == "apply_edits":
                    c["edits_acceptes"] += resultat.startswith('{"ok":true')
                    c["edits_refuses_validation"] += '"etape":"validation"' in resultat and '"ok":false' in resultat
                    c["edits_refuses_juge"] += '"ok":false' in resultat and '"etape":"validation"' not in resultat
                    for edit in arguments.get("edits") or []:
                        if isinstance(edit, dict) and edit.get("op") == "replace_function":
                            c["replace_function"] += 1
                            c["replace_function_bons_champs"] += "script" in edit and "fonction" in edit
                elif nom == "check_script":
                    c["check_script_echec"] += '"ok":false' in resultat
    fins = bilan.get("fins", {})
    return {
        "Durée": bilan.get("duree"),
        "Sessions": bilan.get("sessions"),
        "Fins : budget / contexte / erreur d'appel": f"{fins.get('budget', 0)} / {fins.get('contexte', 0)} / {fins.get('erreur_appel', 0)}",
        "Pas (réponses du modèle)": bilan.get("pas"),
        "Réponses coupées (arguments illisibles)": c["reponses_coupees"],
        "search_docs": appels["search_docs"],
        "vocab_lookup": appels["vocab_lookup"],
        "write_file": appels["write_file"],
        "Écritures identiques à la précédente du même fichier": f"{c['ecritures_identiques']} / {appels['write_file']}",
        "dont signalées « aucun changement »": c["aucun_changement_signale"],
        "apply_edits": appels["apply_edits"],
        "apply_edits acceptés": c["edits_acceptes"],
        "apply_edits refusés à la validation / par le juge": f"{c['edits_refuses_validation']} / {c['edits_refuses_juge']}",
        "replace_function avec script + fonction": f"{c['replace_function_bons_champs']} / {c['replace_function']}",
        "check_script": f"{appels['check_script']}, dont {c['check_script_echec']} en échec",
        "run_tests / load_scene": f"{appels['run_tests']} / {appels['load_scene']}",
        "capture_ecran": appels["capture_ecran"],
        "Verdicts écrits après une capture": f"{c['verdicts_apres_capture']} / {c['captures_montrees']}",
        "Messages du modèle contenant du texte": c["texte"],
    }


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    dossiers = [Path(a) for a in (sys.argv[1:] if argv is None else argv)]
    if not dossiers:
        print(__doc__)
        return 2
    mesures = [mesurer(d) for d in dossiers]
    print("| Mesure | " + " | ".join(d.name for d in dossiers) + " |")
    print("|---|" + "---|" * len(dossiers))
    for cle in mesures[0]:
        print(f"| {cle} | " + " | ".join(str(m[cle]) for m in mesures) + " |")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
