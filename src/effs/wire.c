// ezwire.open, ezwire.read, ezwire.close: one HTTP exchange. A host is
// resolved, a socket is connected and the request is written (open); then the
// response is read a piece at a time (read), until the Bend side, which
// decides when a response is whole (wirespec.bend wire.read.next), closes it
// (close). With `tls` for a scheme the socket is wrapped in a TLS session
// first. Nothing here knows HTTP framing: a server that keeps the connection
// open after a whole response is not waited on, because the Bend side stops
// asking.
//
// The spec arrives as four parts: the scheme, the host, the port, each on its
// own line, and the rest of the string is the request verbatim, written as
// the runtime writes any String, in UTF-8. A second argument, the tail, is a
// list of octets (0..255) written after the request byte for byte: that is
// how a body of octets (a file, a multipart form) reaches the wire unchanged,
// since a String's code points 128..255 would go out as two bytes each. The scheme
// line may carry a timeout after a space, in milliseconds, as 32 binary
// digits least significant first (wirespec.bend); without one it is 60000.
// The timeout bounds the connect, every send and every receive on its own,
// as httpx's does; name resolution is not bounded. A call that runs out of
// time answers status 28 (curl's CURLE_OPERATION_TIMEDOUT), and no other
// failure does. Every answer is a status on its own first line and then the
// text: for open, "0" and a connection number; for read, "0" and the octets
// that arrived (none once the server has closed cleanly); or a non-zero code
// and the reason. A reason names its cause the way strace would: a host that
// does not resolve is status 6 with getaddrinfo's EAI_ name and number, a
// connect that fails is status 7 with the errno's name and number
// (`ECONNREFUSED (111)`), and a failed handshake, send or read adds the
// errno, or over TLS SSL_get_error's answer and the errno (SPEC.md
// HTTP-TRUST-6). wire.js writes the same text.
//
// bend links its binaries with exactly `-std=c11 -O3 -lpthread -lm`, so -lssl
// is not available to anything compiled here. OpenSSL is therefore opened at
// run time with dlopen and every symbol taken with dlsym: nothing is linked,
// so the fixed link line has nothing to say about it. When that fails the
// message says libssl, because "connection refused" for a missing library is
// the kind of error that costs an afternoon.
#include <dlfcn.h>
#include <errno.h>
#include <netdb.h>
#include <poll.h>
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
// SSL_ERROR_WANT_READ and SSL_ERROR_WANT_WRITE: on a blocking socket these
// come back only when a receive or send timeout ran out
#define EZWIRE_WANT_READ 2
#define EZWIRE_WANT_WRITE 3
// the status of an exchange that ran out of time
#define EZWIRE_LATE 28

// whether the call that just failed ran out of time: errno as a timed-out
// socket call leaves it (a connect bounded by SO_SNDTIMEO says EINPROGRESS)
static int ezwire_late_errno(int code) {
  return code == EAGAIN || code == EWOULDBLOCK || code == EINPROGRESS
    || code == ETIMEDOUT;
}

// the symbolic name of an errno a socket call can leave, or "errno" for one
// this table does not know. The names are the C library's own, so a reason
// reads the same as strace or curl would print it; the number is this
// platform's. wire.js keeps the same table, by platform, so the two lanes
// write the same text.
static const char* ezwire_errno_name(int code) {
  switch (code) {
    case EPERM: return "EPERM";
    case ENOENT: return "ENOENT";
    case EINTR: return "EINTR";
    case EIO: return "EIO";
    case EBADF: return "EBADF";
    case EAGAIN: return "EAGAIN";
    case ENOMEM: return "ENOMEM";
    case EACCES: return "EACCES";
    case EINVAL: return "EINVAL";
    case ENFILE: return "ENFILE";
    case EMFILE: return "EMFILE";
    case EPIPE: return "EPIPE";
    case EPROTO: return "EPROTO";
    case ENOTSOCK: return "ENOTSOCK";
    case EPROTONOSUPPORT: return "EPROTONOSUPPORT";
    case EAFNOSUPPORT: return "EAFNOSUPPORT";
    case EADDRINUSE: return "EADDRINUSE";
    case EADDRNOTAVAIL: return "EADDRNOTAVAIL";
    case ENETDOWN: return "ENETDOWN";
    case ENETUNREACH: return "ENETUNREACH";
    case ECONNABORTED: return "ECONNABORTED";
    case ECONNRESET: return "ECONNRESET";
    case ENOBUFS: return "ENOBUFS";
    case EISCONN: return "EISCONN";
    case ENOTCONN: return "ENOTCONN";
    case ETIMEDOUT: return "ETIMEDOUT";
    case ECONNREFUSED: return "ECONNREFUSED";
    case EHOSTDOWN: return "EHOSTDOWN";
    case EHOSTUNREACH: return "EHOSTUNREACH";
    case EALREADY: return "EALREADY";
    case EINPROGRESS: return "EINPROGRESS";
    default: return "errno";
  }
}

