import re
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')
f = base / 'ORGANOGRAPHE_COMPLET.md'
text = f.read_text(encoding='utf-8')

tokens = ['ScytheThrow','Radial','Rush','Grind','Ultimate','MiasmaGeyser','ForwardBite','TurnSlam','PoundCombo','Flurry','Uppercut','Kick','Dash','Defense','Swipe','LungeTurn','VacuumC','Burrow','CBreath','FireBall','Headbang','ClamUp','Spotlight','Teleport','Polymorph','RangedTorches','MeleeCombo','Melee1','BannerSummon','CastOrbit','HowlSummon','CircleSelector','PoundL','PoundR','SwingLeft','SwingRight','RadialIn','Radial2','Radial3','DashBackward','DashForward','Slam','SummonSelector','CastSelector','Underworld']

# Replace all tokens with 'Eff'
for t in tokens:
    text = text.replace(t, 'Eff')

f.write_text(text, encoding='utf-8')
print('Fixed ORGANOGRAPHE_COMPLET.md')
