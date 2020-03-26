@echo off
setlocal EnableDelayedExpansion
prompt $P$G

::
:: 'APPVEYOR_PROJECT_NAME==Watt-32' unless testing this "appveyor-script.bat [build_src | build_bin | build_tests]"
:: locally using 'cmd'.
::
:: Change this for an 'echo.exe' with colour support. Like Cygwin.
::
set _ECHO=%MSYS2_ROOT%\usr\bin\echo.exe -e

if %APPVEYOR_PROJECT_NAME%. == . (
  if %BUILDER%. == . (
    echo BUILDER not set!
    exit /b 1
  )
  if %WATT_ROOT%. == . (
    echo WATT_ROOT not set!
    exit /b 1
  )
  set APPVEYOR_BUILD_FOLDER=%WATT_ROOT%
  set APPVEYOR_BUILD_FOLDER_UNIX=e:/net/watt
  set LOCAL_TEST=1

) else (
  set APPVEYOR_BUILD_FOLDER=c:\projects\watt-32
  set APPVEYOR_BUILD_FOLDER_UNIX=c:/projects/watt-32
  set _ECHO=c:\msys64\usr\bin\echo.exe -e
  set LOCAL_TEST=0
)

::
:: Download stuff to here:
::
set CI_ROOT=%APPVEYOR_BUILD_FOLDER%\CI-temp
md %CI_ROOT%

::
:: Since only 'watcom' has a '%MODEL%' set in 'appveoyr.yml'
::
if %BUILDER%. == watcom. (
  %_ECHO% "\e[1;33mDoing '%1' for 'BUILDER=%BUILDER%', 'MODEL=%MODEL%'.\e[0m"

) else (
  %_ECHO% "\e[1;33mDoing '%1' for 'BUILDER=%BUILDER%'.\e[0m"
)

::
:: Stuff common to '[build_src | build_bin | build_tests]'
::
:: mingw/mingw64: Add PATH to 'gcc' and stuff for 'util/pkg-conf.mak'.
::
if %BUILDER%. == mingw64. (
  md lib\pkgconfig 2> NUL
  set MINGW32=%APPVEYOR_BUILD_FOLDER_UNIX%
  set MINGW64=%APPVEYOR_BUILD_FOLDER_UNIX%
)

::
:: Set the dir for djgpp cross-environment.
:: Use forward slashes for this. Otherwise 'sh' + 'make' will get confused.
:: 7z can create only 1 level of missing directories. So a '%CI_ROOT%\djgpp' will not work
::
set DJGPP=%APPVEYOR_BUILD_FOLDER_UNIX%/CI-temp
set DJ_PREFIX=%DJGPP%/bin/i586-pc-msdosdjgpp-

::
:: Set env-var for building with Watcom 2.0
::
set WATCOM=%CI_ROOT%
set NT_INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
set DOS_INCLUDE=%WATCOM%\h

::
:: Shit for brains 'cmd' cannot have this inside a 'if x (' block since
:: on a AppVeyor build several "c:\Program Files (x86)\Microsoft xxx" strings
:: are in the 'PATH'!
::
:: This is the PATH to the 64-bit 'clang-cl' already on AppVeyor.
::
set PATH=%PATH%;c:\Program Files\LLVM\bin

::
:: And append the '%WATCOM%\binnt' to the 'PATH' since Watcom has an 'cl.exe'
:: which we do not want to use for 'BUILDER=visualc'.
::
set PATH=%PATH%;%WATCOM%\binnt

::
:: In case my curl was built with Wsock-Trace
::
set WSOCK_TRACE_LEVEL=0

::
:: For a true AppVeyor build:
::
if %WATT_ROOT%. == . set WATT_ROOT=%CD%

::
:: Sanity check:
::
if %BUILDER%. == . (
  %_ECHO% "\e[1;31mBUILDER target not specified!\e[0m"
  exit /b 1
)

if %1. == build_src.   goto :build_src
if %1. == build_bin.   goto :build_bin
if %1. == build_tests. goto :build_tests

echo Usage: %~dp0%0 ^[build_src ^| build_bin ^| build_tests^]
exit /b 1

:build_src
cd src

::
:: Generate a 'src\oui-generated.c' file from 'src\oui.txt (do not download it every time).
:: For VisualC / clang-cl only since only those uses '%CL%'.
::
set USES_CL=0
set CL=
if %BUILDER%. == visualc. set USES_CL=1
if %BUILDER%. == clang.   set USES_CL=1

::
:: Assume 'CPU=x86'
::
set BITS=32
if %CPU%. == x64. set BITS=64

