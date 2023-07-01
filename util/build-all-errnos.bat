@echo off
setlocal
prompt $P$G

::
:: Change to suite
::
if %DMC_ROOT%. == . set DMC_ROOT=f:\gv\Prog\DMC

set MAKE_CMD=make -f errnos.mak win32
call :make

set MAKE_CMD=wmake -u -h -f errnos.mak win32/wc_err.exe
call :make

set MAKE_CMD=wmake -u -h -f errnos.mak wc_err.exe
call :make

set PATH=c:\Windows\system32;%DMC_ROOT%\bin
set MAKE_CMD=make -f errnos.mak dm_err.exe
call :make

set MAKE_CMD=make -f errnos.mak win32/dm_err.exe
call :make

exit /b

:make
  echo --------------------------------------------
  echo on
  %MAKE_CMD%
  @echo off
  exit /b
