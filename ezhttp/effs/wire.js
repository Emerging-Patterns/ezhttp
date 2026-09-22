// ezwire.talk: the JS lane's twin of wire.c, and the same exchange.
//
// Bend's JS backend drives raw file descriptors through bun:ffi and runs its
// own poll loop over them, so node's `net` and `tls` modules are not an option
// here: they are built on the event loop that backend bypasses. The socket is
// opened with the same libc calls the C twin uses, and OpenSSL is opened the
// same way too, with dlopen at run time, because neither lane has a link line
// that could name -lssl.
//
// Every name here is a `function`, never a top-level `const`: each effect's JS
// lands in one concatenated script, and a redeclared `const` there is fatal.

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

// a NUL-terminated copy of a string, for a C call that wants one
function ezwire_cstr(s) {
  return Buffer.from(s + "\0", "utf8");
}

// a connected, blocking socket, or -1. glibc's addrinfo is 48 bytes: the
// family at 4, the address length at 16, the sockaddr at 24 and the next
// record at 40.
function ezwire_dial(host, port) {
  const ffi = require("bun:ffi");
  const sys = io_sys();
  const hints = new Uint8Array(48);
  new DataView(hints.buffer).setInt32(8, 1, true); // ai_socktype SOCK_STREAM
  const out = new BigUint64Array(1);
  const rc = ezwire_dns().getaddrinfo(ffi.ptr(ezwire_cstr(host)),
    ffi.ptr(ezwire_cstr(String(port))), ffi.ptr(hints), ffi.ptr(out));
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
    if (fd >= 0 && Number(sys.connect(fd, addr, len)) < 0) {
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
function ezwire_shake(tls, fd, host) {
  const ffi = require("bun:ffi");
  const ssl = tls.SSL_new(tls.ctx);
  if (ssl === null) {
    return null;
  }
  tls.SSL_set_fd(ssl, fd);
  const name = ffi.ptr(ezwire_cstr(host));
  tls.SSL_ctrl(ssl, 55, 0n, name); // SNI, TLSEXT_NAMETYPE_host_name
  tls.SSL_set1_host(ssl, name);
  if (tls.SSL_connect(ssl) !== 1) {
    tls.SSL_free(ssl);
    return null;
  }
  return ssl;
}

// the whole request out, over TLS when there is a session
function ezwire_say(tls, fd, ssl, text) {
  const ffi = require("bun:ffi");
  const b = new TextEncoder().encode(text);
  let at = 0;
  while (at < b.length) {
    const part = b.subarray(at);
    const n = ssl === null
      ? Number(io_sys().send(fd, ffi.ptr(part), part.length, 0))
      : tls.SSL_write(ssl, ffi.ptr(part), part.length);
    if (n <= 0) {
      return false;
    }
    at += n;
  }
  return true;
}

// everything the server sends before it closes. A TLS read that stops for any
// reason other than the peer being done is a cut connection, not a short body:
// SSL_ERROR_ZERO_RETURN is 6 and SSL_ERROR_SYSCALL with nothing read is 5, and
// those two are the only clean ends.
function ezwire_hear(tls, fd, ssl) {
  const ffi = require("bun:ffi");
  const b = new Uint8Array(16384);
  const parts = [];
  let bad = false;
  for (;;) {
    const n = ssl === null
      ? Number(io_sys().recv(fd, ffi.ptr(b), b.length, 0))
      : tls.SSL_read(ssl, ffi.ptr(b), b.length);
    if (n <= 0) {
      if (ssl === null) {
        bad = n < 0;
      } else {
        const why = tls.SSL_get_error(ssl, n);
        bad = !(why === 6 || (why === 5 && n === 0));
      }
      break;
    }
    parts.push(b.slice(0, n));
  }
  let len = 0;
  for (const p of parts) {
    len += p.length;
  }
  const all = new Uint8Array(len);
  let at = 0;
  for (const p of parts) {
    all.set(p, at);
    at += p.length;
  }
  return { bad: bad,
    text: new TextDecoder("utf-8", { ignoreBOM: true }).decode(all) };
}

function ezwire_talk(spec) {
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
  const secure = cut[0] === "tls";
  const tls = secure ? ezwire_tls() : null;
  if (secure && tls === null) {
    return "1\ncould not load libssl at run time; "
      + "install openssl or point EZ_LIBSSL at the library";
  }
  const fd = ezwire_dial(cut[1], cut[2]);
  if (fd < 0) {
    return "6\ncould not reach " + cut[1] + " port " + cut[2];
  }
  const ssl = secure ? ezwire_shake(tls, fd, cut[1]) : null;
  if (secure && ssl === null) {
    io_sys().close(fd);
    return "35\nthe TLS handshake with " + cut[1] + " failed";
  }
  let out;
  if (!ezwire_say(tls, fd, ssl, spec.slice(at))) {
    out = "55\nthe request to " + cut[1] + " could not be sent";
  } else {
    const got = ezwire_hear(tls, fd, ssl);
    out = got.bad ? "56\nthe answer from " + cut[1] + " was cut short"
      : "0\n" + got.text;
  }
  if (ssl !== null) {
    tls.SSL_shutdown(ssl);
    tls.SSL_free(ssl);
  }
  io_sys().close(fd);
  return out;
}
