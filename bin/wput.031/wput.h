#ifndef __WPUT_H
#define __WPUT_H

#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>

#if defined(_WIN32) && !defined(WATT32)
#include <winsock2.h>
#else
#include <sys/errno.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <netdb.h>
#endif

#if defined(WATT32)
  #include <tcp.h>
  #define CLOSE_SOCK close_s
#elif defined(_WIN32)
  #define CLOSE_SOCK closesocket
#else
  #define CLOSE_SOCK close
#endif

#if defined(_WIN32)
  #define sleep(s) Sleep(1000*(s))
#endif

#ifndef S_ISREG
#define S_ISREG(m) (((m) & S_IFMT) == S_IFREG)
#endif

#ifndef S_ISDIR
#define S_ISDIR(m) (((m) & S_IFMT) == S_IFDIR)
#endif

#define BUFLEN 4096
#define TBUFLEN 64
#define ULEN 32
#define PLEN 64
#define FNLEN 512

struct file_timestamp{
  int year;
  int month;
  int day;
  int hour;
  int minute;
  int second;
};

struct ftp_session{

  char sbuf[BUFLEN];
  char rbuf[BUFLEN];
  char tmpbuf[TBUFLEN];

  int csock;    /* ftp client socket */
  int s_socket; /* port mode client server socket */
  int data_socket; /* data socket */

  char user[ULEN];
  char pass[PLEN];
  char shname[64];
  char ip[32];
  int  sftpport;

  char client_ip[32];

  char local_dname[FNLEN];
  char local_fname[FNLEN];
  char target_rdname[FNLEN]; /* target root directory name */
  char target_dname[FNLEN];
  char target_fname[FNLEN];

  long long local_fsize;
  long long target_fsize;

  struct file_timestamp local_ftime;
  struct file_timestamp target_ftime;

  int retry;
  int _retry;
  int retry_interval;
  int passive_mode;
  int proxy;
  int resume;
  int binary;
  int speed_limit;
  int force;
  int overwrite;
  int done;
  int debug_mode;

/*   int retry = 0; */
/*   int retry_interval = 1; */ /* in minute */
/*   int passive_mode = 1;  */
/*   int proxy = 0; */
/*   int resume = 1; */
/*   int binary = 1; */
/*   int speed_limit = 0; */
/*   int debug_mode = 0; */

};

extern struct ftp_session fsession;

int start_recur_ftp (char * dname);

static const char * version = "0.3.1";
static const char * author = "afei@jhu.edu";

#endif
