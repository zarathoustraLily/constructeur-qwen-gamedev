from pathlib import Path

f = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE\fiches\ICONES_UI.json')
text = f.read_text(encoding='utf-8')
# The paths use double backslashes in JSON
text = text.replace('Attributes\\\\Radial', 'Attributes\\\\A12')
text = text.replace('Icons\\\\Dash', 'Icons\\\\Esquive')
f.write_text(text, encoding='utf-8')
print('Fixed ICONES_UI.json paths (double backslash)')
