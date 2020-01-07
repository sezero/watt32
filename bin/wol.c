/*
 * wol.c        Wake On Lan
 *
 * Copyright(c)2000 by Hiroaki Sengoku <sengoku@gcd.org>
 * Version 0.1 Jan 17, 2000
 *
 * Adaption (in a hurry) for Watt-32 by G.Vanem 2002
 *
 * Usage: wol <IP address> <MAC address>
 * Wakeup a machine whose interface is <MAC address>.
 * The wakeup packet is sent to <IP address>,
 * so mostly <IP address> is a broadcast address.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wtime.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <tcp.h>

#define BUFMAX	1024
#define MACLEN	6

static void host2addr (const char *name, struct in_addr *addrp, short *familyp)
{
  struct hostent *hp = gethostbyname(name);

  if ((hp) != NULL) {
     memcpy(addrp,hp->h_addr,hp->h_length);
     if (familyp)
       *familyp = hp->h_addrtype;
  }
  else if ((addrp->s_addr=inet_addr(name)) != INADDR_NONE)
  {
    if (familyp)
       *familyp = AF_INET;
  }
  else
  {
    fprintf(stderr,"Unknown host : %s\n",name);
    exit(1);
  }
}

int hex(char c) {
    if ('0' <= c && c <= '9') return c - '0';
    if ('a' <= c && c <= 'f') return c - 'a' + 10;
    if ('A' <= c && c <= 'F') return c - 'A' + 10;
    return -1;
}

int hex2(char *p) {
    int i;
    unsigned char c;
    i = hex(*p++);
    if (i < 0) return i;
    c = (i << 4);
    i = hex(*p);
    if (i < 0) return i;
    return c | i;
}

int main(argc,argv)
int argc;
char *argv[];
{
    int sd;
    int optval;
    char unsigned buf[BUFMAX];
    int len;
    struct sockaddr_in sin;
    unsigned char mac[MACLEN];
    unsigned char *p;
    int i, j;
    if (argc != 3) {
	fprintf(stderr,
		"Wake On Lan\n"
		"Copyright(C)2000 by Hiroaki Sengoku <sengoku@gcd.org>\n"
		"Usage: wol <IP> <MAC>\n");
	exit(1);
    }
    dbug_init();
    memset(&sin,0,sizeof(sin)); /* clear sin struct */
    sin.sin_family = AF_INET;
    host2addr(argv[1],&sin.sin_addr,&sin.sin_family);	/* host */
    sin.sin_port = htons(9);	/* port */
    if ((sd=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP)) < 0) {
	fprintf(stderr,"Can't get socket.\n");
	exit(1);
    }
    optval = 1;
    if (setsockopt(sd,SOL_SOCKET,SO_BROADCAST,&optval,sizeof(optval)) < 0) {
        fprintf(stderr,"Can't set sockopt; %s.\n",strerror(errno));
	exit(1);
    }
    p = argv[2];
    j = hex2(p);
    if (j < 0) {
    MACerror:
	fprintf(stderr,"Illegal MAC address: %s\n",argv[2]);
	exit(1);
    }
    mac[0] = j;
    p += 2;
    for (i=1; i < MACLEN; i++) {
	if (*p++ != ':') goto MACerror;
	j = hex2(p);
	if (j < 0) goto MACerror;
	mac[i] = j;
	p += 2;
    }
    p = buf;
    for (i=0; i < 6; i++) {	/* 6 bytes of FFhex */
	*p++ = 0xFF;
    }
    for (i=0; i < 16; i++) {	/* MAC addresses repeated 16 times */
	for (j=0; j < MACLEN; j++) {
	    *p++ = mac[j];
	}
    }
    len = p - buf;
#ifdef DEBUG
    for (i=0; i < len; i+=16) {
	for (j=0; j < 16; j++) {
	    if (i+j >= len) break;
	    printf(" %02x",buf[i+j]);
	}
	printf("\n");
    }
#endif
    if (sendto(sd,buf,len,0,
	       (struct sockaddr*)&sin,sizeof(sin)) != len) {
        fprintf(stderr,"Sendto failed; %s.\n",strerror(errno));
    }
    return (0);
}
