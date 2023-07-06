#include "ftp.h"
#include "wput.h"
#include "utils.h"

void do_quit()
{
  send_msg(fsession.csock, "QUIT\r\n");
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  CLOSE_SOCK(fsession.s_socket);
  CLOSE_SOCK(fsession.data_socket);
  CLOSE_SOCK(fsession.csock);
}

void do_abrt()
{
  send_msg(fsession.csock, "ABRT\r\n");
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  CLOSE_SOCK(fsession.csock);
}

int do_login()
{
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  fill_cmd("USER", fsession.user);
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] == '2') get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '3') return -1;

  Debug("---->PASS ******\n");
  fill_cmd("PASS", fsession.pass);
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '2') return -1;

  sprintf(fsession.sbuf, "SYST\r\n");
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);

  fill_cmd("TYPE", "I");
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);

  fill_cmd("REST", "100");
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '3') fsession.resume = 0;

  fill_cmd("REST", "0");
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);

  return 0;
}

int try_do_cwd()
{
  char tmpbuf[FNLEN];
  char * ptr;

  fill_cmd("CWD", "/");
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '2') return -1; /* cannot even change dir to root dir */

  strncpy(tmpbuf, fsession.target_dname, FNLEN);
  ptr = strtok(tmpbuf, "/");
  if(ptr != 0x0){

    fill_cmd("CWD", ptr);
    send_msg(fsession.csock, fsession.sbuf);
    get_msg(fsession.csock, fsession.rbuf, BUFLEN);
    if(fsession.rbuf[0] != '2'){
      fill_cmd("MKD", ptr);
      send_msg(fsession.csock, fsession.sbuf);
      get_msg(fsession.csock, fsession.rbuf, BUFLEN);
      if(fsession.rbuf[0] != '2') return -1;

      fill_cmd("CWD", ptr);
      send_msg(fsession.csock, fsession.sbuf);
      get_msg(fsession.csock, fsession.rbuf, BUFLEN);
      if(fsession.rbuf[0] != '2') return -1;
    }


    while( (ptr = strtok(0x0, "/")) != 0x0){
      fill_cmd("CWD", ptr);
      send_msg(fsession.csock, fsession.sbuf);
      get_msg(fsession.csock, fsession.rbuf, BUFLEN);
      if(fsession.rbuf[0] != '2'){
	fill_cmd("MKD", ptr);
	send_msg(fsession.csock, fsession.sbuf);
	get_msg(fsession.csock, fsession.rbuf, BUFLEN);
	if(fsession.rbuf[0] != '2') return -1;

	fill_cmd("CWD", ptr);
	send_msg(fsession.csock, fsession.sbuf);
	get_msg(fsession.csock, fsession.rbuf, BUFLEN);
	if(fsession.rbuf[0] != '2') return -1;
      }
    }
  }
  return 0;
}

int do_cwd()
{
  fill_cmd("CWD", fsession.target_dname);
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '2') return -1;

  return 0;
}

int do_size()
{
  if (fsession.overwrite)
     return -1;

  fill_cmd("SIZE", fsession.target_fname);
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] == '5') fsession.target_fsize = 0;
  if(fsession.rbuf[0] == '2')
    fsession.target_fsize = strtol((char *)fsession.rbuf + 4, NULL, 0);
  Debug("Remote filesize: %d\n", fsession.target_fsize);

  if(fsession.target_fsize < fsession.local_fsize && fsession.resume){
    fill_cmd("REST", itoa(fsession.target_fsize, (char *)fsession.tmpbuf, 10));
    send_msg(fsession.csock, fsession.sbuf);
    get_msg(fsession.csock, fsession.rbuf, BUFLEN);
    if(fsession.rbuf[0] != '3')
      Debug("Server doesn't support resume. Restarting at 0\n");
  }
  return 0;
}

int create_data_socket()
{
  int res = 0;

  if( fsession.passive_mode == 1){
    res = do_passive();
    if(res == -1){ /* revert back to port mode if passive mode fails */
      res = do_port();
      if(res == -1) return res;
    }
  }
  else{
    res = do_port();
    if(res == -1){ /* revert back to passive mode if port mode fails */
      res = do_passive();
      if(res == -1) return res;
    }
  }
  return res;
}

static double
_timeval_diff (const struct timeval *newer, const struct timeval *older)
{
  long d_sec  = (long)newer->tv_sec - (long)older->tv_sec;
  long d_usec = newer->tv_usec - older->tv_usec;
  return (1E6 * (double)d_sec + (double)d_usec);
}

