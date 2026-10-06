"""Session 6 — mesure : Wilson, règle de victoire (cas limites), non-régression, rapport simulé,
client (faux serveur), traducteurs des réponses, reprise, référence frontière, GameDevBench."""

from __future__ import annotations

import json
import shutil
import threading
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import pytest

from usine.mesure import executer as ex
from usine.mesure import gamedevbench as gdb
from usine.mesure import rapport, reponses, simulation
from usine.mesure.client import ErreurAppel, Reglages, Reponse, completer, extraire_json
from usine.mesure.stats import DEFAITE, EGALITE, NON_MESURE, VICTOIRE, Score, regression, verdict, wilson
from usine.taches import calculer_empreinte

RACINE = Path(__file__).resolve().parent.parent
MODELES = RACINE / "godot" / "taches_modeles"


# ------------------------------------------------------------------ Wilson et règle de victoire

def test_wilson_valeurs_connues():
    s = wilson(5, 10)
    assert (round(s.bas, 4), round(s.haut, 4)) == (0.2366, 0.7634)
    zero, plein = wilson(0, 10), wilson(10, 10)
    assert zero.bas == 0.0 and round(zero.haut, 4) == 0.2775
    assert plein.haut == 1.0 and round(plein.bas, 4) == 0.7225
    assert wilson(0, 0) == Score(0, 0, 0.0, 1.0)
    with pytest.raises(ValueError):
        wilson(3, 2)


def S(k: int, n: int, bas: float, haut: float) -> Score:
    return Score(k, n, bas, haut)


def test_victoire_si_au_dela_de_l_intervalle_et_frontiere_atteinte():
    lora, base = S(40, 50, 0.67, 0.89), S(24, 50, 0.35, 0.61)
    assert verdict(lora, base, S(36, 50, 0.58, 0.83))[0] == VICTOIRE
    # « atteint » : même taux que la frontière (40/50 = 32/40), comparaison exacte des fractions
    assert verdict(lora, base, S(32, 40, 0.65, 0.90))[0] == VICTOIRE


def test_intervalles_qui_se_touchent_ne_suffisent_pas():
    v, motif = verdict(S(30, 50, 0.61, 0.80), S(24, 50, 0.35, 0.61), S(10, 50, 0.1, 0.3))
    assert v == EGALITE and "touchent" in motif


def test_intervalles_qui_se_chevauchent():
    v, motif = verdict(S(30, 50, 0.46, 0.72), S(24, 50, 0.35, 0.61), S(10, 50, 0.1, 0.3))
    assert v == EGALITE and "chevauchent" in motif


def test_frontiere_absente_ou_vide_pas_de_victoire():
    lora, base = S(40, 50, 0.67, 0.89), S(24, 50, 0.35, 0.61)
    for frontiere in (None, Score(0, 0, 0.0, 1.0)):
        v, motif = verdict(lora, base, frontiere)
        assert v == EGALITE and "frontière non mesurée" in motif


def test_sous_la_frontiere():
    v, motif = verdict(S(40, 50, 0.67, 0.89), S(24, 50, 0.35, 0.61), S(41, 50, 0.69, 0.90))
    assert v == EGALITE and "sous la frontière" in motif


def test_defaite_et_non_mesure():
    assert verdict(S(10, 50, 0.11, 0.33), S(30, 50, 0.46, 0.72))[0] == DEFAITE
    # sous base + RAG mais dans l'intervalle : égalité, pas défaite
    assert verdict(S(28, 50, 0.42, 0.69), S(30, 50, 0.46, 0.72))[0] == EGALITE
    assert verdict(None, S(30, 50, 0.46, 0.72))[0] == NON_MESURE
    assert verdict(Score(0, 0, 0.0, 1.0), S(30, 50, 0.46, 0.72))[0] == NON_MESURE


