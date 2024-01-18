/*	$NetBSD: tcp_timer.c,v 1.14.4.2 1996/12/11 04:01:09 mycroft Exp $	*/

/*
 * Copyright (c) 1982, 1986, 1988, 1990, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	@(#)tcp_timer.c	8.1 (Berkeley) 6/10/93
 */

#ifndef TUBA_INCLUDE
#include <sys/param.h>
#include <sys/systm.h>
#include <sys/malloc.h>
#include <sys/mbuf.h>
#include <sys/socket.h>
#include <sys/socketvar.h>
#include <sys/protosw.h>
#include <sys/errno.h>

#include <net/if.h>
#include <net/route.h>

#include <netinet/in.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <netinet/in_pcb.h>
#include <netinet/ip_var.h>
#include <netinet/tcp.h>
#include <netinet/tcp_fsm.h>
#include <netinet/tcp_seq.h>
#include <netinet/tcp_timer.h>
#include <netinet/tcp_var.h>
#include <netinet/tcpip.h>

#ifdef TCP_AUTO

u_long auto_snd_thresh_bytes = AUTO_SND_THRESH << MCLSHIFT;

#ifdef TCP_AUTO_DEBUG
#include <netinet/tcp_debugauto.h>
#endif
#endif

int	tcp_keepidle = TCPTV_KEEP_IDLE;
int	tcp_keepintvl = TCPTV_KEEPINTVL;
int	tcp_maxidle;
#endif /* TUBA_INCLUDE */
/*
 * Fast timeout routine for processing delayed acks
 */
void
tcp_fasttimo()
{
	register struct inpcb *inp;
	register struct tcpcb *tp;
	int s;

	s = splsoftnet();
	inp = tcbtable.inpt_queue.cqh_first;
	if (inp)						/* XXX */
	for (; inp != (struct inpcb *)&tcbtable.inpt_queue;
	    inp = inp->inp_queue.cqe_next) {
		if ((tp = (struct tcpcb *)inp->inp_ppcb) &&
		    (tp->t_flags & TF_DELACK)) {
			tp->t_flags &= ~TF_DELACK;
			tp->t_flags |= TF_ACKNOW;
			tcpstat.tcps_delack++;
			(void) tcp_output(tp);
		}
	}
	splx(s);
}

/*
 * Tcp protocol timeout routine called every 500 ms.
 * Updates the timers in all active tcb's and
 * causes finite state machine actions if timers expire.
 */
