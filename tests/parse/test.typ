#import "/src/exports.typ": *

#let grammar = (
  eq: (infix: $=$, prec: 0),
  sum: (infix: $+$, prec: 1),
  sub: (infix: $-$, prec: 1),
  times: (infix: $times$, prec: 2),
)

#assert.eq(parse($a$, grammar).first(), $a$.body)
#assert.eq(parse($1 + 1$, grammar).first(), (head: "sum", left: $1$.body, right: $1$.body))

#let lisp-expr(it, grammar) = {
  let (tree, rest) = parse(it, grammar)
  util.walk(tree, post: it => it.values())
}

#assert.eq(
  lisp-expr($a + b$, grammar),
  ("sum", $a$.body, $b$.body)
)
#assert.eq(
  lisp-expr($a + b times c$, grammar),
  ("sum", $a$.body, ("times", $b$.body, $c$.body))
)
#assert.eq(
  lisp-expr($a - b times c = d$, grammar),
  ("eq", ("sub", $a$.body, ("times", $b$.body, $c$.body)), $d$.body)
)


#let grammar = (
  eq: (infix: $=$, prec: 1),
  neg: (prefix: $-$, prec: 2),
  fact: (postfix: $!$, prec: 3),
  question: (postfix: $?$, prec: 0),
  parens: (expr: $(wilds("body"))$),
)

#assert.eq(
  lisp-expr($-a!$, grammar),
  ("neg", ("fact", $a$.body))
)
#assert.eq(
  lisp-expr($-a! = (-a)! ?$, grammar),
  ("question", ("eq",
    ("neg", ("fact", $a$.body)),
    ("fact", ("parens", ("neg", $a$.body)))
  ))
)
#assert.eq(
  lisp-expr($-a!$, grammar),
  ("neg", ("fact", $a$.body))
)


#let grammar = (
  unary-sum: (prefix: $+$, prec: 3),
  binary-sum: (infix: $+$, prec: 1),
)
#assert.eq(
  lisp-expr($b+a$, grammar)
  ("binary-sum", $a$.body, $b$.body)
)