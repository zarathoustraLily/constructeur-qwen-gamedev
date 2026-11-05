# Entraîner le LoRA de Qwen 3.8 : manuel pas à pas

Ce manuel est à suivre seul, sans Claude. Les commandes sont pour **cmd.exe**, lancées depuis `D:\constructeur-qwen-gamedev`
sauf mention contraire. Chaque étape dit ce qu'on doit voir.

Calendrier (décision 19.4) :
- étape 1 sur la 5090 : les paires courtes de 1 024 jetons ;
- étape 2 sur la 5090 : les paires de 1 024 et de 2 048 jetons, en reprenant le LoRA de l'étape 1 ;
- étape 3 sur une carte louée : les sessions longues et 5 000 paires courtes, en reprenant le LoRA de l'étape 2.

## 0. Ce qui est prêt

| Fichier | Contenu | Étape |
| --- | --- | --- |
| `donnees\entrainement\palier_1.jsonl` | 19 553 paires de 1 024 jetons au plus (13,3 millions de jetons) | 1, 2 et 3 |
| `donnees\entrainement\palier_2.jsonl` | 12 119 paires de 2 048 jetons au plus (19,9 millions de jetons) | 2 et 3 |
| `donnees\entrainement\dataset_info.json` | la déclaration de `palier_1` et de `palier_2` pour LLaMA-Factory | 1 et 2 |
| `donnees\cours\kart\base\livraison\base_kart_sharegpt.jsonl` | 365 sessions longues au format d'OpenCode | 3 |
| `donnees\cours\roguelike\base\livraison\base_roguelike_sharegpt.jsonl` | 279 sessions longues | 3 |
| `donnees\cours\boss_action_rpg\base\livraison\base_boss_action_rpg_sharegpt.jsonl` | 633 sessions longues | 3 |

Tout est déjà vérifié et au format de LLaMA-Factory : il n'y a rien à convertir.

**Ta décision 20** : « tu ne réentraînes rien tant qu'on n'a pas fini les paires d'entraînement ». Le cours de l'éditeur
de niveaux et ses paires de débogage (accord du 2026-11-05) ne sont pas encore dans ces fichiers. Si tu entraînes
maintenant, ils n'y seront pas.

Outils déjà installés sur ton PC :
- l'entraîneur : LLaMA-Factory 0.9.5, dans `G:\llm_lora_trainer\venv\` ;
- le modèle de base : `G:\llm_lora_trainer\qwen38_27b` ;
- le convertisseur en GGUF : `D:\chat_llama_server\llama-server\tq-src-0831\convert_lora_to_gguf.py`. Seule la build
  tq-src-0831 convertit ; la tq-src-1010 échoue.

## 1. Avant chaque entraînement sur la 5090

1. Fermer llama-server, ComfyUI, les jeux et Godot. L'entraînement prend presque toute la carte : pic de 31 940 Mio
   sur 32 607, mesuré le 2026-10-22.
