import json, csv
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Read all fiches
with open(base / '5_data' / 'FICHES_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    bosses = json.load(f)

attack_ids = set()
for boss in bosses:
    for atk in boss.get('attaques', []):
        attack_ids.add(atk['id'])

with open(base / '5_data' / 'FICHES_ENNEMIS_V2.json','r',encoding='utf-8-sig') as f:
    enemies = json.load(f)

for enemy in enemies:
    for atk in enemy.get('arsenal', []):
        if isinstance(atk, str):
            attack_ids.add(atk)

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

# Build a map from (prefix_type, number, suffix) to attack_id
# RowName format: ANO-.Me_A01 -> prefix_type=ANO, number=., suffix=Me_A01
# Attack ID format: ANO-001_A01 -> prefix_type=ANO, number=001, suffix=01

# Extract all attack_ids by type
ano_ids = set(a for a in attack_ids if a.startswith('ANO'))
crt_ids = set(a for a in attack_ids if a.startswith('CRT'))
min_ids = set(a for a in attack_ids if a.startswith('MIN'))

print(f'ANO: {len(ano_ids)}, CRT: {len(crt_ids)}, MIN: {len(min_ids)}')

# Update RowNames based on prefix
updated = 0
for row in rows:
    old_rowname = row[0]
    
    # Determine type from prefix
    if old_rowname.startswith('ANO-'):
        # Find the ANO number from the row context (OwnerTag)
        owner = row[1] if len(row) > 1 else ''
        # Extract number from owner (e.g., 'ANO-001' -> '001')
        if '-' in owner:
            num = owner.split('-')[-1]
            # Find matching attack
            for atk_id in ano_ids:
                if atk_id.startswith(f'ANO-{num}_A'):
                    # Check suffix match
                    old_suffix = old_rowname.split('_A')[1] if '_A' in old_rowname else ''
                    new_suffix = atk_id.split('_A')[1] if '_A' in atk_id else ''
                    if old_suffix == new_suffix:
                        row[0] = atk_id
                        updated += 1
                        break
    elif old_rowname.startswith('CRT-'):
        owner = row[1] if len(row) > 1 else ''
        if '-' in owner:
            num = owner.split('-')[-1]
            for atk_id in crt_ids:
                if atk_id.startswith(f'CRT-{num}_A'):
                    old_suffix = old_rowname.split('_A')[1] if '_A' in old_rowname else ''
                    new_suffix = atk_id.split('_A')[1] if '_A' in atk_id else ''
                    if old_suffix == new_suffix:
                        row[0] = atk_id
                        updated += 1
                        break
    elif old_rowname.startswith('MIN-'):
        owner = row[1] if len(row) > 1 else ''
        if '-' in owner:
            num = owner.split('-')[-1]
            for atk_id in min_ids:
                if atk_id.startswith(f'MIN-{num}_A'):
                    old_suffix = old_rowname.split('_A')[1] if '_A' in old_rowname else ''
                    new_suffix = atk_id.split('_A')[1] if '_A' in atk_id else ''
                    if old_suffix == new_suffix:
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
