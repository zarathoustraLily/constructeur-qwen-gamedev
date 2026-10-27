"""Famille « chercher dans le RAG, puis employer ce qu'il rend » (B6) : requête, page trouvée, paire en tours."""

from usine.paires import format as fmt, rag

SORTIE = """## Input.mouse_mode  (classes/class_input.rst)
propriété de Input
MouseMode mouse_mode 

- |void| set_mouse_mode(value: MouseMode)
- MouseMode get_mouse_mode()

Controls the mouse mode.

## Input  (classes/class_input.rst)
Inherits: Object"""


def test_le_bloc_du_membre_et_ce_qu_il_dit():
    b = rag.bloc(SORTIE, "Input.mouse_mode")
    assert b.startswith("## Input.mouse_mode") and "Inherits" not in b
    assert rag.ce_que_dit(b) == ("MouseMode mouse_mode", "Controls the mouse mode.")
    assert rag.bloc(SORTIE, "Input.is_action_pressed") is None


def test_les_requetes_visent_les_membres_du_moteur():
    fonction = "func f(v: bool) -> void:\n\tInput.mouse_mode = Input.MOUSE_MODE_CAPTURED if v else Input.MOUSE_MODE_VISIBLE"
    assert rag.requetes(fonction, fonction)[0] == "Input.mouse_mode"


def test_la_paire_en_tours_finit_par_une_reponse_et_compte_l_appel():
    tours = [{"role": "user", "content": "Écris f."},
             {"role": "assistant", "content": "Je vérifie :", "tool_calls": [
                 fmt.appel("a1", "execute", {"code": rag.CODE.format(requete="Input.mouse_mode", n=2)})]},
             {"role": "tool", "tool_call_id": "a1", "content": SORTIE},
             {"role": "assistant", "content": "**Écrire.** f"}]
    p = fmt.paire_tours("rag", "UI", "création", tours, {})
    sans_appel = fmt.jetons_reponse([{"role": "assistant", "content": "Je vérifie :"},
                                     {"role": "assistant", "content": "**Écrire.** f"}])
    assert p["jetons_reponse"] > sans_appel  # l'appel d'outil compte dans les jetons de réponse
    ligne = fmt.vers_llamafactory(p)
    assert [t["from"] for t in ligne["conversations"]] == ["human", "gpt", "human", "gpt"]
    assert 'tools["usine-godot"].search_docs' in ligne["conversations"][1]["value"]