::
:: Local 'cmd' test for '(' in env-vars:
:: This is what AppVeyor have first in their PATH:
::   c:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin
::
:: Hence cannot use a 'if x (what-ever) else (something else)' syntax with that
::
if %LOCAL_TEST% == 1 echo on
if %LOCAL_TEST% == 1 (
  if not exist "%APPVEYOR_BUILD_FOLDER_UNIX%" (echo No %APPVEYOR_BUILD_FOLDER_UNIX%. Edit this .bat-file & exit /b 1)
)

:: if %LOCAL_TEST% == 1 set PATH=%PATH%;c:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin

%_ECHO% "\e[1;33m[%CPU%]: call configur.bat %BUILDER%:\e[0m"

if %USES_CL%. == 1. (
  %_ECHO% "\e[1;33mGenerating src\oui-generated.c.\e[0m"
  python.exe make-oui.py > oui-generated.c
  if errorlevel 0 set CL=-DHAVE_OUI_GENERATATED_C
  %_ECHO% "\e[1;33m--------------------------------------------------------------------------------------------------\e[0m"
)

if %BUILDER%. == visualc. (
  call configur.bat visualc
  %_ECHO% "\e[1;33mBuilding release for %CPU%:\e[0m"
  nmake -nologo -f visualc-release_%BITS%.mak
  exit /b
)

if %BUILDER%. == clang. (
  call :install_LLVM
  call configur.bat clang
  %_ECHO% "\e[1;33mBuilding release for '%CPU%':\e[0m"
  make -f clang-release_%BITS%.mak
  exit /b
)

if %BUILDER%. == mingw32. (
  call configur.bat mingw32
  %_ECHO% "\e[1;33mBuilding for 'x86' only:\e[0m"
  make -f MinGW32.mak
  exit /b
)

if %BUILDER%. == mingw64. (
  call configur.bat mingw64
  %_ECHO% "\e[1;33mBuilding for '%CPU%':\e[0m"
  make -f MinGW64_%BITS%.mak
  exit /b
)

if %BUILDER%. == djgpp. (
  call :install_djgpp
  call configur.bat djgpp
  %_ECHO% "\e[1;33mBuilding for djgpp:\e[0m"
  make -f djgpp.mak
  exit /b
)

if %BUILDER%. == watcom. (
  call :install_watcom
  call configur.bat watcom

  if %MODEL%. == win32. (
    %_ECHO% "\e[1;33mBuilding for Watcom/Win32:\e[0m"
    wmake -f watcom_w.mak

  ) else if %MODEL%. == flat. (
    %_ECHO% "\e[1;33mBuilding for Watcom/flat:\e[0m"
    wmake -f watcom_f.mak

  ) else if %MODEL%. == large. (
    %_ECHO% "\e[1;33mBuilding for Watcom/large:\e[0m"
    wmake -f watcom_l.mak

  ) else if %MODEL%. == small32. (
    %_ECHO% "\e[1;33mBuilding for Watcom/small32:\e[0m"
    wmake -f watcom_3.mak

  ) else (
    %_ECHO% "\e[1;31mBUILDER 'watcom' needs a 'MODEL'!\e[0m"
     exit /b 1
  )
  exit /b
)

%_ECHO% "\e[1;31mIllegal BUILDER / CPU (BUILDER=%BUILDER%, CPU=%CPU%) values! Remember cmd.exe is case-sensitive.\e[0m"
exit /b 1

::
:: Build some example programs in './bin'
::
:build_bin

if %CPU%. == x64. (
  %_ECHO% "\e[1;31mNo 'build_bin' for 'x64' yet.\e[0m"
  exit /b 0
)

::
:: './bin/' programs to build for djgpp, Visual-C and Watcom (Win32 + large + flat):
::
set PROGS_DJ=bping.exe ping.exe finger.exe ident.exe htget.exe tcpinfo.exe tracert.exe country.exe
set PROGS_VC=ping.exe finger.exe tcpinfo.exe host.exe htget.exe tracert.exe con-test.exe gui-test.exe lpq.exe lpr.exe ntime.exe whois.exe ident.exe country.exe
set PROGS_WC_WIN=ping.exe htget.exe finger.exe tcpinfo.exe con-test.exe gui-test.exe htget.exe tracert.exe whois.exe
set PROGS_WC_LARGE=ping.exe htget.exe finger.exe tcpinfo.exe htget.exe whois.exe
set PROGS_WC_FLAT=%PROGS_WC_LARGE%
set PROGS_WC_SMALL32=%PROGS_WC_LARGE%

cd bin
if %BUILDER%. == djgpp. (
  %_ECHO% "\e[1;33mBuilding PROGS_DJ=%PROGS_DJ%:\e[0m"
  make -f djgpp_win.mak DPMI_STUB=0 %PROGS_DJ%
  exit /b
)

