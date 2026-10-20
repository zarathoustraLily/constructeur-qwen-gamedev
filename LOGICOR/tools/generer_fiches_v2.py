import json, csv
from pathlib import Path
from collections import OrderedDict

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Read DT_AttackRegistry.csv
attacks = OrderedDict()
with open(base / '5_data' / 'DT_AttackRegistry.csv','r',encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    for row in reader:
        rowname = row['RowName']
        # Convert to French keys
        french_row = {}
        for k, v in row.items():
            if k == 'RowName':
                french_row['id'] = v
            elif k == 'OwnerTag':
                french_row['proprietaire'] = v
            elif k == 'DisplayName':
                french_row['nom_affiche'] = v
            elif k.startswith('AI_'):
                # Convert AI_ keys to French
                french_key = k.replace('AI_', 'IA.')
                french_row[french_key] = v
            elif k == 'Damage':
                french_row['Degats'] = v
            elif k == 'DamageRadius':
                french_row['RayonDegats'] = v
            elif k == 'Range':
                french_row['Portee'] = v
            elif k == 'Cooldown':
                french_row['Recharge'] = v
        attacks[rowname] = french_row

print(f'Total attacks loaded: {len(attacks)}')

# Read FICHES_BOSSES_V2.json
with open(base / '5_data' / 'FICHES_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    bosses = json.load(f)

# Update attack props with all columns from DT_AttackRegistry
updated = 0
for boss in bosses:
    for atk in boss.get('attaques', []):
        atk_id = atk['id']
        if atk_id in attacks:
            # Merge props
            atk['props'].update(attacks[atk_id])
            updated += 1

print(f'Updated {updated} attacks with full data')

# Write back
with open(base / '5_data' / 'FICHES_BOSSES_V2.json','w',encoding='utf-8') as f:
    json.dump(bosses, f, indent=2, ensure_ascii=False)

print('Saved FICHES_BOSSES_V2.json')
