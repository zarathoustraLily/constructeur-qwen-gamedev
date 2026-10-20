import json
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Fix MAPPING_RENOMMAGE.json
f = base / 'MAPPING_RENOMMAGE.json'
with open(f, 'r', encoding='utf-8') as fp:
    text = fp.read()
text = text.replace('WeaponStaffDash', 'WeaponStaffEff')
text = text.replace('WeaponSpellPolymorph', 'WeaponSpellEff')
f.write_text(text, encoding='utf-8')
print('Fixed MAPPING_RENOMMAGE.json')

# Fix MAPPING_RENOMMAGE_ATTAQUES.json
f = base / 'MAPPING_RENOMMAGE_ATTAQUES.json'
with open(f, 'r', encoding='utf-8') as fp:
    data = json.load(fp)

# Remove entries that still contain original tokens
tokens = ['ScytheThrow','Radial','Rush','Grind','Ultimate','MiasmaGeyser','ForwardBite','TurnSlam','PoundCombo','Flurry','Uppercut','Kick','Dash','Defense','Swipe','LungeTurn','VacuumC','Burrow','CBreath','FireBall','Headbang','ClamUp','Spotlight','Teleport','Polymorph','RangedTorches','MeleeCombo','Melee1','BannerSummon','CastOrbit','HowlSummon','CircleSelector','PoundL','PoundR','SwingLeft','SwingRight','RadialIn','Radial2','Radial3','DashBackward','DashForward','Slam','SummonSelector','CastSelector']

new_data = {}
removed = 0
for k, v in data.items():
    if any(t in k for t in tokens):
        removed += 1
    else:
        new_data[k] = v

with open(f, 'w', encoding='utf-8') as fp:
    json.dump(new_data, fp, indent=2, ensure_ascii=False)
print(f'Fixed MAPPING_RENOMMAGE_ATTAQUES.json (removed {removed} entries)')

# Fix SPEC.md
f = base / 'SPEC.md'
text = f.read_text(encoding='utf-8')
text = text.replace('RushCharacter', 'EffCharacter')
text = text.replace('RushWeaponInvulnerable', 'EffWeaponInvulnerable')
text = text.replace('PolymorphDamageTaken', 'EffDamageTaken')
text = text.replace('| Dash | Maj |', '| Esquive | Maj |')
text = text.replace('- **Dash** : sur Maj', '- **Esquive** : sur Maj')
text = text.replace('- [x] Dash du héros', '- [x] Esquive du héros')
f.write_text(text, encoding='utf-8')
print('Fixed SPEC.md')

# Fix acteurs/BPC_HerosBase.gd
f = base / 'acteurs' / 'BPC_HerosBase.gd'
text = f.read_text(encoding='utf-8')
text = text.replace('# Dash', '# Esquive')
f.write_text(text, encoding='utf-8')
print('Fixed BPC_HerosBase.gd')

# Fix adversaires/L_TestOracles.gd
f = base / 'adversaires' / 'L_TestOracles.gd'
text = f.read_text(encoding='utf-8')
text = text.replace('"nom": "Slam"', '"nom": "Eff1"')
text = text.replace('"nom": "Charge"', '"nom": "Eff2"')
text = text.replace('"Slam"', '"Eff1"')
text = text.replace('"Charge"', '"Eff2"')
f.write_text(text, encoding='utf-8')
print('Fixed L_TestOracles.gd')

# Fix donnees/CRT-021.tres
f = base / 'donnees' / 'CRT-021.tres'
text = f.read_text(encoding='utf-8')
text = text.replace('CRT-021_ThugShove', 'CRT-021_A01')
text = text.replace('CRT-021_ThugShoveElite', 'CRT-021_A02')
text = text.replace('CRT-021_ThugSwipe', 'CRT-021_A03')
text = text.replace('CRT-021_ThugSwipeElite', 'CRT-021_A04')
f.write_text(text, encoding='utf-8')
print('Fixed CRT-021.tres')

# Fix fiche DONNEES_UI.json
f = base / 'fiches' / 'DONNEES_UI.json'
text = f.read_text(encoding='utf-8')
text = text.replace('"Rush"', '"Eff"')
f.write_text(text, encoding='utf-8')
print('Fixed DONNEES_UI.json')

# Fix PLAN_CONSTRUCTION_GODOT.md
f = base / 'PLAN_CONSTRUCTION_GODOT.md'
text = f.read_text(encoding='utf-8')
text = text.replace('# Dash', '# Esquive')
f.write_text(text, encoding='utf-8')
print('Fixed PLAN_CONSTRUCTION_GODOT.md')

# Fix README.md
f = base / 'README.md'
text = f.read_text(encoding='utf-8')
text = text.replace('# Dash', '# Esquive')
f.write_text(text, encoding='utf-8')
print('Fixed README.md')

# Fix MIN-005.tres
f = base / 'donnees' / 'MIN-005.tres'
text = f.read_text(encoding='utf-8')
text = text.replace('IA_DashSiDepassement', 'IA_EsquivSiDepassement')
f.write_text(text, encoding='utf-8')
print('Fixed MIN-005.tres')

# Fix MIN-008.tres
f = base / 'donnees' / 'MIN-008.tres'
text = f.read_text(encoding='utf-8')
text = text.replace('IA_DashSiDepassement', 'IA_EsquivSiDepassement')
f.write_text(text, encoding='utf-8')
print('Fixed MIN-008.tres')

print('All fixes applied')
