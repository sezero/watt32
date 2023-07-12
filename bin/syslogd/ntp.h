
#ifndef __SYS_WTYPES_H
typedef unsigned long   u_int32_t;
#endif

#include <sys/pack_on.h>

typedef struct timestamp
{
	u_int32_t	secs;
	u_int32_t	decsecs;
} timestamp;

struct ntp_packet
{
	unsigned char	livnmode;
	unsigned char	stratum;
	unsigned char	poll;
	signed char	precision;
	u_int32_t	rootdelay;
	u_int32_t	rootdispersion;
	u_int32_t	refclockid;
	timestamp	reference;
	timestamp	originate;
	timestamp	receive;
	timestamp	transmit;
};

#include <sys/pack_off.h>

#define	OFFSET1900	(86400UL*(365UL*70UL+17UL))

#define	NTPV3		3
#define	NTPV4		4
#define	BROADCAST	5
