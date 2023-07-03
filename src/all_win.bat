@echo off
setlocal
prompt $P$G
set MAKE_LOG=all_win.log

::
:: Need Cygwin/Msys 'tee' + 'date' programs below (change to suite)
::
set TEE=
set CLEAN=

if %1. == clean. (
  set CLEAN=clean
  del /Q %MAKE_LOG%
  shift
)

::
:: Using a '4NT', 'tcc' or 'tccle' shell:
::
if %_CMDPROC. == 4NT. .or. %_CMDPROC. == TCC. .or. %_CMDPROC. == TCCLE. on break quit

::
:: For 'bcc_w.mak'
::
set BCCDIR=..\CI\CBuilder
set GNUMAKE=..\CI\gnumake.exe
set W32_BIN2C=..\util\win32\bin2c.exe
set W32_BIN2C_=../util/win32/bin2c.exe

set HAVE_CYGWIN32=0
set HAVE_CYGWIN64=0

if exist %CYGWIN32_ROOT%\bin\gcc.exe (
   set HAVE_CYGWIN32=1
   set TEE=%CYGWIN32_ROOT%\bin\tee.exe
   set DATE=%CYGWIN32_ROOT%\bin\date.exe
   set CYGWIN_ROOT=%CYGWIN32_ROOT%
)

if exist %CYGWIN64_ROOT%\bin\gcc.exe (
   set HAVE_CYGWIN64=1
   set TEE=%CYGWIN64_ROOT%\bin\tee.exe
   set DATE=%CYGWIN64_ROOT%\bin\date.exe
   set CYGWIN_ROOT=%CYGWIN64_ROOT%
)

if exist %MSYS_ROOT%\bin\tee.exe (
   set TEE=%MSYS_ROOT%\bin\tee.exe
   set DATE=%MSYS_ROOT%\bin\date.exe
)

if not exist %TEE% (
  echo Need a Cygwin / Msys 'tee' program
  exit /b 1
)
if not exist %DATE% (
  echo Need a Cygwin / Msys 'date' program
  exit /b 1
)

set TEE=%TEE% --append

set BITS=64
if %CPU. == x86. set BITS=32

set MAKE_CMD=%BCCDIR%\bin\make.exe -nologo -f bcc_w.mak
call :do_make

set MAKE_CMD=nmake.exe -nologo -f visualc-release_%BITS%.mak
call :do_make

set MAKE_CMD=nmake.exe -nologo -f visualc-debug_%BITS%.mak
call :do_make

set MAKE_CMD=make.exe -f clang-release_%BITS%.mak
call :do_make

set MAKE_CMD=make.exe -f clang-debug_%BITS%.mak
call :do_make

set MAKE_CMD=wmake.exe -h -f watcom_w.mak
call :do_make

set MAKE_CMD=make.exe -f MinGW64_%BITS%.mak
call :do_make

if %HAVE_CYGWIN32%. == 1. (
  set PATH=%CYGWIN32_ROOT%\bin;%WINDIR%\System32
  set MAKE_CMD=%GNUMAKE% -f CygWin_32.mak
  call :do_make
) else (
  call :do_log "No 32-bit Cygwin found"
)

if %HAVE_CYGWIN64%. == 1. (
  set PATH=%CYGWIN64_ROOT%\bin;%WINDIR%\System32
  set MAKE_CMD=%GNUMAKE% -f CygWin_64.mak
  call :do_make
) else (
  call :do_log "No 64-bit Cygwin found"
)

echo Look in '%MAKE_LOG%' for details.
exit /b

:do_make
  echo ------------------------------------------------------------------------- | %TEE% %MAKE_LOG%
  %DATE% +%%T                       >> %MAKE_LOG%
  echo Calling '%MAKE_CMD% %CLEAN%' >> %MAKE_LOG%
  echo.                             >> %MAKE_LOG%
  echo on
  %MAKE_CMD% %CLEAN% | %TEE% %MAKE_LOG%
  @echo off
  exit /b

:do_log
  echo ------------------------------------------------------------------------- | %TEE% %MAKE_LOG%
  %DATE% +%%T >> %MAKE_LOG%
  echo %$ | %TEE% %MAKE_LOG%
  exit /b
