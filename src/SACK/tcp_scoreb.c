/*
 * Copyright (c) 1997, Pittsburgh Supercomputing Center, 
 * Jamshid Mahdavi, Matt Mathis, Jeffrey Semke
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

/**********************************************************************
 *
 *  Scoreboard module: 
 *  
 *  This module scoreboards incoming SACK blocks and determines
 *  what data should be retransmitted based on this information.
 *
 **********************************************************************/

#include <sys/param.h>
#include <sys/mbuf.h>
#include <sys/protosw.h>
#include <sys/socket.h>
#include <sys/socketvar.h>
#include <sys/errno.h>
#include <sys/malloc.h>
#include <sys/systm.h>

#include <net/if.h>
#include <net/route.h>

#include <netinet/in.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <netinet/in_pcb.h>
#include <netinet/ip_var.h>
#include "tcp.h"
#include <netinet/tcp_fsm.h>
#include <netinet/tcp_seq.h>
#include <netinet/tcp_timer.h>
#include "tcp_var.h"
#include <netinet/tcpip.h>
#include <netinet/tcp_debug.h>

#ifdef _KERNEL
int scrb_insert_head __P((struct tcpcb*, tcp_seq, tcp_seq, tcp_seq));
int scrb_insert_element __P((struct tcpcb*, struct scrb_entry*, tcp_seq, 
				tcp_seq));

#define CKretran_data() {if (tp->snd_retran_data < 0) \
      panic("retran_data went negative!!!\n");}
#define scrb_getmem(size)    malloc((size), M_TEMP, M_NOWAIT)
#define scrb_freemem(addr)         free((caddr_t)(addr), M_TEMP)

#else   /* for user-mode scoreboard debugging */

#define CKretran_data() {}
#define scrb_getmem(size)    malloc(size)
#define scrb_freemem(addr)         free(addr)

#endif


#define scrb_delete(node) {LIST_REMOVE(node,ptrs);}

#ifdef TCP_FACK
/* scrb_head_passed and scrb_elem_passed:
   1)  Reset retransmitted ptr for all holes who's saved
       snd_max is behind fack.
   2)  Increment "observed" count for all holes to the left
       of the right-most edge of this SACK (bfack)
*/

#define scrb_head_passed(head) {if (SEQ_LT(head->snd_max, tp->snd_fack) && \
				    (head->retran != tp->scrb.last_ack)) { \
				     tp->snd_retran_data -= (head->retran - \
							  tp->scrb.last_ack);\
				     head->retran = tp->scrb.last_ack; \
				     head->sack_cnt = 0; \
				     head->snd_max = tp->snd_max;}\
				if (SEQ_LEQ(head->retran, bfack)) {\
				/* Allow == for RENO emulation */ \
				     head->sack_cnt++;}}
#define scrb_elem_passed(elq,elp) if (SEQ_LT(elq->snd_max, tp->snd_fack) && \
				    (elq->retran != elp->end)) { \
				     tp->snd_retran_data -= (elq->retran - \
							  elp->end);\
				     elq->retran = elp->end; \
				     elq->sack_cnt = 0; \
				     elq->snd_max = tp->snd_max;}\
				if (SEQ_LEQ(elq->retran, bfack)) {\
				/* Allow == for RENO emulation */ \
				     elq->sack_cnt++;}
#endif
     
/*
 *  Clear the scoreboard  
 */
void
scrb_clear (struct tcpcb *tp, int reason)
{
      register struct scrb_entry *node, *tmp, *tmp1;

      if (! scrb_isempty(tp)) {
	    node = tp->scrb.scrb_head;
	    while (node) {
		  tmp1 = node;
		  tmp = node->scrb_next;
		  scrb_delete(node);
		  scrb_freemem(tmp1);
		  node = tmp;
	    }
      }
      if (reason & (SCRB_INIT|SCRB_TIMEOUT))
	    tp->snd_retran_data = 0;
}

/* scrb_insert_* depend on the kernel malloc being quick */

