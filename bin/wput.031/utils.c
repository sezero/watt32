#include "wput.h"
#include "utils.h"


void Abort(char * msg){
  fprintf(stderr, "%s", msg);
  exit(1);
}

void Debug(const char * fmt, ...)
{
  const char *p;
  va_list argp;
  int i;
  char *s;
  char fmtbuf[256];

  if (!fsession.debug_mode)
     return;

  va_start(argp, fmt);

  for(p = fmt; *p != '\0'; p++)
    {
      if(*p != '%')
	{
	  putchar(*p);
	  continue;
	}

      switch(*++p)
	{
	case 'c':
	  i = va_arg(argp, int);
	  putchar(i);
	  break;

	case 'l':
	case 'd':
	  i = va_arg(argp, int);
	  s = itoa(i, fmtbuf, 10);
	  fputs(s, stdout);
	  break;

	case 's':
	  s = va_arg(argp, char *);
	  fputs(s, stdout);
	  break;

	case 'x':
	  i = va_arg(argp, int);
	  s = itoa(i, fmtbuf, 16);
	  fputs(s, stdout);
	  break;

	case '%':
	  putchar('%');
	  break;
	}
  }
  va_end(argp);
}

int get_ip_addr(char* hostname, char * ip)
{
  struct hostent *ht = gethostbyname(hostname);

  if (ht)
  {
    sprintf(ip, "%d.%d.%d.%d", (unsigned char)ht->ipaddr[0],
            (unsigned char)ht->ipaddr[1],
            (unsigned char)ht->ipaddr[2],
            (unsigned char)ht->ipaddr[3]);
    if (fsession.debug_mode)
       printf("Translating %s to %s\n", hostname, ip);
    return 0;
  }
  return -1;
}

int create_new_reply_sockfd(const char * hostname, const int c_port){

  int c_sock;
  struct sockaddr_in remote_addr;


  memset (&remote_addr, '\0', sizeof(remote_addr));
  remote_addr.sin_family        =AF_INET;
  remote_addr.sin_addr.s_addr=inet_addr(hostname);
  remote_addr.sin_port  =htons(c_port);
  /*
   * Open a TCP socket(an internet stream socket).
   */

  if( (c_sock = socket(AF_INET,SOCK_STREAM,0)) < 0)
    perror("client: can't open stream socket");
  /*
   * Connect to the server
   */
  if(connect(c_sock,(struct sockaddr *)&remote_addr,sizeof(remote_addr)) <0)
    perror("client: can't bind to local address");
  Debug("Connection to remote server established.\n");

  return c_sock;

}

int initialize_server_master(int * s_sock, int * s_port){

  struct sockaddr_in serv_addr;

  /*
   * Open a TCP socket(an Internet STREAM socket)
   */
  if ((*s_sock =socket(AF_INET, SOCK_STREAM, 0))<0)
    perror("server: can't open new socket");
  /*
   * Bind out local address so that the client can send to us
   */
  memset (&serv_addr, '\0', sizeof(serv_addr));
  serv_addr.sin_family            =AF_INET;
  serv_addr.sin_port              =htons(*s_port);
  serv_addr.sin_addr.s_addr       =htonl(INADDR_ANY);
  /*
   * Defined in sys/socket.h 0x00000000
   */
  if(bind(*s_sock,(struct sockaddr *)&serv_addr,sizeof(serv_addr)) <0){
    perror("server:can't bind local address");
    exit(0);
  }
  if (!*s_port)
    {
      /* #### addrlen should be a 32-bit type, which int is not
         guaranteed to be.  Oh, and don't try to make it a size_t,
         because that can be 64-bit.  */
      int addrlen = sizeof (struct sockaddr_in);
      if (getsockname (*s_sock, (struct sockaddr *)&serv_addr, &addrlen) < 0)
        {
          CLOSE_SOCK (*s_sock);
	  	  Debug("Failed to open server socket.\n");
          return -1;
        }
      *s_port = ntohs (serv_addr.sin_port);
    }

  /* install a signal handler to clean up if user interrupt the server */
  /* sighandler(*s_sock); */
  listen(*s_sock, 1);
  Debug("Server socket ready to accept client connection.\n");

  return 0;
}

int create_data_sockfd(int s_sock){
  int newsockfd, clilen;
  struct sockaddr_in client_addr;

  clilen = sizeof( client_addr);
  newsockfd = accept(s_sock, (struct sockaddr *)&client_addr, &clilen);
  if(newsockfd == -1){
    perror("accept error");
    exit(-1);
  }
  Debug("Server socket accepted new connection from requesting client.\n");
  return newsockfd;

}

int get_local_ip(int sockfd, char * local_ip){
  struct sockaddr_in mysrv;
  struct sockaddr *myaddr;
  int addrlen = sizeof (mysrv);
  myaddr = (struct sockaddr *) (&mysrv);
  if (getsockname (sockfd, myaddr, (int *)&addrlen) < 0)
    return -1;
  memcpy (local_ip, &mysrv.sin_addr, 4);
  return 0;
}

#if defined(WIN32) && !defined(WATT32)
#include <windows.h>

/*
 * Number of micro-seconds between the beginning of the Windows epoch
 * (Jan. 1, 1601) and the Unix epoch (Jan. 1, 1970).
 */
#if defined(_MSC_VER) || defined(__WATCOMC__)
#define EPOCH_FILETIME 11644473600000000Ui64
#else
#define EPOCH_FILETIME 11644473600000000ULL
#endif

int gettimeofday(struct timeval *tv, void *timezone_not_used)
{
    FILETIME        ft;
    LARGE_INTEGER   li;
    __int64         t;

    if (tv)
    {
        GetSystemTimeAsFileTime(&ft);
        li.LowPart  = ft.dwLowDateTime;
        li.HighPart = ft.dwHighDateTime;
        t  = li.QuadPart / 10;   /* In micro-second intervals */
        t -= EPOCH_FILETIME;     /* Offset to the Epoch time */
        tv->tv_sec  = (long)(t / 1000000);
        tv->tv_usec = (long)(t % 1000000);
    }
    (void) timezone_not_used;
    return 0;
}
#endif