def test_regression_entre_deux_tours():
    ancien = {"D1": wilson(40, 50), "F1": wilson(30, 50), "K1": wilson(30, 50), "S1": wilson(20, 50),
              "S2": wilson(30, 50)}
    nouveau = {"D1": wilson(20, 50), "F1": wilson(28, 50), "K1": wilson(30, 50), "S1": wilson(25, 50),
               "E": wilson(5, 50)}
    statuts = {l["competence"]: (l["statut"], l["bloquant"]) for l in regression(ancien, nouveau)}
    assert statuts == {"D1": ("recul", True), "F1": ("baisse", False), "K1": ("stable", False),
                       "S1": ("hausse", False), "S2": ("absente", True), "E": ("nouvelle", False)}


# ------------------------------------------------------------------ rapport sur résultats simulés

def test_rapport_simule(tmp_path):
    lignes = simulation.simuler()
    assert lignes == simulation.simuler()                       # déterministe
    t = {l["competence"]: l for l in rapport.tableau(lignes, "t0")}
    assert [l["competence"] for l in rapport.tableau(lignes, "t0")][:3] == ["C1", "C2", "S1"]
    assert len(t) == 14
    attendu = {"D1": VICTOIRE, "F1": EGALITE, "K1": EGALITE, "S1": EGALITE, "S2": DEFAITE,
               "C1": NON_MESURE, "E": EGALITE}
    assert {c: t[c]["verdict"] for c in attendu} == attendu
    assert "sous la frontière" in t["F1"]["motif"] and "frontière non mesurée" in t["S1"]["motif"]
    assert t["D1"]["scores"]["lora_rag"].k == 40 and t["D1"]["n"] == 50
    md, fichier_csv = rapport.ecrire(lignes, tmp_path, "t0", notes=["SIMULÉS"])
    texte = md.read_text(encoding="utf-8")
    assert "| D1 | 50 |" in texte and "80,0 % [67,0 ; 88,8] (40/50)" in texte and "**victoire**" in texte
    rangees = fichier_csv.read_text(encoding="utf-8").splitlines()
    assert rangees[0].startswith("competence,n,base_k,base_n,base_taux,base_bas,base_haut,base_rag_k")
    d1 = next(r for r in rangees if r.startswith("D1,"))
    assert ",40,50,0.8000," in d1 and d1.endswith(",victoire,gain sur base + RAG et frontière atteinte")


def test_regression_texte_bloque_sur_un_recul():
    t0 = simulation.simuler(tour="t0")
    t1 = simulation.simuler({**simulation.SCENARIO_DEFAUT, "D1": {"lora_rag": 20}}, tour="t1")
    texte, ok = rapport.texte_regression(t0, t1)
    assert not ok and "RECUL : D1" in texte
    assert rapport.texte_regression(t0, t0)[1]
    with pytest.raises(ValueError, match="plusieurs tours"):
        rapport.tableau(t0 + t1)
    assert rapport.tableau(t0 + t1, "t1")[0]["competence"] == "C1"


# ------------------------------------------------------------------ client (faux serveur)

class FauxServeur:
    """Serveur OpenAI-compatible (et Messages) : enregistre les requêtes, répond par `repondre(corps)`."""

    def __init__(self, repondre):
        self.requetes: list[dict] = []
        parent = self

        class Gestion(BaseHTTPRequestHandler):
            def do_POST(self):  # noqa: N802
                corps = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
                parent.requetes.append({"chemin": self.path, "corps": corps, "entetes": {k.lower(): v for k, v in self.headers.items()}})
                if self.path.endswith("/messages"):
                    rep = {"content": [{"type": "text", "text": parent.repondre(corps)}],
                           "usage": {"input_tokens": 11, "output_tokens": 7}, "stop_reason": "end_turn"}
                else:
                    rep = {"choices": [{"message": {"role": "assistant", "content": parent.repondre(corps)},
                                        "finish_reason": "stop"}], "usage": {"prompt_tokens": 11, "completion_tokens": 7}}
                donnees = json.dumps(rep).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(donnees)))
                self.end_headers()
                self.wfile.write(donnees)

            def log_message(self, *args):
                pass

        self.repondre = repondre
        self.serveur = ThreadingHTTPServer(("127.0.0.1", 0), Gestion)
        self.url = f"http://127.0.0.1:{self.serveur.server_address[1]}/v1"
        threading.Thread(target=self.serveur.serve_forever, daemon=True).start()

    def fermer(self):
        self.serveur.shutdown()
        self.serveur.server_close()