// the symbolic name of a getaddrinfo answer, or "EAI" for one this table
// does not know
static const char* ezwire_gai_name(int code) {
  switch (code) {
#ifdef EAI_BADFLAGS
    case EAI_BADFLAGS: return "EAI_BADFLAGS";
#endif
#ifdef EAI_NONAME
    case EAI_NONAME: return "EAI_NONAME";
#endif
#ifdef EAI_AGAIN
    case EAI_AGAIN: return "EAI_AGAIN";
#endif
#ifdef EAI_FAIL
    case EAI_FAIL: return "EAI_FAIL";
#endif
#ifdef EAI_NODATA
    case EAI_NODATA: return "EAI_NODATA";
#endif
#ifdef EAI_FAMILY
    case EAI_FAMILY: return "EAI_FAMILY";
#endif
#ifdef EAI_SOCKTYPE
    case EAI_SOCKTYPE: return "EAI_SOCKTYPE";
#endif
#ifdef EAI_SERVICE
    case EAI_SERVICE: return "EAI_SERVICE";
#endif
#ifdef EAI_ADDRFAMILY
    case EAI_ADDRFAMILY: return "EAI_ADDRFAMILY";
#endif
#ifdef EAI_MEMORY
    case EAI_MEMORY: return "EAI_MEMORY";
#endif
#ifdef EAI_SYSTEM
    case EAI_SYSTEM: return "EAI_SYSTEM";
#endif
    default: return "EAI";
  }
}

// the name of an SSL_get_error answer
static const char* ezwire_ssl_name(int code) {
  switch (code) {
    case 1: return "SSL_ERROR_SSL";
    case 2: return "SSL_ERROR_WANT_READ";
    case 3: return "SSL_ERROR_WANT_WRITE";
    case 4: return "SSL_ERROR_WANT_X509_LOOKUP";
    case 5: return "SSL_ERROR_SYSCALL";
    case 6: return "SSL_ERROR_ZERO_RETURN";
    case 7: return "SSL_ERROR_WANT_CONNECT";
    case 8: return "SSL_ERROR_WANT_ACCEPT";
    default: return "SSL_ERROR";
  }
}

// why a call failed, as `NAME (n)`: the errno, or with a TLS session the
// SSL_get_error answer and then the errno when there is one
static void ezwire_cause(char* out, size_t cap, int tls, int sslerr, int err) {
  if (!tls) {
    snprintf(out, cap, "%s (%d)", ezwire_errno_name(err), err);
  } else if (err != 0) {
    snprintf(out, cap, "%s (%d), %s (%d)", ezwire_ssl_name(sslerr), sslerr,
      ezwire_errno_name(err), err);
  } else {
    snprintf(out, cap, "%s (%d)", ezwire_ssl_name(sslerr), sslerr);
  }
}

// the timeout the scheme line carries, or 60000 ms when it carries none. A
// zero would mean "no timeout" to setsockopt, so it is read as 1 ms.
static long ezwire_ms(const char* line) {
  const char* gap = strchr(line, ' ');
  if (gap == NULL) {
    return 60000;
  }
  unsigned long ms = 0;
  const char* bits = gap + 1;
  for (int i = 0; i < 32 && bits[i] != '\0'; i++) {
    if (bits[i] == '1') {
      ms |= 1UL << i;
    }
  }
  return ms == 0 ? 1 : (long)ms;
}

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
  int (*pending)(const void*);
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
  ezwire_tls.pending = ezwire_tls_sym(lib, "SSL_pending");
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
static int ezwire_dial(const char* host, const char* port, long ms,
  int* late, int* gai, int* err) {
  struct addrinfo want;
  struct addrinfo* list = NULL;
  memset(&want, 0, sizeof(want));
  want.ai_family = AF_UNSPEC;
  want.ai_socktype = SOCK_STREAM;
  *late = 0;
  *err = 0;
  *gai = getaddrinfo(host, port, &want, &list);
  if (*gai != 0) {
    return -1;
  }
  int fd = -1;
  for (struct addrinfo* at = list; at != NULL && fd < 0; at = at->ai_next) {
    fd = socket(at->ai_family, at->ai_socktype, at->ai_protocol);
    if (fd < 0) {
      *err = errno;
      continue;
    }
    struct timeval wait = { ms / 1000, (ms % 1000) * 1000 };
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &wait, sizeof(wait));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &wait, sizeof(wait));
    if (connect(fd, at->ai_addr, at->ai_addrlen) != 0) {
      *err = errno;
      *late = ezwire_late_errno(*err);
      close(fd);
      fd = -1;
    }
  }
  freeaddrinfo(list);
  return fd;
}

