## Ideas for SACK in Watt-32

From the original `README`:
```
/*
 * Copyright (c) 1997, Pittsburgh Supercomputing Center
 * Jamshid Mahdavi    mahdavi@psc.edu
 * Matt Mathis        mathis@psc.edu
 * Jeffrey Semke      semke@psc.edu
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose and without fee is hereby granted,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.
 *
 * This is experimental software under active development and may
 * potentially contain bugs.   Use at your own risk.
 *
 */
```

README.md file for PSC modifications for SACK, FACK, and Autotuning TCP.

This tar file contains the following files:
```
        README.md
        netinet/tcp.h
        netinet/tcp_debugauto.h
        netinet/tcp_input.c
        netinet/tcp_output.c
        netinet/tcp_scoreb.c
        netinet/tcp_scoreb.h
        netinet/tcp_seq.h
        netinet/tcp_subr.c
        netinet/tcp_timer.c
        netinet/tcp_usrreq.c
        netinet/tcp_var.h
        kern/uipc_socket.c
        kern/uipc_socket2.c
        sys/socketvar.h
```

The PowerPoint [file](04-nonqos-protocols.ppt) also shows some *SACK* / *FACK* concepts.

The modifications for *SACK* and *FACK* consist of three major components.
First, the receiver's generation of *SACK* options.  Second, the sender's score-boarding of *SACK*
options in order to determine what data to retransmit.  Finally, the sender's congestion behavior.

The receiver's generation of *SACK* options introduces a new data
structure (`sack_list`) which is an array of recently sent sack blocks.
Several new subroutines are added to the beginning of [tcp_input.c](tcp_input.c) to
load data into this array appropriately when the reassembly queue is
non-empty.  This is used by both the *TCP_SACK* and the *TCP_FACK* options.

The sender's score-boarding of SACKs is done in the [tcp_scoreb.c](tcp_scoreb.c)
module for both the *TCP_SACK* and the *TCP_FACK* options.  This code is
primarily called from `dooptions()` and loads up the scoreboard as *SACK*s
come in.  The base data structure for the scoreboard is now a linked
list, using the list macros from [sys/queue.h](../../inc/sys/queue.h).

Both of these data structures could probably be optimized.  We will
cheerfully accept contributions from anyone who is interested in
optimizing this code.  One possible optimization would be to reduce lookup
and insertion times for the scoreboard when *SACK*s are received.  This
could be accomplished by changing the scoreboard to a doubly-linked list.
Then a pointer to the end of the list could be kept.  Typically, the first
block received in a *SACK* option will be added to the end, with the subsequent
blocks from the same option corresponding to the nodes near the end of
the scoreboard list.

Finally, the proper congestion behavior.  This release of the *TCP_SACK* code uses
Sally Floyd's "pipe" algorithm, roughly lifted from the code in the
LBNL [`ns` simulator](https://en.wikipedia.org/wiki/Ns_(simulator)).

We believe this to be the most conservative way to implement SACK, both in terms of keeping
as much Reno behavior as possible, and in terms of minimizing changes to the
code (and hence minimizing likelihood for bugs).

The congestion behavior for the *TCP_FACK* option is quite different, however.
It uses an algorithm called Rate Halving.  For a description of this, please refer to:
http://www.psc.edu/networking/papers/FACKnotes/current

Autotuning may be used with or without *SACK* or *FACK*.  Autotuning automatically
and dynamically adjusts TCP socket buffer sizes based on network congestion
and the amount of memory available in the kernel for networking (specifically,
`mbuf` clusters).  Applications that use `setsockopt()` to manually set their socket
buffer sizes will disable autotuning for their own connections.
More information is available on autotuning at: http://www.ncne.org/training/semke/index.htm
and a paper will be released on this shortly.

Autotuning and FACK are research endeavors, and wide deployment should be
considered cautiously.

Installing in the kernel:
  1) Save the originals of /usr/src/sys/netinet/tcp*.[ch],
        `/usr/src/sys/kern/uipc_sock*.c`, and `/usr/src/sys/sys/socketvar.h`

  2) Move our source files from the tar file into `/usr/src/sys/netinet`,
        `/usr/src/sys/kern`, and `/usr/src/sys/sys`

  3) Modify the `/usr/src/sys/conf/files` file to add the `tcp_scoreb.c` module:
        file `netinet/tcp_scoreb.c`   `inet & (tcp_sack | tcp_fack)`

  4) Add at most **one** of the following two lines to the configuration file for
     your kernel (`/usr/src/sys/arch/{your_port}/conf/{your_config_file}`):
        * options  `TCP_SACK`             `# enable SACK`
        * options  `TCP_FACK`             `# enable FACK`

  5) Optionally add the following line to the same config file if you want
     to test autotuning:
     * options         `TCP_AUTO`    `# enable Autotuning`

  6) It is recommended, but not required, that you add the following lines
        to your `config` file.  You may modify the values.  See:
        http://www.psc.edu/networking/perf_tune.html for more information.

        * options  `NMBCLUSTERS=2048`       `# allow 2048 mbuf clusters`
        * options  `SB_MAX=1048576`         `# allow 1MB socket buffers`

  7) Build a new kernel and reboot with it!

