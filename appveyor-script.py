#!/usr/bin/env python

"""A Python replacement for the appveyor-script.bat.
"""

from __future__ import print_function
import sys, os, time

# These can be rather slow:
#
URLs = { 'djgpp':   [ 'http://www.watt-32.net/CI/dj-win.zip',         42100 ],
         'watcom':  [ 'http://www.watt-32.net/CI/watcom20.zip',       18982 ],
         'borland': [ 'http://www.watt-32.net/CI/borland.zip',        37142 ],
         'clang':   [ 'http://www.watt-32.net/CI/llvm-installer.exe',198478 ]
       }                                                         # kBytes ^

builders = [ 'visualc', 'clang', 'mingw32', 'mingw64', 'borland', 'djgpp', 'watcom' ]

use_colorama = 1
use_curl     = int (os.getenv('USE_CURL','0'))

#
# When testing locally, there should be no '%APPVEYOR_PROJECT_NAME%'
#
if os.getenv ("APPVEYOR_PROJECT_NAME"):
  local_test = 0
  echo       = 'c:\\msys64\\usr\\bin\\echo.exe -en'
else:
  local_test = 1
  echo       = os.getenv('MSYS2_ROOT') + '\\usr\\bin\\echo.exe -en'

try:
  from colorama import init, Fore, Style  # Fails on AppVeyour
  init()
  colour_yellow = Fore.YELLOW + Style.BRIGHT
  colour_off    = Style.RESET_ALL
  use_colorama = 1

except ImportError:
  colour_yellow = r'\e[1;33m'
  colour_off    = r'\e[0m'

#
# Why so hard to get colours on AppVeyor?
#
def cprint (s):
  global use_colorama
  if use_colorama:
    s = '%s%s%s' % (colour_yellow, s, colour_off)
    print (s, end="")
  else:
    s = '%s%s%s' % (colour_yellow, s.replace('\\','/'), colour_off)
    cmd = '%s "%s"' % (echo, s)
    # print ('cmd: %s' % cmd)
    os.system (cmd)

def Fatal (s):
  cprint (s)
  sys.exit (1)

#
# Check all needed local env-vars
#
def check_local_env (global_e):
  if not local_test:
    return

  envs = ['WK_ROOT', 'WK_VER', 'VCToolsInstallDir', 'CLANG_32', 'CLANG_64', 'USE_CURL']
  for e in envs:
    if os.getenv(e) == None:
      cprint ("Missing env-var '%s'.\n" % e)

#
# Create a .bat file in '%TEMP' and run it via 'cmd.exe /c file.bat'
#
def write_and_run_bat (fname, content, args=""):
  bat = os.getenv("TEMP") + "\\" + fname
  f = open (bat, 'wt+')
  f.write (':: Generated by %s at %s\n' % (__file__, time.ctime()))
  for l in content:
    f.write (l + '\n')
  f.close()
  return os.system ('cmd.exe /C %s %s' % (bat, args))

#
# Return VisualC binary and library directories
#
def get_visualc_dirs (cpu):
  vc_bin_dir = os.getenv ('VCToolsInstallDir', '?') + r'\bin\Hostx64\%s' % cpu
  vc_lib_dir = os.getenv ('VCToolsInstallDir', '?') + r'\lib\%s' % cpu

  if not os.path.isdir(vc_bin_dir):
    Fatal ("vc_bin_dir '%s' does not exists!\n" % vc_bin_dir)

  if not os.path.isdir(vc_lib_dir):
    Fatal ("vc_lib_dir '%s' does not exists!\n" % vc_lib_dir)

  return vc_bin_dir, vc_lib_dir