// the session over an open socket, with the hostname used for both the name
// sent in the hello and the name the certificate is checked against
static void* ezwire_shake(int fd, const char* host, int* late, int* sslerr,
  int* err) {
  void* ssl = ezwire_tls.ssl_new(ezwire_tls.ctx);
  *sslerr = 1;
  *err = 0;
  if (ssl == NULL) {
    return NULL;
  }
  ezwire_tls.set_fd(ssl, fd);
  ezwire_tls.ctrl(ssl, EZWIRE_SET_SNI, EZWIRE_NAME_HOST, (void*)host);
  ezwire_tls.set_host(ssl, host);
  errno = 0;
  int n = ezwire_tls.connect(ssl);
  if (n != 1) {
    int code = errno;
    int why = ezwire_tls.error(ssl, n);
    *sslerr = why;
    *err = code;
    *late = why == EZWIRE_WANT_READ || why == EZWIRE_WANT_WRITE
      || ezwire_late_errno(code);
    ezwire_tls.ssl_free(ssl);
    return NULL;
  }
  return ssl;
}

// the whole request out, over TLS when there is a session
static int ezwire_say(int fd, void* ssl, const char* text, size_t len,
  int* late, int* sslerr, int* err) {
  size_t at = 0;
  *late = 0;
  while (at < len) {
    errno = 0;
    int n = ssl != NULL ? ezwire_tls.write(ssl, text + at, (int)(len - at))
      : (int)send(fd, text + at, len - at, 0);
    if (n <= 0) {
      int code = errno;
      int why = ssl != NULL ? ezwire_tls.error(ssl, n) : 0;
      *sslerr = why;
      *err = code;
      *late = why == EZWIRE_WANT_WRITE || why == EZWIRE_WANT_READ
        || ezwire_late_errno(code);
      return -1;
    }
    at += (size_t)n;
  }
  return 0;
}

// one receive into buf, over TLS when there is a session: the count, 0 once
// the peer is done, or -1 with `late` set when it ran out of time. A TLS read
// that stops for any reason other than the peer being done is -1, so a
// connection cut mid-body is an error and not a short file that happens to
// parse.
static int ezwire_recv(int fd, void* ssl, char* buf, int cap, int flags,
  int* late, int* sslerr, int* err) {
  errno = 0;
  int n = ssl != NULL ? ezwire_tls.read(ssl, buf, cap)
    : (int)recv(fd, buf, (size_t)cap, flags);
  if (n > 0) {
    return n;
  }
  int code = errno;
  *sslerr = 0;
  *err = code;
  if (ssl == NULL) {
    *late = n < 0 && ezwire_late_errno(code);
    return n < 0 ? -1 : 0;
  }
  int why = ezwire_tls.error(ssl, n);
  *sslerr = why;
  if (why == EZWIRE_SHUT_CLEAN || (why == EZWIRE_SHUT_EOF && n == 0)) {
    return 0;
  }
  *late = why == EZWIRE_WANT_READ || why == EZWIRE_WANT_WRITE
    || ezwire_late_errno(code);
  return -1;
}

