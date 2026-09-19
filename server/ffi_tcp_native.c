/*
 * Tiny TCP shim for the MoonBit native backend (tiny-httpd).
 *
 * Self-contained on purpose: on Windows the winsock2 functions are
 * resolved at runtime through LoadLibrary, so no platform needs extra
 * link flags (-lws2_32 etc.) and the same moon.pkg works everywhere.
 *
 * Copyright (C) 2026 tiny-httpd-moonbit contributors.
 * Licensed under the GNU GPL v2 or later; see LICENSE.
 */

#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>
#endif

#ifdef _WIN32
/* Minimal winsock2 definitions (avoid depending on winsock headers). */
#define TT_AF_INET 2
#define TT_SOCK_STREAM 1
#define TT_SOL_SOCKET 0xFFFF
#define TT_SO_REUSEADDR 4

typedef long (WINAPI *tt_recv_t)(unsigned int, char *, int, int);
typedef long (WINAPI *tt_send_t)(unsigned int, const char *, int, int);
typedef unsigned int (WINAPI *tt_socket_t)(int, int, int);
typedef int (WINAPI *tt_bind_t)(unsigned int, const void *, int);
typedef int (WINAPI *tt_listen_t)(unsigned int, int);
typedef unsigned int (WINAPI *tt_accept_t)(unsigned int, void *, int *);
typedef int (WINAPI *tt_closesocket_t)(unsigned int);
typedef int (WINAPI *tt_wsastartup_t)(unsigned short, void *);
typedef int (WINAPI *tt_setsockopt_t)(unsigned int, int, int, const char *,
                                      int);

static void *tt_ws2(void) {
  static void *handle = NULL;
  if (handle == NULL) {
    handle = (void *)LoadLibraryA("ws2_32.dll");
  }
  return handle;
}

static void *tt_fn(const char *name) {
  void *lib = tt_ws2();
  if (lib == NULL) {
    return NULL;
  }
  return (void *)GetProcAddress((HMODULE)lib, name);
}

static unsigned short tt_htons(unsigned short v) {
  return (unsigned short)(((v & 0xFF) << 8) | ((v >> 8) & 0xFF));
}

/* struct sockaddr_in layout: family(2) port(2) addr(4) zero(8) */
static int tt_bind_addr(int sock, unsigned short port) {
  char addr[16];
  memset(addr, 0, sizeof(addr));
  addr[0] = (char)(TT_AF_INET & 0xFF);
  addr[1] = 0;
  addr[2] = (char)((port >> 8) & 0xFF);
  addr[3] = (char)(port & 0xFF);
  /* INADDR_ANY = 0.0.0.0 stays all zero */
  tt_bind_t bind_fn = (tt_bind_t)tt_fn("bind");
  if (bind_fn == NULL) {
    return -1;
  }
  return bind_fn((unsigned int)sock, addr, (int)sizeof(addr));
}
#endif

int tinyhttpd_socket_open(int port) {
#ifdef _WIN32
  static int started = 0;
  if (!started) {
    tt_wsastartup_t startup = (tt_wsastartup_t)tt_fn("WSAStartup");
    char data[512];
    if (startup != NULL) {
      memset(data, 0, sizeof(data));
      startup(0x0202, data);
    }
    started = 1;
  }
  tt_socket_t socket_fn = (tt_socket_t)tt_fn("socket");
  tt_listen_t listen_fn = (tt_listen_t)tt_fn("listen");
  tt_closesocket_t close_fn = (tt_closesocket_t)tt_fn("closesocket");
  if (socket_fn == NULL || listen_fn == NULL || close_fn == NULL) {
    return -1;
  }
  unsigned int s = socket_fn(TT_AF_INET, TT_SOCK_STREAM, 0);
  if (s == (unsigned int)-1 || s == 0xFFFFFFFFu) {
    return -1;
  }
  {
    /* SO_REUSEADDR so quick restarts work during development */
    tt_setsockopt_t setopt = (tt_setsockopt_t)tt_fn("setsockopt");
    int opt = 1;
    if (setopt != NULL) {
      setopt(s, TT_SOL_SOCKET, TT_SO_REUSEADDR, (const char *)&opt,
             (int)sizeof(opt));
    }
  }
  if (tt_bind_addr((int)s, (unsigned short)port) < 0 || listen_fn(s, 8) < 0) {
    close_fn(s);
    return -1;
  }
  return (int)s;
#else
  int s = (int)socket(AF_INET, SOCK_STREAM, 0);
  if (s < 0) {
    return -1;
  }
  int opt = 1;
  setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (const char *)&opt, sizeof(opt));
  struct sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_ANY);
  addr.sin_port = htons((unsigned short)port);
  if (bind(s, (struct sockaddr *)&addr, sizeof(addr)) < 0 ||
      listen(s, 8) < 0) {
    close(s);
    return -1;
  }
  return s;
#endif
}

int tinyhttpd_accept(int listen_sock) {
#ifdef _WIN32
  tt_accept_t accept_fn = (tt_accept_t)tt_fn("accept");
  if (accept_fn == NULL) {
    return -1;
  }
  unsigned int s = accept_fn((unsigned int)listen_sock, NULL, NULL);
  if (s == 0 || s == 0xFFFFFFFFu) {
    return -1;
  }
  return (int)s;
#else
  return (int)accept(listen_sock, NULL, NULL);
#endif
}

int tinyhttpd_read(int sock, unsigned char *buf, int len) {
  if (buf == NULL || len <= 0) {
    return -1;
  }
#ifdef _WIN32
  {
    tt_recv_t recv_fn = (tt_recv_t)tt_fn("recv");
    if (recv_fn == NULL) {
      return -1;
    }
    return (int)recv_fn((unsigned int)sock, (char *)buf, len, 0);
  }
#else
  return (int)recv(sock, buf, (size_t)len, 0);
#endif
}

int tinyhttpd_write(int sock, const unsigned char *buf, int offset, int len) {
  if (buf == NULL || len <= 0) {
    return -1;
  }
#ifdef _WIN32
  {
    tt_send_t send_fn = (tt_send_t)tt_fn("send");
    if (send_fn == NULL) {
      return -1;
    }
    return (int)send_fn((unsigned int)sock, (const char *)buf + offset, len, 0);
  }
#else
  return (int)send(sock, buf + offset, (size_t)len, 0);
#endif
}

void tinyhttpd_close(int sock) {
#ifdef _WIN32
  {
    tt_closesocket_t close_fn = (tt_closesocket_t)tt_fn("closesocket");
    if (close_fn != NULL) {
      close_fn((unsigned int)sock);
    }
  }
#else
  close(sock);
#endif
}
