import re, csv
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Read DT_EffectRegistry.csv and rename effect names
f = base / 'donnees' / 'DT_EffectRegistry.csv'
with open(f, 'r', encoding='utf-8-sig') as csv_file:
    reader = csv.reader(csv_file)
    header = next(reader)
    rows = list(reader)

print(f'Total rows: {len(rows)}')

# Rename effect names (columns 0, 1, 2)
# Replace Rush, Dash, Polymorph, etc. with generic codes
renamed = 0
for row in rows:
    for i in [0, 1, 2]:
        if i < len(row):
            old = row[i]
            new = old
            # Replace attack names in effect IDs
            for token in ['Rush', 'Dash', 'Polymorph', 'Slam', 'Swipe', 'Teleport', 'Spotlight', 'ClamUp', 'Headbang', 'FireBall', 'Burrow', 'VacuumC', 'LungeTurn', 'ForwardBite', 'TurnSlam', 'PoundCombo', 'Flurry', 'Uppercut', 'Kick', 'Defense', 'Grind', 'Ultimate', 'MiasmaGeyser', 'ScytheThrow', 'Radial', 'RangedTorches', 'MeleeCombo', 'Melee1', 'BannerSummon', 'CastOrbit', 'HowlSummon', 'CircleSelector', 'PoundL', 'PoundR', 'SwingLeft', 'SwingRight', 'RadialIn', 'Radial2', 'Radial3', 'DashBackward', 'DashForward', 'SummonSelector', 'CastSelector']:
                if token in new:
                    new = new.replace(token, 'Eff')
            row[i] = new
            if row[i] != old:
                renamed += 1

print(f'Renamed {renamed} effect name entries')

# Write back
with open(f, 'w', encoding='utf-8', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(header)
    writer.writerows(rows)

print('Saved DT_EffectRegistry.csv')
