// ezwire.talk: one HTTP exchange. A host is resolved, a socket is connected,
// the request is written, and everything the server sends back before it
// closes is read. With `tls` for a scheme the socket is wrapped in a TLS
// session first.
//
// The spec arrives as four parts: the scheme, the host, the port, each on its
// own line, and the rest of the string is the request verbatim. The answer is
// a status on its own first line and then the text: "0" and the raw response,
// or a non-zero code and the reason.
//
// bend links its binaries with exactly `-std=c11 -O3 -lpthread -lm`, so -lssl
// is not available to anything compiled here. OpenSSL is therefore opened at
// run time with dlopen and every symbol taken with dlsym: nothing is linked,
// so the fixed link line has nothing to say about it. When that fails the
// message says libssl, because "connection refused" for a missing library is
// the kind of error that costs an afternoon.
#include <dlfcn.h>
#include <netdb.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

#define EZWIRE_VERIFY_PEER 1
#define EZWIRE_SET_SNI 55
#define EZWIRE_NAME_HOST 0
// SSL_ERROR_ZERO_RETURN, the peer's own close_notify, and SSL_ERROR_SYSCALL
// with nothing read, which is the peer closing the socket without one. Both
// mean the response ended; anything else means it was cut off.
#define EZWIRE_SHUT_CLEAN 6
#define EZWIRE_SHUT_EOF 5

// the OpenSSL entry points a client handshake needs, and the context they are
// used through. A void* stands in for SSL_CTX* and SSL*, which is all a caller
// that never looks inside one needs.
typedef struct {
  void* (*method)(void);
  void* (*ctx_new)(void*);
  int (*ctx_paths)(void*);
  void (*ctx_verify)(void*, int, void*);
  void* (*ssl_new)(void*);
  void (*ssl_free)(void*);
  int (*set_fd)(void*, int);
  long (*ctrl)(void*, int, long, void*);
  int (*set_host)(void*, const char*);
  int (*connect)(void*);
  int (*read)(void*, void*, int);
  int (*write)(void*, const void*, int);
  int (*error)(const void*, int);
  int (*shutdown)(void*);
  void* ctx;
} EzwireTls;

static EzwireTls ezwire_tls;
// 0 not tried, 1 usable, -1 tried and not there
static int ezwire_tls_state = 0;
// what went wrong the one time it was tried, so the error can say
static char ezwire_tls_why[256] = "";

// libssl's own dependency, opened first and opened globally. DT_RUNPATH is
// not inherited, so the loader looking for libcrypto on libssl's behalf does
// not search where this program searches, and the open fails with libcrypto's
// name rather than libssl's. Putting libcrypto in the process first settles
// it. This showed up under a Nix-built binary, whose loader is Nix's own.
static void ezwire_tls_crypto(const char* at) {
  const char* cut = strstr(at, "libssl");
  if (cut == NULL) {
    return;
  }
  char twin[512];
  snprintf(twin, sizeof(twin), "%.*slibcrypto%s", (int)(cut - at), at, cut + 6);
  dlopen(twin, RTLD_NOW | RTLD_GLOBAL);
}

// one candidate, with its libcrypto beside it
static void* ezwire_tls_try(const char* at) {
  ezwire_tls_crypto(at);
  return dlopen(at, RTLD_NOW);
}

// the library, wherever this machine keeps it. EZ_LIBSSL is the way out when
// it is somewhere no search path reaches, which under Nix it usually is.
static void* ezwire_tls_open(void) {
  const char* set = getenv("EZ_LIBSSL");
  if (set != NULL && set[0] != '\0') {
    void* named = ezwire_tls_try(set);
    if (named != NULL) {
      return named;
    }
  }
  static const char* names[] = { "libssl.so.3", "libssl.so.1.1", "libssl.so",
    "libssl.3.dylib", "libssl.dylib" };
  for (size_t i = 0; i < sizeof(names) / sizeof(names[0]); i++) {
    void* lib = ezwire_tls_try(names[i]);
    if (lib != NULL) {
      return lib;
    }
  }
  snprintf(ezwire_tls_why, sizeof(ezwire_tls_why), "%s", dlerror());
  return NULL;
}

// one symbol, and the first one missing is what the error will say
static void* ezwire_tls_sym(void* lib, const char* name) {
  void* at = dlsym(lib, name);
  if (at == NULL && ezwire_tls_why[0] == '\0') {
    snprintf(ezwire_tls_why, sizeof(ezwire_tls_why), "it has no %s", name);
  }
  return at;
}

