#let is-expr(it) = type(it) == dictionary and "kind" in it

#let post-walk(it, fn) = {
  if not is-expr(it) { return it }
  let f(it) = post-walk(it, fn)
  fn(it.pairs().map(((k, v)) => {
    if is-expr(v) { (k, f(v)) }
    else if type(v) == array {
      (k, v.map(f))
    }
    else { (k, v) }
  }).to-dict())
}
