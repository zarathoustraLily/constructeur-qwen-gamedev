import re
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Final token check
tokens = ['ScytheThrow','Radial','Rush','Grind','Ultimate','MiasmaGeyser','ForwardBite','TurnSlam','PoundCombo','Flurry','Uppercut','Kick','Dash','Defense','Swipe','LungeTurn','VacuumC','Burrow','CBreath','FireBall','Headbang','ClamUp','Spotlight','Teleport','Polymorph','RangedTorches','MeleeCombo','Melee1','BannerSummon','CastOrbit','HowlSummon','CircleSelector','PoundL','PoundR','SwingLeft','SwingRight','RadialIn','Radial2','Radial3','DashBackward','DashForward','Slam','SummonSelector','CastSelector','Underworld']

total_tokens = 0
files_with_tokens = 0

for f in base.rglob('*'):
    if not f.is_file():
        continue
    if '.godot' in str(f):
        continue
    if f.suffix in ('.png','.jpg','.ico','.ogg','.wav','.ttf','.otf'):
        continue
    try:
        text = f.read_text(encoding='utf-8')
    except:
        continue
    for t in tokens:
        if t in text:
            files_with_tokens += 1
            total_tokens += text.count(t)
            print(f'{f.relative_to(base)}: [{t}]')

print()
print('FILES WITH TOKENS:', files_with_tokens)
print('TOTAL TOKENS:', total_tokens)

# Count files
count = 0
for f in base.rglob('*'):
    if f.is_file() and '.godot' not in str(f):
        count += 1
print('TOTAL FILES:', count)