2. Vérifier que la carte est libre :
   ```bat
   nvidia-smi --query-gpu=memory.used,memory.total --format=csv
   ```
   On doit voir moins de 6 600 Mio utilisés. Le lanceur refuse de partir s'il reste moins de 26 000 Mio libres
   (« carte occupée : … rien n'est lancé »).
3. Dans les options d'alimentation de Windows, mettre la mise en veille sur « Jamais ».
4. Garder une copie des LoRA déjà faits. Le premier (`donnees\entrainement\lora_etape_1\`) reste tel quel
   (décision 20).

## 2. Étape 1 : palier 1, sur la 5090

### 2.1 Écrire les réglages dans un dossier neuf

**Piège à éviter.** `donnees\entrainement\etape_1.yaml` vise encore `lora_etape_1`, qui contient le premier LoRA et ses
sauvegardes `checkpoint-90` et `checkpoint-99`. LLaMA-Factory reprend seul depuis la dernière sauvegarde qu'il trouve
dans ce dossier : il repartirait de l'ancien entraînement, puis écraserait le premier LoRA. On réécrit donc le fichier
vers un dossier neuf :

```bat
cd /d D:\constructeur-qwen-gamedev
python -m usine.entrainement reglages --etape 1 --jeu donnees\entrainement --nom palier_1 --sortie donnees\entrainement\lora_v2_etape_1
```

Résultat attendu :
```
écrit : D:\constructeur-qwen-gamedev\donnees\entrainement\etape_1.yaml
```

Ouvrir `donnees\entrainement\etape_1.yaml` et vérifier les lignes suivantes :
```
template: qwen3_5
enable_thinking: false
dataset: palier_1
cutoff_len: 1024
output_dir: "D:/constructeur-qwen-gamedev/donnees/entrainement/lora_v2_etape_1"
```

`qwen3_5` est le gabarit de Qwen 3.5 et 3.8 dans LLaMA-Factory 0.9.5, qui ne connaît pas `qwen3_8`. Les `LISEZMOI.md`
des livraisons disent encore `qwen3_8` : leur générateur est corrigé, et la prochaine livraison sera juste.

### 2.2 Lancer

```bat
python -m usine.entrainement lancer --yaml donnees\entrainement\etape_1.yaml
```

- Durée : entre 14 et 18 heures. On compte environ 1 220 pas (19 553 paires, 16 par pas). Au débit mesuré
  (266 jetons/s), cela fait 13,9 h ; au rythme du premier LoRA (52 s par pas), 17,7 h.
- Suivi : `donnees\entrainement\lora_v2_etape_1\journal.txt` se remplit (une ligne de perte tous les 5 pas), et
  `memoire.jsonl` relève la mémoire à chaque pas.
- Sauvegarde automatique tous les 10 pas (`checkpoint-N`).

**Si ça s'arrête** (écran noir, pilote redémarré, coupure) : relancer **exactement la même commande**.
LLaMA-Factory repart de la dernière sauvegarde : on perd au plus 10 pas.

Résultat attendu à la fin : un bloc JSON avec `"code": 0`, puis `dernières pertes : …`. Dans le dossier,
`adapter_model.safetensors` (environ 467 Mo) et `bilan.json` sont présents.

À surveiller : la perte du premier LoRA était passée de 1,18 à 0,012, signe probable d'un apprentissage par cœur des
lectures de sortie, très répétitives. Une perte qui tombe sous 0,05 dès le premier tiers mérite d'être notée.

### 2.3 Convertir en GGUF, pour llama-server

```bat
cd /d D:\constructeur-qwen-gamedev
G:\llm_lora_trainer\venv\Scripts\python.exe usine\rft\convertir_lora.py "D:\chat_llama_server\llama-server\tq-src-0831\convert_lora_to_gguf.py" --base "G:\llm_lora_trainer\qwen38_27b" --outfile "donnees\entrainement\lora_v2_etape_1\lora_v2_etape_1-f16.gguf" --outtype f16 "donnees\entrainement\lora_v2_etape_1"
```

Résultat attendu : `lora_v2_etape_1-f16.gguf`, d'environ 233 Mo (992 tenseurs pour le premier LoRA).

`convertir_lora.py` corrige un défaut du convertisseur d'origine, qui échoue sur `out_proj` de l'attention linéaire
de Qwen 3.8 (NotImplementedError). Il faut donc passer par lui, pas par le convertisseur seul.

### 2.4 Essayer le LoRA dans OpenCode

1. Copier `donnees\entrainement\lora_etape_1\START-QWEN38-OPENCODE-LORA_ETAPE_1.bat` dans
   `donnees\entrainement\lora_v2_etape_1\`, et le renommer `START-QWEN38-OPENCODE-LORA_V2_ETAPE_1.bat`.
2. Dans ce fichier, ne changer que le chemin après `--lora` :
   `"D:\constructeur-qwen-gamedev\donnees\entrainement\lora_v2_etape_1\lora_v2_etape_1-f16.gguf"`.
3. Double-cliquer dessus, puis ouvrir OpenCode comme d'habitude (serveur sur `http://127.0.0.1:8080/v1`).
   Si llama-server refuse de démarrer, retirer `-ngl 99` de la ligne : selon `CLAUDE.md`, ce build refuse cette option
   et il faut laisser le placeur automatique.
4. Tester en conditions réelles (décision 1) : une campagne Starfox propre, avec le LoRA, une fois avec le RAG et une
   fois sans.

## 3. Étape 2 : paliers 1 et 2, sur la 5090

Refaire le §1 (carte libre), puis :

```bat
cd /d D:\constructeur-qwen-gamedev
python -m usine.entrainement reglages --etape 2 --jeu donnees\entrainement --nom palier_1,palier_2 --sortie donnees\entrainement\lora_v2_etape_2 --reprise donnees\entrainement\lora_v2_etape_1
```

Vérifier dans `donnees\entrainement\etape_2.yaml` :
```
dataset: "palier_1,palier_2"
cutoff_len: 2048
output_dir: "D:/constructeur-qwen-gamedev/donnees/entrainement/lora_v2_etape_2"
adapter_name_or_path: "D:/constructeur-qwen-gamedev/donnees/entrainement/lora_v2_etape_1"
```

`adapter_name_or_path` fait reprendre l'entraînement du LoRA de l'étape 1, au lieu d'en créer un neuf
(`llamafactory/model/adapter.py`, « resume lora training »).

```bat
python -m usine.entrainement lancer --yaml donnees\entrainement\etape_2.yaml
```

- Durée : environ 35 heures, sans doute plus (33,2 millions de jetons à 266 jetons/s, environ 1 980 pas).
- Même reprise automatique qu'au §2.2 si ça s'arrête.
- Puis conversion et essai comme aux §2.3 et §2.4, en remplaçant `lora_v2_etape_1` par `lora_v2_etape_2` partout.

## 4. Étape 3 : sur une carte louée (RunPod)

Cette étape n'a pas encore été faite. Il reste à choisir la carte (H200 ou B300, décision 22), et la mémoire à 32 768
jetons n'est pas mesurée. Le premier LoRA de l'usine a déjà été entraîné sur une H200 de RunPod (2 époques, 2 h 04).

### 4.1 Préparer le dossier, sur ton PC

```bat
cd /d D:\constructeur-qwen-gamedev
python -m usine.entrainement etape3
```

Résultat attendu (un bloc JSON) :
- `"longues"` : kart 365, roguelike 279, boss_action_rpg 633 ;
- `"courtes"` : 5000, dont 514 avec images (1 610 fichiers d'images copiés) ;
- dans `donnees\entrainement\etape_3\` (environ 141 Mo) : les trois bases longues, `courtes_etape_3.jsonl`,
  `images\`, `dataset_info.json` et `etape_3.yaml`.

Le tirage des paires courtes est toujours le même (graine 0). Il se fait au hasard dans les deux paliers : le réglage
`max_samples` de LLaMA-Factory prendrait seulement les premières lignes.

Relever les versions de ton entraîneur, à reproduire sur la carte louée :
```bat
G:\llm_lora_trainer\venv\Scripts\pip.exe freeze > donnees\entrainement\etape_3\versions_pc.txt
```

### 4.2 Sur la carte louée

1. Louer un pod RunPod avec la carte choisie et au moins 150 Go de disque. Le modèle de base fait à lui seul plusieurs
   dizaines de Go.
2. Envoyer dans `/workspace/` (par `runpodctl` ou `scp`) :
   - `donnees\entrainement\etape_3\`, qui devient `/workspace/etape_3/` ;
   - `G:\llm_lora_trainer\qwen38_27b\`, qui devient `/workspace/qwen38_27b/` ;
   - le LoRA de l'étape 2, qui devient `/workspace/lora_etape_2/`. Seuls `adapter_config.json` et
     `adapter_model.safetensors` de `donnees\entrainement\lora_v2_etape_2\` sont nécessaires, pas les `checkpoint-N`.
3. Installer l'entraîneur avec les versions de `versions_pc.txt` (llamafactory, transformers, peft, accelerate,
   bitsandbytes, datasets). Sous Linux, torch s'installe depuis l'index de PyTorch pour CUDA 12.8 :
   ```bash
   pip install torch==2.11.0 --index-url https://download.pytorch.org/whl/cu128
   pip install llamafactory==0.9.5 transformers==5.6.0 bitsandbytes
   ```
   Puis ajuster peft, accelerate et datasets aux versions de `versions_pc.txt`.
4. Lancer :
   ```bash
   cd /workspace
   llamafactory-cli train etape_3/etape_3.yaml
   ```
   Si le pod s'arrête, relancer la même commande : la reprise depuis `checkpoint-N` vaut aussi ici.
5. Récupérer `/workspace/lora_etape_3/` (les fichiers `adapter_*`) dans `donnees\entrainement\lora_v2_etape_3\` sur
   ton PC, puis convertir et essayer comme aux §2.3 et §2.4.

## 5. En cas de problème

| Ce qu'on voit | Ce qu'on fait |
| --- | --- |
| « carte occupée : … rien n'est lancé » | fermer llama-server, ComfyUI et les jeux, puis relancer |
| écran noir, pilote qui redémarre, ou PC qui s'est éteint | relancer la même commande : reprise au dernier `checkpoint-N` |
| les pas passent de moins d'une minute à plusieurs minutes | une autre application a pris de la mémoire graphique : la fermer |
| la perte remonte fortement et reste haute | arrêter (fermer la fenêtre), garder le dossier, noter le pas dans `journal.txt` |
| la conversion GGUF échoue avec NotImplementedError | elle a été lancée sans `convertir_lora.py`, ou avec la build tq-src-1010 : refaire le §2.3 tel quel |
| llama-server ne démarre pas avec le LoRA | retirer `-ngl 99` du lanceur ; vérifier le chemin après `--lora` |

## 6. Après l'entraînement

- Comparer en conditions réelles : Qwen de base contre le LoRA, chacun avec et sans le RAG (décision 18.2).
- La suite prévue est la RFT (les sessions réussies du LoRA lui-même), puis la RLVR sur les tâches qu'il réussit
  parfois mais pas toujours (décision 18.4).
