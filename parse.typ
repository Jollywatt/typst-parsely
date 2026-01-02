#import "matching.typ": *
#import "utils.typ": *

#let is-space(it) = (
  repr(it.func()) == "space" or 
  repr(it.func()) == "symbol" and it.fields().text.trim() == ""
)


#let sequence-children(it) = {
  if type(it) == content and repr(it.func()) == "sequence" {
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

#let parse(it, grammar) = {


  let parse-expr(tokens, min-prec) = {

    let parse-op(tokens) = {
      for (name, spec) in grammar {
        let pattern = spec.values().first()
        pattern = pattern.body

        if repr(pattern.func()) == "sequence" {
          pattern = pattern.children
          pattern = squeeze-space(pattern)
        } else {
          pattern = (pattern,)
        }


        let n-ahead = pattern.len()
        if n-ahead > tokens.len() { continue }
        let slice = tokens.slice(0, n-ahead)

        let m = match((pattern), (slice))
        if m == false { continue }

        let slots = m.pairs().map(((slot-name, expr)) => {
          let seq = sequence-children(expr)
          let (tree, rest) = parse-expr(seq, 0)
          if rest.len() > 0 {
            // panic("failed to parse")
            return (slot-name, expr)
          }
          (slot-name, tree)
        }).to-dict()

        let op = (
          kind: spec.keys().first(),
          name: name,
          ..if "prec" in spec { (prec: spec.prec) },
          slots: slots,
        )
        return (op, tokens.slice(n-ahead))
      }

      (none, tokens)
    }


    tokens = squeeze-space(tokens)
    let left = none
    
    if tokens.len() == 0 { return (left, tokens) }


    let (op, tokens) = parse-op(tokens)
    if op == none {
      left = tokens.first()
      tokens = tokens.slice(1)
    } else if op.kind == "expr" {
      left = (head: op.name, ..op.slots)
    
    // prefix
    } else if op.kind == "prefix" {
      let (right, rest) = parse-expr(tokens, op.prec)
      left = (head: op.name, ..op.slots, right: right)
      tokens = rest
    }

    // infix and postfix
    while tokens.len() > 0 {
      let (op, subtokens) = parse-op(tokens)
      if op == none { break }
      
      if op.kind == "postfix" {
        if op.prec < min-prec { break }
        left = (head: op.name, left: left)
        tokens = subtokens

      } else if op.kind == "infix" {
        if op.prec < min-prec { break }
        let (right, rest) = parse-expr(subtokens, op.prec)
        left = (head: op.name, left: left, right: right)
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
  assert: (prefix: $tack$, prec: 0),
  eq: (infix: $=$, prec: 0),
  dot: (infix: $dot$, prec: 2),
  sum: (infix: $+$, prec: 1),
  parens: (expr: $(wilds("expr"))$),
  // unary-plus: (prefix: $+$, prec: 3),
  // unary-int: (prefix: $integral$, prec: 1),
  summation: (
    prefix: $sum_(wild("var") = wild("start"))^wild("stop")$,
    prec: 2
  ),
  pow: (expr: $wild("base")^wild("exp")$),
  times: (infix: $times$, prec: 2),
  div: (op: $div$, prec: 2),
  type: (infix: $::$, prec: 5),
  commutator: (expr: $[wilds("left"), wilds("right")]$),
)

#set page(width: auto, height: auto)

#let eq = $sum_(k = 1)^n 1/k! dot x^n + 3$
// #let eq = $L B times C + D times D$
// #let eq = $a + integral c times d + b$
// #let eq = $ tack sum_(k = 1)^oo [A, B dot k::epsilon] + sqrt(3)$

#squeeze-space(eq.body.children)

#eq

#line()

#let (tree, rest) = parse(eq, grammar)
#tree

#import "@preview/jumble:0.0.1"
#walk(tree, post: it => {
  let (head, ..rest) = it.values()
  let h = array(jumble.md4(head)).sum()*7deg
  let s = calc.rem(array(jumble.md4(head.rev())).sum(), 100)*1%
  let c = color.hsv(h, s/2 + 50%, 80%)
  // text(c, $head(#rest.join($,$))$)
  rect(stroke: (rest: 1pt + c), $ head(#rest.join($,$)) $, fill: c.desaturate(95%).lighten(100%), radius: 15pt)
})
#text(red, $rest.join()$)
