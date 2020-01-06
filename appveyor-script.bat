@echo off
setlocal
:: echo on
prompt $P$G

::
:: 'APPVEYOR_PROJECT_NAME=Watt-32' unless testing this "appveyor-script.bat build" locally using 'cmd'.
::
if %APPVEYOR_PROJECT_NAME%. == . (
  set BUILDER=djgpp
  set BUILDER=VisualC
  set APPVEYOR_PROJECT_NAME=Watt-32
  set APPVEYOR_BUILD_FOLDER=%CD%
  set APPVEYOR_BUILD_FOLDER_UNIX=e:/net/watt
  set APPVEYOR_LOCAL=1
  set VCVARSALL_BAT=NUL
) else (
  set APPVEYOR_LOCAL=0
  set APPVEYOR_BUILD_FOLDER_UNIX=c:/projects/Watt-32
  set VCVARSALL_BAT="c:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
)

::
:: Set PATH for 'make' + 'sh' etc.
::
if %APPVEYOR_LOCAL%. == 0. set PATH=c:\msys64\usr\bin;%PATH%

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
set WATT_ROOT=%APPVEYOR_BUILD_FOLDER%

if %BUILDER%. == . (
  echo BUILDER target not specified!
  exit /b 1
)

cd %APPVEYOR_BUILD_FOLDER%\src

::
:: Generate a 'src\oui-generated.c' file.
::
set CL=
if %BUILDER%. == VisualC. (
  echo Generating src\oui-generated.c
  python make-oui.py > oui-generated.c
  if ERRORLEVEL 0 set CL=-DHAVE_OUI_GENERATATED_C
  echo --------------------------------------------------------------------
)

if %BUILDER%-%CPU%. == VisualC-x86. (
  call %VCVARSALL_BAT% x86
  call configur.bat visualc
  set CL=-D_WIN32_WINNT=0x0601 %CL%
  echo Building release clean all for x86
  nmake -nologo -f visualc-release.mak clean all
  exit /b
)

if %BUILDER%-%CPU%. == VisualC-x64. (
  call %VCVARSALL_BAT% x64
  call configur.bat visualc
  set CL=-D_WIN32_WINNT=0x0601 %CL%
  echo Building release clean all for x64
  nmake -nologo -f visualc-release_64.mak clean all
  exit /b
)

if %BUILDER%. == djgpp. (
  curl -O -# http://www.watt-32.net/CI/dj-win.zip
  7z x -y -o%DJGPP% dj-win.zip > NUL
  rm -f dj-win.zip

  call configur.bat djgpp
  echo Building clean all for djgpp
  make -f djgpp.mak clean all
  exit /b
)

