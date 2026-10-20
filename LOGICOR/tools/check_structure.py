from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# List top-level directories
print('Top-level directories:')
for d in sorted(base.iterdir()):
    if d.is_dir():
        print(f'  {d.name}/')
print()

# Check for the 8 mandatory folders
mandatory = ['0_autoload', '1_core', '2_sequence', '3_entities', '4_ui', '5_data', '6_assets', '7_tests']
print('Mandatory folders present:')
for m in mandatory:
    exists = (base / m).exists()
    status = "YES" if exists else "NO"
    print(f'  {m}: {status}')
