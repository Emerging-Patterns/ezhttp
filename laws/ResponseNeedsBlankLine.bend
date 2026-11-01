import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §2.1): a response whose header section never ended is torn
law parse_needs_blank_line:
  for +raw: String
  for e: {Http.NoCut{} == Http.divide(raw, "\r\n\r\n") : Http.Cut}
  {Http.parse(raw) == Http.Torn{"the response head has no blank line after it"}
    : Http.Reply}
