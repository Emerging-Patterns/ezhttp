// ezwire.open, ezwire.read, ezwire.close: the JS lane's twin of wire.c, and
// the same exchange, with the same timeout: read from the scheme line,
// bounding the connect and every send and receive, and answered as status 28
// when it runs out. As in wire.c, the response is read a piece at a time and
// the Bend side decides when it is whole.
//
// Bend's JS backend drives raw file descriptors through bun:ffi and runs its
// own poll loop over them, so node's `net` and `tls` modules are not an option
// here: they are built on the event loop that backend bypasses. The socket is
// opened with the same libc calls the C twin uses, and OpenSSL is opened the
// same way too, with dlopen at run time, because neither lane has a link line
// that could name -lssl.
//
// The file runs once in a closure of its own and registers the effect at its
// foot with io_eff, as wire.c does. The helpers are still `function`s and the
// loaded libraries still live on globalThis, so each is opened once per process.

// libc's resolver. io_sys() already carries the socket calls; getaddrinfo is
// the one it does not, and it is the whole of ez's DNS.
function ezwire_dns() {
  if (globalThis.EZ_WIRE_DNS === undefined) {
    const ffi = require("bun:ffi");
    const mac = process.platform === "darwin";
    globalThis.EZ_WIRE_DNS = ffi.dlopen(mac ? "libSystem.dylib" : "libc.so.6", {
      getaddrinfo: { args: ["ptr", "ptr", "ptr", "ptr"], returns: "i32" },
      freeaddrinfo: { args: ["ptr"], returns: "void" },
    }).symbols;
  }
  return globalThis.EZ_WIRE_DNS;
}

// every path this machine might keep libssl at. bun's dlopen does not walk the
// loader's own search path, so a bare soname only works when it happens to sit
// beside the script: the paths have to be spelled out, and EZ_LIBSSL is how a
// Nix build spells out its own.
function ezwire_tls_paths() {
  const fs = require("fs");
  const mac = process.platform === "darwin";
  const names = mac ? ["libssl.3.dylib", "libssl.dylib"]
    : ["libssl.so.3", "libssl.so.1.1", "libssl.so"];
  const dirs = (process.env.LD_LIBRARY_PATH || "").split(":")
    .concat(["/usr/lib/x86_64-linux-gnu", "/lib/x86_64-linux-gnu",
      "/usr/lib64", "/usr/lib", "/lib", "/opt/homebrew/opt/openssl@3/lib",
      "/usr/local/opt/openssl@3/lib"]);
  const out = [];
  const set = process.env.EZ_LIBSSL;
  if (set) {
    out.push(set);
  }
  for (const dir of dirs) {
    for (const name of names) {
      const at = dir === "" ? name : dir + "/" + name;
      try {
        if (fs.existsSync(at)) {
          out.push(at);
        }
      } catch (e) {
      }
    }
  }
  return out;
}

// OpenSSL, opened at run time. libssl's own dependency on libcrypto is not
// resolved for it here either, so the sibling libcrypto is opened first and
// the loader then finds it already in the process.
function ezwire_tls() {
  if (globalThis.EZ_WIRE_TLS === undefined) {
    const ffi = require("bun:ffi");
    let lib = null;
    for (const at of ezwire_tls_paths()) {
      try {
        try {
          ffi.dlopen(at.replace("libssl", "libcrypto"),
            { OPENSSL_init_crypto: { args: ["u64", "ptr"], returns: "i32" } });
        } catch (e) {
        }
        lib = ffi.dlopen(at, {
          TLS_client_method: { args: [], returns: "ptr" },
          SSL_CTX_new: { args: ["ptr"], returns: "ptr" },
          SSL_CTX_set_default_verify_paths: { args: ["ptr"], returns: "i32" },
          SSL_CTX_set_verify: { args: ["ptr", "i32", "ptr"], returns: "void" },
          SSL_new: { args: ["ptr"], returns: "ptr" },
          SSL_free: { args: ["ptr"], returns: "void" },
          SSL_set_fd: { args: ["ptr", "i32"], returns: "i32" },
          SSL_ctrl: { args: ["ptr", "i32", "i64", "ptr"], returns: "i64" },
          SSL_set1_host: { args: ["ptr", "ptr"], returns: "i32" },
          SSL_connect: { args: ["ptr"], returns: "i32" },
          SSL_read: { args: ["ptr", "ptr", "i32"], returns: "i32" },
          SSL_write: { args: ["ptr", "ptr", "i32"], returns: "i32" },
          SSL_get_error: { args: ["ptr", "i32"], returns: "i32" },
          SSL_shutdown: { args: ["ptr"], returns: "i32" },
          SSL_pending: { args: ["ptr"], returns: "i32" },
        });
        break;
      } catch (e) {
        lib = null;
      }
    }
    if (lib === null) {
      globalThis.EZ_WIRE_TLS = null;
    } else {
      const s = lib.symbols;
      const ctx = s.SSL_CTX_new(s.TLS_client_method());
      // the trust store is the system's, which OpenSSL takes from
      // SSL_CERT_FILE and SSL_CERT_DIR when they are set
      s.SSL_CTX_set_default_verify_paths(ctx);
      s.SSL_CTX_set_verify(ctx, 1, null);
      globalThis.EZ_WIRE_TLS = { ...s, ctx };
    }
  }
  return globalThis.EZ_WIRE_TLS;
}