#
# local_test: Return Windows-Kits's 'ucrt' and 'um' (user-mode) library directories
#
def get_winkit_lib_dirs (cpu):
  lib_dir = os.getenv('WK_ROOT') + r'\Lib\\' + os.getenv('WK_VER')
  um_dir   = r'%s\um\%s'   % (lib_dir, cpu)
  ucrt_dir = r'%s\ucrt\%s' % (lib_dir, cpu)

  if not os.path.isdir(um_dir):
    Fatal ("WinKit's um_dir '%s' does not exists!\n" % um_dir)

  if not os.path.isdir(ucrt_dir):
    Fatal ("WinKit's ucrt_dir '%s' does not exists!\n" % ucrt_dir)

  return um_dir, ucrt_dir

#
# local_test: Return LLVM root for 'cpu = [x86 | x64]'
#
def get_LLVM_root (cpu):
  if cpu == 'x86':
    root = os.getenv ('CLANG_32')
  elif cpu == 'x64':
    root = os.getenv ('CLANG_64')
  else:
    root = '??'

  if not os.path.isdir(root):
    Fatal ("LLVM's root dir '%s' for 'CPU=%s' does not exists!\n" % (root, cpu))
  return root

#
# Env-vars common to 'build_src', 'build_bin' and 'build_tests' stages.
#
def get_env_vars_common():
  env_var = {}

  global local_test
  if local_test:
    watt_root = os.getenv ('WATT_ROOT')
    if not watt_root:
       Fatal ('WATT_ROOT not set!')
  else:
    watt_root = 'c:\projects\watt-32'  # == %APPVEYOR_BUILD_FOLDER

  cpu     = os.getenv ('CPU', 'x86')
  builder = os.getenv ('BUILDER', None)

  if not builder:
    Fatal ('BUILDER not set!')

  if not builder in builders:
    Fatal ("Illegal BUILDER: '%s'." % builder)

  if cpu != 'x86' and builder in ['watcom', 'djgpp', 'borland']:
    Fatal ("BUILDER '%s' must have 'CPU=x86'." % builder)

  env_var['WATT_ROOT'] = watt_root
  env_var['BUILDER']   = builder
  env_var['CPU']       = cpu
  env_var['CL']        = ''
  env_var['MODEL']     = os.getenv ('MODEL', 'none')
  env_var['PATH']      = os.getenv ('PATH')
  env_var['BITS']      = ['32','64'][cpu == 'x64']
  env_var['CI_ROOT']   = env_var['WATT_ROOT'] + r'\CI-temp'  # Download and install packages here

  #
  # Set needed env-vars unless this is AppVeyor.
  # The 'vcvarsall.bat %CPU%' kludge fails to work here.
  #
  if local_test:
    if builder in ['visualc', 'clang']:
      vc_bin_dir, vc_lib_dir = get_visualc_dirs (cpu)
      um_dir,     ucrt_dir   = get_winkit_lib_dirs (cpu)

      env_var['PATH'] = vc_bin_dir + ';' + env_var['PATH']
      env_var['LIB']  = vc_lib_dir + ';' + um_dir + ';' + ucrt_dir + ';' + os.getenv('LIB')

      if builder == 'clang':
        env_var['PATH'] = get_LLVM_root(cpu) + r'\bin;' + env_var['PATH']

  else:
    if builder == 'clang' and cpu == 'x86':
      env_var['PATH'] = r'c:\Program Files\LLVM\bin;' + env_var['PATH']

  if builder in ['mingw32', 'mingw64']:
    env_var['MINGW32'] = watt_root.replace ('\\','/')
    env_var['MINGW64'] = watt_root.replace ('\\','/')

  #
  # Set the dir for djgpp cross-environment.
  # Use forward slashes for this. Otherwise 'sh' + 'make' will get confused.
  # 7z can create only 1 level of missing directories. So a '%CI_ROOT%\djgpp' will not work
  #
  if builder == 'djgpp':
    env_var['DJGPP']     = env_var['CI_ROOT'].replace ('\\','/')
    env_var['DJ_PREFIX'] = env_var['DJGPP'] + '/bin/i586-pc-msdosdjgpp-'

  if builder == 'watcom':
    env_var['WATCOM']      = env_var['CI_ROOT']
    env_var['NT_INCLUDE']  = env_var['WATCOM'] + r'\h;' + env_var['WATCOM'] + r'\h\nt'
    env_var['DOS_INCLUDE'] = env_var['WATCOM'] + r'\h'
    env_var['PATH']       =  env_var['WATCOM'] + r'\binnt;' + env_var['PATH']

  if builder == 'borland':
    env_var['BCCDIR']  = env_var['CI_ROOT']
    env_var['INCLUDE'] = env_var['BCCDIR'] + r'\include\windows;' + env_var['BCCDIR'] + r'\include\windows\sdk'
    env_var['CBUILDER_IS_LLVM_BASED'] = '1'
    env_var['PATH'] = env_var['BCCDIR'] + r'\bin;' + env_var['PATH']

  env_var['USE_WSOCK_TRACE']   = '0'  # Needed in 'src/tests/makefile.all'

  return env_var