def test_client_openai_schema_lora_et_anthropic():
    faux = FauxServeur(lambda corps: '{"categorie": "autre", "fichier": "res://a.gd", "ligne": 3}')
    try:
        r = Reglages(url=faux.url, modele="qwen", cle="sk-local", max_jetons=128, graine=7)
        rep = completer(r, [{"role": "user", "content": "x"}], reponses.SCHEMAS["D1"], [{"id": 0, "scale": 0.0}])
        corps = faux.requetes[-1]["corps"]
        assert faux.requetes[-1]["chemin"] == "/v1/chat/completions"
        assert corps["response_format"]["type"] == "json_schema"
        assert corps["response_format"]["json_schema"]["schema"] == reponses.SCHEMAS["D1"]
        assert corps["lora"] == [{"id": 0, "scale": 0.0}]
        assert (corps["temperature"], corps["seed"], corps["max_tokens"]) == (0.0, 7, 128)
        assert faux.requetes[-1]["entetes"]["authorization"] == "Bearer sk-local"
        assert extraire_json(rep.contenu)["ligne"] == 3 and (rep.jetons_entree, rep.jetons_sortie) == (11, 7)
        r2 = Reglages(url=faux.url, modele="frontiere", cle="cle", protocole="anthropic")
        rep2 = completer(r2, [{"role": "system", "content": "S"}, {"role": "user", "content": "x"}])
        corps2 = faux.requetes[-1]["corps"]
        assert faux.requetes[-1]["chemin"] == "/v1/messages" and corps2["system"] == "S"
        assert [m["role"] for m in corps2["messages"]] == ["user"]
        assert faux.requetes[-1]["entetes"]["x-api-key"] == "cle" and rep2.fin == "end_turn"
    finally:
        faux.fermer()
    with pytest.raises(ErreurAppel):
        completer(Reglages(url=faux.url, delai_s=2), [{"role": "user", "content": "x"}])


def test_extraire_json():
    assert extraire_json('Voici :\n```json\n{"a": [1, 2]}\n```') == {"a": [1, 2]}
    with pytest.raises(ValueError):
        extraire_json("pas de json")


def test_lora_par_requete():
    r = ex.ReglagesMesure(lora_ids=[0, 1], lora_actif=1)
    assert ex.lora_requete(False, r) == [{"id": 0, "scale": 0.0}, {"id": 1, "scale": 0.0}]
    assert ex.lora_requete(True, r) == [{"id": 0, "scale": 0.0}, {"id": 1, "scale": 1.0}]
    assert ex.lora_requete(False, ex.ReglagesMesure(lora_ids=[])) is None
    with pytest.raises(ValueError):
        ex.lora_requete(True, ex.ReglagesMesure(lora_ids=[]))


# ------------------------------------------------------------------ traducteurs des réponses

def _copie_depart(tmp_path: Path, tache: Path) -> Path:
    copie = tmp_path / "copie"
    shutil.copytree(tache / "depart", copie)
    return copie


def test_appliquer_d1_k1_f1(tmp_path):
    projet = tmp_path / "p"
    shutil.copytree(RACINE / "godot" / "reference", projet, ignore=shutil.ignore_patterns("addons", ".godot"))
    assert reponses.appliquer("D1", {"categorie": "null_instance", "fichier": "res://scripts/hero.gd", "ligne": 4},
                              projet) == ["res://reponse.json"]
    assert json.loads((projet / "reponse.json").read_text(encoding="utf-8"))["ligne"] == 4
    with pytest.raises(reponses.ReponseInvalide):
        reponses.appliquer("D1", {"categorie": "autre", "fichier": "res://a.gd", "ligne": "4"}, projet)
    reponses.appliquer("K1", {"chemin": "res://scripts/neuf.gd", "script": "extends Node"}, projet)
    assert (projet / "scripts" / "neuf.gd").read_text(encoding="utf-8") == "extends Node\n"
    for faux in ("res://../x.gd", "res://addons/x.gd", "scripts/x.gd", "res://scripts/x.txt"):
        with pytest.raises(reponses.ReponseInvalide):
            reponses.appliquer("K1", {"chemin": faux, "script": "extends Node"}, projet)
    valeurs = {"speed": 150.0, "dash_speed": 420.5, "dash_duration": 0.2, "dash_cooldown": 0.75}
    reponses.appliquer("F1", valeurs, projet)
    hero = (projet / "scripts" / "hero.gd").read_text(encoding="utf-8")
    assert "@export var speed: float = 150.0" in hero and "@export var dash_speed: float = 420.5" in hero
    with pytest.raises(reponses.ReponseInvalide):
        reponses.appliquer("F1", {**valeurs, "speed": True}, projet)