// the timeout the scheme line carries, in milliseconds: 32 binary digits,
// least significant first, after a space (wirespec.bend); 60000 without one.
// A zero would mean "no timeout" to setsockopt, so it is read as 1 ms.
function ezwire_ms(line) {
  const gap = line.indexOf(" ");
  if (gap < 0) {
    return 60000;
  }
  let ms = 0;
  const bits = line.slice(gap + 1);
  for (let i = 0; i < 32 && i < bits.length; i++) {
    if (bits[i] === "1") {
      ms += 2 ** i;
    }
  }
  return ms === 0 ? 1 : ms;
}

// whether the call that just failed ran out of time, by its errno (a connect
// bounded by SO_SNDTIMEO says EINPROGRESS)
function ezwire_late_errno(code) {
  const mac = process.platform === "darwin";
  return mac ? (code === 35 || code === 36 || code === 60)
    : (code === 11 || code === 115 || code === 110);
}

// the symbolic names of the errnos a socket call can leave, with their
// numbers on Linux and on macOS: wire.c's table, so the two lanes write the
// same text. An errno this table does not know is written "errno".
const EZWIRE_ERRNO = [
  ["EPERM", 1, 1], ["ENOENT", 2, 2], ["EINTR", 4, 4], ["EIO", 5, 5],
  ["EBADF", 9, 9], ["EAGAIN", 11, 35], ["ENOMEM", 12, 12], ["EACCES", 13, 13],
  ["EINVAL", 22, 22], ["ENFILE", 23, 23], ["EMFILE", 24, 24],
  ["EPIPE", 32, 32], ["EPROTO", 71, 100], ["ENOTSOCK", 88, 38],
  ["EPROTONOSUPPORT", 93, 43], ["EAFNOSUPPORT", 97, 47],
  ["EADDRINUSE", 98, 48], ["EADDRNOTAVAIL", 99, 49], ["ENETDOWN", 100, 50],
  ["ENETUNREACH", 101, 51], ["ECONNABORTED", 103, 53],
  ["ECONNRESET", 104, 54], ["ENOBUFS", 105, 55], ["EISCONN", 106, 56],
  ["ENOTCONN", 107, 57], ["ETIMEDOUT", 110, 60], ["ECONNREFUSED", 111, 61],
  ["EHOSTDOWN", 112, 64], ["EHOSTUNREACH", 113, 65], ["EALREADY", 114, 37],
  ["EINPROGRESS", 115, 36],
];

// getaddrinfo's answers, with their numbers on Linux (glibc) and on macOS
const EZWIRE_GAI = [
  ["EAI_BADFLAGS", -1, 3], ["EAI_NONAME", -2, 8], ["EAI_AGAIN", -3, 2],
  ["EAI_FAIL", -4, 4], ["EAI_NODATA", -5, 7], ["EAI_FAMILY", -6, 5],
  ["EAI_SOCKTYPE", -7, 10], ["EAI_SERVICE", -8, 9],
  ["EAI_ADDRFAMILY", -9, 1], ["EAI_MEMORY", -10, 6], ["EAI_SYSTEM", -11, 11],
];

