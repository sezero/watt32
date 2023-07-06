#ifndef __FTP_H
#define __FTP_H


int start_ftp();
int send_msg(int csock, char * msg);
int get_msg(int csock, char * msg, int buflen);
int fill_cmd(char * cmd, char * value);

int do_login();
int do_cwd();
int do_size();
int do_send();
int create_data_socket();
int do_port();
int do_passive();
void do_quit();
int try_do_cwd();

#endif
