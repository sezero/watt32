/*
 * Rewritten sample from:
 *   https://learn.microsoft.com/en-us/windows/win32/api/lmserver/nf-lmserver-netservergetinfo
 */
#define _UNICODE  /* This must be Unicode since 'LMSTR == wchar_t'! */

#include <stdio.h>
#include <windows.h>
#include <lm.h>

#ifdef _MSC_VER
#pragma comment(lib, "netapi32.lib")
#endif

static NET_API_STATUS nStatus;
static LMSTR          pszServerName = NULL;

static BOOL get_level_100 (void)
{
  SERVER_INFO_100 *pBuf = NULL;

  nStatus = NetServerGetInfo (pszServerName, 101, (LPBYTE*)&pBuf);
  if (nStatus == NERR_Success)
     printf ("Id: %lu, %ws\n", pBuf->sv100_platform_id, pBuf->sv100_name);

  if (pBuf)
     NetApiBufferFree (pBuf);
  return (nStatus == NERR_Success);
}


static BOOL get_level_101 (void)
{
  SERVER_INFO_101 *pBuf = NULL;

  nStatus = NetServerGetInfo (pszServerName, 101, (LPBYTE*)&pBuf);
  if (nStatus == NERR_Success)
  {
     if ((pBuf->sv101_type & SV_TYPE_DOMAIN_CTRL) ||
         (pBuf->sv101_type & SV_TYPE_DOMAIN_BAKCTRL) ||
         (pBuf->sv101_type & SV_TYPE_SERVER_NT))
          printf ("This is a server\n");
     else printf ("This is a workstation\n");
  }
  if (pBuf)
     NetApiBufferFree (pBuf);
  return (nStatus == NERR_Success);
}

static BOOL get_level_102 (void)
{
  SERVER_INFO_102 *pBuf = NULL;

  nStatus = NetServerGetInfo (pszServerName, 102, (LPBYTE*)&pBuf);
  if (nStatus == NERR_Success)
     printf ("Ver: %lu.%lu. Type: 0x%08lX, comment: '%ws', users: %lu, userpath: %ws.\n",
              pBuf->sv102_version_major, pBuf->sv102_version_minor, pBuf->sv102_type,
              pBuf->sv102_comment, pBuf->sv102_users, pBuf->sv102_userpath);

  if (pBuf)
     NetApiBufferFree (pBuf);
  return (nStatus == NERR_Success);
}

int wmain (int argc, wchar_t **argv)
{
  if (argc > 2)
  {
     fwprintf (stderr, L"Usage: %s [\\\\ServerName]\n", argv[0]);
     return (1);
  }
  if (argc == 2)
     pszServerName = argv[1];

  if (!get_level_100())
     fprintf (stderr, "get_level_100() failed: %lu\n", nStatus);

  if (!get_level_101())
     fprintf (stderr, "get_level_101() failed: %lu\n", nStatus);

  if (!get_level_102())
     fprintf (stderr, "get_level_102() failed: %lu\n", nStatus);

  return (0);
}