def test_appliquer_s2_par_les_editions(tmp_path):
    tache = MODELES / "S2" / "s2_001_mort_du_fantome"
    copie = _copie_depart(tmp_path, tache)
    bonne = {"editions": [{"op": "connect", "source": "ghost:HealthComponent", "signal": "died",
                           "cible": "ghost", "methode": "_on_died"}]}
    assert reponses.appliquer("S2", bonne, copie) == ["res://scenes/ghost.tscn"]
    assert '[connection signal="died" from="HealthComponent" to="." method="_on_died"]' in \
        (copie / "scenes" / "ghost.tscn").read_text(encoding="utf-8")
    with pytest.raises(reponses.ReponseInvalide, match="refusées"):
        reponses.appliquer("S2", {"editions": [{**bonne["editions"][0], "signal": "invente"}]},
                           _copie_depart(tmp_path / "b", tache))


def test_appliquer_s1_par_l_ecrivain(tmp_path):
    from usine.scene.spec import scene_read
    tache = MODELES / "S1" / "s1_001_heart_pickup"
    reference = (tache / "reference" / "scenes" / "heart_pickup.tscn").read_text(encoding="utf-8")
    spec = scene_read(reference, "res://scenes/heart_pickup.tscn")
    copie = _copie_depart(tmp_path, tache)
    reponses.appliquer("S1", {"chemin": "res://scenes/heart_pickup.tscn", "spec": spec}, copie)
    assert (copie / "scenes" / "heart_pickup.tscn").is_file()
    faux = json.loads(json.dumps(spec))
    faux["racine"]["type"] = "Fantome2D"
    with pytest.raises(reponses.ReponseInvalide, match="spec refusée"):
        reponses.appliquer("S1", {"chemin": "res://scenes/x.tscn", "spec": faux}, _copie_depart(tmp_path / "b", tache))


def test_reponse_malformee_jamais_un_plantage(tmp_path, monkeypatch):
    """Relevé sous Windows (2026-10-06) : une spec S1 malformée de Qwen faisait planter le tour."""
    tache = MODELES / "S1" / "s1_001_heart_pickup"
    for spec in ({"racine": {"nom": "A", "type": "Area2D"}, "ressources_internes": ["forme"]},
                 {"racine": "Area2D"}, {"ressources_internes": []},
                 {"racine": {"nom": "A", "type": "Area2D", "enfants": {"nom": "B"}}},
                 {"racine": {"nom": "A", "type": "Area2D"}, "ressources_externes": [{"type": "Script"}]}):
        with pytest.raises(reponses.ReponseInvalide, match="spec refusée"):
            reponses.appliquer("S1", {"chemin": "res://scenes/x.tscn", "spec": spec}, _copie_depart(tmp_path / str(id(spec)), tache))
    # tout autre plantage d'un traducteur devient un verdict « reponse » en échec
    d = fausse_tache(tmp_path / "geles", "D1", "d1_0")

    def plante(*a):
        raise AttributeError("'str' object has no attribute 'get'")

    monkeypatch.setattr(reponses, "appliquer", plante)
    v = reponses.juger_reponse(d, '{"categorie": "autre"}')
    assert (v["ok"], v["etape"]) == (False, "reponse") and "AttributeError" in v["erreurs"][0]["message"]


