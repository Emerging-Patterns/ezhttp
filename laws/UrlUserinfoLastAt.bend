import Base
import ../src/url.bend as Url

# For every authority whose `@` split ends in `hostport`, the host and port
# are read from `hostport` alone: every earlier piece, `user:pass` or a
# stray `a@b`, is userinfo and dropped.

# LAW (RFC 3986 §3.2.1): userinfo is stripped up to the last `@`
law host_after_last_at:
  for authority: String
  for hostport: String
  for e: {Some{hostport} == List.last(&2, String, String.split(authority, '@'))
    : Maybe<&2, String>}
  {Url.auth.host(authority) == hostport : String}
