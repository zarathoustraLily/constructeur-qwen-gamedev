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


def test_le_sujet_s_ecrit_comme_dans_les_autres_familles():
    assert [demarche.sujet(s) for s in ("Graphisme 3D", "VFX", "UI", "Gestion de la mémoire")] == [
        "graphisme 3D", "VFX", "UI", "gestion de la mémoire"]


def test_le_plan_vient_du_manifeste_et_coche_ce_qui_est_fait():
    (_, arguments, retour), = demarche._plan("boss_action_rpg", {"de": 16, "a": 18})
    lignes = arguments["content"].splitlines()
    assert len(lignes) == 18 and lignes[14].startswith("- [x] 15.") and lignes[15].startswith("- [ ] 16. Le saut")
    assert arguments["path"].endswith("plan.md") and retour.startswith("Wrote file")


def test_lire_rend_les_lignes_numerotees_du_projet_de_l_etape(tmp_path, monkeypatch):
    (tmp_path / "a.gd").write_text("extends Node\nvar x: int = 1\n", encoding="utf-8")
    monkeypatch.setattr(demarche, "_projet", lambda cours, etape: tmp_path)
    monkeypatch.setattr(demarche, "chemin_jeu", lambda cours, rel: "D:\\jeu\\" + rel)
    (nom, arguments, retour), = demarche._lire("essai", {"etape": 1, "fichier": "a.gd", "debut": 2, "fin": 2})
    assert nom == "read" and arguments == {"path": "D:\\jeu\\a.gd", "offset": 2, "limit": 1}
    assert "2: var x: int = 1" in retour


def test_une_sonde_qui_ne_finit_pas_par_zero_est_ecartee(monkeypatch):
    faux = {"genre": "sonde", "etape": 1, "script": "s.gd"}
    monkeypatch.setattr(demarche, "_sonde", lambda cours, outil: [("shell", {"command": "godot"}, "rien\nCommand exited with code 1.")])
    q, raison = demarche.paire("essai", dict(PAS, outil=faux, attendu=["rien"], lecture="« rien »"), FauxOutils())
    assert q is None and "code 0" in raison


def test_le_journal_du_cours_est_bien_forme():
    journal = json.loads((cfg.RACINE / "cours" / "boss_action_rpg" / "demarche.json").read_text(encoding="utf-8"))
    ids = [p["id"] for p in journal["pas"]]
    assert len(ids) == len(set(ids))
    for p in journal["pas"]:
        assert p["type"] in fmt.TYPES and p["outil"]["genre"] in ("rag", "vocab", "lire", "sonde", "plan")
        assert {"situation", "pensee", "attendu", "lecture", "decision", "sujet", "etape"} <= set(p)
