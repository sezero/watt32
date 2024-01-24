/*
 * Test program for this issue:
 *   https://github.com/gvanem/Watt-32/issues/92
 */

/* Compile for DOS4G (Open Watcom) with
 * `WCC386 -3 -bt=dos -dWATT32=1 -i=INC -mf ECHOTEST` then
 * `WLINK SYS dos4g LIBF LIB\WATTCPWF.LIB F ECHOTEST`
 *
 * Compile for Linux with
 * `gcc echotest.c`
 *
 * Use `nc 127.0.0.1 12345` on a Linux machine to connect
 * then SIGINT (Ctrl + C) nc to initate a TCP RST from the client
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef _MSC_VER
#include <unistd.h>
#endif

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>

#ifdef WATT32
  #include <tcp.h>
  #define close(s) closesocket (s)
#endif

#define PORT        12345
#define BUFFER_SIZE 1024

void print_socket_info (int client_socket, const char *action)
{
  struct sockaddr_in client_info;
  socklen_t          client_info_len = sizeof(client_info);

  if (getpeername(client_socket, (struct sockaddr*)&client_info, &client_info_len) == 0)
       printf ("%s: %s:%d\n", action, inet_ntoa (client_info.sin_addr), htons (client_info.sin_port));
  else printf ("%s: was socket %d (unfortunetly that's all we know)\n", action, client_socket);
}

void handle_client (int client_socket)
{
  char buffer [BUFFER_SIZE];
  int  bytes_received;

  while (1)
  {
    bytes_received = recv (client_socket, buffer, sizeof(buffer), 0);
    if (bytes_received == -1)
    {
      print_socket_info (client_socket, "Error receiving data");
      break;
    }
    if (bytes_received == 0)
    {
      print_socket_info (client_socket, "Connection closed by client");
      break;
    }
    else
    {
      send (client_socket, buffer, bytes_received, 0);
      print_socket_info (client_socket, "Echoed data back to client");
    }
  }
}

int main (void)
{
  struct sockaddr_in server_addr, client_addr;
  int       server_socket, client_socket;
  socklen_t client_len = sizeof (client_addr);

#ifdef WATT32
  dbug_init();
  sock_init();
#endif

  server_socket = socket (AF_INET, SOCK_STREAM, 0);
  if (server_socket < 0)
  {
    perror ("Error creating socket");
    exit (EXIT_FAILURE);
  }

  memset (&server_addr, 0, sizeof(server_addr));
  server_addr.sin_family = AF_INET;
  server_addr.sin_addr.s_addr = INADDR_ANY;
  server_addr.sin_port = htons (PORT);

  if (bind (server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1)
  {
    perror ("Error binding socket");
    exit (EXIT_FAILURE);
  }

  if (listen(server_socket, 5) == -1)
  {
    perror ("Error listening for connections");
    exit (EXIT_FAILURE);
  }

#ifdef WATT32
  client_addr.sin_addr.s_addr = htonl (my_ip_addr);
  printf ("Server listening on %s:%d...\n", inet_ntoa (client_addr.sin_addr), PORT);
#else
  printf ("Server listening on port %d...\n", PORT);
#endif

  while (1)
  {
    client_socket = accept (server_socket, (struct sockaddr*)&client_addr, &client_len);
    if (client_socket < 0)
    {
      perror ("Error accepting connection");
      continue;
    }

    print_socket_info (client_socket, "Accepted connection");
    handle_client (client_socket);
    close (client_socket);
  }
  close (server_socket);
  return (0);
}