// every symbol, or none: a half-loaded OpenSSL is a crash waiting for a
// handshake, so one missing name fails the whole load
static int ezwire_tls_syms(void* lib) {
  ezwire_tls.method = ezwire_tls_sym(lib, "TLS_client_method");
  ezwire_tls.ctx_new = ezwire_tls_sym(lib, "SSL_CTX_new");
  ezwire_tls.ctx_paths = ezwire_tls_sym(lib, "SSL_CTX_set_default_verify_paths");
  ezwire_tls.ctx_verify = ezwire_tls_sym(lib, "SSL_CTX_set_verify");
  ezwire_tls.ssl_new = ezwire_tls_sym(lib, "SSL_new");
  ezwire_tls.ssl_free = ezwire_tls_sym(lib, "SSL_free");
  ezwire_tls.set_fd = ezwire_tls_sym(lib, "SSL_set_fd");
  ezwire_tls.ctrl = ezwire_tls_sym(lib, "SSL_ctrl");
  ezwire_tls.set_host = ezwire_tls_sym(lib, "SSL_set1_host");
  ezwire_tls.connect = ezwire_tls_sym(lib, "SSL_connect");
  ezwire_tls.read = ezwire_tls_sym(lib, "SSL_read");
  ezwire_tls.write = ezwire_tls_sym(lib, "SSL_write");
  ezwire_tls.error = ezwire_tls_sym(lib, "SSL_get_error");
  ezwire_tls.shutdown = ezwire_tls_sym(lib, "SSL_shutdown");
  return ezwire_tls_why[0] == '\0';
}

// the context, made once. Verification is on and the trust store is the
// system's, which OpenSSL takes from SSL_CERT_FILE and SSL_CERT_DIR when they
// are set, and that is how a Nix build points it at a CA bundle.
static int ezwire_tls_ready(void) {
  if (ezwire_tls_state != 0) {
    return ezwire_tls_state;
  }
  ezwire_tls_state = -1;
  void* lib = ezwire_tls_open();
  if (lib != NULL && ezwire_tls_syms(lib)) {
    void* ctx = ezwire_tls.ctx_new(ezwire_tls.method());
    if (ctx == NULL) {
      snprintf(ezwire_tls_why, sizeof(ezwire_tls_why),
        "SSL_CTX_new answered nothing");
    } else {
      ezwire_tls.ctx_paths(ctx);
      ezwire_tls.ctx_verify(ctx, EZWIRE_VERIFY_PEER, NULL);
      ezwire_tls.ctx = ctx;
      ezwire_tls_state = 1;
    }
  }
  return ezwire_tls_state;
}

// a connected socket, or -1. The port is passed as text because getaddrinfo
// takes it that way, and getaddrinfo is also the whole of ez's DNS: Base's
// own TCP.connect runs the host through inet_pton, so it reaches an address
// literal and nothing else.
static int ezwire_dial(const char* host, const char* port) {
  struct addrinfo want;
  struct addrinfo* list = NULL;
  memset(&want, 0, sizeof(want));
  want.ai_family = AF_UNSPEC;
  want.ai_socktype = SOCK_STREAM;
  if (getaddrinfo(host, port, &want, &list) != 0) {
    return -1;
  }
  int fd = -1;
  for (struct addrinfo* at = list; at != NULL && fd < 0; at = at->ai_next) {
    fd = socket(at->ai_family, at->ai_socktype, at->ai_protocol);
    if (fd < 0) {
      continue;
    }
    struct timeval wait = { 60, 0 };
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &wait, sizeof(wait));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &wait, sizeof(wait));
    if (connect(fd, at->ai_addr, at->ai_addrlen) != 0) {
      close(fd);
      fd = -1;
    }
  }
  freeaddrinfo(list);
  return fd;
}

// the session over an open socket, with the hostname used for both the name
// sent in the hello and the name the certificate is checked against
static void* ezwire_shake(int fd, const char* host) {
  void* ssl = ezwire_tls.ssl_new(ezwire_tls.ctx);
  if (ssl == NULL) {
    return NULL;
  }
  ezwire_tls.set_fd(ssl, fd);
  ezwire_tls.ctrl(ssl, EZWIRE_SET_SNI, EZWIRE_NAME_HOST, (void*)host);
  ezwire_tls.set_host(ssl, host);
  if (ezwire_tls.connect(ssl) != 1) {
    ezwire_tls.ssl_free(ssl);
    return NULL;
  }
  return ssl;
}

// the whole request out, over TLS when there is a session
static int ezwire_say(int fd, void* ssl, const char* text, size_t len) {
  size_t at = 0;
  while (at < len) {
    int n = ssl != NULL ? ezwire_tls.write(ssl, text + at, (int)(len - at))
      : (int)send(fd, text + at, len - at, 0);
    if (n <= 0) {
      return -1;
    }
    at += (size_t)n;
  }
  return 0;
}

