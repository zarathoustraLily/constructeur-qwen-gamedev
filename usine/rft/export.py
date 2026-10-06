"""Export SFT : sessions retenues → données d'entraînement et configurations (QLoRA rang 16).

Sorties, dans <tour>/export/ :
  sft.jsonl                     {"messages": [... format chat OpenAI ...], "tools": "<JSON>"} : format
                                commun, lu par le script Unsloth ;
  llamafactory/usine_godot.jsonl  le même contenu au format sharegpt de LLaMA-Factory
                                (human / gpt / function_call / observation) ;
  llamafactory/dataset_info.json  déclaration du jeu « usine_godot » ;
  llamafactory/qwen38_qlora_r16.yaml  configuration QLoRA rang 16, packing désactivé ;
  unsloth/config_unsloth.json   et unsloth/entrainer_unsloth.py (alternative) ;
  bilan.json                    exportées, écartées par raison.

Perte uniquement sur les messages assistant :
  - LLaMA-Factory : seuls les tours gpt et function_call portent la perte (train_on_prompt: false) ;
  - Unsloth : train_on_responses_only, avec les marques de tour de Qwen (<|im_start|>…).
Packing désactivé partout (packing: false, neat_packing: false ; SFTConfig(packing=False)) : sur
l'architecture hybride de Qwen3.8, rien ne garantit que l'état récurrent est remis à zéro entre
exemples empaquetés.

Règle 4 : une session d'une tâche gelée (id ou empreinte du manifeste) ou dont le texte produit
reprend les fragments d'une tâche gelée est écartée.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any

from usine.capture.enregistreur import _ecrire_atomique

NOM_JEU = "usine_godot"
MODELE_UNSLOTH = Path(__file__).resolve().parent / "modeles" / "entrainer_unsloth.py"

# Clés de la configuration LLaMA-Factory (toutes tirées de ses exemples train_qlora / train_lora) :
# une clé inconnue fait échouer son analyseur d'arguments.
CLES_LLAMAFACTORY = (
    "model_name_or_path", "trust_remote_code", "stage", "do_train", "finetuning_type", "lora_rank", "lora_alpha",
    "lora_dropout", "lora_target", "quantization_bit", "quantization_method", "dataset", "dataset_dir", "template",
    "cutoff_len", "packing", "neat_packing", "train_on_prompt", "overwrite_cache", "preprocessing_num_workers",
    "output_dir", "logging_steps", "save_steps", "plot_loss", "overwrite_output_dir", "per_device_train_batch_size",
    "gradient_accumulation_steps", "learning_rate", "num_train_epochs", "lr_scheduler_type", "warmup_ratio", "bf16")


def lire_session(chemin: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    lignes = [json.loads(l) for l in Path(chemin).read_text(encoding="utf-8").splitlines() if l.strip()]
    return lignes[0], lignes[1:]


def messages_propres(messages: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Messages au format chat OpenAI (role, content, tool_calls, tool_call_id), sans les messages
    non assistant qui suivent le dernier message assistant (rien à apprendre après lui)."""
    propres = []
    for m in messages:
        role = m.get("role")
        if role not in ("system", "user", "assistant", "tool"):
            continue
        p: dict[str, Any] = {"role": role, "content": m.get("content") or ""}
        if role == "assistant" and m.get("tool_calls"):
            p["tool_calls"] = [{"id": c.get("id"), "type": "function",
                                "function": {"name": c["function"]["name"], "arguments": c["function"]["arguments"]}}
                               for c in m["tool_calls"]]
        if role == "tool":
            p["tool_call_id"] = m.get("tool_call_id")
        propres.append(p)
    while propres and propres[-1]["role"] != "assistant":
        propres.pop()
    return propres


