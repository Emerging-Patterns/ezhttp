# A named reference's text `s` (with its `;` when it has one) is replaced by
# the characters of the longest name in the HTML Standard's named character
# references table (§13.5, trusted in src/entities.bend) that `s` starts
# with, and the rest of `s` after that name is written as it is; so `&amp;`
# is `&`, a legacy name such as `&amp` or `&not` is read without its `;` and
# `&notit;` is `¬it;`. With no such name, `&` and `s` are written as they
# are. Rows are compared in table order and a later row replaces the best
# only when it is longer.
import Base
import ../src/unescape.bend as Ref
import ../src/entities.bend as Ents

# LAW (§13.2.5.73): a name is read against the whole table, with no best yet
law ref_named:
  for +s: String
  {Ref.named(s) == Ref.named.of(Ref.best(Ents.table(), s, None{}), s)
    : String}

# LAW: with no name the text starts with, `&` and the text are written as
# they are
law ref_named_none:
  for s: String
  {Ref.named.of(None{}, s) == SCon{'&', s} : String}

# LAW: with one, its characters, then the text after it as written
law ref_named_some:
  for +name: String
  for first: U32
  for second: U32
  for s: String
  {Ref.named.of(Some{Ents.Ref{name, first, second}}, s)
    == Ref.chars(first, second) ++ String.drop(s, String.length(name))
    : String}

# LAW: after the last row, the best so far
law ref_best_nil:
  for s: String
  for sofar: Maybe<&2, Ents.Ref>
  {Ref.best([], s, sofar) == sofar : Maybe<&2, Ents.Ref>}

# LAW: the rows are read in order, each against the best so far
law ref_best_cons:
  for r: Ents.Ref
  for t: List<&2, Ents.Ref>
  for +s: String
  for +sofar: Maybe<&2, Ents.Ref>
  {Ref.best(r <> t, s, sofar) == Ref.best(t, s, Ref.best.step(sofar, r, s))
    : Maybe<&2, Ents.Ref>}

# LAW: a row is a candidate when the text starts with its name
law ref_step:
  for +sofar: Maybe<&2, Ents.Ref>
  for +name: String
  for first: U32
  for second: U32
  for +s: String
  {Ref.best.step(sofar, Ents.Ref{name, first, second}, s)
    == Ref.best.hit(sofar, Ents.Ref{name, first, second}, name,
      String.starts_with(s, name)) : Maybe<&2, Ents.Ref>}

# LAW: a row whose name the text does not start with keeps the best
law ref_hit_miss:
  for sofar: Maybe<&2, Ents.Ref>
  for r: Ents.Ref
  for name: String
  {Ref.best.hit(sofar, r, name, False{}) == sofar : Maybe<&2, Ents.Ref>}

# LAW: a candidate is compared by length with the best
law ref_hit_take:
  for +sofar: Maybe<&2, Ents.Ref>
  for +r: Ents.Ref
  for +name: String
  {Ref.best.hit(sofar, r, name, True{})
    == Ref.best.take(sofar, r, Nat.is_lt(Ref.best.len(sofar),
      String.length(name))) : Maybe<&2, Ents.Ref>}

# LAW: a longer candidate is the new best
law ref_take_longer:
  for sofar: Maybe<&2, Ents.Ref>
  for r: Ents.Ref
  {Ref.best.take(sofar, r, True{}) == Some{r} : Maybe<&2, Ents.Ref>}

# LAW: any other keeps the best
law ref_take_keep:
  for sofar: Maybe<&2, Ents.Ref>
  for r: Ents.Ref
  {Ref.best.take(sofar, r, False{}) == sofar : Maybe<&2, Ents.Ref>}

# LAW: no best yet is length 0
law ref_len_none:
  for m: Maybe<&2, Ents.Ref>
  for e: {None{} == m : Maybe<&2, Ents.Ref>}
  {Ref.best.len(m) == 0n : Nat}

# LAW: a best is its name's length
law ref_len_some:
  for +name: String
  for first: U32
  for second: U32
  {Ref.best.len(Some{Ents.Ref{name, first, second}}) == String.length(name)
    : Nat}

# LAW: a row with one code point stands for that character
law ref_chars_one:
  for first: U32
  for +second: U32
  for e: {True{} == U32.is_eq(second, 0) : Bool}
  {Ref.chars(first, second) == SCon{Chr{first}, ""} : String}

# LAW: a row with two stands for both, in order
law ref_chars_two:
  for first: U32
  for +second: U32
  for e: {False{} == U32.is_eq(second, 0) : Bool}
  {Ref.chars(first, second) == SCon{Chr{first}, SCon{Chr{second}, ""}}
    : String}