#
# Env-vars for 'build_bin':
#
def get_env_vars_bin():
  bin_vars = {}

  bin_vars['PROGS_DJ'] = 'bping.exe ping.exe finger.exe ident.exe htget.exe tcpinfo.exe tracert.exe country.exe'
  bin_vars['PROGS_VC'] = 'ping.exe finger.exe tcpinfo.exe host.exe htget.exe tracert.exe con-test.exe gui-test.exe lpq.exe lpr.exe ntime.exe whois.exe ident.exe country.exe'
  bin_vars['PROGS_MW'] = bin_vars['PROGS_VC']    #  MinGW-w64
  bin_vars['PROGS_CL'] = bin_vars['PROGS_VC']    #  clang-cl Win32
  bin_vars['PROGS_BC'] = bin_vars['PROGS_VC']    #  Borland/CBuilder Win32

  bin_vars['PROGS_WC_WIN']     = 'ping.exe htget.exe finger.exe tcpinfo.exe con-test.exe gui-test.exe htget.exe tracert.exe whois.exe'
  bin_vars['PROGS_WC_LARGE']   = 'ping.exe htget.exe finger.exe tcpinfo.exe htget.exe whois.exe'
  bin_vars['PROGS_WC_FLAT']    = bin_vars['PROGS_WC_LARGE']
  bin_vars['PROGS_WC_SMALL32'] = bin_vars['PROGS_WC_LARGE']
  return bin_vars


#
# The progress callback for 'urllib.urlretrieve()'.
#
def url_progress (blocks, block_size, total_size):
  if blocks:
    kBbyte_so_far = (blocks * block_size) / 1024
    cprint ("Got %d kBytes\r" % kBbyte_so_far)

#
# Check if a local 'fname' exist. Otherwise download it from 'url'
# and unzip it using '7z'.
#
def download_and_install (fname, url, fsize, is_clang_x86=False):
  if os.path.exists(fname):
    cprint ("A local %s already exist.\n" % fname)
    return 0

  global use_curl
  if use_curl:
    if 1:
      cprint ("curl version:\n")
      os.system ("curl -V")
      cprint ('--------------------------------------------------------------------------------------------------\n')
    cprint ("curl: %s -> %s  %d kByte.\n" % (url, fname, fsize))
    r = os.system ("curl -# -o %s %s" % (fname, url))
    if r != 0:
      Fatal ("curl failed: %d." % r)

  else:
    try:
      from urllib import urlretrieve as url_get
    except ImportError:
      from urllib.request import urlretrieve as url_get

    cprint ("url_get: %s -> %s  %d kByte.\n" % (url, fname, fsize))
    url_get (url, filename = fname, reporthook = url_progress)
    print ("")

  directory = os.path.dirname (fname)

  if is_clang_x86:
    global local_test
    if local_test:
      cprint ('Not installing 32-bit LLVM using "cd %s & cmd.exe /C start /wait llvm-installer.exe /S"\n' % directory)
    else:
      cprint ('Installing 32-bit LLVM...')
      os.system ('cd %s & cmd.exe /C start /wait llvm-installer.exe /S' % directory)
      os.system ('clang-cl -v')

  else:
    cprint ('Unzipping %s to %s.\n' % (fname, directory))
    r = os.system ('7z x -y -o%s %s > NUL' % (directory, fname))
    if r != 0:
      Fatal ("7z failed: %d." % r)


