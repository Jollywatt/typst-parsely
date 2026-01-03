#import "src/match.typ": *
#import "src/parse.typ": *
#import "src/util.typ": *

#let grammar = (
  assert: (prefix: $tack$, prec: 0),
  eq: (infix: $=$, prec: 0),
  dot: (infix: $dot$, prec: 2),
  sum: (infix: $+$, prec: 1),
  sub: (infix: $-$, prec: 1),
  parens: (expr: $(wilds("expr"))$),
  unary-plus: (prefix: $+$, prec: 3),
  unary-int: (prefix: $integral$, prec: 1),
  summation: (
    prefix: $sum_(wild("var") = wild("start"))^wild("stop")$,
    prec: 2
  ),
  pow: (expr: $wild("base")^wild("exp")$),
  times: (infix: $times$, prec: 2),
  div: (op: $div$, prec: 2),
  dif: (prefix: $dif$, prec: 4),
  factorial: (postfix: $!$, prec: 3),
  type: (infix: $::$, prec: 5),
  commutator: (expr: $[wilds("left"), wilds("right")]$),
  inv: (expr: $wild("base")'$),
)


#set page(width: auto, height: auto)

#let eq = $sum_(k = 1)^n 1/k! dot x^n + a$
#let eq = $[R, U] dot F' dot B$
// #let eq = $L B times C + D times D$
// #let eq = $a + integral c times d + b$
// #let eq = $ a + b! $
// #let eq = $h - root(5, dif x) + k$

#eq


#let (tree, rest) = parse(eq, grammar)
#rest

#import "@preview/jumble:0.0.1"
#walk(tree, post: it => {
  let (head, ..rest) = it.values()
  let h = array(jumble.md4(head)).sum()*7deg
  let s = calc.rem(array(jumble.md4(head.rev())).sum(), 100)*1%
  let c = color.hsv(h, s/2 + 50%, 80%)
  let it =  $ head #rest.join($space$) $
  box(it,
    // stroke: (x: 1.5pt + c, top: 0.25pt + c),
    stroke: (top: 1pt + c),
    outset: (bottom: 3pt),
    inset: (x: 3pt, top: 2pt),
    fill: c.desaturate(95%).lighten(100%),
    // radius: 50pt,
  )
})
#text(red, $rest.join()$)

#tree