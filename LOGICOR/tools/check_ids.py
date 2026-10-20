import json, csv
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Check attack IDs in FICHES_BOSSES_V2.json
with open(base / '5_data' / 'FICHES_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    bosses = json.load(f)

print('Attack IDs in FICHES_BOSSES_V2.json:')
for boss in bosses[:2]:
    print(f'  {boss["id"]}:')
    for atk in boss['attaques'][:3]:
        print(f'    {atk["id"]}')

# Check RowNames in DT_AttackRegistry.csv
print()
print('RowNames in DT_AttackRegistry.csv:')
with open(base / '5_data' / 'DT_AttackRegistry.csv','r',encoding='utf-8-sig') as f:
    reader = csv.reader(f)
    next(reader)
    for i, row in enumerate(reader):
        if i < 5:
            print(f'  {row[0]}')
        else:
            break
