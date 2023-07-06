@echo off
setlocal
prompt $P$G
set MAKE=..\..\util\win32\gnumake.exe

call :do_make USE_MINGW=1 USE_WATT32=1 CPU=x86
call :do_make USE_MINGW=1 USE_WATT32=1 CPU=x64

call :do_make USE_MINGW=1 USE_WATT32=0 CPU=x86
call :do_make USE_MINGW=1 USE_WATT32=0 CPU=x64

call :do_make USE_CLANG=1 USE_WATT32=1
call :do_make USE_CLANG=1 USE_WATT32=0

call :do_make USE_WATT32=1
call :do_make USE_WATT32=0

exit /b 0

:do_make
  %MAKE% -f Makefile.Windows %* clean all
  if not errorlevel == 0 (
     echo gnumake failed
     exit /b 1
  )
  exit /b 0