/* Insert a new element into an empty scoreboard. */
int
scrb_insert_head (register struct tcpcb* tp,
		  tcp_seq start,
		  tcp_seq end,
		  tcp_seq ack)
{
      struct scrb_entry* elm;

      elm = (struct scrb_entry*)scrb_getmem(sizeof(struct scrb_entry));
      if (!elm) {
	    scrb_clear(tp, SCRB_NOMEM);
	    return E_SCRB_CLEAR;
      }
      
      elm->start = start;
      elm->end = end;

      /* Set sack_cnt and snd_max if there
	 was not an older block, moved to the right */
      if (tp->scrb.scrb_head) {
	    elm->sack_cnt = tp->scrb.scrb_head->sack_cnt;
	    elm->snd_max = tp->scrb.scrb_head->snd_max;
	    if (SEQ_LEQ(start, tp->scrb.scrb_head->retran)) {
		  elm->retran = start;
		  if (SEQ_GT(end, tp->scrb.scrb_head->retran)) {
			tp->scrb.scrb_head->retran = end;
		  }
	    }
	    else {
		  elm->retran = tp->scrb.scrb_head->retran;
		  tp->scrb.scrb_head->retran = end;
	    }
      }
      else {
	    elm->sack_cnt = 0;
	    elm->snd_max = tp->snd_max;
	    elm->retran = ack;
      }
      LIST_INSERT_HEAD(&(tp->scrb.head), elm, ptrs);
      return E_SCRB_NOERR;

}


/*  
 *  Insert a new element into the scoreboard.
 *  Does not check for overlap with other scoreboard
 *  elements!
 */
int
scrb_insert_element (struct tcpcb* tp,
		     struct scrb_entry* listelm,
		     tcp_seq start,
		     tcp_seq end)
     
{
      register struct scrb_entry* elm;

      elm = (struct scrb_entry*)scrb_getmem(sizeof(struct scrb_entry));
      if (!elm) {
	    scrb_clear(tp, SCRB_NOMEM);
	    return E_SCRB_CLEAR;
      }
      
      elm->start = start;
      elm->end = end;

      /* Set sack_cnt and snd_max if there
	 was not an older block, moved to the right */
      if (listelm->scrb_next) {
	    elm->sack_cnt = listelm->scrb_next->sack_cnt;
	    elm->snd_max = listelm->scrb_next->snd_max;
	    if (SEQ_LEQ(start, listelm->scrb_next->retran)) {
 		  elm->retran = start;
		  if (SEQ_GT(end, listelm->scrb_next->retran)) {
			listelm->scrb_next->retran = end;
		  }
	    }
	    else {
		  elm->retran = listelm->scrb_next->retran;
		  listelm->scrb_next->retran = end;
	    }
      }
      else {
	    elm->sack_cnt = 0;
	    elm->snd_max = tp->snd_max;
	    elm->retran = listelm->end;
      }
      LIST_INSERT_AFTER(listelm, elm, ptrs);
      return E_SCRB_NOERR;
}

