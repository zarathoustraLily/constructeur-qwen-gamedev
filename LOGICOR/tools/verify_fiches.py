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

print(f'Total unique attack IDs in fiches: {len(attack_ids)}')

# Read DT_AttackRegistry.csv
f = base / '5_data' / 'DT_AttackRegistry.csv'
with open(f, 'r', encoding='utf-8-sig') as csv_file:
    reader = csv.reader(csv_file)
    header = next(reader)
    rows = [row for row in reader if row and row[0].strip()]

rownames = set(row[0] for row in rows)
print(f'Total RowNames in CSV: {len(rownames)}')

# Check overlap
overlap = attack_ids & rownames
print(f'Overlap: {len(overlap)}')

# Check missing
missing_in_csv = attack_ids - rownames
print(f'Missing in CSV: {len(missing_in_csv)}')
if missing_in_csv:
    print('First 5:', list(missing_in_csv)[:5])

missing_in_fiches = rownames - attack_ids
print(f'Missing in fiches: {len(missing_in_fiches)}')
if missing_in_fiches:
    print('First 5:', list(missing_in_fiches)[:5])