def test_contexte_et_messages_identiques_hors_rag():
    tache = MODELES / "D1" / "d1_001_identifiant_inconnu"
    consigne = json.loads((tache / "tache.json").read_text(encoding="utf-8"))["consigne"]
    sans = reponses.messages(tache / "depart", consigne, "D1")
    avec = reponses.messages(tache / "depart", consigne, "D1", "## CharacterBody2D\nextrait")
    assert "=== journal.txt ===" in sans[1]["content"] and "res://project.godot" in sans[1]["content"]
    assert sans[0] == avec[0]
    assert avec[1]["content"].replace("Documentation Godot 4.7 (extraits trouvés pour cette tâche) :\n"
                                      "## CharacterBody2D\nextrait\n\n", "") == sans[1]["content"]
    s2 = MODELES / "S2" / "s2_001_mort_du_fantome"
    assert "ghost:HealthComponent" in reponses.contexte(s2 / "depart", "res://scenes/ghost.tscn", "S2")


# ------------------------------------------------------------------ exécution, reprise, frontière

def fausse_tache(racine: Path, comp: str, ident: str) -> Path:
    d = racine / comp / ident
    (d / "depart").mkdir(parents=True)
    (d / "depart" / "project.godot").write_text("[application]\n", encoding="utf-8")
    tache = {"id": ident, "competence": comp, "consigne": f"Consigne {ident}.", "origine": "test",
             "empreinte": "", "gelee": True}
    tache["empreinte"] = calculer_empreinte(d, tache)
    (d / "tache.json").write_text(json.dumps(tache, ensure_ascii=False), encoding="utf-8")
    return d


def faux_juge(dossier: Path, texte: str) -> dict:
    ok = "bon" in texte
    return {"ok": ok, "etape": "run_tests", "erreurs": [] if ok else [{"categorie": "test_failure", "message": "x"}],
            "tests": {"total": 1, "passes": int(ok), "echecs": []}}


class Coupure(Exception):
    pass


def test_executer_quatre_configurations_et_reprise(tmp_path):
    geles = tmp_path / "geles"
    for i in range(3):
        fausse_tache(geles, "D1", f"d1_{i}")
    fausse_tache(geles, "K2", "k2_0")
    appels: list[tuple] = []

    def appeler(client, msgs, schema, lora, couper_apres=None):
        appels.append((msgs[1]["content"], schema, lora))
        if couper_apres is not None and len(appels) > couper_apres:
            raise Coupure()
        bon = "d1_0" in msgs[1]["content"] or ("d1_1" in msgs[1]["content"] and lora and lora[0]["scale"] == 1.0)
        return Reponse('{"x": "bon"}' if bon else '{"x": "faux"}', 0.5)

    def doc(consigne, r):
        return "EXTRAIT-RAG"

    r = ex.ReglagesMesure(lora_ids=[0], tour="t0")
    sortie = tmp_path / "resultats.jsonl"
    with pytest.raises(Coupure):
        ex.executer(geles, sortie, r, appeler=lambda *a: appeler(*a, couper_apres=5), juger=faux_juge, doc=doc,
                    afficher=lambda s: None, agentiques=False)
    assert len(ex.lire_resultats([sortie])) == 5
    appels.clear()
    bilan = ex.executer(geles, sortie, r, appeler=appeler, juger=faux_juge, doc=doc, afficher=lambda s: None,
                        agentiques=False)
    assert (bilan["faites"], bilan["reprises"], bilan["non_mesurees"]) == (7, 5, {"K2": 1})
    assert len(appels) == 7
    lignes = ex.lire_resultats([sortie])
    assert len(lignes) == 12 and len({(l["configuration"], l["tache_id"]) for l in lignes}) == 12
    assert len(sortie.read_text(encoding="utf-8").splitlines()) == 12          # rien en double
    s = rapport.scores(lignes, "t0")["D1"]
    assert (s["base"].k, s["base_rag"].k, s["lora"].k, s["lora_rag"].k) == (1, 1, 2, 2)
    # même prompt pour les 4 configurations, aux extraits du RAG près
    contenus = [l["reponse"] for l in lignes]
    assert all(c in ('{"x": "bon"}', '{"x": "faux"}') for c in contenus)


