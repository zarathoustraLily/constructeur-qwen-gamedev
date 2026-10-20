import json, csv
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Read FICHES_BOSSES_V2.json to get all attack IDs
with open(base / '5_data' / 'FICHES_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    bosses = json.load(f)

attack_ids = set()
for boss in bosses:
    for atk in boss.get('attaques', []):
        attack_ids.add(atk['id'])

# Read FICHES_ENNEMIS_V2.json
with open(base / '5_data' / 'FICHES_ENNEMIS_V2.json','r',encoding='utf-8-sig') as f:
    enemies = json.load(f)

for enemy in enemies:
    for atk in enemy.get('arsenal', []):
        if isinstance(atk, str):
            attack_ids.add(atk)

# Read FICHES_MINI_BOSSES_V2.json
with open(base / '5_data' / 'FICHES_MINI_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    minis = json.load(f)

for mini in minis:
    for atk in mini.get('attaques', []):
        attack_ids.add(atk['id'])

print(f'Total unique attack IDs: {len(attack_ids)}')

# Read DT_AttackRegistry.csv
f = base / '5_data' / 'DT_AttackRegistry.csv'
with open(f, 'r', encoding='utf-8-sig') as csv_file:
    reader = csv.reader(csv_file)
    header = next(reader)
    rows = [row for row in reader if row and row[0].strip()]

print(f'Total non-empty rows: {len(rows)}')

# Build a map from suffix to full attack_id
# Suffix is everything after _A
suffix_map = {}
for atk_id in attack_ids:
    if '_A' in atk_id:
        suffix = atk_id.split('_A')[1]
        # Keep the first one if duplicates
        if suffix not in suffix_map:
            suffix_map[suffix] = atk_id

print(f'Unique suffixes: {len(suffix_map)}')

# Update RowNames
updated = 0
not_found = []
for row in rows:
    old_rowname = row[0]
    # Extract suffix (after _A)
    if '_A' in old_rowname:
        suffix = old_rowname.split('_A')[1]
        if suffix in suffix_map:
            row[0] = suffix_map[suffix]
            updated += 1
        else:
            not_found.append(old_rowname)

print(f'Updated {updated} RowNames')
print(f'Not found: {len(not_found)}')
if not_found:
    print('First 5 not found:', not_found[:5])

# Write back
with open(f, 'w', encoding='utf-8', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(header)
    writer.writerows(rows)

print('Saved DT_AttackRegistry.csv')
