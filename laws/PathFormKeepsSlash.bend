# The path form writes `/` as itself and the component form writes it as
# `%2F`; on every other character the two forms agree.
import Base
import ../src/pct.bend as Pct

# LAW: the path form writes "/" as itself
law path_keeps_slash:
  for rest: String
  {Pct.one(True{}, 47, rest) == SCon{'/', rest} : String}

# LAW: the component form writes "/" as %2F
law component_escapes_slash:
  for rest: String
  {Pct.one(False{}, 47, rest) == SCon{'%', SCon{'2', SCon{'F', rest}}}
    : String}

# LAW: on every character but "/" the component form writes what the path
# form writes
law component_is_path_elsewhere:
  for +c: U32
  for e: {False{} == U32.is_eq(c, 47) : Bool}
  for rest: String
  {Pct.one(False{}, c, rest) == Pct.one(True{}, c, rest) : String}
