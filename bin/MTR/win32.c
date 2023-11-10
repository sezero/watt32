/*
 * Windows function for MTR.
 *
 * By G. Vanem <gvanem@yahoo.no>
 */
#if defined(_WIN32) && !defined(USE_WATT32) /* rest of file */
#include "config.h"
#include "win32.h"

#include <time.h>
#include <stdio.h>
#include <stdint.h>
#include <malloc.h>

#include <iphlpapi.h>

#if defined(USE_KERBEROS)
#include <wshelper.h>
#endif

extern const int debug;

#if defined(USE_KERBEROS)
/*
 * This stucture is NOT exported by Kerberos' 'bin/wshelper[32|64].dll'.
 * Add our own.
 */
struct state _res;
#endif

/*
 * Number of micro-seconds between the beginning of the Windows epoch
 * (Jan. 1, 1601) and the Unix epoch (Jan. 1, 1970).
 */
#define DELTA_EPOCH_IN_USEC  11644473600000000Ui64

static uint64_t FILETIME_to_unix_epoch (const FILETIME *ft)
{
  uint64_t res = (uint64_t) ft->dwHighDateTime << 32;

  res |= ft->dwLowDateTime;
  res /= 10;                   /* from 100 nano-sec periods to usec */
  res -= DELTA_EPOCH_IN_USEC;  /* from Win epoch to Unix epoch */
  return (res);
}

int gettimeofday (struct timeval *tv, void *tz_not_needed)
{
  FILETIME ft;
  uint64_t tim;

  if (!tv)
    return (-1);

  GetSystemTimePreciseAsFileTime (&ft);
  tim = FILETIME_to_unix_epoch (&ft);
  tv->tv_sec  = (long) (tim / 1000000L);
  tv->tv_usec = (long) (tim % 1000000L);
  (void) tz_not_needed;
  return (0);
}

static const char *h_errlist[] = {
  "Resolver Error 0 (no error)",
  "Unknown host",                    /* 1 HOST_NOT_FOUND */
  "Host name lookup failure",        /* 2 TRY_AGAIN */
  "Unknown server error",            /* 3 NO_RECOVERY */
  "No address associated with name", /* 4 NO_ADDRESS */
};

static int h_nerr = { sizeof h_errlist / sizeof h_errlist[0] };

#undef h_errno                  /* = WSAGetLastError() */
int h_errno;

/*
 * return the string associated with a given "host" errno value.
 */
const char *hstrerror (int err)
{
  if (err < 0)
     return ("Resolver internal error");
  if (err < h_nerr)
     return (h_errlist[err]);
  return ("Unknown resolver error");
}

/*
 * print the error indicated by the h_errno value.
 */
void herror (const char *s)
{
  fprintf (stderr, "%s: %s\n", s, hstrerror (h_errno));
}

#if !defined(USE_KERBEROS)
static u_long inet_aton (const char *name, struct in_addr *adr)
{
  u_long ip = INADDR_ANY;
  int    bytes[4];

  if (sscanf(name,"%d.%d.%d.%d", &bytes[0], &bytes[1], &bytes[2], &bytes[3]) == 4)
     ip = (bytes[0]) + (bytes[1] << 8) + (bytes[2] << 16) + (bytes[3] << 24	);
  if (adr)
     adr->s_addr = ip;
  return (ip);
}
#endif

static int get_netparams (struct in_addr *dns_srv, int max_srv)
{
  FIXED_INFO    *fi   = alloca (sizeof(*fi));
  DWORD          size = sizeof (*fi);
  DWORD (WINAPI *GetNetworkParams) (FIXED_INFO*, DWORD*);  /* available only on Win-98/2000+ */
  HMODULE        handle = LoadLibrary ("iphlpapi.dll");
  int            count  = 0;

  if (!handle)
  {
    if (debug)
       printf ("iphlpapi.dll not found\n");
    return (0);
  }

  GetNetworkParams = GetProcAddress (handle, "GetNetworkParams");
  if (!GetNetworkParams)
  {
    if (debug)
       printf ("iphlpapi.dll: GetNetworkParams() not found\n");
    return (0);
  }

  if ((*GetNetworkParams) (fi, &size) == ERROR_BUFFER_OVERFLOW)
  {
    struct in_addr addr;
    IP_ADDR_STRING *ipAddr;
    int i;

    fi = alloca (size);
    if ((*GetNetworkParams) (fi, &size) != ERROR_SUCCESS)
       return (0);

    if (debug)
    {
      printf ("Host Name: %s\n", fi->HostName);
      printf ("Domain Name: %s\n", fi->DomainName);
      printf ("DNS Servers:\n"
              "    %s (primary)\n", fi->DnsServerList.IpAddress.String);
    }
    if (inet_aton (fi->DnsServerList.IpAddress.String, &addr) != INADDR_ANY && max_srv >= 1)
       dns_srv [count++] = addr;

    for (i = 0, ipAddr = fi->DnsServerList.Next; ipAddr; ipAddr = ipAddr->Next, i++)
    {
      if (inet_aton (ipAddr->IpAddress.String, &addr) != INADDR_ANY && count < max_srv)
         dns_srv [count++] = addr;
      if (debug)
         printf ("    %s (secondary %d)\n", inet_ntoa(addr), i+1);
    }
  }
  return (count);
}

/*
 * Initialase the Resolve for either plain Windows2
 * or when using Kerberos' 'wshelp*.dll'.
 */
int win_dns_open (void)
{
  struct in_addr ns_addr [MAXNS];  /* max 3 srvr */
  struct servent *se = getservbyname ("domain", "udp");
  char  *env;
  int    i, num;
  WORD   ns_port = se ? se->s_port : htons (53);

  if (_res.nscount >= 1 &&  /* Trust that BIND has correct info */
      _res.nsaddr_list[0].sin_addr.s_addr != INADDR_ANY &&
      _res.nsaddr_list[0].sin_port != 0)
     return (1);

  env = getenv ("NAMESERVER");  /* fallback for Win9X/NT */
  num = 1;
  if (!env || inet_aton (env, &ns_addr[0]) == INADDR_ANY)
  {
    ns_addr[0].s_addr = INADDR_ANY;
    num = get_netparams (ns_addr, sizeof(ns_addr)/sizeof(ns_addr[0]));
    if (num <= 0)
    {
      fprintf (stderr, "No nameserver found. Define $NAMESERVER=a.b.c.d\n");
      exit (-1);
    }
  }
  for (i = 0; i < num; i++)
  {
    _res.nsaddr_list[i].sin_addr = ns_addr[i];
    _res.nsaddr_list[i].sin_port = ns_port;
  }
  _res.nscount = num;
  return (1);
}
#endif /* _WIN32 && !USE_WATT32 */

