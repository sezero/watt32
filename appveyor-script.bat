@echo off
setlocal EnableDelayedExpansion
prompt $P$G

::
:: Download-links for djgpp + OpenWatcom files used by 'build_x' on AppVeyor or
:: for local testing if this .bat-file.
::
:: These can be rather slow:
::
set URL_DJ_WIN_ZIP=http://www.watt-32.net/CI/dj-win.zip
set URL_WATCOM_ZIP=http://www.watt-32.net/CI/watcom20.zip
set URL_BORLAND_ZIP=http://www.watt-32.net/CI/borland.zip

::
:: D/L from MS's OneDrive instead with the below cryptic 'URL_x' strings.
::
:: I got these with the help of "CurlWget". An great Chrome extension:
::   https://chrome.google.com/webstore/detail/curlwget/jmocjfidanebdlinpbcdkcmgdifblncg
::
set URL_DJ_WIN_ZIP="https://public.am.files.1drv.com/y4mj1hIt_E5LjPPG9V7PywEz9lsuoYtMOEP1-jEcUkZ06M9ZK3kN7SXPw2AOgn9sf2_RbqhRQgvhMOgaJxyIL_O2GTjzp-u9LUB1RtLylxtr-URpATMJDPcPeUmd3gRhCrsXLWMxO8Hh5q7oR1_9V6gMZKB_VWTU6bPZkZ0rc8Tg9YjpzuzX180lWpc2E8w52hpkV0ApaxuVstkq_M6DwOEbssrymQaX30jYgpUw4YCmlA?access_token=EwAIA61DBAAUzl/nWKUlBg14ZGcybuC4/OHFdfEAAcjk8R21S0WRbnPh7yDX/bpeIL1WFpo1loXmt9HWcrm6dtt2uc8AFFghySuz840rgZYMCXSzwFO1lDjQCyFe1ub5GUO%2bvJnqYAbjOOExBSENan77aZ/Y%2bDqxbAU%2bIiSPebGpjrN5KMlszGXV1pJyOLQVRMk3JpQ8MeM5Cfm6bNLCzNCi2IKOrUN0S5MnLypsP0Y55Q728New95Tp6pId3201zbOoh%2byopzvoFWJeGZ1xRV0uqwzHHKw5PnuZrByFPzLI8/XiQ3IUOC/q/oU/L8BAZk2Y8GCg1S41O5Y7%2bQuQXabLxMN8d3QiJV2Ky/SodxpdipT0OfPBMTHDOadiagkDZgAACOiGp0v9%2bTQS2AFKY3E7XSCFUpNnkjnzUXof10is4AuzeF4Dbk0ruj3eM5fQA0JRzTXpbAp6Aojo/1N1SkNpsNNQzK/VClKSRwr7kT98SLgLFtCDxlEioac66eceN3KU6/CHVEWUPHOuiHSjg6OHHwN4/WWsTEDb3%2bRvg6cch2519pkwMveTzPzW5H3gZ5odyKtMhRRJH27B1gzt3jid4yHENEr66uFsx1m6SCsCDEXuZY6KI/M%2bi7xKni/alNjHYJqpi7rmM2fjQsuW5iSaHv39sEeoxPaWINHfAS189iXL67K7V%2br2avekXVz1C0dNoYWu46g27GWjLAMWHJr/K2r2DvTfWebw6F9Ul6JXGrT0atqKlPY4keV6tbltm2g5rlyNvErTaeCM/ZVmaOEZ7sOm8Q1RxnkwE8dkmFP5DVyTgJKMplNyo7U2W1ElwabCaG2NuMxp59avjuHDvewol8WqjLfL4R/cnJR5d3TomX1Llo2YES81cMJPwmj38RnS8jUE6uZ%2bXkziGxiKij%2b6cFBkNUtW9Nt13uSoiHntF5iF0tZ7xFAvJWwlHXSFVxwCNVyrIPDXExasidYdjdNO4Vdmxe4FUuElI7mEZ4BAWZidu2xY6AaAr0fgBS18gukvgzEyAwI%3d"
set URL_WATCOM_ZIP="https://public.am.files.1drv.com/y4mBFFcbx7AwhTYCTXPW5j2kRm1_SHzk3g1SJB6uvHub9Y7xIcRVWgPWB1jN5Pbjw71_XgJX_5OVcWY6BTfq6II4PvbQl-5OPe_2sBoTWBK-wlhrucAIjHkBqToE57tuIVDeykEu8xaRBiD9il-XoxbppPrRb6HNXrh2VQU7fdWUx7LqliQU0zLTqIRHWbFHoPNtpfZTba6Yey0ck1RWJaC5oz5kdx1LeVPAOt_NXH11RE?access_token=EwAIA61DBAAUzl/nWKUlBg14ZGcybuC4/OHFdfEAAcjk8R21S0WRbnPh7yDX/bpeIL1WFpo1loXmt9HWcrm6dtt2uc8AFFghySuz840rgZYMCXSzwFO1lDjQCyFe1ub5GUO%2bvJnqYAbjOOExBSENan77aZ/Y%2bDqxbAU%2bIiSPebGpjrN5KMlszGXV1pJyOLQVRMk3JpQ8MeM5Cfm6bNLCzNCi2IKOrUN0S5MnLypsP0Y55Q728New95Tp6pId3201zbOoh%2byopzvoFWJeGZ1xRV0uqwzHHKw5PnuZrByFPzLI8/XiQ3IUOC/q/oU/L8BAZk2Y8GCg1S41O5Y7%2bQuQXabLxMN8d3QiJV2Ky/SodxpdipT0OfPBMTHDOadiagkDZgAACOiGp0v9%2bTQS2AFKY3E7XSCFUpNnkjnzUXof10is4AuzeF4Dbk0ruj3eM5fQA0JRzTXpbAp6Aojo/1N1SkNpsNNQzK/VClKSRwr7kT98SLgLFtCDxlEioac66eceN3KU6/CHVEWUPHOuiHSjg6OHHwN4/WWsTEDb3%2bRvg6cch2519pkwMveTzPzW5H3gZ5odyKtMhRRJH27B1gzt3jid4yHENEr66uFsx1m6SCsCDEXuZY6KI/M%2bi7xKni/alNjHYJqpi7rmM2fjQsuW5iSaHv39sEeoxPaWINHfAS189iXL67K7V%2br2avekXVz1C0dNoYWu46g27GWjLAMWHJr/K2r2DvTfWebw6F9Ul6JXGrT0atqKlPY4keV6tbltm2g5rlyNvErTaeCM/ZVmaOEZ7sOm8Q1RxnkwE8dkmFP5DVyTgJKMplNyo7U2W1ElwabCaG2NuMxp59avjuHDvewol8WqjLfL4R/cnJR5d3TomX1Llo2YES81cMJPwmj38RnS8jUE6uZ%2bXkziGxiKij%2b6cFBkNUtW9Nt13uSoiHntF5iF0tZ7xFAvJWwlHXSFVxwCNVyrIPDXExasidYdjdNO4Vdmxe4FUuElI7mEZ4BAWZidu2xY6AaAr0fgBS18gukvgzEyAwI%3d"
set URL_BORLAND_ZIP="https://public.am.files.1drv.com/y4mnJTBulvAogxgzk-Ml9XMm7d43Agamc-X2UH0m6Ja_v4C3t331Q0n2Vd1mn2bax_DU4YIZUJeavzNZqQomOu8R3YAophKnoYXKmwMRIipcWXz1H0EQNFSuvfuDeplT828IQjGzZ7pX1HEMOzCThndQgru60zCj_FD41mDu3lCxJCwA5mi54lQHZtu0AKR3nX7NlDi7mpstcKx0mXjXpyvO-5X-MNri77U996jAUDW6uw?access_token=EwAIA61DBAAUzl/nWKUlBg14ZGcybuC4/OHFdfEAAQLVI7XXjcGWhj9YoWW%2bIRmHGOgHHxYTd0GUVqEZQMJlvuPPECwUjHF3nNy8iOwmtmjvzen%2bsz09JBusvO/mUDGsqfqe8HMgxBs/H6w0Bs3OzPaEVsZXujY4KuPbRvgaMrpjVSLVt9%2bx/JxuNAETgJKM1QvCZ9My16dSSrKjQfSzpNKlLu0sdmRUO9LrWA5VqaNh5o7ZanyCC4B61n2Ad6zUJResVGHvDV4M3FLf1JYdN6x5x2YkPORonnTqWD6wFLjD5NwvRGzW%2bmirU67Zg3YneLWYyWBIg0TEldJuGh0Ee9WDLTwcU2JkZislclVVuHDMBp2Vb3yEpkZA17D4k2IDZgAACO4%2b/pyjBNuo2AG44dw5sfVW0EgYWARrmdkp6G5F5cgECMjsvYGryrqlSF9E9PUuDrnFdEWgMdmeBnNiTfRcoUxsguGPzVRa7YmhikvwHv5aouyMjpwtv9RW9B60Mq%2bhq8Qkwe14Gxu2h52VFXIeEjhf%2badW9up2UdiNmEmJ9XxgZbR/1QwfL04pDi%2b2N3esUQB%2bndIf%2bs2ZEJv0aBJiaQHLN0BC9l3Epaj1ekEJZ/HmbBK9//1p8vp/iHCs7u9adKjN%2bH0M5a0894zyLZdnTn5GlGxUn1FqqMWv%2bQHnWdAfoeYKNZCjjAFzuS1Hi1vDvRdCRt5L36EuB8qlWlos2GlqAdheRPQzZj/Vsnf/WdoCHe97W0TabnJHUfVXQt5sJKCjFvP7ZbXZseg7PMegLJh9%2bBucR4SWdKc3rCMjcrgRQWr6L7HwDqHY9J6XzR7VOEG/KVDdoIZ5iUdN4swcNWEmK/aZGqvX/aIovcipvS%2b/r0Imo2bFxo8EzxDvQESCnUyiTuJLyG4O83YILdzx3T44Osh8cRW8YlenbDw7WElNW9iQQ5/8a9Ikl7746t77bNj6PKoA/eywyCu%2bODyrx4ssF8RAOfBqvWERa3yGrgcgjO13Q27rFlW1dLJcf9EdXP0fAwI%3d"

