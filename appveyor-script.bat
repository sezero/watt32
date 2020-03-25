@echo off
setlocal
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

) else (
  set APPVEYOR_BUILD_FOLDER_UNIX=c:/projects/Watt-32
  set _ECHO=c:\msys64\usr\bin\echo.exe -e
)

%_ECHO% "\e[1;33mDoing '%1' for 'BUILDER=%BUILDER%'.\e[0m"

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
::
set DJGPP=%APPVEYOR_BUILD_FOLDER_UNIX%/CI/djgpp
set DJ_PREFIX=%DJGPP%/bin/i586-pc-msdosdjgpp-

::
:: Set env-var for building with Watcom 2.0
::
set WATCOM=%APPVEYOR_BUILD_FOLDER%\CI\Watcom
set WATCOM_ZIP=%WATCOM%\watcom20.zip
set NT_INCLUDE=%WATCOM%\h;%WATCOM%\h\nt

::
:: Shit for brains 'cmd' cannot have this inside a 'if x (' block since
:: on a AppVeyor build several "C:\Program Files (x86)\Microsoft xxx" strings
:: are in the 'PATH' !
::
:: And append the '%WATCOM%\binnt' to the 'PATH' since Watcom has an 'cl.exe'
:: which we do not want to use for 'BUILDER=visualc'.
::
set PATH=%PATH%;%WATCOM%\binnt

::
:: Append the PATH to the 64-bit 'clang-cl'.
:: Where is the 32-bit 'clang-cl'?
::
set PATH=%PATH%;c:\Program Files\LLVM\bin

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

if %USES_CL%. == 1. (
  %_ECHO% "\e[1;33mGenerating src\oui-generated.c.\e[0m"
  python.exe make-oui.py > oui-generated.c
  if ERRORLEVEL 0 set CL=-DHAVE_OUI_GENERATATED_C
  %_ECHO% "\e[1;33m--------------------------------------------------------------------------------------------------\e[0m"
)

%_ECHO% "\e[1;33m[%CPU%]: call configur.bat %BUILDER%:\e[0m"

if %BUILDER%. == visualc. (
  call configur.bat visualc
  %_ECHO% "\e[1;33mBuilding release for %CPU%:\e[0m"
  nmake -nologo -f visualc-release_%BITS%.mak
  exit /b
)

if %BUILDER%. == clang. (
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
  if not exist %DJGPP%\bin\i586-pc-msdosdjgpp-gcc.exe (
    %_ECHO% "\e[1;33mDownloading Andrew Wu's DJGPP cross compiler:\e[0m"
    curl -O -# http://www.watt-32.net/CI/dj-win.zip
    if not errorlevel == 0 (
      %_ECHO% "\e[1;31mThe curl download of http://www.watt-32.net/CI/dj-win.zip failed!\e[0m"
      exit /b
    )
    7z x -y -o%DJGPP% dj-win.zip > NUL
    rm -f dj-win.zip
  )
  call configur.bat djgpp
  %_ECHO% "\e[1;33mBuilding for djgpp:\e[0m"
  make -f djgpp.mak
  exit /b
)

if %BUILDER%. == watcom. (
  if not exist %WATCOM%\binnt\wmake.exe (
    mkdir %WATCOM%
    %_ECHO% "\e[1;33mDownloading OpenWatcom 2.0:\e[0m"
    curl -o %WATCOM_ZIP% -# http://www.watt-32.net/CI/watcom20.zip
    if not errorlevel == 0 (
      %_ECHO% "\e[1;31mThe curl download of http://www.watt-32.net/CI/watcom20.zip failed!\e[0m"
      exit /b
    )
    7z x -y -o%WATCOM% %WATCOM_ZIP% > NUL
  )
  call configur.bat %BUILDER%
  %_ECHO% "\e[1;33mBuilding for Watcom/Win32:\e[0m"
  wmake -f watcom_w.mak

  %_ECHO% "\e[1;33mBuilding for Watcom/large:\e[0m"
  wmake -f watcom_l.mak

  %_ECHO% "\e[1;33mBuilding for Watcom/flat:\e[0m"
  wmake -f watcom_f.mak
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
:: './bin/' programs to build for djgpp, Visual-C and Watcom (Win32 + large):
::
set PROGS_DJ=bping.exe ping.exe finger.exe ident.exe htget.exe ^
             tcpinfo.exe tracert.exe country.exe

set PROGS_VC=ping.exe finger.exe tcpinfo.exe host.exe htget.exe ^
             popdump.exe tracert.exe revip.exe con-test.exe gui-test.exe ^
             rexec.exe cookie.exe daytime.exe dayserv.exe lpq.exe lpr.exe ^
             ntime.exe ph.exe stat.exe vlsm.exe whois.exe ident.exe country.exe

set PROGS_WC_WIN=ping.exe htget.exe finger.exe tcpinfo.exe con-test.exe gui-test.exe htget.exe tracert.exe whois.exe
set PROGS_WC_LARGE=ping.exe htget.exe finger.exe tcpinfo.exe htget.exe whois.exe

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
  %_ECHO% "\e[1;33mwatcom/Win32: Building PROGS_WC_WIN=%PROGS_WC_WIN%:\e[0m"
  wmake -f wc_win.mak %PROGS_WC_WIN%

  %_ECHO% "\e[1;33mwatcom/large: Building PROGS_WC_LARGE=%PROGS_WC_LARGE%:\e[0m"
  rm -f %PROGS_WC_LARGE%
  wmake -f watcom.mak %PROGS_WC_LARGE%
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
