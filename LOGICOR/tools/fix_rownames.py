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
print('First 10:', list(attack_ids)[:10])

# Read DT_AttackRegistry.csv
f = base / '5_data' / 'DT_AttackRegistry.csv'
with open(f, 'r', encoding='utf-8-sig') as csv_file:
    reader = csv.reader(csv_file)
    header = next(reader)
    rows = list(reader)

print(f'Total rows in DT_AttackRegistry.csv: {len(rows)}')

# Create a mapping from old RowName to new attack ID
# The RowName format is: ANO-.Me_A01 (prefix + . + suffix)
# The attack ID format is: ANO-001_A01 (prefix + _ + suffix)
# We need to match them

# Build a map: suffix -> new_id
suffix_to_new = {}
for atk_id in attack_ids:
    # Extract suffix (after the last underscore)
    if '_' in atk_id:
        suffix = atk_id.split('_')[-1]
        suffix_to_new[suffix] = atk_id

print(f'Suffixes: {len(suffix_to_new)}')

# Update RowNames
updated = 0
for row in rows:
    old_rowname = row[0]
    # Extract suffix from RowName (after the last underscore)
    if '_' in old_rowname:
        suffix = old_rowname.split('_')[-1]
        if suffix in suffix_to_new:
            row[0] = suffix_to_new[suffix]
            updated += 1

print(f'Updated {updated} RowNames')

# Write back
with open(f, 'w', encoding='utf-8', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(header)
    writer.writerows(rows)

print('Saved DT_AttackRegistry.csv')
