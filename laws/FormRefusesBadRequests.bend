# `form.body(boundary, parts)` (`src/form.bend`, exported as `form_body`,
# with `form_field` and `form_file`) builds a `multipart/form-data` request
# body (RFC 7578) from text fields and file parts, and does no IO. A file
# part's content is packed `Bytes`. The builder first looks for the
# delimiter in each file's bytes (`Bytes.find`, trusted in src/wire.bend),
# which gives the parts' plan (`form.plan`): every decision is made there,
# over the parts with each file's content replaced by whether the delimiter
# occurs in it. The plan lays the body out as runs of octets and file
# contents in order, and the body (`Body.Octets`) is those runs and each
# file's bytes, unchanged, put together in that order (trusted in
# src/wire.bend), so a file part's bytes reach the wire unchanged
# (laws/OctetBodiesSentUnchanged.bend). The caller chooses the boundary and
# the builder refuses one that could be misread. Text is written as its
# UTF-8 octets (RFC 3629 §3).
#
# For every boundary `b` and list of parts, the builder refuses exactly
# these, in this order, each with its own reason: a boundary that is not
# valid (laws/FormBoundaryRules.bend); a boundary whose delimiter `--b`
# occurs in some part's content (laws/FormBoundaryRules.bend); a file part
# whose content type holds a CR or an LF. Every other request is planned:
# its Content-Type field value is exactly `multipart/form-data;
# boundary=<b>` and its body is laid out as laws/FormBodyLayout.bend says.
import Base
import ../src/form.bend as Form

# --- multipart/form-data bodies ---

# LAW: a boundary that is not valid is refused
law form_bad_boundary:
  for +b: String
  for ps: List<&2, Form.Part>
  for e: {False{} == Form.form.boundary.ok(b) : Bool}
  {Form.form.plan(b, ps)
    == Form.NoPlan{"the boundary must be 1 to 70 of A-Z a-z 0-9 - _ ."}
    : Form.Plan}

# LAW: a valid boundary whose delimiter occurs in a part's content is refused
law form_clash:
  for +b: String
  for +ps: List<&2, Form.Part>
  for e1: {True{} == Form.form.boundary.ok(b) : Bool}
  for e2: {True{} == Form.form.clash(b, ps) : Bool}
  {Form.form.plan(b, ps) == Form.NoPlan{"the boundary occurs in a part's content"}
    : Form.Plan}

# LAW: a file part whose content type holds a CR or LF is refused
law form_bad_type:
  for +b: String
  for +ps: List<&2, Form.Part>
  for e1: {True{} == Form.form.boundary.ok(b) : Bool}
  for e2: {False{} == Form.form.clash(b, ps) : Bool}
  for e3: {True{} == Form.form.badtype(ps) : Bool}
  {Form.form.plan(b, ps)
    == Form.NoPlan{"a file part's content type holds a CR or LF"} : Form.Plan}

# LAW (RFC 7578 §4.1): every other form is planned: its Content-Type value
# and its parts' runs
law form_ok:
  for +b: String
  for +ps: List<&2, Form.Part>
  for e1: {True{} == Form.form.boundary.ok(b) : Bool}
  for e2: {False{} == Form.form.clash(b, ps) : Bool}
  for e3: {False{} == Form.form.badtype(ps) : Bool}
  {Form.form.plan(b, ps) == Form.Plan{Form.form.type(b), Form.form.parts(b, ps)}
    : Form.Plan}

# LAW (RFC 7578 §4.1): the Content-Type field value names the boundary
law form_type:
  for b: String
  {Form.form.type(b) == "multipart/form-data; boundary=" ++ b : String}