// how many bytes at the end of buf start a UTF-8 sequence that has not all
// arrived, so a read never splits a character: the runtime decodes each
// read's text on its own
static int ezwire_cut(const unsigned char* buf, size_t len) {
  for (int back = 1; back <= 3 && (size_t)back <= len; back++) {
    unsigned char c = buf[len - (size_t)back];
    if ((c & 0xC0) == 0x80) {
      continue;
    }
    int want = (c & 0xE0) == 0xC0 ? 2 : (c & 0xF0) == 0xE0 ? 3
      : (c & 0xF8) == 0xF0 ? 4 : 1;
    return want > back ? back : 0;
  }
  return 0;
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

// an open exchange: its socket, its session, whom it is with, its timeout,
// the start of a UTF-8 sequence held back from the last read, and whether
// the server has closed
typedef struct {
  int used;
  int fd;
  void* ssl;
  char host[256];
  long ms;
  unsigned char held[4];
  int nheld;
  int done;
} EzwireConn;

#define EZWIRE_CONNS 64
static EzwireConn ezwire_conns[EZWIRE_CONNS];

// the most one read answers
#define EZWIRE_READ_MAX (1 << 20)

// connect, shake hands, send the request, and answer a connection number
Term ezwire_open_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* spec = io_cstr(e, f[0], &n);
  uint64_t tn = 0;
  char* tail = io_cbuf(e, f[1], &tn, CID(Con));
  if (tail == NULL) {
    free(spec);
    return ezwire_say_back(e, 22, "a body octet is past 255", 24);
  }
  char* part[4];
  if (!ezwire_split(spec, (size_t)n, part)) {
    free(spec);
    free(tail);
    return ezwire_say_back(e, 22, "a malformed request spec", 24);
  }
  int slot = -1;
  for (int i = 0; i < EZWIRE_CONNS && slot < 0; i++) {
    if (!ezwire_conns[i].used) {
      slot = i;
    }
  }
  if (slot < 0) {
    free(spec);
    free(tail);
    return ezwire_say_back(e, 24, "too many open exchanges", 23);
  }
  int secure = strncmp(part[0], "tls", 3) == 0
    && (part[0][3] == '\0' || part[0][3] == ' ');
  if (secure && ezwire_tls_ready() != 1) {
    free(spec);
    free(tail);
    char why[512];
    int wn = snprintf(why, sizeof(why), "could not load libssl at run time "
      "(%s); install openssl or point EZ_LIBSSL at the library",
      ezwire_tls_why);
    return ezwire_say_back(e, 1, why, (size_t)wn);
  }
  char why[512];
  long ms = ezwire_ms(part[0]);
  int late = 0;
  int gai = 0;
  int err = 0;
  int sslerr = 0;
  char cause[128];
  int fd = ezwire_dial(part[1], part[2], ms, &late, &gai, &err);
  if (fd < 0) {
    int code = gai != 0 ? 6 : late ? EZWIRE_LATE : 7;
    ezwire_cause(cause, sizeof(cause), 0, 0, err);
    int wn = gai != 0
      ? snprintf(why, sizeof(why), "could not resolve %s: %s (%d)",
        part[1], ezwire_gai_name(gai), gai)
      : late
      ? snprintf(why, sizeof(why), "connecting to %s port %s took over %ld ms",
        part[1], part[2], ms)
      : snprintf(why, sizeof(why), "could not reach %s port %s: %s",
        part[1], part[2], cause);
    Term miss = ezwire_say_back(e, code, why, (size_t)wn);
    free(spec);
    free(tail);
    return miss;
  }
  void* ssl = secure ? ezwire_shake(fd, part[1], &late, &sslerr, &err) : NULL;
  if (secure && ssl == NULL) {
    close(fd);
    ezwire_cause(cause, sizeof(cause), 1, sslerr, err);
    int wn = late
      ? snprintf(why, sizeof(why), "the TLS handshake with %s took over %ld ms",
        part[1], ms)
      : snprintf(why, sizeof(why), "the TLS handshake with %s failed: %s",
        part[1], cause);
    Term miss = ezwire_say_back(e, late ? EZWIRE_LATE : 35, why, (size_t)wn);
    free(spec);
    free(tail);
    return miss;
  }
  /* remaining bytes after the third newline — not strlen, so a body may hold NUL */
  size_t req_len = (size_t)n - (size_t)(part[3] - spec);
  if (ezwire_say(fd, ssl, part[3], req_len, &late, &sslerr, &err) != 0
    || ezwire_say(fd, ssl, tail, (size_t)tn, &late, &sslerr, &err) != 0) {
    ezwire_cause(cause, sizeof(cause), ssl != NULL, sslerr, err);
    int wn = late
      ? snprintf(why, sizeof(why), "sending the request to %s took over %ld ms",
        part[1], ms)
      : snprintf(why, sizeof(why), "the request to %s could not be sent: %s",
        part[1], cause);
    Term miss = ezwire_say_back(e, late ? EZWIRE_LATE : 55, why, (size_t)wn);
    if (ssl != NULL) {
      ezwire_tls.shutdown(ssl);
      ezwire_tls.ssl_free(ssl);
    }
    close(fd);
    free(spec);
    free(tail);
    return miss;
  }
  free(tail);
  EzwireConn* c = &ezwire_conns[slot];
  memset(c, 0, sizeof(*c));
  c->used = 1;
  c->fd = fd;
  c->ssl = ssl;
  snprintf(c->host, sizeof(c->host), "%s", part[1]);
  c->ms = ms;
  free(spec);
  char num[16];
  int nn = snprintf(num, sizeof(num), "%d", slot);
  return ezwire_say_back(e, 0, num, (size_t)nn);
}

