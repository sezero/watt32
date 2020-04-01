#!/usr/bin/env python

"""\
Check if 'file' or 'wildcard' of files are binary or have LF or CRLF line ending.
  options:
    -h:  this help.
    -r:  recurse into sub-directories.

  e.g.: '%s -r foo\*.h' will check '*.h' files under ALL sub-directories of 'foo'
    (similar to Posix's 'foo/**/*.h').
"""

import sys, os, glob, string, fnmatch, argparse

parser = argparse.ArgumentParser (add_help=False)
parser.add_argument ("-h", dest="help", action="store_true")
parser.add_argument ("-r", dest="recursive", action="store_true")
parser.add_argument ("spec", nargs='?')
parser.add_argument ("subdir", nargs='?')

opt = parser.parse_args()

total_binary = total_EOL_unix = total_EOL_dos = total_files = 0

def check_EOL (file):
  EOL_dos = EOL_unix = bin_chars = 0
  pos = flen = is_bin = 0

  global total_files
  total_files += 1

  with open(file, 'rb') as infile:
    content = infile.read()
    flen = len(content)
    if flen <= 1:
      return
    while 1:
      c0 = content[pos]
      c1 = content[pos+1]
      if not c0 in string.printable:
        bin_chars += 1
      else:
        c_0A = (c0 == '\n')  # \n
        c_0D = (c0 == '\r')  # \r

        if c_0D and c1 == '\n':    # \r\n
          EOL_dos += 1
          pos     += 1
        elif c_0A and c1 != '\r':  # \n
          EOL_unix += 1

      pos += 1
      if bin_chars > EOL_dos+EOL_unix:
        is_bin = 1
      if is_bin or pos >= flen/10:
        break

  if is_bin:
    print ("Binary:   %s" % file)
    global total_binary
    total_binary += 1
  elif EOL_unix > 0 and EOL_dos == 0:
    print ("Unix EOL: %s" % file)
    global total_EOL_unix
    total_EOL_unix += 1
  elif EOL_unix == 0 and EOL_dos > 0:
    print ("DOS EOL:  %s" % file)
    global total_EOL_dos
    total_EOL_dos += 1

def process_dir (d):
  cwd = os.getcwd()
  os.chdir (d)
  for in_file in glob.glob('*'):
      file = ("%s/%s" % (os.getcwd(), in_file)).replace ('\\','/')
      if os.path.isdir(file):
        if opt.recursive:
          process_dir (file)
      elif fnmatch.fnmatch(in_file, opt.spec):
        check_EOL (file)
  os.chdir (cwd)

#
# main():
#
if opt.help or not opt.spec:
  print ("%s:\n%s" % (__file__, __doc__))
  sys.exit (0)

opt.spec = opt.spec.replace ('\\','/')
if opt.spec.endswith('/'):
  opt.spec += '*'

opt.subdir = os.path.split(opt.spec)[0]
opt.spec   = os.path.split(opt.spec)[1]

process_dir (opt.subdir)

print ("total_binary:   %3d" % total_binary)
print ("total_EOL_unix: %3d" % total_EOL_unix)
print ("total_EOL_dos:  %3d" % total_EOL_dos)
print ("total_files:    %3d" % total_files)


