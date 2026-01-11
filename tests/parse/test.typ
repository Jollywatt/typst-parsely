#import "/src/exports.typ": *

#let grammar = (
  eq: (infix: $=$, prec: 0),
  sum: (infix: $+$, prec: 1),
  sub: (infix: $-$, prec: 1),
  times: (infix: $times$, prec: 2),
)

#assert.eq(parse($a$, grammar).first(), $a$.body)
#assert.eq(
  parse($1 + 2$, grammar).first(),
  (head: "sum", args: ($1$.body, $2$.body), slots: (:)),
)

#let assert-expr(grammar, it, target) = {
  let (tree, rest) = parse(it, grammar)
  let lisp = util.walk(tree, post: it => (it.head, ..it.args, ..it.slots.values()))
  target = util.walk-array(target, leaf: it => {
    if type(it) == content and it.func() == math.equation {
      it.body
    } else {
      it
    }
  })
  assert.eq(lisp, target)
}

#assert-expr(grammar,
  $a + b$,
  ("sum", $a$, $b$)
)
#assert-expr(grammar,
  $a + b times c$,
  ("sum", $a$, ("times", $b$, $c$))
)
#assert-expr(grammar,
  $a - b times c = d$,
  ("eq", ("sub", $a$, ("times", $b$, $c$)), $d$)
)


#let grammar = (
  eq: (infix: $=$, prec: 1),
  neg: (prefix: $-$, prec: 2),
  fact: (postfix: $!$, prec: 3),
  question: (postfix: $?$, prec: 0),
  parens: (expr: $(slot("body*"))$),
)

#assert-expr(grammar,
  $-a!$,
  ("neg", ("fact", $a$))
)
#assert-expr(grammar,
  $-a! = (-a)! ?$,
  ("question", ("eq",
    ("neg", ("fact", $a$)),
    ("fact", ("parens", ("neg", $a$)))
  ))
)
#assert-expr(grammar,
  $-a!$,
  ("neg", ("fact", $a$))
)


#let grammar = (
  binary-sum: (infix: $+$, prec: 1),
  unary-sum: (prefix: $+$, prec: 3),
  group: (expr: $(slot("body*"))$)
)
#assert-expr(grammar,
  $a + b$,
  ("binary-sum", $a$, $b$)
)
#assert-expr(grammar,
  $a + (+b)$,
  ("binary-sum", $a$, ("group", ("unary-sum", $b$),))
)


// juxtaposition as an infix operator

#let grammar = (
  sum: (infix: $+$, prec: 1),
  dot: (infix: $dot$, prec: 2),
  fact: (postfix: $!$, prec: 4),
  mul: (infix: $$, prec: 3),
  group: (expr: $(slot("body*"))$),
)

#assert-expr(grammar,
  $a + b c! dot d$,
  ("sum",
    $a$,
    ("dot",
      ("mul",
        $b$,
        ("fact", $c$)
      ),
      $d$
    )
  )
)
#assert-expr(grammar,
  $a (b + c)$,
  ("mul",
    $a$,
    ("group", ("sum", $b$, $c$)),
  )
)


// associativity

#let grammar = (
  add: (infix: $+$, prec: 1, assoc: true),
  sub: (infix: $-$, prec: 1),
  mul: (infix: $times$, prec: 2, assoc: true),
  div: (infix: $slash$, prec: 2, assoc: left),
  arr: (infix: $->$, prec: 0, assoc: right),
  group: (expr: $(slot("group*"))$),
)

#assert-expr(grammar,
  $a + b + c$,
  ("add", $a$, $b$, $c$),
)
#assert-expr(grammar,
  $a - b - c$,
  ("sub", ("sub", $a$, $b$), $c$)
)
#assert-expr(grammar,
  $a -> b -> c$,
  ("arr", $a$, ("arr", $b$, $c$))
)
#assert-expr(grammar,
  $x -> a + p times q + c$,
  ("arr", $x$, ("add", $a$, ("mul", $p$, $q$), $c$))
)

#let grammar = (
  add: (infix: $+$, prec: 1, assoc: true),
  mul: (infix: $$, prec: 3, assoc: true),
)

#assert-expr(grammar,
  $a + b c$,
  ("add", $a$, ("mul", $b$, $c$))
)

// tightness and looseness

#let grammar = (
  eq: (infix: $=$, prec: 1),
  neg: (prefix: $-$, prec: 2),
  fact: (postfix: $tight !$, prec: 3),
  assert: (postfix: $loose !$, prec: 0),
  question: (postfix: $loose ?$, prec: 0),
)

#assert-expr(grammar,
  $-a! = b !$,
  ("assert", ("eq", ("neg", ("fact", $a$)), $b$)),
)
#assert-expr(grammar,
  $P! ?$,
  ("question", ("fact", $P$)),
)
#assert-expr(grammar,
  $P!!$,
  ("fact", ("fact", $P$)),
)


// trailing tokens

#let grammar = (
  add: (infix: $+$, assoc: true, prec: 1),
  sub: (infix: $-$, assoc: left, prec: 1),
)
#assert.eq(
  parse($a +$, grammar),
  ($a$.body, ([ ], $+$.body))
)
#assert.eq(
  parse($a + b + $, grammar),
  ((head: "add", args:($a$.body, $b$.body), slots: (:)),
  ([ ], $+$.body))
)
#assert.eq(
  parse($a - b - $, grammar),
  ((head: "sub", args:($a$.body, $b$.body), slots: (:)),
  ([ ], $-$.body))
)