#
# Generate a 'src/oui-generated.c' file for including in 'src/winadinf.c'
#
def generate_oui():
  cprint ("Generating 'oui-generated.c'.")
  r = os.system ('python.exe make-oui.py > oui-generated.c')
  cprint ('--------------------------------------------------------------------------------------------------\n')
  return r

#
# Print some usage.
#
def show_help():
  print ("%sUsage: %s [build_src | build_bin | build_tests]" % (__doc__, __file__))
  sys.exit (0)

def get_env_string (envs):
  ret = ""
  for e in sorted(envs):
    ret += 'set %s=%s\n' % (e, envs[e])
  return ret


def get_nmake():
  if local_test:
    return os.getenv ('VCToolsInstallDir', '?') + r'\bin\Hostx86\x86\nmake'
  return 'nmake'

#
# Print a colourised message and return the makefile command for 'build_src':
#
def get_src_make_command (builder, cpu, model=""):
  bits = '32'
  if cpu == 'x64':
    bits = '64'

  if builder == 'visualc':
     cprint ("[%s]: Building release:\n" % cpu)
     return '%s -nologo -f visualc-release_%s.mak' % (get_nmake(), bits)

  if builder == 'clang':
     cprint ("[%s]: Building release:\n" % cpu)
     return 'make -f clang-release_%s.mak' % bits

  if builder == 'mingw32':
     cprint ("[%s]: Building:\n" % cpu)
     return 'make -f MinGW32.mak'

  if builder == 'mingw64':
     cprint ("[%s]: Building:\n" % cpu)
     return 'make -f MinGW64_%s.mak' % bits

  if builder == 'djgpp':
     cprint ("[%s]: Building:\n" % cpu)
     return 'make -f djgpp.mak'

  if builder == 'borland':
     cprint ("[%s]: Building:\n" % cpu)
     return '%s\\bin\\make -f bcc_w.mak' % env_vars['BCCDIR']

  if builder == 'watcom':
    if model == 'win32':
      cprint ("[%s]: Building for Watcom/Win32:\n" % cpu)
      return 'wmake -h -f watcom_w.mak'

    if model == 'flat':
      cprint ("[%s]: Building for Watcom/flat:\n" % cpu)
      return 'wmake -h -f watcom_f.mak'

    if model == 'large':
      cprint ("[%s]: Building for Watcom/large:\n" % cpu)
      return 'wmake -h -f watcom_l.mak'

    Fatal ("[%s]: BUILDER Watcom needs a MODEL!" % cpu)

  Fatal ("[%s]: I did not expect this!" % cpu)