::
:: 'APPVEYOR_PROJECT_NAME==Watt-32' unless testing this as:
::   c:\net\watt-32\> cmd /c appveyor-script.bat [build_src | build_bin | build_tests]
::
:: locally.
:: Change this for an 'echo.exe' with colour support. Like Cygwin.
::
set _ECHO=%MSYS2_ROOT%\usr\bin\echo.exe -e

if %APPVEYOR_PROJECT_NAME%. == . (
  set LOCAL_TEST=1

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
  set LOCAL_TEST=0
  set WATT_ROOT=c:\projects\watt-32
  set APPVEYOR_BUILD_FOLDER=c:\projects\watt-32
  set APPVEYOR_BUILD_FOLDER_UNIX=c:/projects/watt-32
  set _ECHO=c:\msys64\usr\bin\echo.exe -e
)

::
:: Download stuff to here:
::
set CI_ROOT=%APPVEYOR_BUILD_FOLDER%\CI-temp
md %CI_ROOT% 2> NUL

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
:: mingw32/mingw64: Stuff for 'util/pkg-conf.mak'.
::
md lib\pkgconfig 2> NUL
set MINGW32=%APPVEYOR_BUILD_FOLDER_UNIX%
set MINGW64=%APPVEYOR_BUILD_FOLDER_UNIX%

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
:: Set env-var for building with Borland/CBuilder (Win32 only)
::
set BCCDIR=%CI_ROOT%
set LIBDIR=%BCCDIR%\lib
set MAKEDIR=%BCCDIR%\bin
set CBUILDER_IS_LLVM_BASED=1

