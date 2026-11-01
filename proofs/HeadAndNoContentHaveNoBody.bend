# proofs of laws/HeadAndNoContentHaveNoBody.bend
import Base
import ../src/http.bend as Http
import ../laws/HeadAndNoContentHaveNoBody.bend as Laws

def Laws.shape_head(_status, _hs, _body):
  {==}

def Laws.shape_other(_method, e, reply):
  match reply:
    case Http.Torn{why}:
      %e : {Http.reply.for.pick(Http.Torn{why}, _) == Http.Torn{why}
        : Http.Reply}
      {==}
    case Http.Reply{status, hs, body}:
      %e : {Http.reply.for.pick(Http.Reply{status, hs, body}, _)
        == Http.Reply{status, hs, body} : Http.Reply}
      {==}

def Laws.respond_204(_hs, _body):
  {==}

def Laws.respond_304(_hs, _body):
  {==}

def Laws.respond_other(status, e, hs, body):
  %e : {Http.respond.of.body(status, hs, body, _)
    == Http.respond(status, hs, body) : String}
  {==}
