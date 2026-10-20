from pathlib import Path
import shutil

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Create mandatory folders
mandatory = ['0_autoload', '1_core', '2_sequence', '3_entities', '4_ui', '5_data', '6_assets', '7_tests']
for m in mandatory:
    (base / m).mkdir(exist_ok=True)

# Move files
# acteurs/ -> 3_entities/
for f in (base / 'acteurs').iterdir():
    if f.is_file():
        shutil.move(str(f), str(base / '3_entities' / f.name))
(base / 'acteurs').rmdir()

# adversaires/ -> 3_entities/
for f in (base / 'adversaires').iterdir():
    if f.is_file():
        shutil.move(str(f), str(base / '3_entities' / f.name))
(base / 'adversaires').rmdir()

# autoload/ -> 0_autoload/
for f in (base / 'autoload').iterdir():
    if f.is_file():
        shutil.move(str(f), str(base / '0_autoload' / f.name))
(base / 'autoload').rmdir()

# systemes/ -> 1_core/
for f in (base / 'systemes').iterdir():
    if f.is_file():
        shutil.move(str(f), str(base / '1_core' / f.name))
(base / 'systemes').rmdir()

# scenes/ -> 2_sequence/
for f in (base / 'scenes').iterdir():
    if f.is_file():
        shutil.move(str(f), str(base / '2_sequence' / f.name))
(base / 'scenes').rmdir()

# ui/ -> 4_ui/
for f in (base / 'ui').iterdir():
    if f.is_file():
        shutil.move(str(f), str(base / '4_ui' / f.name))
(base / 'ui').rmdir()

# donnees/ -> 5_data/
for f in (base / 'donnees').iterdir():
    if f.is_file():
        shutil.move(str(f), str(base / '5_data' / f.name))
(base / 'donnees').rmdir()

# fiches/ -> 5_data/
for f in (base / 'fiches').iterdir():
    if f.is_file():
        shutil.move(str(f), str(base / '5_data' / f.name))
(base / 'fiches').rmdir()

print('Reorganized A_TRADUIRE to comply with R01-R08')
