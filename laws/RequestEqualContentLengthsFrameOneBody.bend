import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): identical request Content-Length values frame one body
law ask_equal_content_lengths:
  {Http.ask("POST / HTTP/1.1\r\nContent-Length: 5\r\nContent-Length: 5\r\n\r\nhello!!")
    == Http.Request{"POST", "/", [Http.H{"Content-Length", "5"},
      Http.H{"Content-Length", "5"}], "hello"} : Http.Request}
