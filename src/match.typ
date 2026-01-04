#import "util.typ": is-space

#let wild(name, many: false) = metadata((wild: name, many: many))
#let wilds = wild.with(many: true)

#let is-wild(it) = (
  type(it) == content and
  it.func() == metadata and
  type(it.value) == dictionary and
  "wild" in it.value
)
#let wild-name(it) = it.value.wild

#let tight = metadata((tight: true))

#let tighten(tokens) = {
  let out = ()
  let pending = ()
  let is-tight = false
  for t in tokens {
    if is-space(t) {
      if not is-tight { pending.push(t) }
    } else if t == tight {
      is-tight = true
      out.push(t)
      pending = ()
    } else {
      if not is-tight {
        out += pending
        pending = ()
      }
      is-tight = false
      out.push(t)
    }
  }
  return out
}


#let unwrap-styled(it) = {
  if repr(it.func()) == "styled" { it.child }
  else { it }
}


#let match(pattern, expr, ctx: (:)) = {
  
  if is-wild(pattern) {
    let name = wild-name(pattern)
    if name in ctx {
      if ctx.at(name) != expr { return false }
    } else {
      ctx.insert(name, expr)
    }

  } else if type(pattern) == content {
    if type(expr) != content { return false }

    pattern = unwrap-styled(pattern)
    expr = unwrap-styled(expr)

    if pattern.func() != expr.func() { return false }

    for (key, left) in pattern.fields() {
      if key not in expr.fields() { return false }
      let right = expr.at(key)
      ctx = match(left, right, ctx: ctx)
      if ctx == false { return false }
    }

  } else if type(pattern) == array {
    if type(expr) != array { return false }

    pattern = tighten(pattern)

    let (pi, ei) = (0, 0)
    let is-tight = false
    let p-space = false
    while pi < pattern.len() and ei < expr.len() {
      let p = pattern.at(pi)
      let e = expr.at(ei)

      if p == tight {
        is-tight = true
        pi += 1
        continue
      }

      if is-wild(p) and p.value.many == true {
        let p-next = pattern.at(pi + 1, default: none)
        if p-next == none {
          // trailing wild matches rest of expr
          ctx.insert(wild-name(p), expr.slice(ei).join())
          
        } else {
          // wild matches until next pattern token is seen
          let ei-end = ei
          while ei-end < expr.len() {
            let m = match(p-next, expr.at(ei-end), ctx: ctx)
            if m != false { break }
            ei-end += 1
          }
          ctx.insert(wild-name(p), expr.slice(ei, ei-end).join())
          pi += 1
          ei = ei-end
          continue 
        }

      } else {
        let m = match(p, e, ctx: ctx)
        if m == false {
          // ignore whitespace mismatches
          if is-space(p) {
            pi += 1
            continue
          } else if is-space(e) and not is-tight {
            ei += 1
            continue
          }
          return false
        } else {
          ctx = m
        }
      }

      pi += 1
      ei += 1

      is-tight = false
    }


  } else {
    if pattern != expr { return false }
  }

  return ctx
}