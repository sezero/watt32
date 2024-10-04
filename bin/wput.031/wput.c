#include <sys/types.h>

#include "wput.h"
#include "ftp.h"
#include "utils.h"
#include "getopt.h"

int start_fsession();
int start_ftp();

struct ftp_session fsession;

char * main_menu = "wput options:\n"
"\t-u)* user name\n"
"\t-p)* password\n"
"\t-t) turn on port mode ftp (default is passive mode)\n"
"\t-h)* server hostname\n"
"\t-i)* input filename (to be uploaded, recursive mode for directory)\n"
"\t-d)* target directory name (storage location on server)\n"
"\t-r) retry count (0 means infinite, default infinite)\n"
"\t-w) retry wait interval in minute (default 1)\n"
"\t-f) force wput not to be aggressive (default is aggressive)\n"
"\t-m) do not resume upload (default is always resume)\n"
"\t-o) overwrite remote file even if same size as local\n"
"\t-D) debug mode\n"
"\t-v) version\n"
"\t* are required command line options\n";

int main(int argc, char *argv[])
{
  return start_fsession(argc, argv);
}

int start_fsession(int argc, char * argv[]){
  char tmpbuf[FNLEN];
  int c, len;
  struct stat statbuf;
  int res = 0;
  int i_flag = 0;
  int d_flag = 0;

#if defined(_WIN32) && !defined(WATT32)
  WSADATA wsaData;
  WORD    wVersionRequested = MAKEWORD(1, 1);

  if (WSAStartup (wVersionRequested, &wsaData) != 0)
  {
    perror ("Cannot initialise Winsock");
    return (-1);
  }
#endif

  memset (&fsession,0,sizeof(fsession));
  fsession.passive_mode = 1;
  fsession.retry = -1;
  fsession._retry = -1;
  fsession.retry_interval = 1;
  fsession.force = 1;
  fsession.resume = 1;

  while (( c = getopt(argc, argv, "u:p:th:i:d:w:r:mofDv")) != -1) {
    switch(c) {
    case 'u':
      if(strlen(optarg) > ULEN) Abort("user name too long");
      strncpy(fsession.user, optarg, strlen(optarg));
      break;
    case 'p':
      if(strlen(optarg) > PLEN) Abort("user name too long");
      strncpy(fsession.pass, optarg, strlen(optarg));
      break;
    case 't':
      fsession.passive_mode = 0;
      break;
    case 'h':
      res = get_ip_addr(optarg, (char *)fsession.ip);
      if(res == -1) Abort("Cannot determinete remote host ip addr");
      break;
    case 'i':
      if(optarg != 0x0)
		res = stat(optarg, &statbuf);
      else res = -1;
	  i_flag = 1;
      if(res == 0)
      {
		if( S_ISREG(statbuf.st_mode) )
		{
	  	  strncpy(fsession.local_fname, optarg, strlen(optarg) < FNLEN ? strlen(optarg) : FNLEN);
	  	  if(strchr(optarg, '/') != 0x0)
	  	  {
	    	char * ptr = strrchr(optarg, '/');
	    	ptr = ptr+1;
	    	if (ptr != NULL)
	    		strncpy(fsession.target_fname, ptr, (strlen(ptr) < FNLEN) ? strlen(ptr) : FNLEN);
 	     }
	     else
	      strncpy(fsession.target_fname, optarg, strlen(optarg) < FNLEN ? strlen(optarg) : FNLEN);

 	     /* Debug("Resolved local file name: %s\n", fsession.target_fname); */

	     fsession.local_fsize = statbuf.st_size;
	     Debug("Local file: %s (%l)\n", fsession.local_fname, fsession.local_fsize);
	   }
	   else if( S_ISDIR(statbuf.st_mode) )
	   {
	     strncpy(fsession.local_dname, optarg, strlen(optarg) < FNLEN ? strlen(optarg) : FNLEN);
	   }
     }
     else
       Abort("Cannot stat local file!");
      break;

    case 'd':
      memset (&fsession.target_dname, '\0', FNLEN);
      memset (&fsession.target_rdname, '\0', FNLEN);
      strncpy(fsession.target_dname, optarg, strlen(optarg) < FNLEN ? strlen(optarg) : FNLEN);
      strncpy(fsession.target_rdname, optarg, strlen(optarg) < FNLEN ? strlen(optarg) : FNLEN);
      len = strlen(fsession.target_dname);
      if(fsession.target_dname[len-1] != '/'){
	fsession.target_dname[len] = '/';
	fsession.target_rdname[len] = '/';
      }
      d_flag = 1;
      break;
    case 'r':
      fsession.retry = atoi(optarg);
      if(fsession.retry <= 0) fsession.retry = -1;
      fsession._retry = fsession.retry;
      break;
    case 'w':
      fsession.retry_interval = atoi(optarg);
      break;
    case 'm':
      fsession.resume = 0;
      break;
    case 'o':
      fsession.overwrite = 1;
      break;
    case 'f':
      fsession.force = 0;
      break;
    case 'v':
      printf("wput version: %s\n", version);
      exit(0);
    case 'D':
#ifdef WATT32
      dbug_init();
#endif
      fsession.debug_mode = 1;
      break;
    default:
      fprintf(stderr, "usage: %s\n", main_menu);
      exit(0);
      break;
    }
  }

  if (!fsession.pass[0] || !fsession.ip[0] || !i_flag || !d_flag)
  {
    fprintf(stderr, "usage: %s", main_menu);
    return(0);
  }

  if (S_ISREG(statbuf.st_mode))
     return start_ftp();
  if (S_ISDIR(statbuf.st_mode))
    return start_recur_ftp(fsession.local_dname);
  return 0;
}