::
:: Shit for brains 'cmd' cannot have this inside a 'if x (' block since
:: on a AppVeyor build several "c:\Program Files (x86)\Microsoft xxx" strings
:: are in the 'PATH'.
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
:: Generate a 'src/oui-generated.c' file from 'src/oui.txt (do not download it every time).
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
:: Hence cannot use a 'if x (what-ever) else (something else)' syntax with that.
::
if %LOCAL_TEST% == 1 (
  echo on
  if not exist "%APPVEYOR_BUILD_FOLDER_UNIX%" (echo No '%APPVEYOR_BUILD_FOLDER_UNIX%'. Edit this .bat-file & exit /b 1)
)

%_ECHO% "\e[1;33m[%CPU%]: call configur.bat %BUILDER%:\e[0m"

if %USES_CL%. == 1. (
  %_ECHO% "\e[1;33mGenerating 'src/oui-generated.c'.\e[0m"
  python.exe make-oui.py > oui-generated.c
  if errorlevel 0 set CL=-DHAVE_OUI_GENERATATED_C
  %_ECHO% "\e[1;33m--------------------------------------------------------------------------------------------------\e[0m"
)

if %BUILDER%. == visualc. (
  call configur.bat visualc
  %_ECHO% "\e[1;33m[%CPU%]: Building release:\e[0m"
  nmake -nologo -f visualc-release_%BITS%.mak
  exit /b
)