if %BUILDER%. == visualc. (
  %_ECHO% "\e[1;33mBuilding PROGS_VC=%PROGS_VC%:\e[0m"
  nmake -nologo -f visualc.mak %PROGS_VC%
  exit /b
)

if %BUILDER%. == watcom. (
  if %MODEL%. == win32. (
    %_ECHO% "\e[1;33mwatcom/Win32: Building PROGS_WC_WIN=%PROGS_WC_WIN%:\e[0m"
    rm -f %PROGS_WC_WIN%
    wmake -f wc_win.mak %PROGS_WC_WIN%

  ) else if %MODEL%. == flat. (
    %_ECHO% "\e[1;33mwatcom/flat: Building PROGS_WC_FLAT=%PROGS_WC_FLAT%:\e[0m"
    rm -f %PROGS_WC_LARGE%
    wmake -f causeway.mak %PROGS_WC_FLAT%

  ) else if %MODEL%. == large. (
    %_ECHO% "\e[1;33mwatcom/large: Building PROGS_WC_LARGE=%PROGS_WC_LARGE%:\e[0m"
    rm -f %PROGS_WC_LARGE%
    wmake -f watcom.mak %PROGS_WC_LARGE%

  ) else if %MODEL%. == small32. (
    %_ECHO% "\e[1;33mwatcom/small32: Not yet.\e[0m"

  ) else (
    %_ECHO% "\e[1;31mThe 'watcom' needs a 'MODEL'!\e[0m"
     exit /b 1
  )
  exit /b
)

%_ECHO% "\e[1;31mNo 'build_bin' for 'BUILDER=%BUILDER%' yet.\e[0m"
exit /b 0

::
:: Build (and run?) some test programs in './src/tests'
::
:build_tests
  cd src\tests
  %_ECHO% "\e[1;33m[%CPU%]: Simply doing 'call tests/configur.bat %BUILDER%' now.\e[0m"
  call configur.bat %BUILDER%
  exit /b 0

::
:: Download the '%CI_ROOT%\llvm-installer.exe' for 32-bit 'clang-cl'.
:: A 200 MByte download which installs to "c:\Program Files (x86)\LLVM"
::
:: And it's PATH must be prepended to the normal PATH.
::
:install_LLVM
  if %CPU%. == x64. exit /b
  echo on
  echo %CD%
  set PATH=c:\Program Files (x86)\LLVM\bin;%PATH%
  if exist "c:\Program Files (x86)\LLVM\bin\clang-cl.exe" exit /b
  if not exist %CI_ROOT%\llvm-installer.exe call :download_LLVM

  %_ECHO% "\e[1;33mInstalling 32-bit LLVM...'.\e[0m"
  start /wait %CI_ROOT%\llvm-installer.exe /S
  clang-cl -v
  %_ECHO% "\e[1;33mDone\n--------------------------------------------------------'.\e[0m"
  exit /b

:download_LLVM
  %_ECHO% "\e[1;33mDownloading 32-bit LLVM...'.\e[0m"
  curl -# -o %CI_ROOT%\llvm-installer.exe https://prereleases.llvm.org/win-snapshots/LLVM-10.0.0-e20a1e486e1-win32.exe
  if not errorlevel == 0 (
    %_ECHO% "\e[1;31mThe curl download failed!\e[0m"
    exit /b 1
  )
  exit /b

::
:: Download and install cross compiler for djgpp
::
:install_djgpp
  if exist %DJGPP%\bin\i586-pc-msdosdjgpp-gcc.exe exit /b
  call :download_djgpp
  7z x -y -o%DJGPP% %CI_ROOT%\dj-win.zip > NUL
  %_ECHO% "\e[1;33mDone\n--------------------------------------------------------'.\e[0m"
  exit /b

:download_djgpp
  %_ECHO% "\e[1;33mDownloading Andrew Wu's DJGPP cross compiler:\e[0m"
  curl -# -o %CI_ROOT%\dj-win.zip http://www.watt-32.net/CI/dj-win.zip
  if not errorlevel == 0 (
    %_ECHO% "\e[1;31mThe curl download failed!\e[0m"
    exit /b 1
  )
  exit /b

::
:: Download and install OpenWatcom
::
:install_watcom
  if exist %WATCOM%\binnt\wmake.exe exit /b
  %_ECHO% "\e[1;33mDownloading OpenWatcom 2.0:\e[0m"
  curl -# -o %CI_ROOT%\watcom20.zip http://www.watt-32.net/CI/watcom20.zip
  if not errorlevel == 0 (
    %_ECHO% "\e[1;31mThe curl download of http://www.watt-32.net/CI/watcom20.zip failed!\e[0m"
    exit /b
  )
  7z x -y -o%WATCOM% %CI_ROOT%\watcom20.zip > NUL
  exit /b
