import json, re, csv
from pathlib import Path
from collections import Counter, OrderedDict

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Collect ALL attack IDs from all sources
attack_ids = OrderedDict()

# From FICHES_BOSSES_V2.json
with open(base / 'fiches' / 'FICHES_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    data = json.load(f)
for boss in data:
    for atk in boss.get('attaques', []):
        atk_id = atk['id']
        attack_ids[atk_id] = True

# From FICHES_ENNEMIS_V2.json
with open(base / 'fiches' / 'FICHES_ENNEMIS_V2.json','r',encoding='utf-8-sig') as f:
    data = json.load(f)
for enemy in data:
    for atk in enemy.get('arsenal', []):
        if isinstance(atk, str):
            atk_id = re.sub(r'x\d+$', '', atk)
            attack_ids[atk_id] = True

# From FICHES_MINI_BOSSES_V2.json
with open(base / 'fiches' / 'FICHES_MINI_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    data = json.load(f)
for mb in data:
    for atk in mb.get('attaques', []):
        atk_id = atk['id']
        attack_ids[atk_id] = True

# Generate rename map: keep prefix, replace suffix with code
rename_map = {}
counter = Counter()
for atk_id in attack_ids.keys():
    if '_' in atk_id:
        prefix = atk_id.rsplit('_', 1)[0]
        counter[prefix] += 1
        new_id = f'{prefix}_A{counter[prefix]:02d}'
    else:
        new_id = atk_id
    rename_map[atk_id] = new_id

print('Rename map entries:', len(rename_map))
for old, new in list(rename_map.items())[:15]:
    print(f'  {old} -> {new}')

# Save the rename map
with open(base / 'MAPPING_RENOMMAGE_ATTAQUES.json','w',encoding='utf-8') as f:
    json.dump(rename_map, f, indent=2, ensure_ascii=False)

print('Saved MAPPING_RENOMMAGE_ATTAQUES.json')

# Now apply the rename to ALL files in A_TRADUIRE
total_replaced = 0
files_modified = 0

for f in base.rglob('*'):
    if not f.is_file():
        continue
    if f.suffix in ('.png','.jpg','.ico','.ogg','.wav','.ttf','.otf'):
        continue
    try:
        text = f.read_text(encoding='utf-8')
    except:
        continue
    
    new_text = text
    for old, new in rename_map.items():
        if old in new_text:
            new_text = new_text.replace(old, new)
            total_replaced += 1
    
    if new_text != text:
        f.write_text(new_text, encoding='utf-8')
        files_modified += 1

print(f'\nTotal files modified: {files_modified}')
print(f'Total replacements: {total_replaced}')
