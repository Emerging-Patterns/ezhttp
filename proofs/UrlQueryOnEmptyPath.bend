# proofs of laws/UrlQueryOnEmptyPath.bend
import Base
import ../src/url.bend as Url
import ../laws/UrlQueryOnEmptyPath.bend as Laws

def Laws.path_target_query(path, query, e):
  %e : {Url.path.target.of(path, query, _) == path ++ "?" ++ query : String}
  {==}
