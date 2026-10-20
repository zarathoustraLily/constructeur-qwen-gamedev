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

# Build a map from old RowName prefix to new prefix
# RowName format: ANO-.Me_A01 -> ANO-001_A01
# The prefix before _A is the key

# Extract all prefixes from attack_ids
prefix_map = {}
for atk_id in attack_ids:
    # Find the _A pattern
    if '_A' in atk_id:
        prefix = atk_id.split('_A')[0]
        prefix_map[prefix] = prefix

print(f'Prefixes: {len(prefix_map)}')

# Update RowNames
updated = 0
for row in rows:
    old_rowname = row[0]
    # Extract the prefix (before _A)
    if '_A' in old_rowname:
        old_prefix = old_rowname.split('_A')[0]
        # Check if we have a mapping
        if old_prefix in prefix_map:
            new_prefix = prefix_map[old_prefix]
            suffix = old_rowname.split('_A')[1]
            row[0] = f'{new_prefix}_A{suffix}'
            updated += 1
        else:
            # Try to match by suffix
            suffix = old_rowname.split('_A')[-1]
            for atk_id in attack_ids:
                if atk_id.endswith(f'_A{suffix}') and atk_id.split('_A')[0] == old_prefix.replace('-', ''):
                    row[0] = atk_id
                    updated += 1
                    break

print(f'Updated {updated} RowNames')

# Write back
with open(f, 'w', encoding='utf-8', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(header)
    writer.writerows(rows)

print('Saved DT_AttackRegistry.csv')
