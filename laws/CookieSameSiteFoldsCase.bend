# For every cookie and SameSite attribute value (named `samesite` once
# lowercased): the value is compared lowercase, so `lax`, `strict` and
# `none` in any case are stored in their canonical spelling `Lax`, `Strict`
# and `None`, and any other value is dropped and stored as empty (RFC 6265bis
# §5.6.7).
import Base
import ../src/cookie.bend as Cookie

# LAW: SameSite sets the cookie's canonical SameSite
law cookie_named_samesite:
  for c: Cookie.Cookie
  for value: String
  {Cookie.cookie.named(c, "samesite", value)
    == Cookie.cookie.site_set(c, Cookie.cookie.site(value)) : Cookie.Cookie}

# LAW: lax in any case is Lax
law cookie_site_lax:
  for +raw: String
  for e: {True{} == String.eq(String.to_lower(raw), "lax") : Bool}
  {Cookie.cookie.site(raw) == "Lax" : String}

# LAW: strict in any case is Strict
law cookie_site_strict:
  for +raw: String
  for e1: {False{} == String.eq(String.to_lower(raw), "lax") : Bool}
  for e2: {True{} == String.eq(String.to_lower(raw), "strict") : Bool}
  {Cookie.cookie.site(raw) == "Strict" : String}

# LAW: none in any case is None
law cookie_site_none:
  for +raw: String
  for e1: {False{} == String.eq(String.to_lower(raw), "lax") : Bool}
  for e2: {False{} == String.eq(String.to_lower(raw), "strict") : Bool}
  for e3: {True{} == String.eq(String.to_lower(raw), "none") : Bool}
  {Cookie.cookie.site(raw) == "None" : String}

# LAW: any other value is dropped
law cookie_site_unknown:
  for +raw: String
  for e1: {False{} == String.eq(String.to_lower(raw), "lax") : Bool}
  for e2: {False{} == String.eq(String.to_lower(raw), "strict") : Bool}
  for e3: {False{} == String.eq(String.to_lower(raw), "none") : Bool}
  {Cookie.cookie.site(raw) == "" : String}