// SSL_get_error's answers, by number
const EZWIRE_SSL = ["SSL_ERROR_NONE", "SSL_ERROR_SSL", "SSL_ERROR_WANT_READ",
  "SSL_ERROR_WANT_WRITE", "SSL_ERROR_WANT_X509_LOOKUP", "SSL_ERROR_SYSCALL",
  "SSL_ERROR_ZERO_RETURN", "SSL_ERROR_WANT_CONNECT", "SSL_ERROR_WANT_ACCEPT"];

// a number's name in one of the tables above, or the fallback
function ezwire_name(table, code, fallback) {
  const col = process.platform === "darwin" ? 2 : 1;
  for (const row of table) {
    if (row[col] === code) {
      return row[0];
    }
  }
  return fallback;
}

// why a call failed, as `NAME (n)`: the errno, or with a TLS session the
// SSL_get_error answer and then the errno when there is one (wire.c's
// ezwire_cause)
function ezwire_cause(tls, sslerr, err) {
  const e = ezwire_name(EZWIRE_ERRNO, err, "errno") + " (" + err + ")";
  if (!tls) {
    return e;
  }
  const s = (sslerr >= 1 && sslerr <= 8 ? EZWIRE_SSL[sslerr] : "SSL_ERROR")
    + " (" + sslerr + ")";
  return err !== 0 ? s + ", " + e : s;
}

// the receive and send timeouts on a socket, as a struct timeval
function ezwire_wait(sys, fd, ms) {
  const mac = process.platform === "darwin";
  const tv = new BigInt64Array([BigInt(Math.floor(ms / 1000)),
    BigInt((ms % 1000) * 1000)]);
  const level = mac ? 0xffff : 1;
  sys.setsockopt(fd, level, mac ? 0x1006 : 20, sys.ptr(tv), 16);
  sys.setsockopt(fd, level, mac ? 0x1005 : 21, sys.ptr(tv), 16);
}

// a NUL-terminated copy of a string, for a C call that wants one
function ezwire_cstr(s) {
  return Buffer.from(s + "\0", "utf8");
}

// a connected, blocking socket, or -1. glibc's addrinfo is 48 bytes: the
// family at 4, the address length at 16, the sockaddr at 24 and the next
// record at 40.
function ezwire_dial(host, port, ms, late) {
  const ffi = require("bun:ffi");
  const sys = io_sys();
  const hints = new Uint8Array(48);
  new DataView(hints.buffer).setInt32(8, 1, true); // ai_socktype SOCK_STREAM
  const out = new BigUint64Array(1);
  const rc = ezwire_dns().getaddrinfo(ffi.ptr(ezwire_cstr(host)),
    ffi.ptr(ezwire_cstr(String(port))), ffi.ptr(hints), ffi.ptr(out));
  late.gai = rc;
  late.err = 0;
  if (rc !== 0) {
    return -1;
  }
  const head = Number(out[0]);
  let at = head;
  let fd = -1;
  while (at !== 0 && fd < 0) {
    const family = Number(ffi.read.i32(at, 4));
    const len = Number(ffi.read.i32(at, 16));
    const addr = Number(ffi.read.ptr(at, 24));
    fd = Number(sys.socket(family, 1, 0));
    if (fd < 0) {
      late.err = Number(sys.errno());
    }
    if (fd >= 0) {
      ezwire_wait(sys, fd, ms);
    }
    if (fd >= 0 && Number(sys.connect(fd, addr, len)) < 0) {
      late.err = Number(sys.errno());
      late.late = ezwire_late_errno(late.err);
      sys.close(fd);
      fd = -1;
    }
    at = Number(ffi.read.ptr(at, 40));
  }
  ezwire_dns().freeaddrinfo(head);
  return fd;
}