def test_executer_agentique_par_l_agent_maison(tmp_path):
    geles = tmp_path / "geles"
    shutil.copytree(MODELES / "K2" / "k2_001_take_damage", geles / "K2" / "k2_001_take_damage")
    recus = []

    def appeler(client, msgs, schema, lora, outils=None):
        recus.append((schema, lora, sorted(o["function"]["name"] for o in outils), msgs[1]["content"]))
        return Reponse("Fini.", 0.2, message={"role": "assistant", "content": "Fini."})

    juges = []
    sortie = tmp_path / "res.jsonl"
    bilan = ex.executer(geles, sortie, ex.ReglagesMesure(lora_ids=[0]), configurations=["base", "lora_rag"],
                        appeler=appeler, doc=lambda c, r: "EXTRAIT-RAG", afficher=lambda s: None,
                        juger_projet=lambda d, copie: juges.append(copie.name) or
                        {"ok": True, "etape": "run_tests", "erreurs": [], "tests": {"total": 3, "passes": 3, "echecs": []}})
    assert bilan["faites"] == 2 and bilan["non_mesurees"] == {} and juges == ["projet", "projet"]
    (s0, l0, o0, u0), (s1, l1, o1, u1) = recus
    assert s0 is None and l0 == [{"id": 0, "scale": 0.0}] and l1 == [{"id": 0, "scale": 1.0}]
    assert "search_docs" not in o0 and "search_docs" in o1 and set(o1) - set(o0) == {"search_docs"}
    assert "EXTRAIT-RAG" not in u0 and "EXTRAIT-RAG" in u1
    lignes = {l["configuration"]: l for l in ex.lire_resultats([sortie])}
    assert lignes["base"]["ok"] and lignes["base"]["pas"] == 1 and lignes["base"]["reponse"] == "Fini."
    session = tmp_path / "res.jsonl.sessions" / "lora_rag" / "k2_001_take_damage.jsonl"
    entete = json.loads(session.read_text(encoding="utf-8").splitlines()[0])
    assert entete["configuration"] == "lora_rag" and entete["verdict_final"]["ok"] is True


def test_taches_gelees_refuse_une_tache_modifiee(tmp_path):
    d = fausse_tache(tmp_path / "geles", "D1", "d1_0")
    assert ex.taches_gelees(tmp_path / "geles") == [d]
    (d / "depart" / "project.godot").write_text("[modifie]\n", encoding="utf-8")
    with pytest.raises(ValueError, match="modifiée"):
        ex.taches_gelees(tmp_path / "geles")


def test_juger_reponses_de_la_frontiere(tmp_path):
    geles = tmp_path / "geles"
    d = fausse_tache(geles, "D1", "d1_0")
    tache = json.loads((d / "tache.json").read_text(encoding="utf-8"))
    rep = tmp_path / "frontiere.jsonl"
    for conf, texte, empreinte in (("frontiere", '{"x": "bon"}', tache["empreinte"]),
                                   ("frontiere_rag", '{"x": "faux"}', tache["empreinte"]),
                                   ("frontiere_rag", '{"x": "bon"}', "autre-version")):
        ex.ajouter_ligne(rep, {"tour": "frontiere", "configuration": conf, "tache_id": "d1_0", "competence": "D1",
                               "empreinte": empreinte, "reponse": texte, "duree_appel_s": 2.0, "modele": "f"})
    sortie = tmp_path / "res.jsonl"
    assert ex.juger_reponses(rep, geles, sortie, juger=faux_juge, afficher=lambda s: None) == 2
    assert ex.juger_reponses(rep, geles, sortie, juger=faux_juge, afficher=lambda s: None) == 0   # reprise
    s = rapport.scores(ex.lire_resultats([sortie]))["D1"]
    assert (s["frontiere"].k, s["frontiere_rag"].k) == (1, 0)


