@echo off
setlocal
prompt $P$G

::
:: Change to suite
::
if %DIGMARS%. == . set DIGMARS=f:\gv\Prog\DMC
if %BCCDIR%.  == . set BCCDIR=f:\gv\Prog\CBuilder10

::
:: First build the Windows versions with compilers on PATH:
::
set MAKE_CMD= make -f errnos.mak win32/clang_err.exe
call :make

set MAKE_CMD= make -f dj-errno.mak win32/dj_err.exe
call :make

set MAKE_CMD= make -f errnos.mak win32/ls_err.exe
call :make

set MAKE_CMD= make -f errnos.mak win32/oc_err.exe
call :make

set MAKE_CMD= make -f errnos.mak win32/vc_err.exe
call :make

set MAKE_CMD= wmake -u -h -f errnos.mak win32/wc_err.exe
call :make

::
:: Now build the DOS versions with compilers on PATH:
::
set MAKE_CMD= make -f dj-errno.mak dj_err.exe
call :make

set MAKE_CMD= wmake -u -h -f errnos.mak wc_err.exe
call :make

set MAKE_CMD= make -f errnos.mak hc_err.exe
call :make

set MAKE_CMD= make -f errnos.mak dm_err.exe
call :make

set MAKE_CMD= make -f errnos.mak win32/dm_err.exe
call :make

::
:: Now build the rest for compilers NOT on PATH:
::
set PATH=c:\Windows\system32;%BCCDIR%\bin;%DIGMARS%\bin;
set MAKE_CMD= make -f errnos.mak win32/bcc_err.exe
call :make

set MAKE_CMD= make -f errnos.mak bcc_err.exe
call :make

set MAKE_CMD= make -f errnos.mak tcc_err.exe
call :make


exit /b

:make
  echo -------------------------------------------------------------------------
  echo on
  %MAKE_CMD%
  @echo off
  exit /b