// the session over an open socket. The hostname is both the name sent in the
// hello and the name the certificate is checked against.
function ezwire_shake(tls, fd, host, late) {
  const ffi = require("bun:ffi");
  const ssl = tls.SSL_new(tls.ctx);
  late.ssl = 1;
  late.err = 0;
  if (ssl === null) {
    return null;
  }
  tls.SSL_set_fd(ssl, fd);
  const name = ffi.ptr(ezwire_cstr(host));
  tls.SSL_ctrl(ssl, 55, 0n, name); // SNI, TLSEXT_NAMETYPE_host_name
  tls.SSL_set1_host(ssl, name);
  const n = tls.SSL_connect(ssl);
  if (n !== 1) {
    const code = Number(io_sys().errno());
    const why = tls.SSL_get_error(ssl, n);
    late.ssl = why;
    late.err = code;
    late.late = why === 2 || why === 3 || ezwire_late_errno(code);
    tls.SSL_free(ssl);
    return null;
  }
  return ssl;
}

// the whole request out, over TLS when there is a session: a string as its
// UTF-8, or a Uint8Array as its bytes
function ezwire_say(tls, fd, ssl, text, late) {
  const ffi = require("bun:ffi");
  const b = typeof text === "string" ? new TextEncoder().encode(text) : text;
  let at = 0;
  while (at < b.length) {
    const part = b.subarray(at);
    const n = ssl === null
      ? Number(io_sys().send(fd, ffi.ptr(part), part.length, 0))
      : tls.SSL_write(ssl, ffi.ptr(part), part.length);
    if (n <= 0) {
      const code = Number(io_sys().errno());
      const why = ssl === null ? 0 : tls.SSL_get_error(ssl, n);
      late.ssl = why;
      late.err = code;
      late.late = why === 2 || why === 3 || ezwire_late_errno(code);
      return false;
    }
    at += n;
  }
  return true;
}

// one receive into b: the count, 0 once the peer is done, or -1 with
// late.late set when it ran out of time. A TLS read that stops for any reason
// other than the peer being done is a cut connection, not a short body:
// SSL_ERROR_ZERO_RETURN is 6 and SSL_ERROR_SYSCALL with nothing read is 5, and
// those two are the only clean ends.
function ezwire_recv(tls, fd, ssl, b, flags, late) {
  const ffi = require("bun:ffi");
  const n = ssl === null
    ? Number(io_sys().recv(fd, ffi.ptr(b), b.length, flags))
    : tls.SSL_read(ssl, ffi.ptr(b), b.length);
  if (n > 0) {
    return n;
  }
  const code = Number(io_sys().errno());
  late.ssl = 0;
  late.err = code;
  if (ssl === null) {
    late.late = n < 0 && ezwire_late_errno(code);
    return n < 0 ? -1 : 0;
  }
  const why = tls.SSL_get_error(ssl, n);
  late.ssl = why;
  if (why === 6 || (why === 5 && n === 0)) {
    return 0;
  }
  late.late = why === 2 || why === 3 || ezwire_late_errno(code);
  return -1;
}

// the open exchanges, by connection number
function ezwire_conns() {
  if (globalThis.EZ_WIRE_CONNS === undefined) {
    globalThis.EZ_WIRE_CONNS = new Map();
    globalThis.EZ_WIRE_NEXT = 0;
  }
  return globalThis.EZ_WIRE_CONNS;
}

