"""Session 5 — boucle RFT : filtre, export (SFT, LLaMA-Factory, Unsloth), GGUF et lanceur, tour avec
reprise, agent maison, harnais OpenCode (faux CLI passant par le vrai proxy de capture)."""

from __future__ import annotations

import json
import shutil
import sys
import textwrap
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import pytest

from usine.mesure.client import Reglages, Reponse
from usine.rft import agent, export, filtre, gguf, opencode
from usine.rft.essais import ReglagesRft, essayer, longueur
from usine.rft.tour import lire_registre, selectionner, tour
from usine.taches import calculer_empreinte

RACINE = Path(__file__).resolve().parent.parent


def fausse_tache(racine: Path, comp: str, ident: str) -> Path:
    d = racine / comp / ident
    (d / "depart").mkdir(parents=True)
    (d / "depart" / "project.godot").write_text("[application]\n", encoding="utf-8")
    tache = {"id": ident, "competence": comp, "consigne": f"Consigne {ident}.", "origine": "test",
             "empreinte": "", "gelee": False}
    tache["empreinte"] = calculer_empreinte(d, tache)
    (d / "tache.json").write_text(json.dumps(tache, ensure_ascii=False), encoding="utf-8")
    return d


# ------------------------------------------------------------------ filtre

def test_filtre_garde_la_plus_courte_et_renvoie_les_echecs():
    reg = [{"tache_id": "a", "essai": "0", "ok": "True", "longueur": "50"},
           {"tache_id": "a", "essai": "1", "ok": "True", "longueur": "20"},
           {"tache_id": "a", "essai": "2", "ok": "False", "longueur": "5"},
           {"tache_id": "b", "essai": "0", "ok": "True", "longueur": "30"},
           {"tache_id": "b", "essai": "1", "ok": "True", "longueur": "30"},
           {"tache_id": "c", "essai": "0", "ok": "False", "longueur": "1"}]
    retenus, a_refaire = filtre.retenir(reg)
    assert [(l["tache_id"], l["essai"]) for l in retenus] == [("a", "1"), ("b", "0")]
    assert a_refaire == ["c"]


def test_longueur_compte_contenu_et_appels():
    msgs = [{"role": "user", "content": "xxxxxxxxxx"},
            {"role": "assistant", "content": "abc",
             "tool_calls": [{"id": "1", "type": "function", "function": {"name": "run", "arguments": "{}"}}]},
            {"role": "tool", "tool_call_id": "1", "content": "long résultat ignoré"},
            {"role": "assistant", "content": "fin"}]
    assert longueur(msgs) == 3 + 3 + 2 + 3


# ------------------------------------------------------------------ export

SESSION_AGENT = [
    {"role": "system", "content": "S"},
    {"role": "user", "content": "Tâche"},
    {"role": "assistant", "content": "",
     "tool_calls": [{"id": "a", "type": "function", "function": {"name": "read_file", "arguments": '{"chemin": "x.gd"}'}},
                    {"id": "b", "type": "function", "function": {"name": "list_files", "arguments": "{}"}}]},
    {"role": "tool", "tool_call_id": "a", "content": "contenu"},
    {"role": "tool", "tool_call_id": "b", "content": "res://x.gd"},
    {"role": "assistant", "content": "", "tool_calls": [
        {"id": "c", "type": "function", "function": {"name": "run_tests", "arguments": "{}"}}]},
    {"role": "tool", "tool_call_id": "c", "content": "6/6"},
    {"role": "assistant", "content": "Fait."},
    {"role": "user", "content": "message après la fin, à retirer"},
]
OUTILS = [{"type": "function", "function": {"name": "run_tests", "description": "d", "parameters": {"type": "object"}}}]


