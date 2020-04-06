#!/usr/bin/env python

"""A Python test of colorama on AppVeyor.
"""

import sys

try:
  from colorama import init, Style, Fore
except ImportError as e:
  print ("Module 'colorama' not found")
  sys.exit (0)

init()
print ("%sHello world%s" % (Fore.YELLOW + Style.BRIGHT, Style.RESET_ALL))
