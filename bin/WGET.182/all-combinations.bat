@echo off
setlocal
prompt $P$G
set MAKE=..\..\util\win32\gnumake.exe

rm -f all-combinations.log

::
:: Change to suite:
::
set TEE=%CYGWIN_ROOT%\bin\tee.exe --append
set ECHO=%CYGWIN_ROOT%\bin\echo.exe -e
set DO_ONE=0

::
:: Using a '4NT', 'tcc' or 'tccle' shell:
::
if %_CMDPROC%. == 4NT. .or. %_CMDPROC%. == TCC. .or. %_CMDPROC%. == TCCLE. on break quit

if %1. == -h. (
   echo Usage: %0 ^[ mingw ^| cygwin ^| clang ^| djgpp ^| msvc ^]
   exit /b 0
)

if not %1. == . (
   set DO_ONE=1
   call :%1
   echo '%1' is not a valid target
   exit /b 1
)

::
:: A dual-mode MinGW (TDM-gcc) for x86 / x64
::
:mingw
call :do_make USE_MINGW=1 USE_CYGWIN=0 USE_CLANG=0 USE_WATT32=1 CPU=x86
call :do_make USE_MINGW=1 USE_CYGWIN=0 USE_CLANG=0 USE_WATT32=1 CPU=x64

call :do_make USE_MINGW=1 USE_CYGWIN=0 USE_CLANG=0 USE_WATT32=0 CPU=x86
call :do_make USE_MINGW=1 USE_CYGWIN=0 USE_CLANG=0 USE_WATT32=0 CPU=x64
if %DO_ONE% == 1 exit /b 0

::
:: Cygwin for presumably 'x64' only
::
:cygwin
call :do_make USE_CYGWIN=1 USE_MINGW=0 USE_CLANG=0 USE_WATT32=1
call :do_make USE_CYGWIN=1 USE_MINGW=0 USE_CLANG=0 USE_WATT32=0
if %DO_ONE% == 1 exit /b 0

::
:: clang-cl for x86 / x64
::
:clang
call :do_make USE_CLANG=1 USE_MINGW=0 USE_CYGWIN=0 USE_WATT32=1 USE_ASAN=1 USE_UBSAN=1 CPU=x86
call :do_make USE_CLANG=1 USE_MINGW=0 USE_CYGWIN=0 USE_WATT32=1 USE_ASAN=1 USE_UBSAN=1 CPU=x64

call :do_make USE_CLANG=1 USE_MINGW=0 USE_CYGWIN=0 USE_WATT32=0 USE_ASAN=1 USE_UBSAN=1 CPU=x86
call :do_make USE_CLANG=1 USE_MINGW=0 USE_CYGWIN=0 USE_WATT32=0 USE_ASAN=1 USE_UBSAN=1 CPU=x64
if %DO_ONE% == 1 exit /b 0

::
:: djgpp for x86
::
:djgpp
call :do_make USE_DJGPP=1 USE_CLANG=0 USE_MINGW=0 USE_CYGWIN=0
if %DO_ONE% == 1 exit /b 0

::
:: MSVC for default CPU only
::
:msvc
call :do_make USE_CLANG=0 USE_MINGW=0 USE_CYGWIN=0 USE_WATT32=1
call :do_make USE_CLANG=0 USE_MINGW=0 USE_CYGWIN=0 USE_WATT32=0
if %DO_ONE% == 1 exit /b 0
exit /b 0

:do_make
  %ECHO% "\e[1;31mRunning: %MAKE% -f Makefile.Windows %* clean all \e[0m"
  echo --------------------------------------------------------------------------------------------- >> all-combinations.log
  echo %MAKE% -f Makefile.Windows %* clean all                                                       >> all-combinations.log
  %MAKE% -f Makefile.Windows %* clean all | %TEE% all-combinations.log
  if not errorlevel == 0 (
     echo gnumake failed | %TEE% all-combinations.log
     exit 1
  )
  exit /b 0