// the next octets: one receive that waits (bounded by the timeout), then
// whatever has already arrived behind it, without waiting, up to
// EZWIRE_READ_MAX. A UTF-8 sequence cut at the end is held for the next
// read; once the server has closed, what was held goes out and then nothing.
Term ezwire_read_run(Env e, Term* f, IoWork* w) {
  u32 slot = (u32)f[0];
  if (slot >= EZWIRE_CONNS || !ezwire_conns[slot].used) {
    return ezwire_say_back(e, 22, "no such exchange", 16);
  }
  EzwireConn* c = &ezwire_conns[slot];
  size_t cap = EZWIRE_READ_MAX + 8;
  char* buf = malloc(cap);
  memcpy(buf, c->held, (size_t)c->nheld);
  size_t at = (size_t)c->nheld;
  c->nheld = 0;
  int late = 0;
  int sslerr = 0;
  int err = 0;
  // until there is a whole character to answer, or the server is done
  while (!c->done) {
    int got = ezwire_recv(c->fd, c->ssl, buf + at, 16384, 0, &late, &sslerr,
      &err);
    if (got < 0) {
      free(buf);
      char why[512];
      char cause[128];
      ezwire_cause(cause, sizeof(cause), c->ssl != NULL, sslerr, err);
      int wn = late
        ? snprintf(why, sizeof(why), "%s sent nothing for %ld ms",
          c->host, c->ms)
        : snprintf(why, sizeof(why), "the answer from %s was cut short: %s",
          c->host, cause);
      return ezwire_say_back(e, late ? EZWIRE_LATE : 56, why, (size_t)wn);
    }
    if (got == 0) {
      c->done = 1;
      break;
    }
    at += (size_t)got;
    // what is already here, without waiting
    while (at + 16384 <= EZWIRE_READ_MAX) {
      int more;
      if (c->ssl != NULL) {
        if (ezwire_tls.pending(c->ssl) <= 0) {
          break;
        }
        more = ezwire_recv(c->fd, c->ssl, buf + at, 16384, 0, &late, &sslerr,
          &err);
      } else {
        struct pollfd p = { c->fd, POLLIN, 0 };
        if (poll(&p, 1, 0) <= 0) {
          break;
        }
        more = ezwire_recv(c->fd, NULL, buf + at, 16384, MSG_DONTWAIT, &late,
          &sslerr, &err);
      }
      if (more == 0) {
        c->done = 1;
      }
      if (more <= 0) {
        break;
      }
      at += (size_t)more;
    }
    int keep = c->done ? 0 : ezwire_cut((unsigned char*)buf, at);
    if ((size_t)keep < at) {
      memcpy(c->held, buf + at - (size_t)keep, (size_t)keep);
      c->nheld = keep;
      at -= (size_t)keep;
      break;
    }
  }
  Term out = ezwire_say_back(e, 0, buf, at);
  free(buf);
  return out;
}

// close an exchange's session and socket
Term ezwire_close_run(Env e, Term* f, IoWork* w) {
  u32 slot = (u32)f[0];
  if (slot < EZWIRE_CONNS && ezwire_conns[slot].used) {
    EzwireConn* c = &ezwire_conns[slot];
    if (c->ssl != NULL) {
      ezwire_tls.shutdown(c->ssl);
      ezwire_tls.ssl_free(c->ssl);
    }
    close(c->fd);
    memset(c, 0, sizeof(*c));
  }
  return term_pak(CID(Unit), 0);
}

#ifdef CID(ezwire.open)
static void __attribute__((constructor)) ezwire_open_use(void) {
  io_eff(CID(ezwire.open), ezwire_open_run);
}
#endif

#ifdef CID(ezwire.read)
static void __attribute__((constructor)) ezwire_read_use(void) {
  io_eff(CID(ezwire.read), ezwire_read_run);
}
#endif

#ifdef CID(ezwire.close)
static void __attribute__((constructor)) ezwire_close_use(void) {
  io_eff(CID(ezwire.close), ezwire_close_run);
}
#endif
