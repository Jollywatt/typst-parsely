#let is-space(it) = (
  repr(it.func()) == "space" or 
  repr(it.func()) == "symbol" and it.fields().text.trim() == ""
)

#let is-content-type(name, it) = type(it) == content and repr(it.func()) == name
#let is-equation = is-content-type.with("equation")
#let is-sequence = is-content-type.with("sequence")

#let sequence-children(it) = {
  if is-sequence(it) {
    it.children
  } else if type(it) == array {
    it
  } else {
    (it,)
  }
}

#let squeeze-space(seq) = seq.filter(it => not is-space(it))

#let flatten-sequence(seq) = {
  sequence-children(seq).map(sequence-children).flatten()
}


#let is-node(it) = type(it) == dictionary

#let walk(it, pre: it => it, post: it => it) = {
  if not is-node(it) { return it }
  let w(it) = walk(it, pre: pre, post: post)
  post(pre(it).pairs().map(((k, v)) => {
    if type(v) == array { (k, v.map(w)) }
    else if is-node(v) { (k, w(v)) }
    else { (k, v) }
  }).to-dict())
}

#let walk-array(it, pre: it => it, post: it => it) = {
  if type(it) != array { return it }
  post(pre(it).map(walk-array.with(pre: pre, post: post)))
}
