#import "matching.typ": *
#import "utils.typ": *

#let is-space(it) = {
  repr(it.func()) == "space"
}

#let squeeze-space(seq) = seq.filter(it => not is-space(it))


#let parse(it, grammar) = {

  let parse-op(tokens) = {
    for (name, spec) in grammar {
      let pattern = spec.values().first()
      pattern = pattern.body

      if repr(pattern.func()) == "sequence" {
        pattern = pattern.children
      } else {
        pattern = (pattern,)
      }

      let n-ahead = pattern.len()
      if n-ahead > tokens.len() { continue }

      let m = match(pattern, tokens.slice(0, n-ahead))
      if m == false { continue }

      let op = (
        kind: spec.keys().first(),
        name: name,
        ..if "prec" in spec { (prec: spec.prec) },
        slots: m,
      )
      return (op, tokens.slice(n-ahead))
    }

    (none, tokens)
  }

  let parse-expr(tokens, min-prec) = {
    tokens = squeeze-space(tokens)
    let left = none
    
    if tokens.len() == 0 { return (left, tokens) }


    let (op, tokens) = parse-op(tokens)
    if op == none {
      left = tokens.first()
      tokens = tokens.slice(1)
    } else if op.kind == "expr" {
      left = (op: op.name, ..op.slots)
    
    // prefix
    } else if op.kind == "prefix" {
      let (right, rest) = parse-expr(tokens, op.prec)
      left = (op: op.name, ..op.slots, right: right)
      tokens = rest
    }

    // infix and postfix
    while tokens.len() > 0 {
      let (op, subtokens) = parse-op(tokens)
      if op == none { break }
      
      if op.kind == "postfix" {
        if op.prec < min-prec { break }
        left = (op: op.name, left: left)
        tokens = subtokens

      } else if op.kind == "infix" {
        if op.prec < min-prec { break }
        let (right, rest) = parse-expr(subtokens, op.prec)
        left = (op: op.name, left: left, right: right)
        tokens = rest

      } else {
        break
      }
    }
    
    (left, tokens)
  }
  
  parse-expr(it.body.children, 0)
}


#let grammar = (
  eq: (infix: $=$, prec: 0),
  dot: (infix: $dot$, prec: 2),
  sum: (infix: $+$, prec: 1),
  // unary-plus: (prefix: $+$, prec: 3),
  unary-int: (prefix: $integral$, prec: 1),
  summation: (
    prefix: $sum_(wild("var") = wild("start"))^wild("stop")$,
    prec: 2
  ),
  pow: (
    expr: $wild("base")^wild("exp")$,
  ),
  times: (infix: $times$, prec: 2),
  // div: (op: $div$, prec: 2),
  // type: (
  //   infix: $::$,
  //   prec: 3,
  // ),
  // commutator: (
  //   expr: $[wild("left"), wild("right")]$,
  // ),
)

#let eq = $sum_(k = 1)^n 1/k! dot x^n + 3$
// #let eq = $L B times C + D times D$
// #let eq = $a + integral c times d + b$
// #let eq = $a times b + c$

#squeeze-space(eq.body.children)

#eq

#line()

#let (tree, rest) = parse(eq, grammar)
#tree

#import "@preview/jumble:0.0.1"
#post-walk(tree, it => {
  let (head, ..rest) = it.values()
  let h = array(jumble.md4(head)).sum()*7deg
  let s = calc.rem(array(jumble.md4(head.rev())).sum(), 100)*1%
  let c = color.hsv(h, s/2 + 50%, 70%)
  text(c, $head(#rest.join($,$))$)
})

