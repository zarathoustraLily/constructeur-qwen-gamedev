import re, csv
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Read DT_AttackRegistry.csv and rename column 3 (DisplayName)
f = base / 'donnees' / 'DT_AttackRegistry.csv'
with open(f, 'r', encoding='utf-8-sig') as csv_file:
    reader = csv.reader(csv_file)
    header = next(reader)
    rows = list(reader)

print(f'Total rows: {len(rows)}')
print(f'Header: {header}')

# Rename column 3 (index 2) - the DisplayName column
# Format: boss-004-lvl_4ScytheThrow -> ANO-004_A12
renamed = 0
for row in rows:
    if len(row) > 2:
        old_name = row[2]
        # Extract the type and number
        if old_name.startswith('boss-'):
            num = old_name.split('-')[1]
            new_name = f'ANO-{num[:3]}_A??'
        elif old_name.startswith('enemi-'):
            num = old_name.split('-')[1]
            new_name = f'CRT-{num[:3]}_A??'
        elif old_name.startswith('miniboss-'):
            num = old_name.split('-')[1]
            new_name = f'MIN-{num[:3]}_A??'
        else:
            new_name = old_name
        row[2] = new_name
        renamed += 1

print(f'Renamed {renamed} DisplayName entries')

# Write back
with open(f, 'w', encoding='utf-8', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(header)
    writer.writerows(rows)

print('Saved DT_AttackRegistry.csv')
