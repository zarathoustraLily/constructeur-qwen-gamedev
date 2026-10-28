"""Famille « démarche » (usine/paires/demarche.py) : le pas est écarté quand la sortie rejouée ne contient pas ce
qu'il attend ou ce qu'il cite ; la paire suit la forme d'OpenCode (appel du Code Mode, vraie sortie, lecture) ; une
réponse qui cite une convention du plan va au palier 2, plan compris ; le journal du cours boss_action_rpg est bien
formé."""

from __future__ import annotations

import json

from usine import config as cfg
from usine.paires import demarche
from usine.paires import format as fmt


class FauxOutils:
    """Les outils du serveur MCP, réduits à des sorties connues."""

    def search_docs(self, requete: str, n: int) -> str:
        return f"## Area3D.monitorable  (classes/class_area3d.rst)\nIf true, other monitoring areas can detect this area."

    def vocab_lookup(self, classe: str, membre: str) -> str:
        return f"propriété [{classe}] {membre}: Basis"


PAS = {"id": "essai", "etape": 5, "sujet": "Physique", "type": "analyse",
       "situation": "Une zone doit-elle surveiller pour être touchée par un rayon ?",
       "pensee": "Je lis la documentation.",
       "outil": {"genre": "rag", "requete": "Area3D monitorable", "n": 1},
       "attendu": ["other monitoring areas"],
       "lecture": "« If true, other monitoring areas can detect this area. »",
       "decision": "Je coupe monitoring et un test le confirme."}


def test_une_citation_absente_de_la_sortie_ecarte_le_pas():
    faux = dict(PAS, lecture="« Rays always detect areas. »")
    q, raison = demarche.paire("essai", faux, FauxOutils())
    assert q is None and "citation absente" in raison
    faux = dict(PAS, attendu=["collide_with_areas"])
    q, raison = demarche.paire("essai", faux, FauxOutils())
    assert q is None and "fragment attendu absent" in raison


def test_la_paire_suit_la_forme_d_opencode():
    q, raison = demarche.paire("essai", PAS, FauxOutils())
    assert raison == "" and q["preuve"]["palier"] == 1
    roles = [m["role"] for m in q["messages"]]
    assert roles == ["user", "assistant", "tool", "assistant"]
    appel = q["messages"][1]["tool_calls"][0]["function"]
    assert appel["name"] == "execute" and 'tools["usine-godot"].search_docs' in appel["arguments"]["code"]
    assert q["messages"][2]["content"].endswith("can detect this area.")
    assert q["type"] in fmt.TYPES and q["jetons"] <= demarche.PLAFONDS[1]


def test_une_convention_du_plan_va_au_palier_2():
    q, _ = demarche.paire("essai", dict(PAS, decision="Les réglages vont dans 5_data/boss/."), FauxOutils())
    assert q["preuve"]["palier"] == 2 and q["messages"][0]["role"] == "system"


def test_le_journal_du_cours_est_bien_forme():
    journal = json.loads((cfg.RACINE / "cours" / "boss_action_rpg" / "demarche.json").read_text(encoding="utf-8"))
    ids = [p["id"] for p in journal["pas"]]
    assert len(ids) == len(set(ids))
    for p in journal["pas"]:
        assert p["type"] in fmt.TYPES and p["outil"]["genre"] in demarche.CODES
        assert {"situation", "pensee", "attendu", "lecture", "decision", "sujet", "etape"} <= set(p)
