# For every rest of a token, a method token that starts with a lowercase `g`
# is not `GET`: method tokens are compared case-sensitively (RFC 9110 §9.1),
# so `get` is not GET.
import Base

# LAW (RFC 9110 §9.1): method tokens are case-sensitive
law method_tokens_are_case_sensitive:
  for t: String
  {String.eq("GET", "g" ++ t) == False{} : Bool}