def test_frontiere_desactivee_par_defaut_et_jamais_importee(monkeypatch, capsys):
    from usine import config as cfg
    from usine.mesure import frontiere
    monkeypatch.setattr(cfg, "charger_config", lambda *a: {})
    assert frontiere.main(["--appel-externe"]) == 2
    assert "désactivée" in capsys.readouterr().out
    monkeypatch.setattr(cfg, "charger_config", lambda *a: {"frontiere": {"active": True}})
    assert frontiere.main([]) == 2
    assert "non confirmé" in capsys.readouterr().out
    for dossier in ("usine", "mcp_serveur", "outils"):
        for f in (RACINE / dossier).rglob("*.py"):
            if f.name != "frontiere.py":
                texte = f.read_text(encoding="utf-8")
                assert "mesure.frontiere" not in texte and "import frontiere" not in texte, f


def test_frontiere_collecte_avec_le_meme_prompt(tmp_path):
    from usine.mesure import frontiere
    geles = tmp_path / "geles"
    fausse_tache(geles, "D1", "d1_0")
    fausse_tache(geles, "K2", "k2_0")
    recus = []

    def appeler(client, msgs, schema, lora):
        recus.append((msgs, schema, lora))
        return Reponse('{"x": "bon"}', 1.0)

    sortie = tmp_path / "rep.jsonl"
    n = frontiere.collecter(geles, sortie, Reglages(protocole="anthropic"), appeler=appeler,
                            doc=lambda c, r: "EXTRAIT-RAG", afficher=lambda s: None)
    assert n == 2 and [l for l in recus if l[2] is not None] == []
    assert recus[0][1] is None                                       # pas de schéma en protocole anthropic
    sans, avec = recus[0][0], recus[1][0]
    assert sans == reponses.messages(geles / "D1" / "d1_0" / "depart", "Consigne d1_0.", "D1")
    assert avec == reponses.messages(geles / "D1" / "d1_0" / "depart", "Consigne d1_0.", "D1", "EXTRAIT-RAG")
    assert frontiere.collecter(geles, sortie, Reglages(), appeler=appeler, afficher=lambda s: None) == 0


# ------------------------------------------------------------------ GameDevBench

def faux_depot(racine: Path) -> Path:
    depot = racine / "gamedevbench"
    (depot / "gamedevbench" / "src").mkdir(parents=True)
    (depot / "gamedevbench" / "src" / "benchmark_runner.py").write_text("# runner\n", encoding="utf-8")
    (depot / "results").mkdir()
    (depot / "results" / "leaderboard.csv").write_text(
        "rank,model,harness,pass_at_1_percent,ci_95_percent,new\n1,modele-a,Codex,69.97,4.9,true\n"
        "2,modele-b,Claude Code,67.3,5.0,false\n", encoding="utf-8")
    (depot / "tasks.yaml").write_text("tasks:\n- task_0002\n- task_0003\n", encoding="utf-8")
    (depot / "tasks").mkdir()
    (depot / "tasks_gt").mkdir()
    for dossier in ("tasks", "tasks_gt"):
        with zipfile.ZipFile(depot / dossier / "task_0002.zip", "w") as z:
            z.writestr(f"{dossier}/task_0002/task_config.json", json.dumps({"task_id": 2, "instruction": "x"}))
            z.writestr(f"{dossier}/task_0002/project.godot", "")
    return depot


