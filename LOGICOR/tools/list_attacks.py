import json, re, csv
from pathlib import Path
from collections import Counter

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Collect all attack name suffixes from all sources
attack_suffixes = Counter()

# From FICHES_BOSSES_V2.json
with open(base / 'fiches' / 'FICHES_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    data = json.load(f)
for boss in data:
    for atk in boss.get('attaques', []):
        atk_id = atk['id']
        if '_' in atk_id:
            suffix = atk_id.split('_')[-1]
            attack_suffixes[suffix] += 1

# From FICHES_ENNEMIS_V2.json
with open(base / 'fiches' / 'FICHES_ENNEMIS_V2.json','r',encoding='utf-8-sig') as f:
    data = json.load(f)
for enemy in data:
    for atk in enemy.get('arsenal', []):
        if isinstance(atk, str) and '_' in atk:
            suffix = atk.split('_')[-1]
            attack_suffixes[suffix] += 1

# From FICHES_MINI_BOSSES_V2.json
with open(base / 'fiches' / 'FICHES_MINI_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    data = json.load(f)
for mb in data:
    for atk in mb.get('arsenal', []):
        if isinstance(atk, str) and '_' in atk:
            suffix = atk.split('_')[-1]
            attack_suffixes[suffix] += 1

print('Total unique attack suffixes:', len(attack_suffixes))
for suffix, count in attack_suffixes.most_common(50):
    print(f'  {count:3d}  {suffix}')
