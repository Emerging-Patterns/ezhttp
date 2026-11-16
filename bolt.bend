# bolt.bend: how bolt lints this repo. See bolt/config.bend for groups and
# levels.
import Base

# what will fail or blow up
def correctness() -> String:
  "error"

# what is probably a slip
def suspicious() -> String:
  "error"

# comments and whitespace
def style() -> String:
  "error"

# a pure def named by no law
def laws() -> String:
  "error"

# a law with no `for` or `exs` binder
def closed() -> String:
  "error"

# a def no quantified law reaches
def coverage() -> String:
  "error"
