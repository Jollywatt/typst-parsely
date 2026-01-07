#let is-space(it) = (
  repr(it.func()) == "space" or 
  repr(it.func()) == "symbol" and it.fields().text.trim() == ""
)

#let is-content-type(name, it) = type(it) == content and repr(it.func()) == name
#let is-equation = is-content-type.with("equation")
#let is-sequence = is-content-type.with("sequence")

#let as-array(it) = {
  if is-sequence(it) { it.children }
  else if type(it) == array { it }
  else { (it,) }
}
#let flatten-sequence(seq) = as-array(seq).map(as-array).flatten()

#let squeeze-space(seq) = seq.filter(it => not is-space(it))

#let is-node(it) = type(it) == dictionary and "head" in it

#let walk(it, pre: it => it, post: it => it, leaf: it => it) = {
  if not is-node(it) { return leaf(it) }
  let w(it) = walk(it, pre: pre, post: post, leaf: leaf)
  post(pre(it).pairs().map(((k, v)) => {
    if type(v) == array { (k, v.map(w)) }
    else if is-node(v) { (k, w(v)) }
    else { (k, leaf(v)) }
  }).to-dict())
}

#let walk-array(it, pre: it => it, post: it => it, leaf: it => it) = {
  if type(it) != array { return leaf(it) }
  post(pre(it).map(walk-array.with(pre: pre, post: post, leaf: leaf)))
}


#let dict-to-content(fn, fields) = {
  if repr(fn) in ("symbol", "raw") {
    let (text, ..rest) = fields
    fn(text, ..rest)
  } else if repr(fn) == "styled" {
    let (child, styles) = fields
    fn(child, styles)
  } else if fn == metadata {
    let (value,) = fields
    metadata(value)
  } else if repr(fn) == "sequence" {
    fields.children.map(it => [#it]).join()
  } else if repr(fn) == "lr" {
    let (body,) = fields
    math.lr(body)
  } else if fn == math.equation {
    let (body, block) = fields
    math.equation(body, block: block)
  } else if fn == math.attach {
    let (base, ..rest) = fields
    math.attach(base, ..rest)
  } else if fn == math.primes {
    let (count, ..rest) = fields
    math.primes(count)
  } else if fn == math.root {
    let (radicand, ..rest) = fields
    math.root([8], [d])
  } else if fn == math.underbrace {
    let (body, annotation, ..rest) = fields
    math.underbrace(body, annotation, ..rest)
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
  post(dict-to-content(it.func(), fields))
}


#let tree-node-depths(tree) = walk(tree, post: it => {
  let depth = 0
  for (k, v) in it {
    if type(v) == dictionary and "depth" in v {
      depth = calc.max(depth, v.depth)
    } else if type(v) == array {
      for vi in v {
        if type(vi) == dictionary and "depth" in vi {
          if vi.depth > depth { depth = vi.depth }
        }
      }
    }
  }
  it + (depth: depth + 1)
})