int do_send()
{
#define DBUFSIZE 4096
  int fd;
  char databuf[DBUFSIZE];
  int readbytes = 0;
  int res = 0;
  long transfered_size = 0;
  long last_transfered_size = 0;
  double msec;
  struct timeval start, stop;

#if 0 /* WTF! Why should this matter? Do such broken ftp-servers still exists? */
  if(fsession.target_fsize >= fsession.local_fsize){
    Debug("Remote file size is larger or equal than local size. Finish upload.\n");
    fsession.done = 1;
    return 0;
  }
#endif

  res = create_data_socket();
  if(res == -1){
    fprintf(stderr, "Cannot create data socket");
    return -1;
  }

  if((fd=open(fsession.local_fname, O_RDONLY|O_BINARY)) == -1) {
    fprintf(stderr, "Can't open local source file to read");
    return -1;
  }

  gettimeofday(&start, NULL);

  printf("File is being uploaded, please wait...\n");
  memset (&databuf, '\0', DBUFSIZE);
  while( ( readbytes = read(fd, (char *)databuf, DBUFSIZE)) != 0 ){
    if( readbytes == -1){
      fprintf(stderr, "Error reading local file");
      return -1;
    }

    transfered_size += readbytes;

    res = send(fsession.data_socket, databuf, readbytes, 0);
    if(res != readbytes){
      fprintf(stderr, "Error encountered during uploading data");
      do_abrt();
      return -1;
    }
    printf ("%.0f%%\r", 100 * (double)transfered_size / (double)fsession.local_fsize);
    fflush(stdout);
  }

  gettimeofday(&stop, NULL);
  msec = _timeval_diff (&stop,&start) / 1000.0;
  if (msec == 0.0)
     msec = 1.0;
  printf("\t%12d bytes, %.2f kByte/s [Upload finished]\n",
         transfered_size, (double)transfered_size / msec);

  close(fd);
  CLOSE_SOCK(fsession.data_socket);

  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '2') res = -1;
  if(transfered_size == fsession.local_fsize) fsession.done = 1, res = 0;

  return res;
}

int do_passive()
{
  char * resp, * ptr;
  int ntok = 0, nlen = 0;
  int sport = 0, n1;

  fill_cmd("PASV", NULL);
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '2') return -1;

  resp = (char *)fsession.rbuf;
  ptr = strtok(resp, ",");
  while ( ((ptr = strtok(0x0, ",")) != 0x0) && ntok < 3)
    ntok ++;
  sport = atoi(ptr);
  if( (ptr = strtok(0x0, ",")) != 0x0){ /* one more token */
    n1 = atoi(ptr);
    sport = ((sport << 8) & 0xff00) +n1;
  }

  Debug("Remote server data port: %d\n", sport);
  fsession.data_socket = create_new_reply_sockfd(fsession.ip, sport);


  fill_cmd("STOR", fsession.target_fname);
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '1') return -1;

  return 0;
}

int do_port()
{
  int sport = 0, i;
  char portbuf[64];
  initialize_server_master(&fsession.s_socket, &sport);

  sprintf(portbuf, "%d,%d,%d,%d,%d,%d", fsession.client_ip[0]&0xff,fsession.client_ip[1]&0xff,fsession.client_ip[2]&0xff,fsession.client_ip[3]&0xff, (unsigned) (sport & 0xff00) >> 8, (unsigned) sport & 0x00ff);

  fill_cmd("PORT", portbuf);
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '2') return -1;

  fill_cmd("STOR", fsession.target_fname);
  send_msg(fsession.csock, fsession.sbuf);
  get_msg(fsession.csock, fsession.rbuf, BUFLEN);
  if(fsession.rbuf[0] != '1') return -1;

  fsession.data_socket = create_data_sockfd(fsession.s_socket);
  CLOSE_SOCK(fsession.s_socket);
  return 0;
}


int send_msg(int csock, char * msg){
  if(strncmp(msg, "PASS", 4) != 0)
    Debug("---->%s", msg);
  return send(csock, msg, strlen(msg), 0);
}

int get_msg(int csock, char * msg, int buflen){
  int res = 0;
  memset (msg, '\0', buflen);
  res = recv(csock, msg, buflen-1, 0);
  Debug("%s", msg);
  return res;
}

int fill_cmd(char * cmd, char * value){
  if( value != NULL && (strlen(cmd)+strlen(value)+1) > BUFLEN) {
    fprintf(stderr, "Invalid argument");
    return -1;
  }
  if(value == NULL)
    sprintf ((char *)fsession.sbuf, "%s\r\n", cmd);
  else
    sprintf ((char *)fsession.sbuf, "%s %s\r\n", cmd, value);
  return 0;
}


