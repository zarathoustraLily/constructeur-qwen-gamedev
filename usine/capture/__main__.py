"""CLI de la capture.

    python -m usine.capture proxy [--port 8090] [--amont http://127.0.0.1:8080/v1] [--sortie donnees/sessions]
    python -m usine.capture preuve        (faux serveur scripté → proxy → client ; relais et enregistrement)
    python -m usine.capture lister [--sortie donnees/sessions]

Défauts lus dans config.toml : [capture].port_proxy et [llm].url.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from usine import config as cfg


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    config = cfg.charger_config()
    parser = argparse.ArgumentParser(prog="python -m usine.capture")
    sous = parser.add_subparsers(dest="commande", required=True)
    p = sous.add_parser("proxy", help="relais OpenCode → llama-server qui enregistre les sessions")
    p.add_argument("--port", type=int, default=int(config.get("capture", {}).get("port_proxy", 8090)))
    p.add_argument("--amont", default=config.get("llm", {}).get("url", "http://127.0.0.1:8080/v1"))
    p.add_argument("--sortie", type=Path, default=cfg.dossier_donnees() / "sessions")
    p.add_argument("--bavard", action="store_true")
    sous.add_parser("preuve", help="rejoue un échange scripté à travers le proxy")
    p = sous.add_parser("lister", help="sessions enregistrées")
    p.add_argument("--sortie", type=Path, default=cfg.dossier_donnees() / "sessions")
    args = parser.parse_args(argv)

    if args.commande == "proxy":
        from usine.capture.proxy import ProxyCapture
        serveur = ProxyCapture(args.port, args.amont, args.sortie, bavard=args.bavard)
        print(f"Proxy de capture : http://127.0.0.1:{serveur.port}/v1 → {args.amont}")
        print(f"Sessions : {args.sortie}   (Ctrl+C pour arrêter)")
        try:
            serveur.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            serveur.server_close()
        return 0
    if args.commande == "preuve":
        from usine.capture.preuve import preuve
        return preuve()
    from usine.capture.enregistreur import lire_session
    fichiers = sorted(args.sortie.glob("*.jsonl"))
    for f in fichiers:
        entete, messages = lire_session(f)
        roles = {}
        for m in messages:
            roles[m["role"]] = roles.get(m["role"], 0) + 1
        appels = [c["function"]["name"] for m in messages for c in (m.get("tool_calls") or [])]
        print(f"{f.name}  {entete['echanges']} échanges  {len(messages)} messages {roles}  outils : {', '.join(appels) or '—'}")
    print(f"{len(fichiers)} sessions dans {args.sortie}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