// everything the server sends before it closes. `Connection: close` is what
// makes that the end of the response; the framing headers then say how much of
// it is body. A TLS read that stops for any reason other than the peer being
// done sets `bad`, so a connection cut mid-body is an error and not a short
// file that happens to parse.
static char* ezwire_hear(int fd, void* ssl, size_t* len, int* bad) {
  size_t cap = 65536;
  size_t at = 0;
  char* buf = malloc(cap);
  for (;;) {
    if (at + 16384 > cap) {
      cap *= 2;
      buf = realloc(buf, cap);
    }
    int n = ssl != NULL ? ezwire_tls.read(ssl, buf + at, 16384)
      : (int)recv(fd, buf + at, 16384, 0);
    if (n <= 0) {
      if (ssl == NULL) {
        *bad = n < 0;
      } else {
        int why = ezwire_tls.error(ssl, n);
        *bad = !(why == EZWIRE_SHUT_CLEAN
          || (why == EZWIRE_SHUT_EOF && n == 0));
      }
      break;
    }
    at += (size_t)n;
  }
  *len = at;
  return buf;
}

// the answer: a status line, then the text. The status is 0 only when a whole
// response came back.
static Term ezwire_say_back(Env e, int code, const char* text, size_t len) {
  char head[16];
  int hn = snprintf(head, sizeof(head), "%d\n", code);
  char* out = malloc((size_t)hn + len);
  memcpy(out, head, (size_t)hn);
  memcpy(out + (size_t)hn, text, len);
  Term s = io_str(e, out, (size_t)hn + len);
  free(out);
  return s;
}

// the spec's four parts. The newlines become terminators, and whatever is left
// after the third is the request, which has newlines of its own.
static int ezwire_split(char* spec, size_t n, char** part) {
  size_t got = 1;
  part[0] = spec;
  for (size_t i = 0; i < n && got < 4; i++) {
    if (spec[i] == '\n') {
      spec[i] = '\0';
      part[got++] = spec + i + 1;
    }
  }
  return got == 4;
}

Term ezwire_talk_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* spec = io_cstr(e, f[0], &n);
  char* part[4];
  if (!ezwire_split(spec, (size_t)n, part)) {
    free(spec);
    return ezwire_say_back(e, 22, "a malformed request spec", 24);
  }
  int secure = strcmp(part[0], "tls") == 0;
  if (secure && ezwire_tls_ready() != 1) {
    free(spec);
    char why[512];
    int wn = snprintf(why, sizeof(why), "could not load libssl at run time "
      "(%s); install openssl or point EZ_LIBSSL at the library",
      ezwire_tls_why);
    return ezwire_say_back(e, 1, why, (size_t)wn);
  }
  char why[512];
  int fd = ezwire_dial(part[1], part[2]);
  if (fd < 0) {
    int wn = snprintf(why, sizeof(why), "could not reach %s port %s",
      part[1], part[2]);
    Term miss = ezwire_say_back(e, 6, why, (size_t)wn);
    free(spec);
    return miss;
  }
  void* ssl = secure ? ezwire_shake(fd, part[1]) : NULL;
  if (secure && ssl == NULL) {
    close(fd);
    int wn = snprintf(why, sizeof(why), "the TLS handshake with %s failed",
      part[1]);
    Term miss = ezwire_say_back(e, 35, why, (size_t)wn);
    free(spec);
    return miss;
  }
  Term out;
  /* remaining bytes after the third newline — not strlen, so a body may hold NUL */
  size_t req_len = (size_t)n - (size_t)(part[3] - spec);
  if (ezwire_say(fd, ssl, part[3], req_len) != 0) {
    int wn = snprintf(why, sizeof(why), "the request to %s could not be sent",
      part[1]);
    out = ezwire_say_back(e, 55, why, (size_t)wn);
  } else {
    size_t len = 0;
    int bad = 0;
    char* got = ezwire_hear(fd, ssl, &len, &bad);
    if (bad) {
      int wn = snprintf(why, sizeof(why), "the answer from %s was cut short",
        part[1]);
      out = ezwire_say_back(e, 56, why, (size_t)wn);
    } else {
      out = ezwire_say_back(e, 0, got, len);
    }
    free(got);
  }
  if (ssl != NULL) {
    ezwire_tls.shutdown(ssl);
    ezwire_tls.ssl_free(ssl);
  }
  close(fd);
  free(spec);
  return out;
}

static void __attribute__((constructor)) ezwire_talk_use(void) {
  io_eff(CID_EZWIRE_TALK, ezwire_talk_run, 0);
}
