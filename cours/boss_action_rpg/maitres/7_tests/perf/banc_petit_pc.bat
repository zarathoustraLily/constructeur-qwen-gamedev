@echo off
chcp 65001 > nul
rem Le banc du petit PC : le niveau rendu sur la carte de ce PC, avec la qualité qu'il choisit tout seul, trois mesures de 10 secondes
rem (au repos, en tirant, sorts au plus fort). Résultat dans banc_petit_pc.txt, à la racine du projet : la carte, le temps de chaque
rem image (médiane, 99e centile, pire image), le nombre d'images de plus de 16,7 ms, la mémoire. 60 images par seconde : 16,7 ms.
rem Adapter GODOT si l'exécutable est ailleurs. La première fois, le projet doit être importé (ouvrir l'éditeur une fois).
set GODOT=D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe
cd /d "%~dp0..\.."
del /q banc_petit_pc.txt 2> nul
for %%m in ("" "--tir" "--magie") do (
	"%GODOT%" --path . --resolution 1280x720 --disable-vsync -s res://7_tests/perf/mesurer_rendu.gd -- 120 600 banc_petit_pc.png %%~m | findstr /b "@@RENDU@@" >> banc_petit_pc.txt
)
type banc_petit_pc.txt
echo === Résultat dans banc_petit_pc.txt
pause