void
tcp_slowtimo()
{
	register struct inpcb *ip, *ipnxt;
	register struct tcpcb *tp;
	int s;
	register long i;
#ifdef TCP_AUTO
	u_long sum_small_targs = 0;          /* sum of small network targets */
	u_long small_conns = 0;              /* number of small connections */
	u_long big_conns = 0;                /* number of large connections */
#endif

	s = splsoftnet();
	tcp_maxidle = TCPTV_KEEPCNT * tcp_keepintvl;
	/*
	 * Search through tcb's and update active timers.
	 */
	ip = tcbtable.inpt_queue.cqh_first;
	if (ip == (struct inpcb *)0) {				/* XXX */
		splx(s);
		return;
	}
	for (; ip != (struct inpcb *)&tcbtable.inpt_queue; ip = ipnxt) {
		ipnxt = ip->inp_queue.cqe_next;
		tp = intotcpcb(ip);
		if (tp == 0)
			continue;
		for (i = 0; i < TCPT_NTIMERS; i++) {
			if (tp->t_timer[i] && --tp->t_timer[i] == 0) {
				(void) tcp_usrreq(tp->t_inpcb->inp_socket,
				    PRU_SLOWTIMO, (struct mbuf *)0,
				    (struct mbuf *)i, (struct mbuf *)0,
				    (struct proc *)0);
				/* XXX NOT MP SAFE */
				if ((ipnxt == (void *)&tcbtable.inpt_queue &&
				    tcbtable.inpt_queue.cqh_last != ip) ||
				    ipnxt->inp_queue.cqe_prev != ip)
					goto tpgone;
			}
		}
		tp->t_idle++;
		if (tp->t_rtt)
			tp->t_rtt++;
#ifdef TCP_AUTO
		/* Count small conns (and memory used by them) and count
		     large conns.
		   The memory used by small conns is set aside from the
		     general pool, then the pool is divided up among the
		     large conns.
		   Non-autotuned connections count as "small conns" for this
		     purpose, because their memory is also set aside from
		     the pool.
		     */
		if (tp->t_state & (TCPS_ESTABLISHED | TCPS_CLOSE_WAIT)) {
		      if ((tp->t_alt_flags & TAF_AUTO_OFF) ||
			  (tp->t_inpcb->inp_socket->so_snd.sb_net_target <
			   hiwat_fair_share)) {
			    sum_small_targs += 
				 tp->t_inpcb->inp_socket->so_snd.sb_net_target;
			    small_conns++;
		      } else {
			    big_conns++;
		      }
		}
#endif

tpgone:
		;
	}
	tcp_iss += TCP_ISSINCR/PR_SLOWHZ;		/* increment iss */
#ifdef TCP_COMPAT_42
	if ((int)tcp_iss < 0)
		tcp_iss = 0;				/* XXX */
#endif
	tcp_now++;					/* for timestamps */

#ifdef TCP_AUTO
	/* determine new fair share */
	if (sum_small_targs > auto_snd_thresh_bytes) {
	      /* too many small conns to subtract them from the total */
	      /* hiwat_fair_share = auto_snd_thresh_bytes / (1 + big_conns + 
							  small_conns); */
	      hiwat_fair_share = auto_snd_thresh_bytes / 
		    ((big_conns || small_conns) ? 
		     (big_conns + small_conns) : 1);
	} else {
	      /* otherwise, exempt the small conns from the calculation */
	      hiwat_fair_share = (auto_snd_thresh_bytes - sum_small_targs) / 
		    (big_conns ? big_conns : 1);
	      /*hiwat_fair_share = (auto_snd_thresh_bytes - sum_small_targs) / 
		    (1 + big_conns); */
	}

	ip = tcbtable.inpt_queue.cqh_first;
	/* don't need to check for null ip, since it was checked above */
	for (; ip != (struct inpcb *)&tcbtable.inpt_queue; ip = ipnxt) {
		ipnxt = ip->inp_queue.cqe_next;
		tp = intotcpcb(ip);
		if (tp == 0)
			continue;

		/* adjust mem_targets for autotuned conns */
		if (!(tp->t_alt_flags & TAF_AUTO_OFF)) {
		      if (tp->t_inpcb->inp_socket->so_snd.sb_net_target >= 
			  hiwat_fair_share) {
			    tp->t_inpcb->inp_socket->so_snd.sb_mem_target = 
				  hiwat_fair_share;
		      } else {
			    tp->t_inpcb->inp_socket->so_snd.sb_mem_target =
				 tp->t_inpcb->inp_socket->so_snd.sb_net_target;
		      }
		}
	}
#endif

	splx(s);
}
#ifndef TUBA_INCLUDE

/*
 * Cancel all timers for TCP tp.
 */
void
tcp_canceltimers(tp)
	struct tcpcb *tp;
{
	register int i;

	for (i = 0; i < TCPT_NTIMERS; i++)
		tp->t_timer[i] = 0;
}

int	tcp_backoff[TCP_MAXRXTSHIFT + 1] =
    { 1, 2, 4, 8, 16, 32, 64, 64, 64, 64, 64, 64, 64 };

/*
 * TCP timer processing.
 */
