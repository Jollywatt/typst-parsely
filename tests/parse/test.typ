#import "/src/exports.typ": *

#let grammar = (
  eq: (infix: $=$, prec: 0),
  sum: (infix: $+$, prec: 1),
  sub: (infix: $-$, prec: 1),
  times: (infix: $times$, prec: 2),
  pow: (expr: $wild("base")^wild("exp")$),
)

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
  lisp-expr($a + b times c = d$, grammar),
  ("eq", ("sum", $a$.body, ("times", $b$.body, $c$.body)), $d$.body)
)


#let grammar = (
  neg: (prefix: $-$, prec: 2),
  fact: (postfix: $!$, prec: 3),
  question: (postfix: $?$, prec: 0),
)

#raw(repr($#util.flatten-sequence($-a!$.body).join()$))

#parse($#util.flatten-sequence($-a!$.body).join()$, grammar)

#assert.eq(
  lisp-expr($-6!$, grammar),
  ("neg", ("fact", $6$.body))
)