As the copyright says, this is first release Alpha software, and
probably has bugs.  Comments and corrections will be gratefully
accepted.

Changes from NetBSD 1.1 SACK to NetBSD 1.2 *SACK* and *FACK*:

The reassembly queue list changed between NetBSD 1.1 to 1.2, so build_sack
was updated appropriately.

The scoreboard data structure was changed from an array to a list, to allow
for a dynamically-sized scoreboard.  The list macros from NetBSD 1.2's queue.h
were used to implement this list.  (However, because of this, the list can
only be traversed in the forward direction.)

Each node in the scoreboard now represents a hole followed by received data,
whereas in 1.1, each node represented data followed by a hole.  The new
method is conceptually simpler, and allows the head and tail of the list
to be dealt with in a more consistent manner.

Changes from NetBSD 1.1 *FACK* to NetBSD 1.2 *FACK*:

`TF_RECOVERY` was split into two flags: `TF_RECOVERY` and `TF_RATEHALF` to allow
   for Tahoe-style recovery after a timeout.
`TF_SACK_PERMIT` was split into `TF_SACK_SEEN` and `TF_SACK_PERMIT` to differentiate
   between whether we are allowed to send *SACK*s and whether the other
   end seems to be able to send *SACK*s.

See version.history for more information about changes to this version.

 -- Jamshid, Matt, and Jeff

From the original `TODO` file:
```
FACK:
5/8-Split TF_RECOVERY into TF_RECOVERY and TF_RATEHALF (allows repairs after
        timeout, for a Tahoe-style recover)
5/8-Make sure code for Tahoe recovery exists following timeout
5/8-differentiate SACK_SEEN (receive) and SACK_PERMIT (send)
5/20-When sending to non-SACK receivers, rate halving occurs for the first
        dropped packet.  Upon receipt of the first ACK to advance the window
        to the next hole, all (re)transmissions stop, and a timeout occurs.
        -Use sackdebug tool on a tcpdump trace to determine if scrb_fake_sack
        and scrb_update are doing their jobs.  I suspect scrb_getnextretran
        is getting back a 0 instead of a block to retransmit.
-What should happen if in slow-start recovery after timeout, another packet
        drop occurs? hold-state?
-When sending to a machine that runs out of receiver window (for instance,
        during recovery), cwnd decays to 1 until the window opens again.
        Then slow start occurs.  Cwnd is not able to be maintained separately
        from awnd, and can even be forced to 0, resulting in a timeout.
-What should happen to the scoreboard after a timeout?  Clear it?  Insert a
        hole from snd_una to snd_max?  Reduce the retransmit threshold to 1?
        Mark the scoreboard as suspect?
-Rewrite FACK->Reno code to be NewReno?

SACK:
-sometimes doesn't cut the window in half after recovery (this was in
        NetBSD 1.1 and may not exist anymore)

FACK/SACK:
-add separate compile option for sender- and receiver-side behavior
-option space bug - the size of packets subtracts the length of the
        SACK option more than once
-should reverse scoreboard order, adding a pointer to the end of the list.
        This is a speed optimization since new SACK blocks are added to the
        scoreboard much more often than candidates for retransmission are
        selected.
-add debugging: "SACK/FACK connection opened to XXX.XXX.XXX.XXX" to syslog.
        This will help to determine the stability of these modifications
        by knowing if the modifications are ever really being used.
12/17-add "SACK/FACK/AUTO version XX" message during booting
-make sure that scrb_clear is called with the correct reason everywhere.
        This determines if retran_data gets reset to 0 or not.
-delayed ACK does not seem to be implemented correctly (in NetBSD itself).
        ACKs get sent for in-order packets only if: 1) the reassembly
        queue is non-empty; or 2) the 200ms timer goes off while TF_DELACK
        is set.
3/1-debug m_copydata panics (thought to be from telnet's to non-SACK receivers)
3/1-debug TCP neg offset panics
        - validity checking of scoreboard entries has been added, preventing
                the error from causing these panics
        - however, entries from different connections are thought to be
                making their way into the scoreboard


AUTO:
9/5-move more tests into sbdrop
-consider 128-byte mbufs vs mbuf clusters
9/5-pull back target hiwat during timeout
9/4-adjust thresholds
9/19-consider reducing Shiwat by more than acked if sb_cc is small or 0
-set more reasonable default values for SB_MAX and NMBCLUSTERS
-redo winshift section so that rcv buf size is set before winshift is
        calculated.  Then original calculation should work.  Edit in
        tcp_input.c and tcp_usrreq.c.
```

