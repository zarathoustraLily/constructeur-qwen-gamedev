"""Le débogage et l'analyse au palier de 2 048 jetons : tirés de paires et de sessions déjà vérifiées, avec le plan."""

from __future__ import annotations

from usine.paires import analyse_sessions, debogage_boucle
from usine.paires import format as fmt

REPONSE = """**Lire l'erreur.** Godot signale, dans `res://1_core/a.gd` ligne 3 : « SCRIPT ERROR: Parse Error ».

**Chercher.**
La fonction s'appelle `_finish`.

**Corriger.** Une seule ligne change :
Dans `res://1_core/a.gd`, ligne 3, je remplace :
```gdscript
	_finish_choix()
```
par :
```gdscript
	_finish()
```

**Tester.** Je relance la même commande :
```
$ godot --headless --path . --check-only -s res://1_core/a.gd
```"""


def _source(**preuve) -> dict:
    base = {"commande": "godot --headless --path . --check-only -s res://1_core/a.gd", "sortie": "SCRIPT ERROR",
            "code": 1, "sortie_apres": "", "code_apres": 0, "etape": "boss-003", "fichier": "1_core/a.gd", "ligne": 3,
            "genre": "appel"}
    return {"famille": "compilation", "sujet": "gameplay", "type": "débogage", "preuve": {**base, **preuve},
            "messages": [{"role": "user", "content": "Corrige l'erreur."}, {"role": "assistant", "content": REPONSE}]}


def test_la_correction_passe_par_edit_puis_la_vraie_sortie_est_lue(monkeypatch):
    monkeypatch.setattr(debogage_boucle, "dossier_jeu", lambda cours: "D:\\jeu")
    q, raison = debogage_boucle.paire("boss_action_rpg", _source(), "extends Node\n\t_finish()\n")
    assert raison == "" and q["type"] == "débogage" and q["messages"][0]["role"] == "system"
    appels = q["messages"][2]["tool_calls"]
    assert [a["function"]["name"] for a in appels] == ["edit", "shell"]
    assert appels[0]["function"]["arguments"]["oldString"].strip() == "_finish_choix()"
    assert appels[0]["function"]["arguments"]["path"] == "D:\\jeu\\1_core\\a.gd"
    assert "code 0" in q["messages"][4]["content"] and "ligne 3" in q["messages"][-1]["content"]


def test_un_passage_fautif_deja_present_ailleurs_est_ecarte():
    q, raison = debogage_boucle.paire("boss_action_rpg", _source(), "\t_finish_choix()\n")
    assert q is None and "unique" in raison


def test_une_sortie_qui_ne_passe_pas_est_ecartee():
    q, raison = debogage_boucle.paire("boss_action_rpg", _source(sortie_apres="SCRIPT ERROR", code_apres=1), "\t_finish()\n")
    assert q is None and "lecture" in raison


def test_la_meme_faute_s_analyse_sans_rien_modifier():
    source = _source()
    source["messages"][0]["content"] = "La sortie.\n\nCorrige l'erreur."
    q, raison = debogage_boucle.paire_analyse(source)
    assert raison == "" and q["type"] == "analyse" and q["messages"][0]["content"] == fmt.plan()
    assert "sans rien modifier" in q["messages"][1]["content"] and "Corrige" not in q["messages"][1]["content"]
    reponse = q["messages"][2]["content"]
    assert "**À changer.**" in reponse and "_finish()" in reponse and "tool_calls" not in q["messages"][2]


def test_l_analyse_quitte_la_consigne_d_opencode_et_prend_le_plan():
    exemple = {"tache_id": "kart-001-analyse-1", "sujet": "gameplay, VFX", "type": "analyse", "messages": [
        {"role": "system", "content": "consigne d'OpenCode"}, {"role": "user", "content": "Dis-moi ce qui ne va pas."},
        {"role": "assistant", "content": "La ligne 3 appelle une fonction absente."}]}
    q, raison = analyse_sessions.paire("kart", exemple)
    assert raison == "" and q["sujet"] == "gameplay" and q["messages"][0]["content"] == fmt.plan()
    assert all("consigne d'OpenCode" not in m["content"] for m in q["messages"])
