# For every method and status, a reply is written with its head only, no
# octets and no chunks, exactly when the method is `HEAD` (RFC 9110 §9.3.2)
# or the status is 204 or 304 (`step.bare`, RFC 9110 §15.3.5, §15.4.5); a
# packed octets reply written bare carries the head of an empty body, as a
# text reply does (laws/HeadAndNoContentHaveNoBody.bend).
import Base
import ../src/http.bend as Http
import ../src/step.bend as Step

# LAW (RFC 9110 §9.3.2): a reply to HEAD is written bare
law bare_head:
  for +status: U32
  {Step.step.bare("HEAD", status) == True{} : Bool}

# LAW: a reply to any other method is bare exactly when its status is 204
# or 304
law bare_other:
  for +method: String
  for e: {False{} == String.eq(method, "HEAD") : Bool}
  for +status: U32
  {Step.step.bare(method, status) == Http.status.nocontent(status) : Bool}

# LAW: a 204 or 304 is exactly what nocontent names
law nocontent_is:
  for +code: U32
  {Http.status.nocontent(code)
    == Bool.or(U32.is_eq(code, 204), U32.is_eq(code, 304)) : Bool}