def test_gamedevbench_preparer_commande_score(tmp_path):
    depot = faux_depot(tmp_path)
    assert gdb.verifier_depot(depot) == []
    assert gdb.decompresser(depot) == 2
    assert (depot / "tasks" / "task_0002" / "task_config.json").is_file()
    assert (depot / "tasks_gt" / "task_0002" / "project.godot").is_file()
    assert gdb.lire_liste(depot / "tasks.yaml") == ["task_0002", "task_0003"]
    liste = gdb.ecrire_liste(tmp_path / "l.yaml", ["task_0003"])
    assert gdb.lire_liste(liste) == ["task_0003"]
    r = {"depot": depot, "godot": Path("D:/godot441/godot.exe"), "modele": "llamacpp/qwen", "confinement": "off",
         "python": ["uv", "run", "python"], "agent": "opencode"}
    cmd, env = gdb.commande(r, liste)
    assert cmd[:3] == ["uv", "run", "python"] and cmd[3].replace("\\", "/") == "gamedevbench/src/benchmark_runner.py"
    assert cmd[4:10] == ["--agent", "opencode", "--model", "llamacpp/qwen", "--confinement", "off"]
    assert cmd[10:12] == ["run", "--task-list"] and env == {"GODOT_EXEC_PATH": str(r["godot"])}
    resultats = tmp_path / "final_results.json"
    resultats.write_text(json.dumps({"success": 2, "tasks_attempted": 3, "task_success_rate": 66.67, "tasks": [
        {"task_name": "task_0002", "success": True}, {"task_name": "task_0003", "success": False},
        {"task_name": "task_0004", "success": True}]}), encoding="utf-8")
    s, info = gdb.score(resultats)
    assert (s.k, s.n) == (2, 3) and info["taux_publie_par_le_runner"] == 66.67
    lignes = gdb.lignes_rapport(s, info, gdb.classement(depot))
    assert any("modele-a" in l and "69.97 %" in l for l in lignes)
    assert any("seul le score sur les 333 tâches est comparable" in l for l in lignes)


def test_gamedevbench_refuse_une_archive_qui_remonte(tmp_path):
    depot = faux_depot(tmp_path)
    with zipfile.ZipFile(depot / "tasks" / "task_0009.zip", "w") as z:
        z.writestr("../evasion.txt", "x")
    with pytest.raises(ValueError, match="refusé"):
        gdb.decompresser(depot)
    assert not (tmp_path / "evasion.txt").exists()


# ------------------------------------------------------------------ de bout en bout (Godot)

@pytest.mark.godot
def test_mesure_de_bout_en_bout_d1_contre_un_faux_serveur(tmp_path):
    """Deux tâches D1 modèles « gelées » ; le faux serveur répond juste pour la première et se
    trompe de ligne pour la seconde. Le vrai juge (GdUnit4) note les réponses."""
    geles = tmp_path / "geles"
    attendues = {}
    for ident in ("d1_001_identifiant_inconnu", "d1_002_cible_nulle"):
        shutil.copytree(MODELES / "D1" / ident, geles / "D1" / ident)
        attendues[ident] = json.loads((MODELES / "D1" / ident / "reference" / "reponse.json").read_text(encoding="utf-8"))

    def repondre(corps):
        texte = corps["messages"][1]["content"]
        for ident, rep in attendues.items():
            if f"{rep['fichier']}:{rep['ligne']}" in texte:
                juste = ident.startswith("d1_001")
                return json.dumps({**rep, "ligne": rep["ligne"] if juste else rep["ligne"] + 1})
        return "{}"

    faux = FauxServeur(repondre)
    try:
        r = ex.ReglagesMesure(client=Reglages(url=faux.url), lora_ids=[0])
        sortie = tmp_path / "res.jsonl"
        bilan = ex.executer(geles, sortie, r, configurations=["base", "lora_rag"], doc=lambda c, rr: "EXTRAIT",
                            afficher=lambda s: None)
    finally:
        faux.fermer()
    assert bilan["faites"] == 4
    lignes = {(l["configuration"], l["tache_id"]): l for l in ex.lire_resultats([sortie])}
    for conf in ("base", "lora_rag"):
        assert lignes[(conf, "d1_001_identifiant_inconnu")]["ok"] is True
        assert lignes[(conf, "d1_002_cible_nulle")]["ok"] is False
        assert lignes[(conf, "d1_002_cible_nulle")]["etape"] == "run_tests"
    loras = [q["corps"]["lora"] for q in faux.requetes]
    assert {json.dumps(l) for l in loras} == {json.dumps([{"id": 0, "scale": 0.0}]), json.dumps([{"id": 0, "scale": 1.0}])}
    assert sum("EXTRAIT" in q["corps"]["messages"][1]["content"] for q in faux.requetes) == 2
