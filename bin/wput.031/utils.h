#ifndef __UTILS_H
#define __UTILS_H

#include "wput.h"
#include <stdarg.h>

#define ipaddr h_addr_list[0]

void Abort(char * msg);
void Debug(const char * fmt, ...);

int create_new_reply_sockfd(const char * hostname, const int c_port);
int get_ip_addr (char* hostname, char *ip);
int get_local_ip (int sockfd, char *ip);
int initialize_server_master(int * s_sock, int * s_port);
int create_data_sockfd(int s_sock);

#if defined(_WIN32) && !defined(WATT32)
int gettimeofday(struct timeval *tv, void *timezone_not_used);
#endif

#endif