int
scrb_update(register struct tcpcb *tp, 
		  struct tcpiphdr *ti, 
		  register struct sackblock *sackblock_list, 
		  int sackblock_list_len)
{
    register struct scrb_entry *p, *q;
    struct scrb_entry *tmp1, *tmp2;
    register tcp_seq start, end;
    register int i;
#ifdef TCP_FACK
    tcp_seq bfack = ti->ti_ack;    /* forward-most SACK block in this packet */
#endif

    /*  Process the advancing ACK first.  If ACK is advancing, check 
     *  each element in the scoreboard.  If it has been advanced over,
     *  delete it.  
     */
    if (SEQ_GT(ti->ti_ack, tp->scrb.last_ack)) {  /* ack advance */
    ack_loop:
	  if (! scrb_isempty(tp)) {
	    /*  First, deal with retransmitted data  */
	    if (SEQ_GT(ti->ti_ack, tp->scrb.scrb_head->retran)) {
		tp->snd_retran_data -= (tp->scrb.scrb_head->retran - 
				    tp->scrb.last_ack);
		tp->scrb.scrb_head->retran = ti->ti_ack;
		/*  Check for consistency  */
		CKretran_data();
	    } else {
		tp->snd_retran_data -= (ti->ti_ack - tp->scrb.last_ack);
		/*  Check for consistency  */
		CKretran_data();
	    }

	    /*  Now figure out if we are obsoleting all or part of a block */
	    if (SEQ_GEQ(ti->ti_ack, tp->scrb.scrb_head->end)) {
		  /*  Delete the block  */
		  tp->scrb.last_ack = tp->scrb.scrb_head->end;
		  tmp1 = tp->scrb.scrb_head;
		  scrb_delete(tp->scrb.scrb_head);
		  scrb_freemem(tmp1);

		  goto ack_loop;
	    } 
	    if (SEQ_GEQ(ti->ti_ack, tp->scrb.scrb_head->start)) {
		/*  This means something is wrong.  The receiver 
		 *  has reneiged.  Clear the scoreboard to be safe.
		 *  Go on to process any SACK blocks in this packet, 
		 *  however.
		 */
		scrb_clear(tp, SCRB_RENEGE );
	    }
	}
	tp->scrb.last_ack = ti->ti_ack;
    }

    /*  Loop through all of the SACK blocks.  */
    for (i=0; i<sackblock_list_len; i++) {
	start = sackblock_list[i].start;
	end   = sackblock_list[i].end;
	/*  For each sackblock:
	            0)  See if it makes sense 
		    1)  Find the appropriate place in the structure.
		    2)  Insert the new block there.
		    3)  Update snd_retran_data if the block SACKs 
		        retransmitted data.
		    4)  Delete or merge in any subsequent blocks which 
		        overlap this one.
		    */
	if (SEQ_GT(end, tp->snd_max))
	      end = tp->snd_max;
	if (SEQ_LT(start, tp->snd_una))
	      start = tp->snd_una;

	if (SEQ_GT(start, end)) {  /* allow = for new Reno emulation */
	      continue;          /* skip */
	}


	if (scrb_isempty(tp)) {
	    /*  There is no scoreboard.  Just add it and continue  */
	    tp->scrb.last_ack = ti->ti_ack; /* was tp->snd_una */

	    if (scrb_insert_head (tp, start, end, ti->ti_ack))
		  return E_SCRB_CLEAR;
	    continue;
	}

	if (SEQ_LEQ(end, tp->scrb.last_ack)) {
	    /*  A SACK block came in after it was ACKed -- throw it out  */
	    continue;
	}

	if (SEQ_LEQ(start, tp->scrb.last_ack) || SEQ_LEQ(start, tp->snd_una)) {
	    /*  A SACK block came in which spans last_ack.  This is
	     *  an error case indicating reneging -- clear the scoreboard
	     *  and drop the block.
	     */
	    scrb_clear(tp, SCRB_RENEGE);
	    continue;
	}

	if (SEQ_LEQ(start, tp->scrb.scrb_head->start)) {
	    /*  Handle the first block specially  */
	    if (SEQ_LT(start, tp->scrb.scrb_head->retran)) {
		/*  Some retransmitted data has left the network  */
		  if (SEQ_LT(end, tp->scrb.scrb_head->retran)) {
			tp->snd_retran_data -= (end - start);
		  }
		  else {
			tp->snd_retran_data -= (tp->scrb.scrb_head->retran - 
					    start);
		  }
		  /*  Check for consistency  */
		  CKretran_data();
	    }
	    /*  Stick in the block  */
	    if (scrb_insert_head (tp, start, end, ti->ti_ack))
		  return E_SCRB_CLEAR;
	    /* p gets new element, q gets next
	       These will be used in the while loop below */
	    p = tp->scrb.scrb_head;
	    q = p->scrb_next;
	} 
	else {
	      if (SEQ_LEQ(end, tp->scrb.scrb_head->end)) {
		    continue;
	      }
	      for (p = tp->scrb.scrb_head, q = p->scrb_next; 
		   q; 
 		   p = q, q = q->scrb_next) {

		    if (SEQ_LEQ(start, q->start)) {
			  /*  We have located the start of the block. 
			   *  If it overlaps the previous block, merge it; if 
			   *  it is a subset, toss it.  */
			  if (SEQ_LEQ(start, p->end)) {
				if (SEQ_LEQ(end, p->end)) {
				      continue;
				} 

				/*  We must merge with the prev. SACK block  */
				if (SEQ_GT(end, q->retran)) {
				      tp->snd_retran_data -= (q->retran - p->end);
				      p->end = end;
				      q->retran = end;
				}
				else {
				      tp->snd_retran_data -= (end - p->end);
				      p->end = end;
				}
				/*  Check for consistency  */
				CKretran_data();

				/* p now holds the modified element,
				   q holds following element 
				   These will be used in the while loop below*/
				break;
			  }
			  else {
				if (SEQ_LT(start, q->retran)) {
				      /*  Some retransmitted data has left 
					  the network  */
				      if (SEQ_LT(end, q->retran))
					    tp->snd_retran_data -= (end - 
								start);
				      else {
					    tp->snd_retran_data -= (q->retran - 
								start);
				      }
				      /*  Check for consistency  */
				      CKretran_data();
				}
				if (scrb_insert_element(tp, p, start, 
							end))
				      return E_SCRB_CLEAR;
				p = p->scrb_next;  /* p gets new element */
				q = p->scrb_next;  /* q gets following 
						      element, if exists*/
				                   /* These will be used in 
						      the while loop below */
				break;
			  }
		    }
	      }
	      if (!q) {
		    /*  The block goes after the end of the existing 
			sackblocks--an easy case.  Insert and continue.  */
		    if (scrb_insert_element(tp, p, start, end))
			  return E_SCRB_CLEAR;
		    		    q = p->scrb_next;  /* q gets following 
							  element, if exists*/
		               /* These will be used in the while loop below */
				    /* continue; */
	      }
	}
	/*  Now, p holds our new block - see if there is overlap with next */
	while ( q && (SEQ_GEQ(p->end, q->start))) {
	      if (q == q->scrb_next)
		    panic("Scoreboard has a loop!\n");
	      if (SEQ_GT(p->end, q->end)) {
		    /* p covers q.  q will be deleted below, but we need to
		       update retran if q->scrb_next exists */
		    if (q->scrb_next) {
			  if (SEQ_GT(p->end, q->scrb_next->retran)) {
				tp->snd_retran_data -= (q->scrb_next->retran -
						    q->end);
				q->scrb_next->retran = p->end;
			  }
			  else {
				tp->snd_retran_data -= (p->end - q->end);
			  }
			  /* Check for consistency */
			  CKretran_data();

		    }
	      }
	      else {
		    /*  Here, the block overlaps part of a subsequent SACK 
		     *  block.
		     *  Normally, this shouldn't happen.  It could be a sign of
		     *  the receiver reneiging, or just happen due to out-of- 
		     *  order packets.  Here, we assume the latter and just 
		     *  merge with the following SACK block.  
		     */
		    p->end = q->end;
	      }
			  
	      /*  delete the block */
	      tmp1 = q->scrb_next;
	      tmp2 = q;
	      scrb_delete(q);
	      scrb_freemem(tmp2);
	      q = tmp1;
	}
    }
#ifdef TCP_FACK
	/* Find the forward-most SACK block, bfack, from this option list */
    for (i=0; i<sackblock_list_len; i++) {
	  if (SEQ_GT(sackblock_list[i].end, bfack))
		bfack = sackblock_list[i].end;
    }

    if (SEQ_GT(bfack, tp->snd_fack))
	  tp->snd_fack = bfack;

    /* for all entries until (entry->start > bfack), do:
       5)  Reset retransmitted ptr for all holes who's saved
           snd_max is behind fack.
       6)  Increment "observed" count for all holes to the left
           of the right-most edge of this SACK (bfack)
     */
    if (tp->scrb.scrb_head) {
	  scrb_head_passed(tp->scrb.scrb_head);
	  for ( tmp1 = tp->scrb.scrb_head, tmp2 = tmp1->scrb_next; 
		tmp2 ; 
		tmp1 = tmp2, tmp2 = tmp2->scrb_next) {
		scrb_elem_passed(tmp2,tmp1) else break;
	  }
    }
#endif
    return E_SCRB_NOERR;
}
/*
 *  This routine checks to see if retransmitted data has again 
 *  been lost.  This is true if a SACK block is received which 
 *  acknowledges data beyond the value of snd_max recorded at the
 *  time data was retransmitted.  The variable "fack" provides the
 *  highest sequence number acknowledged in a SACK block.
 *  Called from dooptions in tcp_input.
 */