::
:: Need to do 'call :install_LLVM' here to set the PATH for 'clang-cl.exe'!
::
if %BUILDER%. == clang. (
  call :install_LLVM
  call configur.bat clang
  %_ECHO% "\e[1;33m[%CPU%]: Building release:\e[0m"
  make -f clang-release_%BITS%.mak
  exit /b
)

if %BUILDER%. == mingw32. (
  call configur.bat mingw32
  %_ECHO% "\e[1;33m[%CPU%]: Building:\e[0m"
  make -f MinGW32.mak
  exit /b
)

if %BUILDER%. == mingw64. (
  call configur.bat mingw64
  %_ECHO% "\e[1;33m[%CPU%]: Building:\e[0m"
  make -f MinGW64_%BITS%.mak
  exit /b
)

if %BUILDER%. == djgpp. (
  call :install_djgpp
  call configur.bat djgpp
  %_ECHO% "\e[1;33m[%CPU%]: Building:\e[0m"
  make -f djgpp.mak
  exit /b
)

if %BUILDER%. == borland. (
  call :install_borland
  call configur.bat borland
  %_ECHO% "\e[1;33m[%CPU%]: Building:\e[0m"
  %BCCDIR%\bin\make -f bcc_w.mak
  exit /b
)

if %BUILDER%. == watcom. (
  call :install_watcom
  call configur.bat watcom

  if %MODEL%. == win32. (
    %_ECHO% "\e[1;33m[%CPU%]: Building for Watcom/Win32:\e[0m"
    wmake -h -f watcom_w.mak

  ) else if %MODEL%. == flat. (
    %_ECHO% "\e[1;33m[%CPU%]: Building for Watcom/flat:\e[0m"
    wmake -h -f watcom_f.mak

  ) else if %MODEL%. == large. (
    %_ECHO% "\e[1;33m[%CPU%]: Building for Watcom/large:\e[0m"
    wmake -h -f watcom_l.mak

  ) else if %MODEL%. == small32. (
    %_ECHO% "\e[1;33m[%CPU%]: Building for Watcom/small32:\e[0m"
    wmake -h -f watcom_3.mak

  ) else (
    %_ECHO% "\e[1;31m[%CPU%]: BUILDER 'watcom' needs a 'MODEL'!\e[0m"
     exit /b 1
  )
  exit /b
)

%_ECHO% "\e[1;31mIllegal BUILDER / CPU (BUILDER=%BUILDER%, CPU=%CPU%) values! Remember cmd.exe is case-sensitive.\e[0m"
exit /b 1

::
:: './bin/' programs to build for djgpp, Visual-C, MinGW-w64, clang-cl and Watcom (Win32 + large + flat):
::
:build_bin

set PROGS_BC_WIN=ping.exe ident.exe htget.exe finger.exe tcpinfo.exe tracert.exe
set PROGS_DJ=bping.exe ping.exe finger.exe ident.exe htget.exe tcpinfo.exe tracert.exe country.exe
set PROGS_VC=ping.exe finger.exe tcpinfo.exe host.exe htget.exe tracert.exe con-test.exe gui-test.exe lpq.exe lpr.exe ntime.exe whois.exe ident.exe country.exe
set PROGS_MW=%PROGS_VC%
set PROGS_CL=%PROGS_VC%
set PROGS_WC_WIN=ping.exe htget.exe finger.exe tcpinfo.exe con-test.exe gui-test.exe htget.exe tracert.exe whois.exe
set PROGS_WC_LARGE=ping.exe htget.exe finger.exe tcpinfo.exe htget.exe whois.exe
set PROGS_WC_FLAT=%PROGS_WC_LARGE%
set PROGS_WC_SMALL32=%PROGS_WC_LARGE%

cd bin

if %BUILDER%. == djgpp. (
  %_ECHO% "\e[1;33m[%CPU%]: Building PROGS_DJ=%PROGS_DJ%:\e[0m"
  make -f djgpp_win.mak DPMI_STUB=0 %PROGS_DJ%
  exit /b
)

if %BUILDER%. == visualc. (
  %_ECHO% "\e[1;33m[%CPU%]: Building PROGS_VC=%PROGS_VC%:\e[0m"
  nmake -nologo -f visualc.mak %PROGS_VC%
  exit /b
)

