"""Les garde-fous de la carte graphique (usine/garde_carte.py) : aucun de ces tests ne touche à la carte."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

from usine import bureau_cache, garde_carte
from usine.cours.base import godot
from usine.paires import volume
from usine.processus import Resultat

RACINE = Path(__file__).resolve().parents[1]
windows = pytest.mark.skipif(sys.platform != "win32", reason="verrou et bureau caché de Windows")
VRAI_CARTE_PRISE = garde_carte.carte_prise
# Ce que le poste de laurent montrait le 2026-11-01.
SORTIE_COMFYUI = ("D:\\Comfyui 04 Vace\\python_embeded\\python.exe\n"
                  ".\\python_embeded\\python.exe  -s ComfyUI\\main.py --windows-standalone-build\n")
SORTIE_USINE = "C:\\Python312\\python.exe\npython -m usine.paires bloc --cours fluides\n"
SORTIE_QWEN = "E:\llama\llama-server.exe\nllama-server.exe  -m \"E:\llama_models\qwen3.8\modele.gguf\" -ngl 99\n"
VIOLATION = -1073741819  # 0xC0000005
# bureau_cache.main dans un processus à part, sans regarder ComfyUI : ces lancements ne se servent pas de la carte.
SANS_COMFYUI = ("import sys\n"
                "from usine import bureau_cache, garde_carte\n"
                "garde_carte.carte_prise = lambda: False\n"
                "sys.exit(bureau_cache.main(sys.argv[1:]))\n")


@pytest.fixture(autouse=True)
def carte_libre(tmp_path, monkeypatch):
    monkeypatch.setattr(garde_carte, "_fichier", lambda extension: tmp_path / f"carte.{extension}")
    monkeypatch.setattr(garde_carte, "carte_prise", lambda: False)
    yield
    if garde_carte._VERROU is not None:
        garde_carte._VERROU.close()
        garde_carte._VERROU = None


def plantages(*instants: float) -> None:
    for t in instants:
        assert garde_carte.noter_fin(0xC0000005, t)


def test_trois_plantages_en_dix_minutes_arretent_la_carte_jusqu_au_rearmement():
    plantages(0, 60)
    assert garde_carte.entrer() is None
    plantages(120)
    code, raison = garde_carte.entrer()
    assert code == garde_carte.CODE_REFUSEE and "--rearmer" in raison
    assert not garde_carte.noter_fin(0, 100_000)
    assert garde_carte.entrer()[0] == garde_carte.CODE_REFUSEE
    garde_carte.rearmer()
    assert garde_carte.entrer() is None


def test_des_plantages_espaces_n_arretent_rien():
    plantages(0, 400, 800, 1200)
    assert garde_carte.entrer() is None


@pytest.mark.parametrize("code", [0, 1, 100, 101])
def test_un_test_rouge_n_est_pas_un_plantage(code):
    assert not garde_carte.noter_fin(code, 0)


@pytest.mark.parametrize("code", [0xC0000005, 0xC0000409, 0xFFFFFFFF])
def test_une_exception_du_systeme_est_un_plantage(code):
    assert garde_carte.est_plantage(code)


def test_un_etat_rempli_de_zeros_par_un_arret_brutal_ne_bloque_rien():
    garde_carte._fichier("json").write_bytes(b"\0" * 64)
    assert garde_carte.entrer() is None
    plantages(0)


@windows
def test_un_seul_godot_a_la_fois_sur_la_carte():
    import msvcrt
    with garde_carte._fichier("verrou").open("a+b") as autre:
        msvcrt.locking(autre.fileno(), msvcrt.LK_NBLCK, 1)
        assert garde_carte.entrer()[0] == garde_carte.CODE_OCCUPEE
    assert garde_carte.entrer() is None


@windows
@pytest.mark.parametrize("sortie, attendu", [(SORTIE_COMFYUI, True), (SORTIE_QWEN, True), (SORTIE_USINE, False)])
def test_comfyui_se_reconnait_a_ses_processus(monkeypatch, sortie, attendu):
    monkeypatch.setattr(garde_carte.subprocess, "run", lambda *a, **k: SimpleNamespace(returncode=0, stdout=sortie))
    assert VRAI_CARTE_PRISE() is attendu


@windows
def test_dans_le_doute_la_carte_attend(monkeypatch):
    def echec(*a, **k):
        raise subprocess.TimeoutExpired("powershell", 60)
    monkeypatch.setattr(garde_carte.subprocess, "run", echec)
    assert VRAI_CARTE_PRISE() is True


def test_comfyui_fait_attendre(monkeypatch):
    monkeypatch.setattr(garde_carte, "carte_prise", lambda: True)
    code, raison = garde_carte.entrer()
    assert code == garde_carte.CODE_OCCUPEE and "ComfyUI" in raison


def test_la_carte_integree_n_attend_pas_comfyui(monkeypatch):
    monkeypatch.setattr(garde_carte, "carte_prise", lambda: True)
    assert garde_carte.entrer(sur_la_5090=False) is None


def test_la_carte_integree_garde_l_arret_apres_les_plantages():
    plantages(0, 60, 120)
    assert garde_carte.entrer(sur_la_5090=False)[0] == garde_carte.CODE_REFUSEE


def test_sur_la_carte_integree_il_faut_huit_plantages():
    for t in range(garde_carte.PLANTAGES_MAX_INTEGREE - 1):
        assert garde_carte.noter_fin(0xC0000005, t, limite=garde_carte.PLANTAGES_MAX_INTEGREE)
    assert garde_carte.entrer(sur_la_5090=False) is None
    garde_carte.noter_fin(0xC0000005, 8, limite=garde_carte.PLANTAGES_MAX_INTEGREE)
    assert garde_carte.entrer(sur_la_5090=False)[0] == garde_carte.CODE_REFUSEE


def test_vulkan_part_sur_la_carte_integree_sans_changer_ses_arguments():
    commande = ["godot", "--path", ".", "--rendering-driver", "vulkan", "++", "--shot=a.png"]
    assert garde_carte.vers_carte_integree(commande) == ["godot", "--gpu-index", "1", *commande[1:]]


@pytest.mark.parametrize("commande", [["godot", "--rendering-driver", "opengl3", "--quit-after", "6000"],
                                      ["godot", "--gpu-index", "0", "--rendering-driver", "vulkan"],
                                      ["godot", "--path", "."]])
def test_le_reste_reste_ou_il_est(commande):
    assert garde_carte.vers_carte_integree(commande) is None


def test_une_famille_attend_son_tour_hors_du_delai(monkeypatch, capsys):
    occupee = Resultat(garde_carte.CODE_OCCUPEE, "carte occupée : ComfyUI tourne\n", 0.1)
    reponses = [occupee, occupee, Resultat(0, "fini", 1.0)]
    attentes: list[float] = []
    monkeypatch.setattr(garde_carte, "executer", lambda commande, **options: reponses.pop(0))
    monkeypatch.setattr(garde_carte.time, "sleep", attentes.append)
    assert garde_carte.executer_carte(["godot"]).sortie == "fini"
    assert attentes == [garde_carte.ATTENTE_S] * 2
    assert capsys.readouterr().out.count("j'attends") == 1


def test_une_carte_arretee_arrete_tout_le_volume(monkeypatch, tmp_path):
    refus = Resultat(garde_carte.CODE_REFUSEE, "carte arrêtée", 0.1)
    monkeypatch.setattr(garde_carte, "executer", lambda commande, **options: refus)
    monkeypatch.setattr(volume, "_familles", lambda nom, cours: [(f"{nom} fluides", lambda: garde_carte.executer_carte(["godot"]))])
    with pytest.raises(garde_carte.CarteRefusee, match="carte arrêtée"):
        volume.lancer(["bloc"], tmp_path / "volume.log", ["fluides"])


def test_godot_passe_par_la_garde_seulement_sur_la_carte(monkeypatch, tmp_path):
    vus: list[str] = []
    monkeypatch.setattr(godot.cfg, "chemin_godot", lambda: "godot")
    monkeypatch.setattr(godot, "executer_carte", lambda commande, **options: vus.append("carte") or Resultat(0, "", 0.1))
    monkeypatch.setattr(godot, "executer", lambda commande, **options: vus.append("sans carte") or Resultat(0, "", 0.1))
    godot._lancer_vraiment(["--path", "."], str(tmp_path), 10, ["python", "bureau_cache.py"], None)
    godot._lancer_vraiment(["--headless", "--path", "."], str(tmp_path), 10, None, None)
    assert vus == ["carte", "sans carte"]


@windows
def test_le_bureau_cache_ne_lance_rien_sur_un_refus(monkeypatch, capsys):
    monkeypatch.setattr(garde_carte, "entrer", lambda sur_la_5090: (garde_carte.CODE_REFUSEE, "carte arrêtée"))
    monkeypatch.setattr(bureau_cache.ctypes, "WinDLL", lambda *a, **k: pytest.fail("rien ne devait partir"))
    assert bureau_cache.main(["godot"]) == garde_carte.CODE_REFUSEE
    assert "carte arrêtée" in capsys.readouterr().out


def _environnement(dossier: Path) -> dict[str, str]:
    return {**os.environ, "TEMP": str(dossier), "TMP": str(dossier), "PYTHONPATH": str(RACINE)}


def _tour(dossier: Path, code: int) -> int:
    """Un petit programme sur le vrai bureau caché, qui sort avec `code`."""
    return subprocess.run([sys.executable, "-c", SANS_COMFYUI, sys.executable, "-c", f"import os; os._exit({code})"],
                          env=_environnement(dossier), cwd=dossier, timeout=60).returncode


@windows
def test_de_bout_en_bout_trois_plantages_bloquent_les_lancements_suivants(tmp_path):
    assert _tour(tmp_path, 7) == 7
    for _ in range(3):
        assert _tour(tmp_path, VIOLATION) != garde_carte.CODE_REFUSEE
    assert _tour(tmp_path, 0) == garde_carte.CODE_REFUSEE
    rearmer = subprocess.run([sys.executable, str(RACINE / "usine" / "bureau_cache.py"), "--rearmer"],
                             env={**_environnement(tmp_path), "PYTHONPATH": ""}, cwd=tmp_path, timeout=60)
    assert rearmer.returncode == 0
    assert _tour(tmp_path, 0) == 0