int start_recur_ftp(char * dname){

  int res = 0;
  char tmpbuf[FNLEN], fname[FNLEN];
  struct stat statbuf;
  struct dirent * dent;
  DIR * ldir;

  memset (&tmpbuf, '\0', FNLEN);
  memset (&fname, '\0', FNLEN);

  strncpy(tmpbuf, dname, strlen(dname) < FNLEN ? strlen(dname) : FNLEN);
  if (dname[strlen(dname)] != '/')
     tmpbuf[strlen(tmpbuf)] = '/';
  if ((ldir = opendir(dname)) != 0x0)
  {
    while ((dent = readdir(ldir)) != 0x0)
    {
      Debug("Dir entry name: %s\n", dent->d_name);
      if (strncmp(dent->d_name, ".", 1) == 0 || strncmp(dent->d_name, "..", 2) == 0)
      	 continue;

      sprintf(fname, "%s%s", tmpbuf, dent->d_name);
      if (stat(fname, &statbuf) == 0)
      {
		if ( S_ISREG(statbuf.st_mode) )
		{
	  	  memset (&fsession.local_fname, '\0', FNLEN);
	  	  memset (&fsession.target_fname, '\0', FNLEN);
	  	  memset (&fsession.target_dname, '\0', FNLEN);

	  	  strncpy(fsession.local_fname, fname, strlen(fname) < FNLEN ? strlen(fname) : FNLEN);
	  	  fsession.local_fsize = statbuf.st_size;
	  	  strncpy(fsession.target_fname, dent->d_name, strlen(dent->d_name) < FNLEN ?
	  			strlen(dent->d_name) : FNLEN);
	  	  sprintf(fname, "%s%s", fsession.target_rdname, dname);
	  	  strncpy(fsession.target_dname, fname, strlen(fname) < FNLEN ? strlen(fname) : FNLEN);
	  	  fsession.done = 0;
	  	  fsession.retry = fsession._retry;
	  	  start_ftp();
	  	  sleep(3);
	    }
	    else if (S_ISDIR(statbuf.st_mode))
	    {
	  	  start_recur_ftp(fname);
	    }
      }
      else
	    fprintf(stderr, "Error encountered but ignored during stat:%s\n", fname);
    }
    closedir(ldir);
  }
  else
    fprintf(stderr, "Error encountered but ignored during opendir:%s\n", fname);

  return 0;
}


int start_ftp()
{
  int res = 0;
  /* we don't do any GUI interactive stuff, so we can afford a simpler flow of command
     sequence */
  Debug("%s : %s : %s : %s : %s\n", fsession.local_dname, fsession.local_fname, fsession.target_rdname, fsession.target_dname, fsession.target_fname);
  printf("Upload %s to %s\n", fsession.local_fname, fsession.ip);
  while(!fsession.done && ( fsession.retry > 0 || fsession.retry == -1) ){

    if(fsession.retry != -1) fsession.retry --;

    fsession.csock = create_new_reply_sockfd(fsession.ip, 21);
    res = get_local_ip(fsession.csock, (char *)fsession.client_ip);
    if(res == -1) Abort("Cannot determine local IP address");
    Debug("Local IP: %d.%d.%d.%d\n", fsession.client_ip[0]&0xff,fsession.client_ip[1]&0xff,fsession.client_ip[2]&0xff,fsession.client_ip[3]&0xff);

    res = do_login();
    if( res == -1){
	    do_quit();
	    fprintf(stderr, "Waiting to restart...\n");
	    sleep(fsession.retry_interval*60);
	    continue;
    }
    res = do_cwd();
    if( res == -1 && fsession.force )
      if( try_do_cwd() == -1)
	Abort("Failed to change to target directory");

    res = do_size();
    if(res == -1) fsession.target_fsize = 0;

    res = do_send();
    if( res == -1) {
	    fprintf(stderr, "Waiting to restart...\n");
	    sleep(fsession.retry_interval*60);
	    continue;
    }

    do_quit();

  } /* while */
  return res;
}
