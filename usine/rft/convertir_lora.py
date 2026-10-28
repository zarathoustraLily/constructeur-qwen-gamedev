"""Conversion d'un LoRA de Qwen 3.8 (architecture hybride qwen35) en GGUF : le `convert_lora_to_gguf.py` de
llama.cpp, lancé tel quel, avec une correction pour l'attention linéaire.

Le convertisseur réordonne les têtes V des couches d'attention linéaire (`_reorder_v_heads` de `conversion/qwen.py` :
les lignes de in_proj_qkv, in_proj_z, in_proj_a, in_proj_b ; les colonnes de out_proj). Pour un LoRA (W = B·A), ce
réordonnement est une permutation : celle des lignes de B quand elle porte sur les lignes de W, celle des colonnes de
A quand elle porte sur ses colonnes. Le script de la build tq-src-0831 le fait par `reshape`, que sa classe
LoraTorchTensor ne sait pas faire sur la dernière dimension : NotImplementedError sur out_proj (relevé le
2026-10-28). Ici, la permutation est appliquée directement aux deux facteurs ; les tenseurs ordinaires passent par
la fonction d'origine.

Lancé avec un Python qui a torch, transformers et safetensors (celui de LLaMA-Factory) ; il n'importe rien de
l'usine :

    python convertir_lora.py <convert_lora_to_gguf.py> --base <HF> --outfile <sortie.gguf> --outtype f16 <adaptateur>
"""

import os
import runpy
import sys
from pathlib import Path


def permutation(num_k_heads: int, num_v_per_k: int, head_dim: int):
    """L'ordre des têtes V après réordonnement : nouvel[i] = ancien[perm[i]] (groupé par tête K → en tuiles)."""
    import torch
    n = num_k_heads * num_v_per_k * head_dim
    return torch.arange(n).reshape(num_k_heads, num_v_per_k, head_dim).permute(1, 0, 2).reshape(-1)


def corriger(module) -> int:
    """Remplace `_reorder_v_heads` des classes du module qui la définissent ; rend leur nombre."""
    classes = [c for c in vars(module).values() if isinstance(c, type) and "_reorder_v_heads" in vars(c)]
    for cls in classes:
        original = vars(cls)["_reorder_v_heads"].__func__

        def reordonner(tensor, dim, num_k_heads, num_v_per_k, head_dim, _original=original):
            if not (hasattr(tensor, "_lora_A") and hasattr(tensor, "_lora_B")):
                return _original(tensor, dim, num_k_heads, num_v_per_k, head_dim)
            perm = permutation(num_k_heads, num_v_per_k, head_dim)
            a, b = tensor._lora_A, tensor._lora_B
            rang = len(tensor.shape)
            dim = dim + rang if dim < 0 else dim
            if dim == rang - 1:
                a = a.index_select(a.dim() - 1, perm)   # colonnes de W : colonnes de A
            else:
                b = b.index_select(dim, perm)           # lignes de W : lignes de B
            return type(tensor)(a, b)

        cls._reorder_v_heads = staticmethod(reordonner)
    return len(classes)


def main() -> None:
    script = Path(sys.argv[1]).resolve()
    sys.argv = [str(script)] + sys.argv[2:]
    sys.path.insert(0, str(script.parent))
    if "NO_LOCAL_GGUF" not in os.environ:
        sys.path.insert(1, str(script.parent / "gguf-py"))
    import conversion.qwen as qwen
    n = corriger(qwen)
    print(f"convertir_lora : _reorder_v_heads corrigée dans {n} classe(s)", flush=True)
    runpy.run_path(str(script), run_name="__main__")


if __name__ == "__main__":
    main()
