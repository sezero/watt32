This is a port of syslogd-1.3.3 from the Linux sources to WATT32,
a TCP/IP stack for DOS (in normal and extended 32 bit mode). See
http://www.watt-32.net/ for WATT32.  snprintf.c was taken from
BeroFTPD but originates from sendmail, according to the comments.

Ken Yap <ken@nlc.net.au> 1999

The README.linux file is at the bottom.

READ THIS DISCLAIMER: THIS PROGRAM IS PROVIDED AS IS WITH NO WARRANTY
AND NO RESPONSIBILITY IS ACCEPTED FOR ANY CONSEQUENCES OF USING IT.
Syslogd is a useful security tool and should be used as part of a
comprehensive security policy. While a DOS machine running syslogd
cannot be broken into because the machine is only passively logging
syslog entries, offering no other services, it is still vulnerable to
denial of service attacks, e.g. flooding the machine with packets to
overflow the log. Therefore it is recommended that you set your firewall
to block syslog packets from any machine outside your net. You may also
wish to log entries to a printer for an indelible record.

The differences from the Linux version are all due to OS support. All
changes to the original source are ifdefed so that future changes to
syslogd can be tracked more easily.

Note these points:

+ You need to configure the supplied wattcp.cfg before running syslogd. If
you set the envvar ETC to /etc, there should be an /etc/services file
and it should contain these lines:

ntp	123/udp
syslog	514/udp

+ Only -r operation makes sense since under DOS there are no other
processes to log, only other machines on the net. Thus most people will
want to start it thus:

	syslogd -r -m1

+ The default config file is in ./syslog.conf.  Users, pipes and wall (*)
are not supported and will fail.  Remote machines don't make sense, except
perhaps for the startup message, so this has not been tested. Filenames
of the form /dev/xxx are converted to filenames of the form xxx so that
/dev/con will log to the console and /dev/prn will log to the printer.
As a special case /dev/console will log to stdout.

+ SIGALRM is not supported in many DOS C compilers so the -m interval
option doesn't work for local marks.

+ One enhancement over the Linux syslogd: this one receives NTP broadcasts
and prints a timestamp to the log. The timestamp is that of the NTP
packet, the local clock is not changed. (In fact, except for the starting
banner, all times are that of the hosts sending the log messages.) If
you want the starting banner and NTP timestamp to be printed as the
local time, you must set the envvar TZ to XXX[+-][N]N for no daylight
saving or XXX[+-][N]NYYY for daylight saving, where XXX is the usual
name of the timezone, YYY the daylight saving name of the timezone, and
[N]N the number of hours west (blank or +) or west (-) of UTC normally.
(Incidentally the names of the timezones are not relevant, what matter
are the offsets.)  The -m option also affects how often the NTP timestamps
are printed.


------------------- The original README.linux ------------------------

Welcome to the sysklogd package for Linux.  All the utility
documentation has now been moved into the man pages.  Please review
these carefully before proceeding.

Version 1.3 of the package is the culmination of about two years of
experience and bug reports on the 1.2 version from both the INTERNET
and our corporate Linux networks.  The utilities in this package should
provide VERY reliable system logging.  Klogd and syslogd have both
been stress tested in kernel development environments where literally
hundreds of megabytes of kernel messages have been blasted through
them.  If either utility should fail the development team would
appreciate debug information so that the bug can be reproduced and
squashed.

Both utilities (syslogd, klogd) can be either run from init or started
as part of the rc.* sequence.  Caution should be used when starting
these utilities from init since the default configuration is for both of
these utilities to auto-background themselves.  Depending on the
version of init being used this could either result in the process
table being filled or at least 10 copies of the daemon being started.
If auto-backgrounding is NOT desired the command line option -n should
be used to disable the auto-fork feature.

I have found work on the sysklogd package to be an interesting example
of the powers of the INTERNET.  Stephen, Juha, Shane, Martin and
myself have successfully collaborated on the development of this
package without ever having met each other, in fact we could pass on
the street without realizing it.  What I have developed is a profound
respect for the personal capabilities of each one of these
individuals.  Perhaps the greatest `Linux Legacy' will be that its
development/enhancement is truly an example of the powers of
international cooperation through the worldwide INTERNET.

We would be interested in keeping track of any and all bug
fixes/changes that are made.  At the time that work was started on the
sysklogd package the syslog(d) sources seemed to have fallen into
neglect.  This work started with and continues the believe that it is
important to maintain consistent standardized system utilities
sources.  Hopefully the Linux community will find these sources to be
a useful addition to the software gene pool.

There is a mailing list covering this package and syslog in general.
The lists address is sysklogd@Infodrom.North.DE .  To subscribe send a
mail to Majordomo@Infodrom.North.DE with a line "subscribe sysklogd"
in the message body.

New versions of this package will be available at Joey's ftp server.
ftp://ftp.infodrom.north.de/pub/people/joey/sysklogd/

Best regards,

Dr. Wettstein
Oncology Research Division Computing Facility
Roger Maris Cancer Center
Fargo, ND
greg@wind.enjellic.com

Stephen Tweedie
Department of Computer Science
Edinburgh University, Scotland

Juha Virtanen
jiivee@hut.fi

Shane Alderton
shane@ion.apana.org.au

Martin Schulze
Infodrom Oldenburg
joey@linux.de

And a host of bug reporters whose contributions cannot be underestimated.