def fonctions(outils: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Définitions d'outils sans l'enveloppe OpenAI ({"type": "function", "function": {...}})."""
    return [o.get("function", o) for o in outils or []]


def vers_sharegpt(messages: list[dict[str, Any]], outils: list[dict[str, Any]]) -> dict[str, Any]:
    """Conversion vers le format sharegpt de LLaMA-Factory. ValueError si l'alternance
    (human|observation) / (gpt|function_call) n'est pas respectée."""
    systeme = "\n\n".join(m["content"] for m in messages if m["role"] == "system")
    tours: list[dict[str, str]] = []
    for m in messages:
        if m["role"] == "system":
            continue
        if m["role"] == "user":
            tours.append({"from": "human", "value": m["content"]})
        elif m["role"] == "assistant" and m.get("tool_calls"):
            appels = [{"name": c["function"]["name"], "arguments": json.loads(c["function"]["arguments"] or "{}")}
                      for c in m["tool_calls"]]
            tours.append({"from": "function_call",
                          "value": json.dumps(appels[0] if len(appels) == 1 else appels, ensure_ascii=False)})
        elif m["role"] == "assistant":
            tours.append({"from": "gpt", "value": m["content"]})
        elif tours and tours[-1]["from"] == "observation":
            tours[-1]["value"] += "\n" + m["content"]          # plusieurs résultats d'outils : un seul tour
        else:
            tours.append({"from": "observation", "value": m["content"]})
    for i, t in enumerate(tours):
        attendu = ("human", "observation") if i % 2 == 0 else ("gpt", "function_call")
        if t["from"] not in attendu:
            raise ValueError(f"alternance rompue au tour {i} ({t['from']})")
    if not tours or tours[-1]["from"] not in ("gpt", "function_call"):
        raise ValueError("la conversation ne finit pas par un tour assistant")
    exemple = {"conversations": tours, "system": systeme}
    if outils:
        exemple["tools"] = json.dumps(fonctions(outils), ensure_ascii=False)
    return exemple


def config_llamafactory(base_hf: str, dossier_donnees: str, sortie: str, cutoff_len: int = 16384,
                        template: str = "qwen3") -> dict[str, Any]:
    c = {"model_name_or_path": base_hf, "trust_remote_code": True,
         "stage": "sft", "do_train": True, "finetuning_type": "lora", "lora_rank": 16, "lora_alpha": 32,
         "lora_dropout": 0.05, "lora_target": "all", "quantization_bit": 4, "quantization_method": "bitsandbytes",
         "dataset": NOM_JEU, "dataset_dir": dossier_donnees, "template": template, "cutoff_len": cutoff_len,
         "packing": False, "neat_packing": False, "train_on_prompt": False, "overwrite_cache": True,
         "preprocessing_num_workers": 4, "output_dir": sortie, "logging_steps": 10, "save_steps": 200,
         "plot_loss": True, "overwrite_output_dir": True, "per_device_train_batch_size": 1,
         "gradient_accumulation_steps": 8, "learning_rate": 1.0e-4, "num_train_epochs": 2.0,
         "lr_scheduler_type": "cosine", "warmup_ratio": 0.05, "bf16": True}
    assert tuple(c) == CLES_LLAMAFACTORY
    return c


def _yaml_valeur(v: Any) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    return "'" + str(v).replace("'", "''") + "'"


def ecrire_yaml(c: dict[str, Any]) -> str:
    """YAML plat (clé: valeur), chaînes entre apostrophes : les chemins Windows passent tels quels."""
    entete = ("# QLoRA rang 16 sur Qwen3.8-27B (usine, session 5). Lancer : llamafactory-cli train <ce fichier>\n"
              "# template : vérifier le nom du gabarit de Qwen3.8 dans ta version de LLaMA-Factory.\n"
              "# packing désactivé : architecture hybride, état récurrent non garanti entre exemples.\n")
    return entete + "".join(f"{k}: {_yaml_valeur(v)}\n" for k, v in c.items())


def lire_yaml_plat(texte: str) -> dict[str, Any]:
    """Relit le YAML plat d'ecrire_yaml (preuve « la configuration se charge » sans PyYAML)."""
    c: dict[str, Any] = {}
    for ligne in texte.splitlines():
        if not ligne.strip() or ligne.lstrip().startswith("#"):
            continue
        cle, _, brut = ligne.partition(": ")
        brut = brut.strip()
        if brut in ("true", "false"):
            c[cle] = brut == "true"
        elif brut.startswith("'") and brut.endswith("'"):
            c[cle] = brut[1:-1].replace("''", "'")
        else:
            c[cle] = float(brut) if any(x in brut for x in ".e") else int(brut)
    return c


def config_unsloth(base_hf: str, donnees: str, sortie: str, max_seq_length: int = 16384) -> dict[str, Any]:
    return {"base": base_hf, "donnees": donnees, "sortie": sortie, "max_seq_length": max_seq_length,
            "charger_en_4bit": True, "rang": 16, "alpha": 32, "dropout": 0.05,
            "modules_cibles": ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
            "packing": False, "lot": 1, "accumulation": 8, "taux_apprentissage": 1.0e-4, "epoques": 2,
            "graine": 1, "marque_utilisateur": "<|im_start|>user\n", "marque_assistant": "<|im_start|>assistant\n"}


def exporter(retenus: list[dict[str, Any]], sessions: Path, sortie: Path, exclusion=None,
             base_hf: str = "A_RENSEIGNER") -> dict[str, Any]:
    """Écrit l'export d'un tour à partir des essais retenus (filtre.retenir)."""
    sortie = Path(sortie)
    ecartees: dict[str, int] = {}
    sft, sharegpt = [], []
    for ligne in retenus:
        entete, messages = lire_session(Path(sessions) / ligne["session"])
        if exclusion is not None and exclusion.session_exclue(entete):
            ecartees["tache_gelee"] = ecartees.get("tache_gelee", 0) + 1
            continue
        propres = messages_propres(messages)
        produit = "\n".join((m["content"] or "") + "".join(c["function"]["arguments"] for c in m.get("tool_calls", []))
                            for m in propres if m["role"] == "assistant")
        if exclusion is not None and exclusion.texte_exclu(produit):
            ecartees["reprend_une_tache_gelee"] = ecartees.get("reprend_une_tache_gelee", 0) + 1
            continue
        outils = entete.get("tools") or []
        try:
            exemple_sharegpt = vers_sharegpt(propres, outils)
        except ValueError:
            ecartees["format_invalide"] = ecartees.get("format_invalide", 0) + 1
            continue
        sft.append({"messages": propres, "tools": json.dumps(fonctions(outils), ensure_ascii=False),
                    "tache_id": entete["tache_id"], "competence": entete["competence"]})
        sharegpt.append(exemple_sharegpt)
    lf = sortie / "llamafactory"
    us = sortie / "unsloth"
    jsonl = lambda lignes: "".join(json.dumps(l, ensure_ascii=False) + "\n" for l in lignes)  # noqa: E731
    _ecrire_atomique(sortie / "sft.jsonl", jsonl(sft))
    _ecrire_atomique(lf / f"{NOM_JEU}.jsonl", jsonl(sharegpt))
    info = {NOM_JEU: {"file_name": f"{NOM_JEU}.jsonl", "formatting": "sharegpt",
                      "columns": {"messages": "conversations", "system": "system", "tools": "tools"},
                      "tags": {"role_tag": "from", "content_tag": "value", "user_tag": "human", "assistant_tag": "gpt",
                               "observation_tag": "observation", "function_tag": "function_call",
                               "system_tag": "system"}}}
    _ecrire_atomique(lf / "dataset_info.json", json.dumps(info, ensure_ascii=False, indent=2) + "\n")
    _ecrire_atomique(lf / "qwen38_qlora_r16.yaml",
                     ecrire_yaml(config_llamafactory(base_hf, str(lf.resolve()), str((sortie / "lora_llamafactory").resolve()))))
    _ecrire_atomique(us / "config_unsloth.json", json.dumps(
        config_unsloth(base_hf, str((sortie / "sft.jsonl").resolve()), str((sortie / "lora_unsloth").resolve())),
        ensure_ascii=False, indent=2) + "\n")
    us.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(MODELE_UNSLOTH, us / "entrainer_unsloth.py")
    par_comp: dict[str, int] = {}
    for e in sft:
        par_comp[e["competence"]] = par_comp.get(e["competence"], 0) + 1
    bilan = {"exportees": len(sft), "par_competence": dict(sorted(par_comp.items())), "ecartees": ecartees}
    _ecrire_atomique(sortie / "bilan.json", json.dumps(bilan, ensure_ascii=False, indent=2) + "\n")
    return bilan