#
# Print a colourised message and return the makefile command for 'build_bin'.
# Return the 'PROGS_x' and makefile name.
#
def get_bin_make_command (env_vars):
  builder = env_vars['BUILDER']
  cpu     = env_vars['CPU']

  if builder == 'djgpp':
    cprint ('[%s]: Building PROGS_DJ=%s:' % (cpu, env_vars['PROGS_DJ']))
    return 'make -f djgpp_win.mak DPMI_STUB=0', env_vars['PROGS_DJ']

  if builder == 'visualc':
     cprint ("[%s]: Building PROGS_VC=%s\n" % (cpu, env_vars['PROGS_VC']))
     return '%s -nologo -f visualc.mak' % get_nmake(), env_vars['PROGS_VC']

  if builder == 'mingw64':
     cprint ("[%s]: Building PROGS_MW=%s\n" % (cpu, env_vars['PROGS_MW']))
     return 'make -f mingw64.mak CPU=%s ' % cpu, env_vars['PROGS_MW']

  if builder == 'clang':
     cprint ("[%s]: Building PROGS_CL=%s\n" % (cpu, env_vars['PROGS_CL']))
     return 'make -f clang.mak CPU=%s check_CPU ' % cpu, env_vars['PROGS_CL']

  if builder == 'borland':
     cprint ("[%s]: Building PROGS_BC=%s\n" % (cpu, env_vars['PROGS_BC']))
     return '%s\\bin\\make -f bcc_win.mak' % env_vars['BCCDIR'], env_vars['PROGS_BC']

  if builder == 'watcom':
    model = env_vars['MODEL']
    if model == 'win32':
      cprint ('[%s]: watcom/Win32: Building PROGS_WC_WIN=%s' % (cpu, env_vars['PROGS_WC_WIN']))
      return 'wmake -h -f wc_win.mak', env_vars['PROGS_WC_WIN']

    if model == 'flat':
      cprint ('[%s]: watcom/flat: Building PROGS_WC_FLAT=%s' % (cpu, env_vars['PROGS_WC_FLAT']))
      return 'wmake -h -f causeway.mak', env_vars['PROGS_WC_FLAT']

    if model == 'large':
      cprint ('[%s]: watcom/large: Building PROGS_WC_LARGE=%s' % (cpu, env_vars['PROGS_WC_LARGE']))
      return 'wmake -h -f watcom.mak', env_vars['PROGS_WC_LARGE']

    Fatal ("[%s]: BUILDER Watcom needs a MODEL!" % cpu)

  cprint ("[%s]: No 'build_bin' for 'BUILDER=%s' yet." % (cpu, builder))
  return '', ''

#
# Concatinate 2 dictionaries:
#   https://stackoverflow.com/questions/38987/how-do-i-merge-two-dictionaries-in-a-single-expression/26853961#26853961
#
def merge_dicts (a, b):
  r = a.copy()   # start with a's keys and values
  r.update (b)   # modifies r with b's keys and values and returns None
  return r

#
# Check if 'prog' exist and run it. Optionally with 'args'.
#
def run_test (prog, args=[]):
  if not os.path.exists(prog):
    cprint ("Test program '%s' failed to link! -----------------------------------------------\n" % prog)
    return 1

  cmd = prog + ' ' + ' '.join(args)
  cprint ("Running test '%s' ---------------------------------------------------------------\n" % cmd)
  return os.system (cmd)

