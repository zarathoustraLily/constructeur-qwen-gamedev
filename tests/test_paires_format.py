"""Format commun des paires : messages rognés, rendu de LLaMA-Factory identique à celui du gabarit (étape A4)."""

from usine.cours.base import opencode
from usine.paires import format as fmt


def test_a_change_ne_retient_que_ce_qui_differe_de_la_base():
    apres = {"a.gd": "un", "b.gd": "deux", "c.gd": "nouveau"}
    base = {"a.gd": "un", "b.gd": "autre"}
    assert [r for r in apres if fmt.a_change(apres, base, r)] == ["b.gd", "c.gd"]
    assert all(fmt.a_change(apres, {}, r) for r in apres)


def test_les_espaces_de_fin_ne_changent_pas_le_rendu(tmp_path):
    image = tmp_path / "vue.png"
    image.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00\x00\x00\x0dIHDR" + (640).to_bytes(4, "big")
                      + (360).to_bytes(4, "big"))
    p = fmt.paire("essai", "gameplay", "analyse", f"{fmt.MARQUE_IMAGE}\nQue voit-on ?  \n\n", "Le joueur.  \n",
                  {}, systeme="# EN PERMANENCE\nle plan.\n", images=[str(image)])
    assert [m["content"] for m in p["messages"]] == ["# EN PERMANENCE\nle plan.",
                                                       f"{fmt.MARQUE_IMAGE}\nQue voit-on ?", "Le joueur."]
    ligne = fmt.vers_llamafactory(p)
    assert opencode.rendre_sharegpt(ligne) == opencode.rendre(p["messages"], [])
    assert ligne["images"] == [str(image)] and ligne["system"] == "# EN PERMANENCE\nle plan."