def test_sharegpt_alternance_et_appels_multiples():
    propres = export.messages_propres(SESSION_AGENT)
    assert propres[-1] == {"role": "assistant", "content": "Fait."}
    e = export.vers_sharegpt(propres, OUTILS)
    assert [t["from"] for t in e["conversations"]] == ["human", "function_call", "observation", "function_call",
                                                       "observation", "gpt"]
    assert json.loads(e["conversations"][1]["value"]) == [{"name": "read_file", "arguments": {"chemin": "x.gd"}},
                                                          {"name": "list_files", "arguments": {}}]
    assert e["conversations"][2]["value"] == "contenu\nres://x.gd"
    assert e["system"] == "S" and json.loads(e["tools"])[0]["name"] == "run_tests"
    with pytest.raises(ValueError, match="alternance"):
        export.vers_sharegpt([{"role": "assistant", "content": "x"}], [])


def test_yaml_llamafactory_relu_et_sans_packing():
    c = export.config_llamafactory("G:\\llm_lora_trainer\\Qwen3.8-27B", "D:\\d", "D:\\o")
    relu = export.lire_yaml_plat(export.ecrire_yaml(c))
    assert relu == c and relu["model_name_or_path"] == "G:\\llm_lora_trainer\\Qwen3.8-27B"
    assert (relu["packing"], relu["neat_packing"], relu["train_on_prompt"], relu["lora_rank"]) == (False, False, False, 16)
    yaml = pytest.importorskip("yaml")
    assert yaml.safe_load(export.ecrire_yaml(c)) == c


class FausseExclusion:
    def session_exclue(self, entete):
        return entete.get("tache_id") == "gelee"

    def texte_exclu(self, texte):
        return "gelee_par_fragment" if "SECRET" in texte else None


def test_exporter_ecarte_les_taches_gelees(tmp_path):
    sessions = tmp_path / "sessions"
    retenus = []
    for tid, contenu in (("t1", "Fait."), ("gelee", "Fait."), ("t2", "SECRET")):
        msgs = [{"role": "system", "content": "S"}, {"role": "user", "content": "u"},
                {"role": "assistant", "content": contenu}]
        (sessions / tid).mkdir(parents=True)
        lignes = [{"tache_id": tid, "competence": "D1", "tools": []}] + msgs
        (sessions / tid / "essai_0.jsonl").write_text("".join(json.dumps(l) + "\n" for l in lignes), encoding="utf-8")
        retenus.append({"session": f"{tid}/essai_0.jsonl"})
    bilan = export.exporter(retenus, sessions, tmp_path / "export", FausseExclusion(), "BASE")
    assert bilan == {"exportees": 1, "par_competence": {"D1": 1},
                     "ecartees": {"tache_gelee": 1, "reprend_une_tache_gelee": 1}}
    sft = [json.loads(l) for l in (tmp_path / "export" / "sft.jsonl").read_text(encoding="utf-8").splitlines()]
    assert [e["tache_id"] for e in sft] == ["t1"]
    compile((tmp_path / "export" / "unsloth" / "entrainer_unsloth.py").read_text(encoding="utf-8"), "u", "exec")
    u = json.loads((tmp_path / "export" / "unsloth" / "config_unsloth.json").read_text(encoding="utf-8"))
    assert u["packing"] is False and u["rang"] == 16 and u["base"] == "BASE"


# ------------------------------------------------------------------ GGUF et lanceur

def test_conversion_et_lanceur(tmp_path):
    cmd = gguf.commande_conversion(Path("conv.py"), Path("lora"), Path("base"), Path("o.gguf"), python="py")
    assert cmd == ["py", "conv.py", "--base", "base", "--outfile", "o.gguf", "--outtype", "f16", "lora"]
    bat = gguf.ecrire_lanceur(tmp_path / "l.bat", Path("C:/llama/llama-server.exe"), Path("D:/qwen.gguf"),
                              [Path("D:/a.gguf"), Path("D:/b.gguf")])
    octets = bat.read_bytes()
    texte = octets.decode("utf-8")
    assert b"\r\n" in octets and b"\n" not in octets.replace(b"\r\n", b"")
    commande = texte.strip().splitlines()[-1]
    assert "-ngl" not in commande.split() and commande.endswith("--reasoning off --reasoning-budget 0 --no-prefill-assistant")
    assert '--lora "D:/a.gguf" --lora "D:/b.gguf"' in texte and "rem   1 = b.gguf" in texte
    assert "--lora-init-without-apply" not in texte
    with pytest.raises(ValueError, match="interdite"):
        gguf.lanceur_bat(Path("s"), Path("m"), [], options=["-ngl", "99"])


