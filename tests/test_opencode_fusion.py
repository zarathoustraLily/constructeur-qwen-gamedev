"""Fusion de la config OpenCode d'un projet : ajoute l'usine, ne touche à rien d'autre."""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "outils"))
import opencode_fusion as fusion  # noqa: E402

GODOT_AI = {"type": "local", "enabled": True, "command": ["godot-ai.exe"], "timeout": 120000}


def _projet(tmp: Path, contenu: dict | str | None) -> Path:
    projet = tmp / "projet"
    projet.mkdir()
    (projet / "project.godot").write_text("", encoding="utf-8")
    if contenu is not None:
        texte = contenu if isinstance(contenu, str) else json.dumps(contenu)
        (projet / "opencode.json").write_text(texte, encoding="utf-8")
    return projet


def test_fusion_garde_godot_ai_et_sauvegarde(tmp_path):
    avant = {"mcp": {"godot-ai": GODOT_AI}, "skills": {"paths": ["C:/GodotPrompter/skills"]}, "theme": "x"}
    projet = _projet(tmp_path, avant)
    assert fusion.main([str(projet)]) == 0
    apres = json.loads((projet / "opencode.json").read_text(encoding="utf-8"))
    assert apres["mcp"]["godot-ai"] == GODOT_AI and apres["theme"] == "x"
    entree = apres["mcp"]["usine-godot"]
    assert entree["type"] == "local" and entree["enabled"] is True and entree["timeout"] == 120000
    assert entree["command"][1:] == [str(fusion.RACINE / "mcp_serveur" / "serveur.py"), "--projet", str(projet.resolve())]
    assert apres["skills"]["paths"] == ["C:/GodotPrompter/skills", str(fusion.RACINE / "skills")]
    assert "provider" not in apres
    sauvegardes = list(projet.glob("opencode.json.sauvegarde-*"))
    assert len(sauvegardes) == 1 and json.loads(sauvegardes[0].read_text(encoding="utf-8")) == avant
    # Idempotent, et --retirer rend le fichier de départ.
    assert fusion.main([str(projet)]) == 0
    assert len(list(projet.glob("opencode.json.sauvegarde-*"))) == 1
    assert fusion.retirer(apres) == {**avant, "$schema": "https://opencode.ai/config.json"}


def test_jsonc_refuse(tmp_path):
    projet = _projet(tmp_path, '{\n  // commentaire\n  "mcp": {}\n}')
    assert fusion.main([str(projet)]) == 1
    assert "// commentaire" in (projet / "opencode.json").read_text(encoding="utf-8")


def test_proxy_surcharge_le_fournisseur_detecte(tmp_path, monkeypatch):
    globale = tmp_path / "global" / "opencode.json"
    globale.parent.mkdir()
    globale.write_text('{\n // régénéré par un script\n "provider": {"llama": {"npm": "@ai-sdk/openai-compatible",'
                       ' "options": {"baseURL": "http://localhost:8080/v1"}, "models": {"qwen": {}}},'
                       ' "autre": {"options": {"baseURL": "https://exemple.invalid/v1"}},}\n}', encoding="utf-8")
    monkeypatch.setattr(fusion.cfg, "charger_config", lambda: {"opencode": {"config_globale": str(globale)},
                                                                "llm": {"url": "http://127.0.0.1:8080/v1"},
                                                                "capture": {"port_proxy": 8090}})
    projet = _projet(tmp_path, None)
    assert fusion.main([str(projet), "--proxy"]) == 0
    apres = json.loads((projet / "opencode.json").read_text(encoding="utf-8"))
    assert apres["provider"] == {"llama": {"options": {"baseURL": "http://127.0.0.1:8090/v1"}}}
    texte_global = globale.read_text(encoding="utf-8")
    assert "régénéré" in texte_global  # config globale jamais réécrite
    assert fusion.main([str(projet), "--retirer"]) == 0
    assert "provider" not in json.loads((projet / "opencode.json").read_text(encoding="utf-8"))


def test_proxy_sans_fournisseur_detecte_refuse(tmp_path, monkeypatch):
    monkeypatch.setattr(fusion.cfg, "charger_config", lambda: {"opencode": {"config_globale": str(tmp_path / "absent.json")}})
    projet = _projet(tmp_path, None)
    assert fusion.main([str(projet), "--proxy"]) == 1
    assert not (projet / "opencode.json").exists()
    assert fusion.main([str(projet), "--proxy", "--fournisseur", "llama"]) == 0
