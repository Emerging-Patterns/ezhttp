# Every other status stops the chain, and so does any response when no hops
# are left.
import Base
import ../src/redirect.bend as Redirect

# LAW: every status other than 301, 302, 303, 307 and 308 stops the chain
law redir_other:
  for +status: U32
  for e: {False{} == Bool.or(U32.is_eq(status, 301), Bool.or(U32.is_eq(status,
    302), Bool.or(U32.is_eq(status, 303), Bool.or(U32.is_eq(status, 307),
    U32.is_eq(status, 308))))) : Bool}
  for left: Nat
  for url: String
  for +loc: String
  {Redirect.redirect.next(left, url, status, loc) == Redirect.Stop{}
    : Redirect.Hop}

# LAW: with no hops left the chain stops, whatever the response
law redir_zero:
  for url: String
  for +status: U32
  for +loc: String
  {Redirect.redirect.next(0n, url, status, loc) == Redirect.Stop{}
    : Redirect.Hop}
