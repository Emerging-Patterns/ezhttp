import Base
import ../src/url.bend as Url

# For every text whose `#` split starts with `hier`, dropping the fragment
# keeps exactly `hier`: everything from the first `#` on, a `?` in it
# included, is gone before the query is looked for.

# LAW (RFC 3986 §3.5): the fragment is everything after the first `#`
law frag_first:
  for s: String
  for hier: String
  for rest: List<&2, String>
  for e: {hier <> rest == String.split(s, '#') : List<&2, String>}
  {Url.frag.drop(s) == hier : String}