if %BUILDER%. == mingw64. (
  %_ECHO% "\e[1;33m[%CPU%]: Building PROGS_MW=%PROGS_MW%:\e[0m"
  make -f mingw64.mak %PROGS_MW%
  exit /b
)

::
:: Need to do 'call :install_LLVM' here to set the PATH for 'clang-cl.exe' again.
::
if %BUILDER%. == clang. (
  call :install_LLVM
  %_ECHO% "\e[1;33m[%CPU%]: Building PROGS_CL=%PROGS_CL%:\e[0m"
  make -f clang.mak check_CPU %PROGS_CL%
  exit /b
)

if %BUILDER%. == borland. (
  %_ECHO% "\e[1;33m[%CPU%]: Building PROGS_BC_WIN=%PROGS_BC_WIN%:\e[0m"
  %BCCDIR%\bin\make -f bcc_win.mak %PROGS_BC_WIN%
  exit /b
)

if %BUILDER%. == watcom. (
  if %MODEL%. == win32. (
    %_ECHO% "\e[1;33mwatcom/Win32: Building PROGS_WC_WIN=%PROGS_WC_WIN%:\e[0m"
    rm -f %PROGS_WC_WIN%
    wmake -h -f wc_win.mak %PROGS_WC_WIN%

  ) else if %MODEL%. == flat. (
    %_ECHO% "\e[1;33mwatcom/flat: Building PROGS_WC_FLAT=%PROGS_WC_FLAT%:\e[0m"
    rm -f %PROGS_WC_LARGE%
    wmake -h -f causeway.mak %PROGS_WC_FLAT%

  ) else if %MODEL%. == large. (
    %_ECHO% "\e[1;33mwatcom/large: Building PROGS_WC_LARGE=%PROGS_WC_LARGE%:\e[0m"
    rm -f %PROGS_WC_LARGE%
    wmake -h -f watcom.mak %PROGS_WC_LARGE%

  ) else if %MODEL%. == small32. (
    %_ECHO% "\e[1;33mwatcom/small32: Not yet.\e[0m"

  ) else (
    %_ECHO% "\e[1;31mThe 'watcom' needs a 'MODEL'!\e[0m"
     exit /b 1
  )
  exit /b
)

%_ECHO% "\e[1;31m[%CPU%]: No 'build_bin' for 'BUILDER=%BUILDER%' yet.\e[0m"
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
  set PATH=c:\Program Files (x86)\LLVM\bin;%PATH%
  if exist "c:\Program Files (x86)\LLVM\bin\clang-cl.exe" exit /b
  if not exist %CI_ROOT%\llvm-installer.exe call :download_LLVM

  %_ECHO% "\e[1;33mInstalling 32-bit LLVM...'.\e[0m"
  start /wait %CI_ROOT%\llvm-installer.exe /S
  clang-cl -v
  %_ECHO% "\e[1;33mDone\n--------------------------------------------------------\e[0m"
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
  %_ECHO% "\e[1;33mDone\n--------------------------------------------------------\e[0m"
  exit /b

:download_djgpp
  %_ECHO% "\e[1;33mDownloading Andrew Wu's DJGPP cross compiler:\e[0m"
  curl -# -o %CI_ROOT%\dj-win.zip %URL_DJ_WIN_ZIP%
  if not errorlevel == 0 (
    %_ECHO% "\e[1;31mThe curl download failed!\e[0m"
    exit /b 1
  )
  exit /b

::
:: Download and install Borland/CBuilder
::
:install_borland
  if exist %BCCDIR%\bin\make.exe exit /b
  %_ECHO% "\e[1;33mDownloading Borland:\e[0m"
  curl -# -o %CI_ROOT%\borland.zip %URL_BORLAND_ZIP%
  if not errorlevel == 0 (
    %_ECHO% "\e[1;31mThe curl download failed!\e[0m"
    exit /b
  )
  7z x -y -o%BCCDIR% %CI_ROOT%\borland.zip > NUL
  exit /b

::
:: Download and install OpenWatcom
::
:install_watcom
  if exist %WATCOM%\binnt\wmake.exe exit /b
  %_ECHO% "\e[1;33mDownloading OpenWatcom 2.0:\e[0m"
  curl -# -o %CI_ROOT%\watcom20.zip %URL_WATCOM_ZIP%
  if not errorlevel == 0 (
    %_ECHO% "\e[1;31mThe curl download failed!\e[0m"
    exit /b
  )
  7z x -y -o%WATCOM% %CI_ROOT%\watcom20.zip > NUL
  exit /b
