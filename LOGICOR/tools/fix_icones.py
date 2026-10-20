from pathlib import Path

f = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE\fiches\ICONES_UI.json')
text = f.read_text(encoding='utf-8')
text = text.replace('PerkRadial', 'PerkA12')
text = text.replace('Attributes\\Radial', 'Attributes\\A12')
text = text.replace('"nom": "Dash"', '"nom": "Esquive"')
text = text.replace('Icons\\Dash', 'Icons\\Esquive')
text = text.replace('PerfectDashIcon', 'PerfectEsquiveIcon')
f.write_text(text, encoding='utf-8')
print('Fixed ICONES_UI.json')