# ------------------------------------------------------------------ tour, reprise

class Coupure(Exception):
    pass


def faux_juge(dossier: Path, texte: str) -> dict:
    ok = "bon" in texte
    return {"ok": ok, "etape": "run_tests", "erreurs": [], "tests": {"total": 1, "passes": int(ok), "echecs": []}}


def test_tour_reprise_sans_doublon(tmp_path):
    taches = [fausse_tache(tmp_path / "taches", "D1", f"d1_{i}") for i in range(4)]
    appels = []

    def appeler(client, msgs, schema, lora, outils=None):
        appels.append(client.graine)
        tid = msgs[1]["content"].split("Consigne ")[1].split(".")[0]
        bon = (tid, client.graine) in {("d1_0", 1), ("d1_0", 2), ("d1_1", 3)}
        return Reponse('{"x": "bon, plus long"}' if (tid, client.graine) == ("d1_0", 1) else
                       ('{"x": "bon"}' if bon else '{"x": "faux"}'), 0.1)

    r = ReglagesRft(n_essais=3, graine=1, maxi_reussites=None)
    sortie = tmp_path / "t1"

    def coupe(*a, **k):
        if len(appels) >= 7:
            raise Coupure()
        return appeler(*a, **k)

    with pytest.raises(Coupure):
        tour(taches, sortie, r, appeler=coupe, afficher=lambda s: None, juger_un_appel=faux_juge)
    assert len(lire_registre(sortie / "registre.csv")) == 6          # 2 tâches finies, la 3e coupée
    appels.clear()
    bilan = tour(taches, sortie, r, appeler=appeler, afficher=lambda s: None, juger_un_appel=faux_juge)
    assert len(appels) == 6 and bilan["reprises"] == 2                # seules les tâches 2 et 3 refaites
    registre = lire_registre(sortie / "registre.csv")
    assert len(registre) == 12 and len({(l["tache_id"], l["essai"]) for l in registre}) == 12
    retenus = lire_registre(sortie / "retenus.csv")
    assert [(l["tache_id"], l["essai"]) for l in retenus] == [("d1_0", "1"), ("d1_1", "2")]
    assert (sortie / "a_refaire.txt").read_text(encoding="utf-8").split() == ["d1_2", "d1_3"]
    assert bilan["export"]["exportees"] == 2
    entete = json.loads((sortie / "sessions" / "d1_0" / "essai_1.jsonl").read_text(encoding="utf-8").splitlines()[0])
    assert entete["verdict_final"]["ok"] is True and entete["graine"] == 2 and entete["harnais"] == "appel"
    # tour suivant : seulement les tâches jamais réussies
    assert [d.name for d in selectionner(tmp_path / "taches", depuis=sortie / "a_refaire.txt")] == ["d1_2", "d1_3"]


def test_selection_refuse_une_tache_gelee(tmp_path):
    fausse_tache(tmp_path / "taches", "D1", "gelee")
    with pytest.raises(ValueError, match="règle 4"):
        selectionner(tmp_path / "taches", exclusion=FausseExclusion())


# ------------------------------------------------------------------ agent maison

def test_definitions_reprennent_les_outils_mcp():
    noms = [d["function"]["name"] for d in agent.definitions()]
    for n in ("vocab_lookup", "search_docs", "scene_write", "apply_edits", "run_tests", "measure_efficiency",
              "list_files", "read_file", "write_file"):
        assert n in noms
    assert all(d["type"] == "function" and "parameters" in d["function"] for d in agent.definitions())