struct tcpcb *
tcp_timers(tp, timer)
	register struct tcpcb *tp;
	int timer;
{

	switch (timer) {

	/*
	 * 2 MSL timeout in shutdown went off.  If we're closed but
	 * still waiting for peer to close and connection has been idle
	 * too long, or if 2MSL time is up from TIME_WAIT, delete connection
	 * control block.  Otherwise, check again in a bit.
	 */
	case TCPT_2MSL:
		if (tp->t_state != TCPS_TIME_WAIT &&
		    tp->t_idle <= tcp_maxidle)
			tp->t_timer[TCPT_2MSL] = tcp_keepintvl;
		else
			tp = tcp_close(tp);
		break;

	/*
	 * Retransmission timer went off.  Message has not
	 * been acked within retransmit interval.  Back off
	 * to a longer retransmit interval and retransmit one segment.
	 */
	case TCPT_REXMT:
		if (++tp->t_rxtshift > TCP_MAXRXTSHIFT) {
			tp->t_rxtshift = TCP_MAXRXTSHIFT;
			tcpstat.tcps_timeoutdrop++;
			tp = tcp_drop(tp, tp->t_softerror ?
			    tp->t_softerror : ETIMEDOUT);
			break;
		}
		tcpstat.tcps_rexmttimeo++;
		TCPT_RANGESET(tp->t_rxtcur,
		    TCP_REXMTVAL(tp) * tcp_backoff[tp->t_rxtshift],
		    tp->t_rttmin, TCPTV_REXMTMAX);
		tp->t_timer[TCPT_REXMT] = tp->t_rxtcur;
		/*
		 * If losing, let the lower level know and try for
		 * a better route.  Also, if we backed off this far,
		 * our srtt estimate is probably bogus.  Clobber it
		 * so we'll take the next rtt measurement as our srtt;
		 * move the current srtt into rttvar to keep the current
		 * retransmit times until then.
		 */
		if (tp->t_rxtshift > TCP_MAXRXTSHIFT / 4) {
			in_losing(tp->t_inpcb);
			tp->t_rttvar += (tp->t_srtt >> TCP_RTT_SHIFT);
			tp->t_srtt = 0;
		}
#ifdef TCP_SACK
		scrb_clear (tp, SCRB_INIT);
		tp->pipe = 0;
		tp->recover = tp->snd_nxt = tp->snd_una;
#else
		tp->snd_nxt = tp->snd_una;
#endif
		/*
		 * If timing a segment in this window, stop the timer.
		 */
		tp->t_rtt = 0;
		/*
		 * Close the congestion window down to one segment
		 * (we'll open it by one segment for each ack we get).
		 * Since we probably have a window's worth of unacked
		 * data accumulated, this "slow start" keeps us from
		 * dumping all that data as back-to-back packets (which
		 * might overwhelm an intermediate gateway).
		 *
		 * There are two phases to the opening: Initially we
		 * open by one mss on each ack.  This makes the window
		 * size increase exponentially with time.  If the
		 * window is larger than the path can handle, this
		 * exponential growth results in dropped packet(s)
		 * almost immediately.  To get more time between 
		 * drops but still "push" the network to take advantage
		 * of improving conditions, we switch from exponential
		 * to linear window opening at some threshhold size.
		 * For a threshhold, we use half the current window
		 * size, truncated to a multiple of the mss.
		 *
		 * (the minimum cwnd that will give us exponential
		 * growth is 2 mss.  We don't allow the threshhold
		 * to go below this.)
		 */
#if defined(TCP_AUTO) && defined(TCP_AUTO_DEBUG)
		TAD_SNAPSHOT(tp, tp->t_inpcb->inp_socket);
#endif
#ifndef TCP_FACK
		{
		u_int win = min(tp->snd_wnd, tp->snd_cwnd) / 2 / tp->t_maxseg;
		if (win < 2)
			win = 2;
		tp->snd_cwnd = tp->t_maxseg;
		tp->snd_ssthresh = win * tp->t_maxseg;
		tp->t_dupacks = 0;
		}
#else
		if ((tp->t_alt_flags & TAF_RECOVERY) == 0) {
		    u_int win = min(tp->snd_wnd, tp->snd_cwnd)/2/tp->t_maxseg;

		    if (win < 2) win = 2;
		    tp->hithresh = win*tp->t_maxseg;

		    win /= 2;
		    if (win < 2) win = 2;
		    tp->snd_ssthresh = tp->lothresh = win * tp->t_maxseg;
		    tp->recover = tp->snd_nxt;
		    tp->t_alt_flags |= TAF_RECOVERY;
		}
		tp->snd_cwnd = tp->t_maxseg;
		scrb_clear (tp, SCRB_TIMEOUT);
		tp->t_alt_flags &= ~(TAF_RATEHALF|TAF_REPAIRED|TAF_WHOLD
				     |TAF_TOGGLE);
		tp->snd_fack = tp->snd_nxt;
#endif
#ifdef TCP_AUTO
		if (! (tp->t_alt_flags & TAF_AUTO_OFF)) {
		      /* reduce the target, since cwnd is now 1 mss */
		      tp->t_inpcb->inp_socket->so_snd.sb_net_target = 
			    tp->snd_cwnd << 2;
		      /* in case space freed up--unlikely case */
		      if ((tp->t_inpcb->inp_socket->so_snd.sb_mem_target >
			   tp->t_inpcb->inp_socket->so_snd.sb_hiwat) &&
			  ((mbstat.m_clusters - mbstat.m_clfree +
			    ((tp->t_inpcb->inp_socket->so_snd.sb_mem_target
			     - tp->t_inpcb->inp_socket->so_snd.sb_cc) 
			    >> MCLSHIFT)) < AUTO_SND_THRESH))
			    sbreserve(&tp->t_inpcb->inp_socket->so_snd,
				      tp->t_inpcb->inp_socket->so_snd.sb_mem_target);
		}
#ifdef TCP_AUTO_DEBUG
		TAD_SNAPSHOT(tp, tp->t_inpcb->inp_socket);
#endif
#endif
		(void) tcp_output(tp);
		break;

	/*
	 * Persistance timer into zero window.
	 * Force a byte to be output, if possible.
	 */
	case TCPT_PERSIST:
		tcpstat.tcps_persisttimeo++;
		tcp_setpersist(tp);
		tp->t_force = 1;
		(void) tcp_output(tp);
		tp->t_force = 0;
		break;

	/*
	 * Keep-alive timer went off; send something
	 * or drop connection if idle for too long.
	 */
	case TCPT_KEEP:
		tcpstat.tcps_keeptimeo++;
		if (TCPS_HAVEESTABLISHED(tp->t_state) == 0)
			goto dropit;
		if (tp->t_inpcb->inp_socket->so_options & SO_KEEPALIVE &&
		    tp->t_state <= TCPS_CLOSE_WAIT) {
		    	if (tp->t_idle >= tcp_keepidle + tcp_maxidle)
				goto dropit;
			/*
			 * Send a packet designed to force a response
			 * if the peer is up and reachable:
			 * either an ACK if the connection is still alive,
			 * or an RST if the peer has closed the connection
			 * due to timeout or reboot.
			 * Using sequence number tp->snd_una-1
			 * causes the transmitted zero-length segment
			 * to lie outside the receive window;
			 * by the protocol spec, this requires the
			 * correspondent TCP to respond.
			 */
			tcpstat.tcps_keepprobe++;
#ifdef TCP_COMPAT_42
			/*
			 * The keepalive packet must have nonzero length
			 * to get a 4.2 host to respond.
			 */
			tcp_respond(tp, tp->t_template, (struct mbuf *)NULL,
			    tp->rcv_nxt - 1, tp->snd_una - 1, 0);
#else
			tcp_respond(tp, tp->t_template, (struct mbuf *)NULL,
			    tp->rcv_nxt, tp->snd_una - 1, 0);
#endif
			tp->t_timer[TCPT_KEEP] = tcp_keepintvl;
		} else
			tp->t_timer[TCPT_KEEP] = tcp_keepidle;
		break;
	dropit:
		tcpstat.tcps_keepdrops++;
		tp = tcp_drop(tp, ETIMEDOUT);
		break;
	}
	return (tp);
}
#endif /* TUBA_INCLUDE */
