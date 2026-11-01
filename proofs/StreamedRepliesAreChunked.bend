# proofs of laws/StreamedRepliesAreChunked.bend
import Base
import ../src/http.bend as Http
import ../laws/StreamedRepliesAreChunked.bend as Laws

def Laws.stream_head(status, e, hs):
  %e : {"HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
    ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
    ++ Http.te.line(Bool.not(_)) ++ "\r\n"
    == "HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ "Transfer-Encoding: chunked\r\n" ++ "\r\n" : String}
  {==}

def Laws.stream_head_bare(status, e, hs):
  %e : {"HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
    ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
    ++ Http.te.line(Bool.not(_)) ++ "\r\n"
    == "HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n" ++ Http.headers.lines(hs) ++ ""
      ++ "\r\n" : String}
  {==}

def Laws.chunk_line(_n):
  {==}

def Laws.hex_at(_n, _k):
  {==}

def Laws.hex_nib(_v):
  {==}

def Laws.chunk_empty(n, e):
  %e : {Http.chunk.frame.of(n, _) == Http.NoChunk{} : Http.Chunk}
  {==}

def Laws.chunk_some(n, e):
  %e : {Http.chunk.frame.of(n, _) == Http.Chunk{Http.chunk.line(n)} : Http.Chunk}
  {==}

def Laws.chunk_end(_s, e):
  %e : {Http.chunk.end() ++ _ == "0\r\n\r\n" : String}
  {==}