// connect, shake hands, send the request and then the tail's octets byte for
// byte, and answer a connection number
function ezwire_open(spec, tail) {
  const bytes = io_unlist(tail);
  if (bytes === null) {
    return "22\na body octet is past 255";
  }
  const cut = [];
  let at = 0;
  while (cut.length < 3) {
    const n = spec.indexOf("\n", at);
    if (n < 0) {
      return "22\na malformed request spec";
    }
    cut.push(spec.slice(at, n));
    at = n + 1;
  }
  const secure = cut[0] === "tls" || cut[0].startsWith("tls ");
  const ms = ezwire_ms(cut[0]);
  const late = { late: false };
  const tls = secure ? ezwire_tls() : null;
  if (secure && tls === null) {
    return "1\ncould not load libssl at run time; "
      + "install openssl or point EZ_LIBSSL at the library";
  }
  const fd = ezwire_dial(cut[1], cut[2], ms, late);
  if (fd < 0) {
    if (late.gai !== 0) {
      return "6\ncould not resolve " + cut[1] + ": "
        + ezwire_name(EZWIRE_GAI, late.gai, "EAI") + " (" + late.gai + ")";
    }
    return late.late
      ? "28\nconnecting to " + cut[1] + " port " + cut[2] + " took over "
        + ms + " ms"
      : "7\ncould not reach " + cut[1] + " port " + cut[2] + ": "
        + ezwire_cause(false, 0, late.err);
  }
  const ssl = secure ? ezwire_shake(tls, fd, cut[1], late) : null;
  if (secure && ssl === null) {
    io_sys().close(fd);
    return late.late
      ? "28\nthe TLS handshake with " + cut[1] + " took over " + ms + " ms"
      : "35\nthe TLS handshake with " + cut[1] + " failed: "
        + ezwire_cause(true, late.ssl, late.err);
  }
  if (!ezwire_say(tls, fd, ssl, spec.slice(at), late)
    || !ezwire_say(tls, fd, ssl, bytes, late)) {
    if (ssl !== null) {
      tls.SSL_shutdown(ssl);
      tls.SSL_free(ssl);
    }
    io_sys().close(fd);
    return late.late
      ? "28\nsending the request to " + cut[1] + " took over " + ms + " ms"
      : "55\nthe request to " + cut[1] + " could not be sent: "
        + ezwire_cause(ssl !== null, late.ssl, late.err);
  }
  const conns = ezwire_conns();
  const id = globalThis.EZ_WIRE_NEXT;
  globalThis.EZ_WIRE_NEXT = (id + 1) % 4294967296;
  conns.set(id, { fd: fd, ssl: ssl, tls: tls, host: cut[1], ms: ms,
    dec: new TextDecoder("utf-8", { ignoreBOM: true }), done: false });
  return "0\n" + id;
}

// the next octets: one receive that waits (bounded by the timeout), then
// whatever has already arrived behind it, without waiting, up to 1 MiB. The
// decoder streams, so a UTF-8 sequence cut at the end waits for the next
// read; once the server has closed, what it held goes out and then nothing.
function ezwire_read(id) {
  const c = ezwire_conns().get(id);
  if (c === undefined) {
    return "22\nno such exchange";
  }
  const mac = process.platform === "darwin";
  const late = { late: false };
  const b = new Uint8Array(16384);
  let text = "";
  while (text === "" && !c.done) {
    const n = ezwire_recv(c.tls, c.fd, c.ssl, b, 0, late);
    if (n < 0) {
      return late.late
        ? "28\n" + c.host + " sent nothing for " + c.ms + " ms"
        : "56\nthe answer from " + c.host + " was cut short: "
        + ezwire_cause(c.ssl !== null, late.ssl, late.err);
    }
    if (n === 0) {
      c.done = true;
      text = c.dec.decode();
      break;
    }
    text += c.dec.decode(b.subarray(0, n), { stream: true });
    let total = n;
    while (total + 16384 <= 1048576) {
      if (c.ssl !== null && c.tls.SSL_pending(c.ssl) <= 0) {
        break;
      }
      const more = ezwire_recv(c.tls, c.fd, c.ssl, b,
        c.ssl === null ? (mac ? 0x80 : 0x40) : 0, { late: false });
      if (more === 0) {
        c.done = true;
        text += c.dec.decode();
      }
      if (more <= 0) {
        break;
      }
      total += more;
      text += c.dec.decode(b.subarray(0, more), { stream: true });
    }
  }
  return "0\n" + text;
}

// close an exchange's session and socket
function ezwire_close(id) {
  const conns = ezwire_conns();
  const c = conns.get(id);
  if (c !== undefined) {
    if (c.ssl !== null) {
      c.tls.SSL_shutdown(c.ssl);
      c.tls.SSL_free(c.ssl);
    }
    io_sys().close(c.fd);
    conns.delete(id);
  }
  return { $: CID(Unit) };
}

io_eff(CID(ezwire.open), ezwire_open);
io_eff(CID(ezwire.read), ezwire_read);
io_eff(CID(ezwire.close), ezwire_close);