#
# main entry. Turn this into a 'main_loop()' that handles all args?
#
def main():
  if len(sys.argv) != 2 or \
     sys.argv[1] not in ["build_src", "build_bin", "build_tests"]:
    show_help()

  env_vars = get_env_vars_common()

  base = os.path.basename(__file__)
  file = env_vars['WATT_ROOT'] + '\\' + base

  if not os.path.exists(base):
    Fatal ("Run %s from it's directory." % file)

  check_local_env (env_vars)

  os.system ('md %s 2> NUL' % env_vars['CI_ROOT'])

  builder = env_vars['BUILDER']
  cpu     = env_vars['CPU']
  model   = env_vars['MODEL']
  cmd     = sys.argv[1]

  # Since only 'watcom' has a '%MODEL%' set in 'appveoyr.yml'
  #
  if builder == 'watcom':
    cprint ("Doing '%s' for 'BUILDER=%s', 'MODEL=%s'\n" % (cmd, builder, model))
  else:
    cprint ("Doing '%s' for 'BUILDER=%s'\n" % (cmd, builder))

  #
  # Should be done for 'cmd == build_src' only.
  #
  try:
    installer = env_vars['CI_ROOT'] + '\\' + os.path.basename (URLs[builder][0])
    if builder == 'clang' and cpu == 'x86':
      download_and_install (installer, URLs[builder][0], URLs[builder][1], True)
    else:
      download_and_install (installer, URLs[builder][0], URLs[builder][1])
  except KeyError:
    pass

  if cmd == 'build_src':
    os.chdir ('src')
    if generate_oui() == 0:
      env_vars['CL'] = '-DHAVE_OUI_GENERATATED_C'

    write_and_run_bat ("build_src_1.bat",
                       [ '@echo off',
                         'setlocal',
                         'prompt $P$G',
                         get_env_string (env_vars),
                         'call configur.bat %s' % builder
                       ] )

    bin2c  = env_vars['WATT_ROOT'] + r'\util\win32\bin2c.exe'
    bin2c_ = bin2c.replace ('\\','/')

    nasm  = env_vars['WATT_ROOT'] + r'\util\win32\nasm.exe'
    nasm_ = nasm.replace ('\\','/')

    r = write_and_run_bat ("build_src_2.bat",
                           [ '@echo off',
                             'setlocal',
                             'prompt $P$G',
                             get_env_string (env_vars),
                             r'set W32_BIN2C=%s'  % bin2c,
                             r'set W32_BIN2C_=%s' % bin2c_,
                             r'set W32_NASM=%s'   % nasm,
                             r'set W32_NASM_=%s'  % nasm_,
                             get_src_make_command (builder, env_vars['CPU'], env_vars['MODEL'])
                           ] )

  elif cmd == 'build_bin':
    os.chdir ('bin')
    bin_vars = get_env_vars_bin()
    bin_make, bin_progs = get_bin_make_command (merge_dicts(env_vars, bin_vars))
    if bin_progs == '':
      return 0

    r = write_and_run_bat ("build_bin.bat",
                           [ '@echo off',
                             'setlocal',
                             'prompt $P$G',
                             'rm -f %s' % bin_progs,
                             get_env_string (env_vars),
                             get_env_string (bin_vars),
                             '%s %s' % (bin_make, bin_progs)
                           ] )

  elif cmd == 'build_tests':
    if builder == 'watcom' and model not in ['large', 'flat', 'win32']:
      Fatal ("[%s]: BUILDER Watcom needs a MODEL!" % cpu)

    os.chdir ('src\\tests')
    r = write_and_run_bat ("build_tests.bat",
                           [ '@echo off',
                             'prompt $P$G',
                             get_env_string (env_vars),
                             r'call configur.bat %BUILDER%',
                             r'if %BUILDER%. == visualc.  make -f visualc_%BITS%.mak clean all',
                             r'if %BUILDER%. == clang.    make -f clang_%BITS%.mak   clean all',
                             r'if %BUILDER%. == mingw64.  make -f MinGW64_%BITS%.mak clean all',
                             r'if %BUILDER%. == borland.  make -f bcc_w.mak          clean all',
                             r'if %BUILDER%. == djgpp.    make -f djgpp.mak          clean all',
                             r'if %BUILDER%. == watcom. (',
                             r'   if %MODEL%. == large. make -f watcom_l.mak clean all',
                             r'   if %MODEL%. == flat.  make -f watcom_f.mak clean all',
                             r'   if %MODEL%. == win32. make -f watcom_w.mak clean all',
                             ')',
                           ] )

    can_run_on_windows = (builder in ['visualc', 'clang', 'mingw32', 'mingw64', 'borland', 'watcom'])
    if builder == 'watcom' and model != 'win32':
      can_run_on_windows = False

    if can_run_on_windows:
      run_test ('cpu.exe')
      run_test ('cpuspeed.exe', ['1', '1'])
      run_test ('swap.exe')
      run_test ('chksum.exe', ['-s'])
    else:
      cprint ("Cannot run '%s' tests on Windows.\n" % builder)

  if r:
    cprint ("r: %d" % r)

if __name__ == '__main__':
  main()