int 
scrb_check_snd_max (struct tcpcb *tp, tcp_seq fack)
{
      register struct scrb_entry *ptr;

      if (scrb_isempty(tp)) {
	    /*  There is no scoreboard...  */
	    return (0);
      }

      for (ptr = tp->scrb.scrb_head; ptr->scrb_next; ptr = ptr->scrb_next) {
	    if (SEQ_LT(ptr->snd_max, fack)) {
		  /*  A retransmitted segment has been lost  */
		  return (1);
	    }
      }
      return (0);
}

/*
 *  This function hunts through the scoreboard and returns the 
 *  next block of data to be retransmitted.  The start and end of
 *  the block are filled in to start_ptr and end_ptr, and the 
 *  length of the block is returned.  A zero return value indicates
 *  that there is no data to be retransmitted at this time.
 *  Note that end_ptr actually points to the first byte of data
 *  which is NOT to be retransmitted (or the first byte following the
 *  data to be retransmitted) similar in fashion to the rest of this
 *  code.
 */
int 
scrb_getnextretran_func (struct tcpcb *tp, 
		 tcp_seq *start_ptr,
		 tcp_seq *end_ptr)
{
      register struct scrb_entry* p;

      /* assumes that scrb_getnextretran macro has tested for empty
	 scoreboard */
      for (p = tp->scrb.scrb_head; p; p = p->scrb_next) {
	    if (SEQ_LT(p->retran, p->start)
#ifdef TCP_FACK
		&& p->sack_cnt >= TCP_FACK_REXMTTHRESH
#endif
		) {
		  *start_ptr = p->retran;
		  *end_ptr = p->start;
		  if (SEQ_LT(*start_ptr, tp->snd_una))
			*start_ptr = tp->snd_una;
		  if (SEQ_GT(*end_ptr, tp->snd_max))
			*end_ptr = tp->snd_max;
		  if (SEQ_GEQ(*start_ptr, *end_ptr))
			continue;
		  return(*end_ptr - *start_ptr);
	    }
      }
      /*  There are no holes left to retran  */
      *start_ptr = *end_ptr = 0;
      return (0);
}

