import json
from pathlib import Path

f = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE\fiches\FICHES_MINI_BOSSES_V2.json')
text = f.read_text(encoding='utf-8')

tokens = ['ScytheThrow','Radial','Rush','Grind','Ultimate','MiasmaGeyser','ForwardBite','TurnSlam','PoundCombo','Flurry','Uppercut','Kick','Dash','Defense','Swipe','LungeTurn','VacuumC','Burrow','CBreath','FireBall','Headbang','ClamUp','Spotlight','Teleport','Polymorph','RangedTorches','MeleeCombo','Melee1','BannerSummon','CastOrbit','HowlSummon','CircleSelector','PoundL','PoundR','SwingLeft','SwingRight','RadialIn','Radial2','Radial3','DashBackward','DashForward','Slam','SummonSelector','CastSelector']

for i, line in enumerate(text.split('\n'), 1):
    for t in tokens:
        if t in line:
            print(f'{i}: [{t}] {line.strip()[:100]}')
            break
