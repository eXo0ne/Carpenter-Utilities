@echo OFF
title Sawhorse - Aftman Quick-Install Script
cd ..
call "tools/aftman.exe" install --no-trust-check
echo Toolchain installed. Press any key to close...
pause>NUL