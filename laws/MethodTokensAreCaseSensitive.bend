import Base

# LAW (RFC 9110 §9.3): method tokens are case-sensitive
law method_tokens_are_case_sensitive:
  {String.eq("GET", "get") == False{} : Bool}
