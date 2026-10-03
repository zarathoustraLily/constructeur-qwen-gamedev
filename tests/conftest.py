"""Configuration pytest : les tests marqués `godot` sont ignorés sans binaire Godot."""

from __future__ import annotations

import pytest

from usine import config as cfg


def pytest_configure(config):
    config.addinivalue_line("markers", "godot: nécessite un binaire Godot (config.toml ou godot_bin/)")


def pytest_collection_modifyitems(config, items):
    if cfg.godot_disponible():
        return
    saut = pytest.mark.skip(reason="Godot introuvable (config.toml ou outils/installer_godot_cloud.sh)")
    for item in items:
        if "godot" in item.keywords:
            item.add_marker(saut)
