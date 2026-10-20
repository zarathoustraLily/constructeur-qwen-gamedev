import json
from pathlib import Path

with open(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE\fiches\FICHES_MINI_BOSSES_V2.json','r',encoding='utf-8-sig') as f:
    data = json.load(f)

tokens = ['ScytheThrow','Radial','Rush','Grind','Ultimate','MiasmaGeyser','ForwardBite','TurnSlam','PoundCombo','Flurry','Uppercut','Kick','Dash','Defense','Swipe','LungeTurn','VacuumC','Burrow','CBreath','FireBall','Headbang','ClamUp','Spotlight','Teleport','Polymorph','RangedTorches','MeleeCombo','Melee1','BannerSummon','CastOrbit','HowlSummon','CircleSelector','PoundL','PoundR','SwingLeft','SwingRight','RadialIn','Radial2','Radial3','DashBackward','DashForward','Slam','SummonSelector','CastSelector']

for mb in data:
    for atk in mb.get('attaques', []):
        atk_id = atk['id']
        for t in tokens:
            if t in atk_id:
                print(f'{mb["id"]}: {atk_id} contains {t}')
