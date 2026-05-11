@echo off
REM Build HbBuilder for Windows - VS 2022/2026 Ready (MSVC x64)
setlocal enabledelayedexpansion

set HBDIR=C:\harbour
set HBINC=%HBDIR%\include
set HBBIN=%HBDIR%\bin
set HBLIB=%HBDIR%\lib
set SRCDIR=%~dp0source
set CPPDIR=%~dp0source\cpp
set INCDIR=%~dp0include
set OUTDIR=%~dp0bin
set RESDIR=%~dp0resources

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

if not exist "%HBBIN%\harbour.exe" (
   echo ERROR: harbour.exe no encontrado en "%HBBIN%".
   pause & exit /b 1
)
if not exist "%HBLIB%\hbvm.lib" (
   echo ERROR: librerias de Harbour no encontradas en "%HBLIB%".
   pause & exit /b 1
)

REM ============================================================
REM   Detect Visual Studio via vswhere
REM ============================================================
set VSWHERE="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist %VSWHERE% set VSWHERE="%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"

if not exist %VSWHERE% (
   echo ERROR: vswhere.exe no encontrado. Instala Visual Studio.
   pause & exit /b 1
)

for /f "usebackq tokens=*" %%i in (`%VSWHERE% -latest -property installationPath`) do set VSDIR=%%i

if not exist "%VSDIR%" (
   echo ERROR: No se encontro instalacion de Visual Studio.
   pause & exit /b 1
)

echo Detectado: %VSDIR%
echo Harbour:   %HBDIR% (x64)
echo.

REM Configura cl.exe / link.exe para x64 (Harbour install es x64)
call "%VSDIR%\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64 >nul
if errorlevel 1 (echo VsDevCmd FAILED & pause & exit /b 1)

REM ============================================================
REM   Build Process
REM ============================================================
echo === Step 1: Compile Harbour PRG ===
cd /d "%SRCDIR%"
"%HBBIN%\harbour.exe" hbbuilder_win.prg -n -w -es2 -q -I%HBINC% -I%INCDIR%
if errorlevel 1 (echo HARBOUR FAILED & pause & exit /b 1)

echo === Step 2: Compile C/CPP sources ===
REM /D_CRT_SECURE_NO_WARNINGS silencia las deprecaciones de strcpy/sprintf/fopen...
REM (codigo C estandar legitimo; no migramos a las variantes _s no portables).
set CL_BASE=/nologo /c /O2 /EHsc /MT /D_CRT_SECURE_NO_WARNINGS /I"%HBINC%" /I"%INCDIR%"

REM /wd4101 solo en el .c generado por harbour.exe (unreferenced locals
REM intrinsecos a la generacion PRG -> C, no corregibles aqui).
cl.exe %CL_BASE% /W3 /wd4101 hbbuilder_win.c /Fohbbuilder_win.obj
if errorlevel 1 (echo CL FAILED on hbbuilder_win.c & pause & exit /b 1)

for %%f in (tform hbbridge tcontrol tcontrols hb_db_real) do (
   if exist "%CPPDIR%\%%f.cpp" (
      cl.exe %CL_BASE% /W3 "%CPPDIR%\%%f.cpp" /Fo%%f.obj
      if errorlevel 1 (echo CL FAILED on %%f.cpp & pause & exit /b 1)
   )
)

echo === Step 3: Link ===
set OBJS=hbbuilder_win.obj tform.obj hbbridge.obj tcontrol.obj tcontrols.obj hb_db_real.obj
set HBLIBS=hbvm.lib hbrtl.lib hbcommon.lib hblang.lib hbrdd.lib hbmacro.lib hbpp.lib ^
 hbcplr.lib hbct.lib hbhsx.lib hbsix.lib hbusrrdd.lib ^
 rddntx.lib rddnsx.lib rddcdx.lib rddfpt.lib ^
 hbcpage.lib hbpcre.lib hbzlib.lib hbdebug.lib ^
 hbsqlit3.lib sqlite3.lib ^
 gtgui.lib gtwin.lib gtwvt.lib
set SYSLIBS=user32.lib kernel32.lib gdi32.lib comctl32.lib comdlg32.lib shell32.lib ^
 ole32.lib oleaut32.lib advapi32.lib uuid.lib ws2_32.lib winmm.lib msimg32.lib ^
 gdiplus.lib winspool.lib dwmapi.lib iphlpapi.lib

link.exe /NOLOGO /OUT:"%OUTDIR%\hbbuilder_win.exe" /SUBSYSTEM:WINDOWS ^
   /LIBPATH:"%HBLIB%" %OBJS% %HBLIBS% %SYSLIBS%

if errorlevel 1 (
    echo LINK FAILED
    pause
    exit /b 1
)

echo === Step 4: Copy Scintilla DLLs ===
if exist "%RESDIR%\Scintilla.dll" copy /y "%RESDIR%\Scintilla.dll" "%OUTDIR%\" >nul
if exist "%RESDIR%\Lexilla.dll"   copy /y "%RESDIR%\Lexilla.dll"   "%OUTDIR%\" >nul

echo.
echo === BUILD SUCCESSFUL ===
echo Output: %OUTDIR%\hbbuilder_win.exe
pause
