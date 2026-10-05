"""Entraînement QLoRA rang 16 de Qwen3.8-27B avec Unsloth (alternative à LLaMA-Factory).

Copié dans <tour>/export/unsloth/ par `python -m usine.rft tour`. À lancer sur la machine :
    python entrainer_unsloth.py config_unsloth.json

- Données : sft.jsonl (messages au format chat OpenAI, outils en JSON), mis en forme par le
  gabarit de conversation du modèle.
- Perte sur les seuls messages assistant : train_on_responses_only (marques de tour de la config).
- Packing désactivé (architecture hybride : état récurrent non garanti entre exemples empaquetés).
Non exécuté dans le cloud (pas de GPU) : vérifier les noms d'arguments avec la version installée
d'Unsloth et de TRL (VERIFIER_EN_LOCAL.md).
"""

import json
import sys
from pathlib import Path


def main() -> int:
    cfg = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    if cfg.get("packing"):
        raise SystemExit("packing interdit sur cette architecture")
    from datasets import load_dataset
    from trl import SFTConfig, SFTTrainer
    from unsloth import FastLanguageModel
    from unsloth.chat_templates import train_on_responses_only

    modele, tokenizer = FastLanguageModel.from_pretrained(
        cfg["base"], max_seq_length=cfg["max_seq_length"], load_in_4bit=cfg["charger_en_4bit"])
    modele = FastLanguageModel.get_peft_model(
        modele, r=cfg["rang"], lora_alpha=cfg["alpha"], lora_dropout=cfg["dropout"],
        target_modules=cfg["modules_cibles"], use_gradient_checkpointing="unsloth", random_state=cfg["graine"])

    def mettre_en_forme(exemple):
        outils = json.loads(exemple["tools"]) if exemple.get("tools") else None
        texte = tokenizer.apply_chat_template(exemple["messages"], tools=outils or None, tokenize=False)
        return {"text": texte}

    donnees = load_dataset("json", data_files=cfg["donnees"], split="train")
    donnees = donnees.map(mettre_en_forme, remove_columns=donnees.column_names)
    entraineur = SFTTrainer(
        model=modele, tokenizer=tokenizer, train_dataset=donnees,
        args=SFTConfig(dataset_text_field="text", max_seq_length=cfg["max_seq_length"], packing=False,
                       per_device_train_batch_size=cfg["lot"], gradient_accumulation_steps=cfg["accumulation"],
                       learning_rate=cfg["taux_apprentissage"], num_train_epochs=cfg["epoques"],
                       lr_scheduler_type="cosine", warmup_ratio=0.05, logging_steps=10, seed=cfg["graine"],
                       bf16=True, output_dir=cfg["sortie"]))
    entraineur = train_on_responses_only(entraineur, instruction_part=cfg["marque_utilisateur"],
                                         response_part=cfg["marque_assistant"])
    entraineur.train()
    modele.save_pretrained(cfg["sortie"])
    tokenizer.save_pretrained(cfg["sortie"])
    print(f"Adaptateur écrit dans {cfg['sortie']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
