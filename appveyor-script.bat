@echo off
setlocal
prompt $P$G

::
:: 'APPVEYOR_PROJECT_NAME=Watt-32' unless testing this "appveyor-script.bat [build_src | build_bin | test]"
:: locally using 'cmd'.
::
if %APPVEYOR_PROJECT_NAME%. == . (
  set BUILDER=VisualC
  set APPVEYOR_BUILD_FOLDER_UNIX=e:/net/watt
) else (
  set APPVEYOR_BUILD_FOLDER_UNIX=c:/projects/Watt-32
)

::
:: Stuff common to '[build_src | build_bin | test]'
::
:: MinGW: Add PATH to 'gcc' and stuff for 'util/pkg-conf.mak'.
::
if %BUILDER%. == MinGW. (
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
:: In case my curl was built with Wsock-Trace
::
set WSOCK_TRACE_LEVEL=0
set WATT_ROOT=%CD%

if %BUILDER%. == . (
  echo BUILDER target not specified!
  exit /b 1
)

if %1. == build_src. goto :build_src
if %1. == build_bin. goto :build_bin
if %1. == test.      goto :test

echo Usage: %~dp0%0 ^[build_src ^| build_bin ^| test^]
exit /b 1

:build_src
cd src

::
:: Generate a 'src\oui-generated.c' file from 'src\oui.txt (do not download it every time).
:: For VisualC / clang-cl only since only those uses '%CL%'.
::
set USES_CL=0
set CL=
if %BUILDER%. == VisualC. set USES_CL=1
if %BUILDER%. == clang.   set USES_CL=1

::
:: Assume 'CPU=x86'
::
set BITS=32
if %CPU%. == x64. set BITS=64

if %USES_CL%. == 1. (
  echo Generating src\oui-generated.c
  python make-oui.py > oui-generated.c
  if ERRORLEVEL 0 set CL=-DHAVE_OUI_GENERATATED_C
  echo --------------------------------------------------------------------------------------------------
)

if %BUILDER%. == VisualC. (
  call configur.bat visualc
  set CL=-D_WIN32_WINNT=0x0601 %CL%
  echo Building release for %CPU%
  nmake -nologo -f visualc-release_%BITS%.mak
  exit /b
)

if %BUILDER%. == clang. (
  call configur.bat clang
  echo Building for %CPU%
  make -f clang%BITS%.mak
  exit /b
)

if %BUILDER%. == MinGW. (
  echo ------- where date.exe --------------------
  where date.exe
  echo --------test date.exe ---------------------
  date.exe  +%%d-%%B-%%Y
  echo -------------------------------------------

  call configur.bat mingw64
  echo Building for %CPU%
  make -f MinGW64_%BITS%.mak
  exit /b
)

if %BUILDER%. == djgpp. (
  if not exist %DJGPP%\bin\i586-pc-msdosdjgpp-gcc.exe (
    echo Downloading Andrew Wu's DJGPP cross compiler
    curl -O -# http://www.watt-32.net/CI/dj-win.zip
    7z x -y -o%DJGPP% dj-win.zip > NUL
    rm -f dj-win.zip
  )
  call configur.bat djgpp
  echo Building for djgpp
  make -f djgpp.mak
  exit /b
)

echo Illegal BUILDER / CPU (BUILDER=%BUILDER%, CPU=%CPU%) values!
exit /b 1

::
:: Build some example programs in './bin'
::
:build_bin

if %CPU%. == x64. (
  echo No build_bin for x64 yet.
  exit /b 0
)

::
:: './bin/' programs to build for djgpp and Visual-C:
::
set PROGS_DJ=bping.exe ping.exe finger.exe tcpinfo.exe ident.exe htget.exe ^
             tcpinfo.exe tracert.exe country.exe

set PROGS_VC=ping.exe finger.exe tcpinfo.exe host.exe htget.exe ^
             popdump.exe tracert.exe revip.exe con-test.exe gui-test.exe ^
             rexec.exe cookie.exe daytime.exe dayserv.exe lpq.exe lpr.exe ^
             ntime.exe ph.exe stat.exe vlsm.exe whois.exe ident.exe country.exe

cd bin
if %BUILDER%. == djgpp. (
  make -f djgpp_win.mak DPMI_STUB=0 %PROGS_DJ%
  exit /b
)

if %BUILDER%. == VisualC. (
  nmake -f visualc.mak %PROGS_VC%
  exit /b
)

exit /b

::
:: Build (and run?) some test programs in './src/tests'
::
:test
cd src\tests
echo Test will come here later
echo -- CD: ------------------------------------------------------------------
echo %CD%
exit /b
