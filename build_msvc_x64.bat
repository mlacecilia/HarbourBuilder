@echo off
REM Non-interactive wrapper: feed "3" (MSVC x64) to build_win.bat
echo 3| call "%~dp0build_win.bat"