def _appel(i: str, nom: str, args: dict) -> dict:
    return {"id": i, "type": "function", "function": {"name": nom, "arguments": json.dumps(args)}}


def test_agent_execute_les_outils_et_s_arrete(tmp_path):
    projet = tmp_path / "p"
    shutil.copytree(RACINE / "godot" / "reference", projet, ignore=shutil.ignore_patterns("addons", ".godot"))
    script = [
        {"role": "assistant", "content": "", "tool_calls": [
            _appel("1", "write_file", {"chemin": "res://scripts/neuf.gd", "contenu": "extends Node\n"}),
            _appel("2", "read_file", {"chemin": "res://../evasion.gd"}),
            _appel("3", "outil_invente", {})]},
        {"role": "assistant", "content": "", "tool_calls": [_appel("4", "vocab_lookup", {"classe": "Area2D", "membre": "body_entered"})]},
        {"role": "assistant", "content": "Terminé."}]
    recus = []

    def appeler(client, msgs, schema, lora, outils):
        recus.append((len(msgs), lora, len(outils)))
        m = script[len(recus) - 1]
        return Reponse(m["content"], 0.1, message=m)

    msgs, outils, fin = agent.resoudre(projet, "Écrire neuf.gd", "K1", Reglages(), [{"id": 0, "scale": 1.0}], 10, appeler)
    assert fin == "termine" and (projet / "scripts" / "neuf.gd").read_text(encoding="utf-8") == "extends Node\n"
    resultats = [m["content"] for m in msgs if m["role"] == "tool"]
    assert resultats[0].startswith("écrit : res://scripts/neuf.gd")
    assert resultats[1].startswith("Erreur") and "hors du projet" in resultats[1]
    assert resultats[2] == "Erreur : outil inconnu : outil_invente"
    assert resultats[3] == "signal [Area2D] body_entered(body: Node2D)"
    assert recus[0][1] == [{"id": 0, "scale": 1.0}] and msgs[-1] == {"role": "assistant", "content": "Terminé."}
    assert "Fiche de la compétence" in msgs[0]["content"]
    # budget : la session s'arrête au bout de max_pas appels
    boucle = lambda c, m, s, l, o: Reponse("", 0.0, message=script[1])  # noqa: E731
    msgs2, _, fin2 = agent.resoudre(projet, "x", "K2", Reglages(), None, 3, boucle)
    assert fin2 == "budget" and sum(m["role"] == "assistant" for m in msgs2) == 3


def test_essai_agentique_ecrit_sa_session(tmp_path):
    dossier = tmp_path / "K2" / "k2_x"
    shutil.copytree(RACINE / "godot" / "taches_modeles" / "K2" / "k2_001_take_damage", dossier)

    def appeler(client, msgs, schema, lora, outils):
        return Reponse("Fait.", 0.1, message={"role": "assistant", "content": "Fait."})

    vus = []
    e = essayer(dossier, 2, ReglagesRft(), tmp_path / "sessions", appeler,
                juger_projet=lambda d, copie: vus.append((copie / "project.godot").is_file()) or
                {"ok": True, "etape": "run_tests", "erreurs": [], "tests": {}})
    assert e.ok and vus == [True] and e.session == "k2_001_take_damage/essai_2.jsonl"
    lignes = (tmp_path / "sessions" / e.session).read_text(encoding="utf-8").splitlines()
    entete = json.loads(lignes[0])
    assert entete["harnais"] == "agent" and entete["graine"] == 3 and len(entete["tools"]) >= 12
    assert json.loads(lignes[-1]) == {"content": "Fait.", "role": "assistant"}


# ------------------------------------------------------------------ OpenCode (faux CLI, vrai proxy)

