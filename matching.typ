#let wild(name) = metadata((wildcard: name))
#let is-wildcard(it) = (
  type(it) == content and
  it.func() == metadata and
  type(it.value) == dictionary and
  "wildcard" in it.value
)
#let wildcard-name(it) = it.value.wildcard

#let match(pattern, expr, ctx: (:)) = {
  
  if is-wildcard(pattern) {
    let name = wildcard-name(pattern)
    if name in ctx {
      if ctx.at(name) != expr { return false }
    } else {
      ctx.insert(name, expr)
    }

  } else if type(pattern) == content {
    if type(expr) != content { return false }
    if pattern.func() != expr.func() { return false }

    for (key, left) in pattern.fields() {
      if key not in expr.fields() { return false }
      let right = expr.at(key)
      ctx = match(left, right, ctx: ctx)
      if ctx == false { return false }
    }

  } else if type(pattern) == array {
    if type(expr) != array { return false }
    if pattern.len() != expr.len() { return false }

    for (i, left) in pattern.enumerate() {
      let right = expr.at(i)
      ctx = match(left, right, ctx: ctx)
      if ctx == false { return false }
    }

  } else {
    if pattern != expr { return false }
  }

  return ctx
}

#match($sin(arcsin(wild("x"))) = wild("x")$, $sin(arcsin(A)) = A$)

#$x + oo(a b)$.body.children


