#!/usr/bin/env python

"""\
Check if 'file' or 'wildcard' of files are binary or have LF or CRLF line ending.
%s [options] <file | wildcard>
    -h:  this help.
    -r:  recurse into sub-directories.

  e.g.: '%s -r foo\*.h' will check '*.h' files under ALL sub-directories of 'foo'
  (similar to Posix's 'foo/**/*.h').
"""

#
# Mainly used to check text-files in the Watt-32 project.
#
# By G. Vanem <gvanem@yahoo.no> 2020

import sys, os, glob, string, fnmatch, argparse

parser = argparse.ArgumentParser (add_help=False)
parser.add_argument ("-h", dest="help", action="store_true")
parser.add_argument ("-r", dest="recursive", action="store_true")
parser.add_argument ("-v", dest="verbose", action="count")
parser.add_argument ("spec", nargs='?')
parser.add_argument ("subdir", nargs='?')

opt = parser.parse_args()

def trace (level, s):
  if opt.verbose >= level:
    print (s)

def check_file (file, tot):
  EOL_dos = EOL_unix = bin_chars = 0
  pos = flen = is_bin = ascii_chars = 0

  with open(file, 'rb') as infile:
    content = infile.read()
    flen = len(content)
    if flen <= 1:
      tot ['unknown'] += 1
      return

    while 1:
      c0 = content [pos]
      c1 = content [pos+1]
      if not str(c0) in string.printable:
        bin_chars += 1
      else:
        ascii_chars += 1
        c0_0A = (c0 == '\n')
        c0_0D = (c0 == '\r')
        c1_0A = (c1 == '\n')
        c1_0D = (c1 == '\r')

        if c0_0D and c1_0A:        # \r\n
          EOL_dos += 1
          pos     += 1
        elif c0_0A and not c1_0D:  # \n
          EOL_unix += 1

      pos += 1
      if bin_chars > ascii_chars:
        is_bin = 1

      if is_bin or pos >= flen or pos >= max(100,flen/10):
        break

  if is_bin:
    print ("Binary:   %s" % file)
    tot['binary'] += 1

  elif EOL_unix > 0 and EOL_dos == 0:
    print ("Unix EOL: %s" % file)
    tot['EOL_unix'] += 1

  elif EOL_unix == 0 and EOL_dos > 0:
    print ("DOS EOL:  %s" % file)
    tot['EOL_dos'] += 1

  else:
    tot['unknown'] += 1
    print ("Unknown:  %s" % file)

def process_dir (d, tot):
  cwd = os.getcwd()
  try:
    os.chdir(d)
  except:
    print ("No such directory: %s" % d)
    return

  for in_file in glob.glob('*'):
      file = ("%s/%s" % (os.getcwd(), in_file)).replace ('\\','/')
      if os.path.isdir(file):
        if opt.recursive:
          process_dir (file, tot)
      elif fnmatch.fnmatch(in_file, opt.spec):
        tot ['files'] += 1
        check_file (file, tot)
      else:
        trace (2, "skipping %s" % in_file)

  os.chdir (cwd)

#
# main():
#
if opt.help or not opt.spec:
  print (__doc__ % (__file__, __file__))
  sys.exit (0)

opt.spec = opt.spec.replace ('\\','/')
if opt.spec.endswith('/'):
  opt.spec += '*'

opt.subdir = os.path.split (opt.spec)[0]
opt.spec   = os.path.split (opt.spec)[1]
if opt.subdir == '':
  opt.subdir = '.'

totals = { 'files'    : 0,
           'binary'   : 0,
           'unknown'  : 0,
           'EOL_dos'  : 0,
           'EOL_unix' : 0 }

trace (1, "Searching, opt.subdir: '%s', opt.spec: '%s'" % (opt.subdir, opt.spec))

process_dir (opt.subdir, totals)

print ("total_binary:   %3d" % totals['binary'])
print ("total_EOL_unix: %3d" % totals['EOL_unix'])
print ("total_EOL_dos:  %3d" % totals['EOL_dos'])
print ("total_unknown:  %3d" % totals['unknown'])
print ("total_files:    %3d" % totals['files'])
