#import "matching.typ": *
#import "utils.typ": *

#let is-space(it) = {
  repr(it.func()) == "space"
}

#let squeeze-space(seq) = seq.filter(it => not is-space(it))

#let parse-atom(grammar, tokens) = {
  for (name, schema) in grammar {
    if "pattern" not in schema { continue }

    let pattern = schema.pattern.body
    let (next, ..rest) = tokens

    if repr(pattern.func()) == "sequence" {
      pattern = squeeze-space(pattern.children)
      let len = pattern.len()
      if tokens.len() < len { continue }
      next = tokens.slice(0, len)
      rest = tokens.slice(len)
    }

    let m = match(pattern, next)
    if m == false { continue }

    return ((kind: name, ..m), rest)
  }
  return (tokens.first(), tokens.slice(1))
}



#let parse-sequence(grammar, tokens, min-prec: 0) = {
  tokens = squeeze-space(tokens)

  let match-operator(token) = {
    for (name, schema) in grammar {
      if "op" not in schema { continue }
      if token == schema.op.body {
        return name
      }
    }
  }

  let (result, remaining) = parse-atom(grammar, tokens)

  while remaining.len() > 0 {
    let next = remaining.first()

    let o = match-operator(next)
    if o == none { break }
    let prec = grammar.at(o).precedence
    if prec < min-prec { break }


    let op = next.text
    remaining = remaining.slice(1)
    
    // Parse right operand with higher precedence
    let (rhs, r) = parse-sequence(grammar, remaining, min-prec: prec + 1)
    remaining = r
    
    result = (kind: "op", op: op, lhs: result, rhs: rhs)
  }

  return (result, remaining)

}


#let grammar = (
  eq: (op: $=$, precedence: 0),
  sum: (
    op: $+$,
    // pattern: $wild("left") + wild("right")$,
    precedence: 1,
  ),
  unary-plus: (prefix: $+$, precedence: 3),
  unary-int: (prefix: $integral$, precedence: 1),
  summation: (
    pattern: $sum_(wild("var") = wild("start"))^wild("stop") wild("summand")$
  ),
  pow: (
    pattern: $wild("base")^wild("exp")$,
    precedence: 3,
  ),
  times: (
    op: $times$,
    pattern: $wild("left") times wild("right")$,
    precedence: 2,
  ),
  div: (
    op: $div$,
    precedence: 2,
  ),
  juxt: (
    // pattern: $wild("left") wild("right")$,
    precedence: 2,
  ),
  dot: (op: $dot$, precedence: 2),
  type: (
    pattern: $wild("value")::wild("type")$,
    precedence: 3,
  ),
  commutator: (
    pattern: $[wild("left"), wild("right")]$,
  ),
)

#let eq = $sum_(k = 1)^n 1/k! dot x^k$
#let eq = $L B times C + D times D$
#let eq = $a + integral c times d + b$

#squeeze-space(eq.body.children)

#eq

#line()

#let (tree, rest) = parse-sequence(grammar, eq.body.children)
#tree


#post-walk(tree, it => {
  if it.kind == "op" {
    $(it.lhs #text(blue, symbol(it.op)) it.rhs)$
  } else {
    let (head, ..rest) = it.values()
    $head(#rest.join($,$))$
  }
})

