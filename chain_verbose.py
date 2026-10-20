"""Chaîne du portillon avec affichage PAR TEST (début + résultat) en temps réel.

Appelle usine.portillon.chaine.chaine() sans modifier le dépôt : on remplace
`evaluer` au niveau du module chaine (là où il est appelé), et on écrit
chaque événement dans un fichier JSONL (donnees/chain_events.jsonl) que le
dashboard peut suivre en temps réel.

USAGE : python chain_verbose.py
"""
from __future__ import annotations

import json
import sys
import time
import threading
from pathlib import Path
from unittest import mock

import usine.portillon.regles as regles_mod
from usine.portillon import chaine as chaine_mod
from usine.portillon.regles import evaluer as evaluer_base

_verrou_aff = threading.Lock()
_FICHIER_LOG: Path | None = None
_FICHIER_EVENTS: Path | None = None


def afficher(msg: str) -> None:
    with _verrou_aff:
        print(msg, flush=True)
        if _FICHIER_LOG is not None:
            try:
                with open(_FICHIER_LOG, "a", encoding="utf-8") as f:
                    f.write(msg + "\n")
            except OSError:
                pass


def _ecrire_event(d: dict) -> None:
    """Écrit un événement dans le fichier JSONL pour le dashboard."""
    if _FICHIER_EVENTS is None:
        return
    d["ts"] = time.strftime("%H:%M:%S")
    try:
        with open(_FICHIER_EVENTS, "a", encoding="utf-8") as f:
            f.write(json.dumps(d, ensure_ascii=False) + "\n")
    except OSError:
        pass


def evaluer_instr(dossier: Path, reglages: regles_mod.Reglages) -> regles_mod.Decision:
    """Version instrumentée de evaluer : affiche + écrit un événement JSONL."""
    _ecrire_event({"type": "test_debut", "nom": dossier.name,
                   "competence": dossier.parent.name})
    t0 = time.monotonic()
    dec = evaluer_base(dossier, reglages)
    dt = time.monotonic() - t0
    verdicts = dec.mesures.get("depart", []) + dec.mesures.get("reference", [])
    vtxt = " | ".join(verdicts) if verdicts else "(aucun verdict)"
    acceptee = dec.acceptee
    raison = "acceptée" if acceptee else dec.raison
    _ecrire_event({"type": "test_fin", "nom": dossier.name,
                   "competence": dossier.parent.name,
                   "acceptee": acceptee, "raison": raison,
                   "duree_s": round(dt, 1), "verdicts": vtxt})
    afficher(f"   [TEST] {'RESSUSCITE' if acceptee else 'REJET'}  {dossier.name}  →  "
             f"{'ACCEPTÉE' if acceptee else dec.raison}  ({dt:.1f} s)  {vtxt}")
    return dec


def main() -> int:
    global _FICHIER_LOG, _FICHIER_EVENTS
    graine = 1
    f1 = 80
    sortie = Path("donnees")
    _FICHIER_LOG = sortie / "chain_verbose_log.txt"
    _FICHIER_LOG.unlink(missing_ok=True)
    _FICHIER_EVENTS = sortie / "chain_events.jsonl"
    _FICHIER_EVENTS.unlink(missing_ok=True)

    # On patche evaluer AU NIVEAU DU MODULE CHAINE (là où il est appelé),
    # pas au niveau de regles (où il est défini).
    with mock.patch.object(chaine_mod, "evaluer", evaluer_instr):
        t0 = time.monotonic()
        afficher(f"== CHAINE DÉMARRAGE ({time.strftime('%H:%M:%S')}), graine={graine}, f1={f1}")
        _ecrire_event({"type": "info", "txt": f"Chaîne démarrée : graine={graine}, f1={f1}"})
        r = chaine_mod.chaine(sortie, graine, travailleurs=4, nombre_f1=f1, afficher=afficher)
        afficher_rapport_local(r)
        afficher(f"== CHAINE FINI ({time.strftime('%H:%M:%S')}), durée {time.monotonic() - t0:.0f} s")
        _ecrire_event({"type": "info", "txt": f"Chaîne terminée : durée {time.monotonic() - t0:.0f} s"})
    return 0 if r["acceptees"] and not r["doublons_avec_geles"] else 1


def afficher_rapport_local(r: dict) -> None:
    afficher(f"\n{'compétence':<11}{'candidates':>11}{'qualifiées':>11}{'gelées':>8}{'acceptées':>10}  rejets")
    for comp, c in r["competences"].items():
        rejets = ", ".join(f"{k} {v}" for k, v in c["rejets"].items()) or "—"
        afficher(f"{comp:<11}{c['candidates']:>11}{c['qualifiees']:>11}{c['gelees']:>8}{c['acceptees']:>10}  {rejets}")
        _ecrire_event({"type": "rapport_ligne", "txt":
                       f"{comp:<11}{c['candidates']:>11}{c['qualifiees']:>11}"
                       f"{c['gelees']:>8}{c['acceptees']:>10}  {rejets}"})
    total = {k: sum(c[k] for c in r["competences"].values()) for k in ("candidates", "qualifiees", "gelees", "acceptees")}
    afficher(f"{'TOTAL':<11}{total['candidates']:>11}{total['qualifiees']:>11}{total['gelees']:>8}{total['acceptees']:>10}")
    afficher("\nRejets du portillon par raison : " + (", ".join(f"{k} {v}" for k, v in r["rejets_par_raison"].items()) or "aucun"))
    afficher(f"Acceptées : {len(r['acceptees'])} | Doublons avec les jeux gelés : {len(r['doublons_avec_geles'])}")


if __name__ == "__main__":
    sys.exit(main())