class Amont(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self):
        class G(BaseHTTPRequestHandler):
            def do_POST(self):  # noqa: N802
                self.rfile.read(int(self.headers["Content-Length"]))
                d = json.dumps({"choices": [{"message": {"role": "assistant", "content": "Fait par OpenCode."},
                                             "finish_reason": "stop"}], "usage": {}}).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(d)))
                self.end_headers()
                self.wfile.write(d)

            def log_message(self, *a):
                pass

        super().__init__(("127.0.0.1", 0), G)
        threading.Thread(target=self.serve_forever, daemon=True).start()


FAUX_CLI = textwrap.dedent('''
    import json, sys, urllib.request
    from pathlib import Path
    args = sys.argv[1:]
    assert args[:3] == ["run", "--format", "json"] and args[3] == "--dir"
    projet = Path(args[4])
    conf = json.loads((projet / "opencode.json").read_text(encoding="utf-8"))
    assert "usine-godot" in conf["mcp"]
    url = conf["provider"]["llama"]["options"]["baseURL"]
    corps = {"model": "qwen", "messages": [{"role": "user", "content": args[-1]}], "stream": False}
    req = urllib.request.Request(url + "/chat/completions", data=json.dumps(corps).encode(),
                                 headers={"Content-Type": "application/json"})
    urllib.request.urlopen(req).read()
    (projet / "trace_opencode.txt").write_text("passé", encoding="utf-8")
''')


def test_harnais_opencode_par_le_proxy_de_capture(tmp_path):
    cli = tmp_path / "faux_opencode.py"
    cli.write_text(FAUX_CLI, encoding="utf-8")
    copie = tmp_path / "copie"
    (copie / "scripts").mkdir(parents=True)
    amont = Amont()
    try:
        msgs, outils, fin = opencode.resoudre(copie, "Ajouter un piège", "K2",
                                              Reglages(url=f"http://127.0.0.1:{amont.server_address[1]}/v1"),
                                              {"cli": [sys.executable, str(cli)], "fournisseur": "llama", "delai_s": 60})
    finally:
        amont.shutdown()
        amont.server_close()
    assert fin == "termine" and (copie / "trace_opencode.txt").is_file()
    assert not (copie / "opencode.json").exists()                      # retiré avant le jugement
    assert msgs[0]["role"] == "user" and "Ajouter un piège" in msgs[0]["content"]
    assert msgs[-1]["role"] == "assistant" and msgs[-1]["content"] == "Fait par OpenCode."
    assert opencode.commande("opencode", Path("p"), "c", "llama/qwen") == [
        "opencode", "run", "--format", "json", "--dir", "p", "--model", "llama/qwen", "c"]


@pytest.mark.godot
def test_preuve_mini_tour_juste_a_60_pour_cent(tmp_path):
    from usine.rft.preuve import executer_preuve
    res = executer_preuve(tmp_path, afficher=lambda s: None)
    assert all(res["controles"].values()), res["controles"]
    assert len(res["retenus"]) == 3 and len(res["a_refaire"]) == 2 and res["taches_finies_avant_coupure"] == 2


def test_filtre_de_difficulte_ecarte_les_taches_acquises():
    reg = [{"tache_id": t, "essai": str(n), "ok": str(ok), "longueur": "10"}
           for t, oks in (("acquise", [1, 1, 1, 1]), ("utile", [0, 1, 1, 0]), ("dure", [0, 0, 0, 0]))
           for n, ok in enumerate(map(bool, oks))]
    retenus, a_refaire = filtre.retenir(reg)
    gardes, ecartes = filtre.appliquer_difficulte(reg, retenus, essais=4, mini=1, maxi=3)
    assert [l["tache_id"] for l in gardes] == ["utile"] and ecartes == {"acquise": "trop_facile"}
    assert a_refaire == ["dure"]
    assert filtre.appliquer_difficulte(reg, retenus, essais=4, maxi=None) == (retenus, {})
