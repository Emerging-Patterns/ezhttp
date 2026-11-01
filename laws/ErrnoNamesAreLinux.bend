# The name of an error number (`wire.errno.name`) is its Linux errno symbol
# for 1 `EPERM`, 2 `ENOENT`, 4 `EINTR`, 5 `EIO`, 9 `EBADF`, 11 `EAGAIN`, 12
# `ENOMEM`, 13 `EACCES`, 22 `EINVAL`, 23 `ENFILE`, 24 `EMFILE`, 32 `EPIPE`,
# 71 `EPROTO`, 88 `ENOTSOCK`, 93 `EPROTONOSUPPORT`, 97 `EAFNOSUPPORT`, 98
# `EADDRINUSE`, 99 `EADDRNOTAVAIL`, 100 `ENETDOWN`, 101 `ENETUNREACH`, 103
# `ECONNABORTED`, 104 `ECONNRESET`, 105 `ENOBUFS`, 106 `EISCONN`, 107
# `ENOTCONN`, 110 `ETIMEDOUT`, 111 `ECONNREFUSED`, 112 `EHOSTDOWN`, 113
# `EHOSTUNREACH`, 114 `EALREADY` and 115 `EINPROGRESS`, and `errno` for
# every other number.
#
# also rests on: laws/PhraseTableLookup.bend
import Base
import ../src/http.bend as Http
import ../src/wirespec.bend as Spec

# the Linux errno symbols laws/ErrnoNamesAreLinux.bend lists, as the law
# states them
def errnos() -> List<&2, Http.Phrase>:
  [Http.P{1, "EPERM"}, Http.P{2, "ENOENT"}, Http.P{4, "EINTR"},
    Http.P{5, "EIO"}, Http.P{9, "EBADF"}, Http.P{11, "EAGAIN"},
    Http.P{12, "ENOMEM"}, Http.P{13, "EACCES"}, Http.P{22, "EINVAL"},
    Http.P{23, "ENFILE"}, Http.P{24, "EMFILE"}, Http.P{32, "EPIPE"},
    Http.P{71, "EPROTO"}, Http.P{88, "ENOTSOCK"},
    Http.P{93, "EPROTONOSUPPORT"}, Http.P{97, "EAFNOSUPPORT"},
    Http.P{98, "EADDRINUSE"}, Http.P{99, "EADDRNOTAVAIL"},
    Http.P{100, "ENETDOWN"}, Http.P{101, "ENETUNREACH"},
    Http.P{103, "ECONNABORTED"}, Http.P{104, "ECONNRESET"},
    Http.P{105, "ENOBUFS"}, Http.P{106, "EISCONN"},
    Http.P{107, "ENOTCONN"}, Http.P{110, "ETIMEDOUT"},
    Http.P{111, "ECONNREFUSED"}, Http.P{112, "EHOSTDOWN"},
    Http.P{113, "EHOSTUNREACH"}, Http.P{114, "EALREADY"},
    Http.P{115, "EINPROGRESS"}]

# LAW: an error number's name is the one the table lists for it, or `errno`
# when the table lists none (reason_in_nil, reason_in_hit, reason_in_miss
# read the table)
law errno_names:
  for +n: U32
  {Spec.wire.errno.name(n) == Spec.wire.errno.or(Http.reason.in(errnos(), n))
    : String}

# LAW: a number the table has no name for is named `errno`
law errno_or_none:
  for s: String
  for e: {True{} == String.is_empty(s) : Bool}
  {Spec.wire.errno.or(s) == "errno" : String}

# LAW: a name the table gives is kept as it is
law errno_or_named:
  for s: String
  for e: {False{} == String.is_empty(s) : Bool}
  {Spec.wire.errno.or(s) == s : String}
