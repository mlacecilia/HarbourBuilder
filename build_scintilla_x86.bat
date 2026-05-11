@echo off
REM Build 32-bit Scintilla.dll + Lexilla.dll from resources\scintilla_src using MSVC x86.
REM Output -> resources\x86\Scintilla.dll, resources\x86\Lexilla.dll
setlocal

set "VS=C:\Program Files\Microsoft Visual Studio\18\Community"
set "VCVARS=%VS%\VC\Auxiliary\Build\vcvarsall.bat"
if not exist "%VCVARS%" ( echo ERROR: vcvarsall.bat not found at "%VCVARS%" & exit /b 1 )

call "%VCVARS%" x86
if errorlevel 1 ( echo ERROR: vcvarsall x86 failed & exit /b 1 )

set "ROOT=%~dp0"
set "SCI=%ROOT%resources\scintilla_src\scintilla\win32"
set "LEX=%ROOT%resources\scintilla_src\lexilla\src"
set "OUT=%ROOT%resources\x86"
if not exist "%OUT%" mkdir "%OUT%"

echo === Building Scintilla.dll (x86) ===
pushd "%SCI%"
nmake -f scintilla.mak clean >nul 2>&1
nmake -f scintilla.mak QUIET=1
if errorlevel 1 ( echo SCINTILLA BUILD FAILED & popd & exit /b 1 )
popd
if not exist "%ROOT%resources\scintilla_src\scintilla\bin\Scintilla.dll" ( echo ERROR: Scintilla.dll not produced & exit /b 1 )

echo === Building Lexilla.dll (x86) ===
pushd "%LEX%"
nmake -f lexilla.mak clean >nul 2>&1
nmake -f lexilla.mak QUIET=1
if errorlevel 1 ( echo LEXILLA BUILD FAILED & popd & exit /b 1 )
popd
if not exist "%ROOT%resources\scintilla_src\lexilla\bin\lexilla.dll" ( echo ERROR: lexilla.dll not produced & exit /b 1 )

echo === Copying to resources\x86 ===
copy /y "%ROOT%resources\scintilla_src\scintilla\bin\Scintilla.dll" "%OUT%\Scintilla.dll" >nul
copy /y "%ROOT%resources\scintilla_src\lexilla\bin\lexilla.dll"   "%OUT%\Lexilla.dll"   >nul

echo === DONE ===
dir "%OUT%\*.dll"
endlocal
