import re
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Check each remaining file for the tokens
tokens = ['ScytheThrow','Radial','Rush','Grind','Ultimate','MiasmaGeyser','ForwardBite','TurnSlam','PoundCombo','Flurry','Uppercut','Kick','Dash','Defense','Swipe','LungeTurn','VacuumC','Burrow','CBreath','FireBall','Headbang','ClamUp','Spotlight','Teleport','Polymorph','RangedTorches','MeleeCombo','Melee1','BannerSummon','CastOrbit','HowlSummon','CircleSelector','PoundL','PoundR','SwingLeft','SwingRight','RadialIn','Radial2','Radial3','DashBackward','DashForward','Slam','SummonSelector','CastSelector','Underworld']

for f in base.rglob('*'):
    if not f.is_file():
        continue
    if f.suffix in ('.png','.jpg','.ico','.ogg','.wav','.ttf','.otf'):
        continue
    try:
        text = f.read_text(encoding='utf-8')
    except:
        continue
    for t in tokens:
        if t in text:
            # Find the lines
            for i, line in enumerate(text.split('\n'), 1):
                if t in line:
                    print(f'{f.relative_to(base)}:{i}: [{t}] {line.strip()[:100]}')
