#include  "portable.h"
#include  "ntp.h"

unsigned long ntp_time(void *v)
{
	struct ntp_packet	*p = (struct ntp_packet *)v;

	/* valid NTP packet? */
	if ((p->livnmode & 0x1f) == ((NTPV3 << 3) | BROADCAST)
		|| (p->livnmode & 0x1f) == ((NTPV4 << 3) | BROADCAST))
		return((u_int32_t)ntohl(p->transmit.secs) - OFFSET1900);
	return (0);
}