/*  
 *  Mark a segment as being retransmitted.
 */
void
scrb_markretran (struct tcpcb *tp,
	     register tcp_seq start, 
	     register tcp_seq end)
{
      register struct scrb_entry *q;

      if (scrb_isempty(tp)) {
	    /*  There is no scoreboard.  This is an error  */
	    printf ("Attempted retransmission from empty scoreboard\n");
      }

      tp->snd_retran_data += end - start;

      for (q = tp->scrb.scrb_head; q; q = q->scrb_next) {
	    if (SEQ_LT(start, q->start)) {
		  /* We have found where to insert the retransmit */
		  if (SEQ_LEQ(end, q->start)) {
			if (SEQ_GEQ(end, q->retran)) {
			      q->retran = end;
			      q->snd_max = tp->snd_max;
			}
			return;
		  }
		  q->retran = q->start;
		  q->snd_max = tp->snd_max;
		  /* Continue on into the next block. */
	    }
      }
}


#ifdef TCP_FACK
/*
 * Fake a SACK block, in response to a duplicate ACK.
 * This will be a zero length block, typically one mss beyond ti_ack.
 */
void 
scrb_fake_sack(struct tcpcb *tp,
	       struct tcpiphdr *ti) {
      struct sackblock list[1];
      tcp_seq ack = ti->ti_ack + tp->t_maxseg ;

      if (SEQ_GT(ack, tp->snd_nxt)) 
	    ack = tp->snd_nxt;
      list[0].start = list[0].end = ack;
      scrb_update(tp, ti, list, 1);
}
#endif

#if 0
void
print_scrb(struct tcpcb *tp) {
      struct scrb_entry* ptr;

      ptr = tp->scrb->head;

      while (ptr) {
	    printf("start=%lx end=%lx retran=%lx snd_max=%lx sack_cnt=%lx\n",
		   ptr->start, ptr->end, ptr->retran, ptr->snd_max, 
		   ptr->sack_cnt);
	    ptr = ptr->scrb_next;
      }
}
#endif
