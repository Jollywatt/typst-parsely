#let is-space(it) = {
  if type(it) == str { return it.trim() == "" }
  if type(it) == content {
    if repr(it.func()) == "space" { return true }
    if repr(it.func()) == "symbol" {
      return it.fields().text.trim() == ""
    }
  }
  return false
}

#let is-content-type(name, it) = type(it) == content and repr(it.func()) == name
#let is-equation = is-content-type.with("equation")
#let is-sequence = is-content-type.with("sequence")

#let as-array(it) = {
  if is-sequence(it) { it.children }
  else if type(it) == array { it }
  else { (it,) }
}
#let flatten-sequence(seq) = as-array(seq).map(as-array).flatten()

#let is-node(it) = type(it) == dictionary and "head" in it

#let walk(it, pre: it => it, post: it => it, leaf: it => it) = {
  if not is-node(it) { return leaf(it) }
  let w(it) = walk(it, pre: pre, post: post, leaf: leaf)
  it = pre(it)
  it.args = it.args.map(w)
  it.slots = it.slots.keys().zip(it.slots.values().map(w)).to-dict()
  post(it)
}


#let walk-array(it, pre: it => it, post: it => it, leaf: it => it) = {
  if type(it) != array { return leaf(it) }
  post(pre(it).map(walk-array.with(pre: pre, post: post, leaf: leaf)))
}

#let content-positional-args = (
  symbol: ("text",),
  styled: ("child", "styles"),
  metadata:  ("value",),
  lr: ("body",),
  equation: ("body",),
  attach: ("base",),
  primes: ("count",),
)
#let construct-content(fn, fields) = {
  if repr(fn) == "sequence" {
    fields.children.join()
  } else if repr(fn) in content-positional-args {
    let pos = ()
    for k in content-positional-args.at(repr(fn)) {
      pos.push(fields.remove(k))
    }
    fn(..pos, ..fields)
  } else {
    let fname = repr(fn)
    fn(..fields)
  }
}


#let walk-content(it, pre: it => it, post: it => it) = {
  if type(it) != content { return it }
  let w(it) = walk-content(it, pre: pre, post: post)
  let fields = pre(it).fields().pairs().map(((k, v)) => {
    if type(v) == array { (k, v.map(w)) }
    else if type(it) == content { (k, w(v)) }
    else { (k, v) }
  }).to-dict()
  post(construct-content(it.func(), fields))
}


#let tree-node-depths(tree) = walk(tree, post: it => {
  let depth = 0
  for sub in it.args + it.slots.values() {
    if type(sub) == dictionary and "depth" in sub {
      depth = calc.max(depth, sub.depth)
    }
  }
  it + (depth: depth + 1)
})