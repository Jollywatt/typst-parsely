#let is-expr(it) = type(it) == dictionary

#let walk(it, pre: it => it, post: it => it) = {
  if not is-expr(it) { return it }
  let w(it) = walk(it, pre: pre, post: post)
  post(pre(it).pairs().map(((k, v)) => {
    if type(v) == array { (k, v.map(w)) }
    else if is-expr(v) { (k, w(v)) }
    else { (k, v) }
  }).to-dict())
}

#let walk-array(it, pre: it => it, post: it => it) = {
  if type(it) != array { return it }
  post(pre(it).map(walk-array.with(pre: pre, post: post)))
}
