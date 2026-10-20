"""Convertit en GGUF un LoRA de Qwen3.8 qui touche l'attention linéaire (lora_target: all).

Le convert_lora_to_gguf.py de llama.cpp échoue sur linear_attn.out_proj : la conversion réordonne
les têtes V le long des colonnes, ce que son tenseur LoRA (W = B·A) ne sait pas faire. Or permuter
les colonnes de W revient à permuter celles de A seul. Ce lanceur ajoute ce cas, sans modifier
llama.cpp, puis exécute le convertisseur tel quel.

Usage : python convertir_lora_qwen38.py <convert_lora_to_gguf.py> [ses arguments]
"""

from __future__ import annotations

import runpy
import sys
from pathlib import Path


def main() -> None:
    convertisseur = Path(sys.argv[1]).resolve()
    sys.path.insert(0, str(convertisseur.parent))
    from conversion import qwen

    base = qwen._LinearAttentionVReorderBase
    origine = base._reorder_v_heads

    def reordonner(tensor, dim, num_k_heads, num_v_per_k, head_dim):
        nd = len(tensor.shape)
        if hasattr(tensor, "_lora_A") and dim % nd == nd - 1:
            return type(tensor)(origine(tensor._lora_A, -1, num_k_heads, num_v_per_k, head_dim), tensor._lora_B)
        return origine(tensor, dim, num_k_heads, num_v_per_k, head_dim)

    base._reorder_v_heads = staticmethod(reordonner)
    sys.argv = [str(convertisseur), *sys.argv[2:]]
    runpy.run_path(str(convertisseur), run_name="__main__")


if __name__ == "__main__":
    main()
