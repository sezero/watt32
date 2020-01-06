@echo off
setlocal
prompt $P$G
:: if %BUILDER%. == MinGW. echo on

::
:: 'APPVEYOR_PROJECT_NAME=Watt-32' unless testing this "appveyor-script.bat build" locally using 'cmd'.
::
if %APPVEYOR_PROJECT_NAME%. == . (
  set APPVEYOR_PROJECT_NAME=Watt-32
  set APPVEYOR_BUILD_FOLDER_UNIX=e:/net/watt
  set APPVEYOR_LOCAL=1
) else (
  set APPVEYOR_LOCAL=0
  set APPVEYOR_BUILD_FOLDER_UNIX=c:/projects/Watt-32
)

::
:: It seems the cmd doesn't parse a 'set PATH=some space value' inside an 'if .. (' block.
:: So put this here.
:: Also add stuff for 'util/pkg-conf.mak'.
::
if %BUILDER%. == MinGW. (
  if %CPU%. == x86. (set PATH=c:\msys64\MinGW32\bin;%PATH%) else (set PATH=c:\msys64\MinGW64\bin;%PATH%)
  md lib\pkgconfig 2> NUL
  set MINGW32=%APPVEYOR_BUILD_FOLDER_UNIX%
  set MINGW64=%APPVEYOR_BUILD_FOLDER_UNIX%
)

::
:: Then set PATH for 'make' + 'sh' and the 'vcvarsall.bat' crap.
::
set PATH=c:\msys64\usr\bin;c:\Program Files (x86)\Microsoft Visual Studio 14.0\VC;%PATH%

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

cd src

if %1. == test. goto :test

::
:: Generate a 'src\oui-generated.c' file from 'src\oui.txt (do not download it every time).
:: For VisualC / clang-cl only since only those uses '%CL%'.
::
set USES_CL=0
set CL=
if %BUILDER%. == VisualC. set USES_CL=1
if %BUILDER%. == clang.   set USES_CL=1

if %USES_CL%. == 1. (
  echo Generating src\oui-generated.c
  python make-oui.py > oui-generated.c
  if ERRORLEVEL 0 set CL=-DHAVE_OUI_GENERATATED_C
  echo --------------------------------------------------------------------------------------------------
)

if %BUILDER%-%CPU%. == VisualC-x86. (
  call vcvarsall.bat x86
  call configur.bat  visualc
  set CL=-D_WIN32_WINNT=0x0601 %CL%
  echo Building release clean all for x86
  nmake -nologo -f visualc-release.mak clean all
  exit /b
)

if %BUILDER%-%CPU%. == VisualC-x64. (
  call vcvarsall.bat x64
  call configur.bat  visualc
  set CL=-D_WIN32_WINNT=0x0601 %CL%
  echo Building release clean all for x64
  nmake -nologo -f visualc-release_64.mak clean all
  exit /b
)

if %BUILDER%-%CPU%. == clang-x86. (
  call vcvarsall.bat x86
  call configur.bat  clang
  echo Building clean all for x86
  make -f clang32.mak clean all
  exit /b
)

if %BUILDER%-%CPU%. == clang-x64. (
  call vcvarsall.bat x64
  call configur.bat  clang
  echo Building clean all for x64
  make -f clang64.mak clean all
  exit /b
)

if %BUILDER%-%CPU%. == MinGW-x86. (
  call configur.bat mingw64
  echo Building clean all for x86
  make -f MinGW64_32.mak clean all
  exit /b
)

if %BUILDER%-%CPU%. == MinGW-x64. (
  call configur.bat mingw64
  echo Building clean all for x64
  make -f MinGW64_64.mak clean all
  exit /b
)

if %BUILDER%. == djgpp. (
  echo Downloading Andrew Wu's DJGPP cross compiler
  curl -O -# http://www.watt-32.net/CI/dj-win.zip
  7z x -y -o%DJGPP% dj-win.zip > NUL
  rm -f dj-win.zip

  call configur.bat djgpp
  echo Building clean all for djgpp
  make -f djgpp.mak clean all
  exit /b
)
exit /b

:test
  echo Test will come here later
