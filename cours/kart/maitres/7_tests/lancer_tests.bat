@echo off
chcp 65001 > nul
rem Lance tous les tests du jeu (GdUnit4) sans fenêtre, à cadence fixe (60 images par seconde).
rem Adapter GODOT si l'exécutable est ailleurs. Rapport HTML : .godot\rapports_tests\report_N\index.html
set GODOT=D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe
cd /d "%~dp0.."
"%GODOT%" --headless --path . --fixed-fps 60 -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -rd .godot/rapports_tests -a res://7_tests ++ cadence_fixe
if errorlevel 1 (echo === AU MOINS UN TEST ECHOUE) else (echo === TOUS LES TESTS PASSENT)
pause
