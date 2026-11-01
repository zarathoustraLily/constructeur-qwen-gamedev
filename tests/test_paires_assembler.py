"""Assembleur des paliers (B8, D4) : palier de chaque paire, partage 40/40/20 par sujet, trous signalés."""

import random

from usine.paires import assembler, format as fmt


def test_un_doublon_se_reconnait_a_la_duree_pres():
    paire = lambda sortie, fin: {"messages": [{"role": "system", "content": "plan"}, {"role": "user", "content": "demande"},  # noqa: E731
                                              {"role": "assistant", "content": sortie}, {"role": "assistant", "content": fin}]}
    a = dict(paire("x", "cas FAILED 25ms, total 1s 102ms"), jetons=1)
    b = dict(paire("y", "cas FAILED 31ms, total 2s 9ms"), jetons=1)
    c = dict(paire("x", "cas PASSED 25ms"), jetons=1)
    assert assembler._cle(a) == assembler._cle(b) != assembler._cle(c)
    assert assembler._cle(dict(a, images=["a.png"])) != assembler._cle(dict(a, images=["b.png"]))


def _p(type_, sujet, n, systeme=None, jetons=500):
    messages = ([{"role": "system", "content": systeme}] if systeme else []) + [
        {"role": "user", "content": "demande"}, {"role": "assistant", "content": f"réponse {type_} {n}"}]
    return {"famille": "f", "sujet": sujet, "type": type_, "messages": messages, "images": [], "preuve": {},
            "jetons": jetons, "jetons_reponse": n}


def test_le_palier_suit_la_section_3():
    assert assembler.palier(_p("analyse", "UI", 10)) == (1, "")
    assert assembler.palier(_p("analyse", "UI", 10, jetons=1500))[0] is None
    assert assembler.palier(_p("analyse", "UI", 10, systeme=fmt.plan(), jetons=1500)) == (2, "")
    assert assembler.palier(_p("analyse", "UI", 10, systeme="autre", jetons=600))[0] is None
    assert assembler.palier(_p("analyse", "UI", 10, systeme=fmt.plan(), jetons=2100))[0] is None


def test_le_debogage_n_est_jamais_coupe_et_un_type_court_n_enleve_rien():
    def paire(type_: str, jetons: int) -> dict:
        return {"sujet": "gameplay", "type": type_, "jetons_reponse": jetons}

    paires = [paire("débogage", 100) for _ in range(40)] + [paire("création", 100) for _ in range(10)]
    paires += [paire("analyse", 100) for _ in range(50)]
    gardees, trous = assembler.equilibrer(paires, random.Random(1))
    compte = {t: sum(1 for p in gardees if p["type"] == t) for t in assembler.CIBLE}
    assert compte["débogage"] == 40 and compte["création"] == 10
    assert 19 <= compte["analyse"] <= 21
    assert any("création" in t for t in trous)


def test_la_creation_n_est_jamais_coupee_non_plus():
    def paire(type_: str) -> dict:
        return {"sujet": "gameplay", "type": type_, "jetons_reponse": 100}

    paires = [paire("création") for _ in range(40)] + [paire("débogage") for _ in range(10)]
    paires += [paire("analyse") for _ in range(50)]
    gardees, trous = assembler.equilibrer(paires, random.Random(1))
    compte = {t: sum(1 for p in gardees if p["type"] == t) for t in assembler.CIBLE}
    assert compte["création"] == 40 and compte["débogage"] == 10 and 19 <= compte["analyse"] <= 21
    assert any("débogage" in t for t in trous)


def test_le_partage_par_sujet_vise_40_40_20():
    paires = ([_p("création", "UI", 100) for _ in range(9)] + [_p("débogage", "UI", 100) for _ in range(9)]
              + [_p("analyse", "UI", 100) for _ in range(9)] + [_p("analyse", "audio", 100)])
    gardees, trous = assembler.equilibrer(paires, random.Random(1))
    parts = assembler.parts(gardees)["UI"]
    assert abs(parts["création"] - 0.4) < 0.05 and abs(parts["débogage"] - 0.4) < 0.05
    assert abs(parts["analyse"] - 0.2) < 0.05
    assert trous == ["audio : pas de création, débogage"]
    assert sum(1 for p in gardees if p["sujet"] == "audio") == 1  # un sujet incomplet n'est pas réduit