From the original `VERSION.History`:
```
V0.0
This version is the first port of SACK and FACK (with Rate Halving) to
        NetBSD 1.2 by the Pittsburgh Supercomputing Center.
It is also the first port to allow compilation of either option from the
        same source code.

V0.1
Splits the TF_RECOVERY flag into the TF_RECOVERY (holes exist) and the
        TF_RATEHALF (reducing window) flags.  This allows a Tahoe-style
        recovery following timeout.
Splits the TF_SACK_PERMIT into 2 flags: TF_SACK_PERMIT (sender may send
        SACKs), TF_SACK_SEEN (receiver has seen SACKs from the other end).
Fixes bugs during recovery between a FACK sender and a non-SACK receiver.

V0.2
Cleans up prototyping warnings as well as several other warnings that
        preventing compiling under NetBSD1.2/Sparc.

V0.2a
Adds validity checking of sack blocks before they are added to the
        scoreboard and before they are returned by scrb_getnextretran.

AUTO1
The first version of autotuning.  It does not contain SACK or FACK, the
        receiver window and hiwat are SB_MAX, the sender grows the hiwat
        to 1.5*cwnd.

V0.3
Combines SACK/FACK V0.2a with AUTO1.  Adds an alternate flag variable
        (t_alt_flags) to the tcpcb, since there were not sufficient flag
        bits for SACK/FACK/AUTOTUNING.

V0.4
Adds mbuf cluster starvation avoidance.  ACKs can be sent and received freely.
        Data to be received is dropped if mbufs clusters are running low.
        When data is to be sent and mbufs are running low, the data is
        accepted, but the hiwat is reduced.

V0.5
Modifies send socket buffer sizing to track cwnd increases and decreases.
        If cwnd > hiwat/2, then hiwat = 2 * cwnd.  If cwnd < hiwat/4, then
        hiwat = 4 * cwnd.  This should produce more equitable sharing of
        memory between connections sharing an interface.
A TCP kernel variable monitoring table was created to learn more about
        autotuning dynamics.  An application can read the table using kvm.
The snd_nxt field associated with retransmitted segments from the scoreboard
        now holds tp->snd_max at the time of a retransmission, since snd_fack
        quickly advances after a timeout, fooling the sender into thinking the
        retransmission was dropped.
Fixes a bug in comparing awnd to cwnd.

V0.6
Modifies the socket option to turn off autotuning into a TCP-level option.
    -To turn off autotuning for a single connection:
      int zero = 0;
      if (setsockopt(sockfd, IPPROTO_TCP, TCP_AUTO_OP, &zero, sizeof(int))) {
                 perror("Setsockopt(TCP_AUTO_OP)");
                 exit(-1);
      }
    -Setting the socket buffer sizes on a connection will automatically
                turn off autotuning for that connection.  To force it back on,
                use the same option listed above, but use the parameter
                'int one = 1;' instead.
Allows SB_MAX to be assigned in a kernel config file, by adding #ifndef around
        the original assignment in socketvar.h.
V0.7
Adds boot message that reports the PSC modifications and version.
Fixes FACK->Reno panic bug in which snd_fack > snd_nxt during recovery.
Changed name of snd_nxt member of scoreboard entry to be snd_max.
Fixed bug in SYN_SENT, in which first packet of some connections was delayed
        until a timeout occurred.

V0.8
Now compares proposed changes of target_hiwat + system mbuf clusters
        used against the threshold before making the change.  Prior versions
        didn't add in the proposed changes before making the comparison.
        I suspect this was a problem on systems where NMBCLUSTERS (in bytes)
        was less than or equal to SB_MAX.  During slow start (when cwnd can
        double quickly), the test indicated usage below the threshold (by
        default 1/2 of NMBCLUSTERS), so the target was doubled, filling
        all the NMBCLUSTERS instantly.
Converted the sb_target_hiwat variable to sb_net_target, representing the
        hiwat size preferred by the network.  Added sb_mem_target to
        represent the hiwat size preferred by memory allocation algorithm,
        which calculates a "fair share" of the available network memory.
Fixed FACK/SACK bug in which a FIN war resulted on connections that had a
        single data byte in the final packet.
Added initialization of t_alt_flags.  Cleaned up much of the SACK/FACK code
        to use more of the Reno code and each other's code when the same
        tasks are being accomplished.
Fixed FACK bug (introduced in V0.2) which sometimes allowed snd_fack to not
        be updated correctly.  This resulted in incorrect awnd calculations,
        preventing retransmissions until a timeout occurred.
Fixed FACK bug in which snd_una was not being correctly updated in FACK->Reno
        transfers if ACK advanced.
Renamed TF_* masking macros that are used for t_alt_flags to TAF_*, to
        better differentiate them from the masking macros used with
        t_flags.
Replaced the recurring autotuning code with macros that could be inserted in
        the appropriate places.
```
