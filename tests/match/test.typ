#import "/src/match.typ": *
#import "/src/util.typ": stringify

#let assert-match(pattern, ..expr-result) = {
  for (expr, result) in expr-result.pos().chunks(2) {
    if type(result) == dictionary {
      result = result.keys().zip(result.values().map(unwrap)).to-dict()
    }
    assert.eq(match(pattern, expr), result)
  }
}

#assert-match("A", "A", (:))
#assert-match("A", "B", false)
#assert-match(slot("x"), "A", (x: "A"))
#assert-match($slot("x")$, $A$, (x: $A$))
#assert-match($A$, $A$, (:))
#assert-match($A B$, $A B$, (:))
#assert-match(
  $slot("x") B$,
  $A B$,
  (x: $A$.body),
)
#assert-match(
  $slot("x") slot("y")$,
  $A B$,
  (x: $A$.body, y: $B$.body),
)
#assert-match(
  $slot("x") slot("x")$,
  $A B$, false,
  $A A$, (x: $A$.body),
)

#assert-match(
  $a + slot("x")$,
  $a + (b + c)$,
  (x: $(b + c)$.body),
)
#assert-match(
  $a + (b slot("op") c)$,
  $a + (b + c)$,
  (op: $+$.body),
)
#assert-match(
  $(dif slot("x"))/2$,
  $frac(dif x, 2)$,
  (x: $x$.body),
)
#assert-match(
  $slot("x")^i_j$,
  $a_j^i$,
  (x: $a$.body),
)
#assert-match(
  $sum_(slot("var") = slot("start"))^slot("stop")$,
  $sum_(k= 1)^n$,
  (var: $k$.body, start: $1$.body, stop: $n$.body),
)

#assert-match(
  $[slot("seq*")]$,
  $[1, 2, 3]$,
  (seq: $1, 2, 3$.body),
)
#assert-match(
  $[slot("left*"), slot("right*")]$,
  $[a b c, x y z]$,
  (left: $a b c$.body, right: $x y z$.body),
)

#assert-match($a+b$, $a + b$, (:))
#assert-match($a + b$, $a+b$, (:))

#assert-match($a + b$, $a + b + c$, (:))


#assert-match($f(slot("arg")).$, $f(x)$, false)
#assert-match(
  $f(slot("arg"))$,
  $f(x)$,
  (arg: $x$.body),
)


// whitespace sensitive matching

#assert-match($a tight + tight b$, $a+b$, (:))
#assert-match($a tight + b$, $a+ b$, (:))
#assert-match($a tight + b$, $a +b$, false)

#assert-match(
  $slot("fn") tight (slot("args*"))$,
  $f(x)$,
  (fn: $f$.body, args: $x$.body),
)
#assert-match(
  $slot("fn") tight (slot("args*"))$,
  $f (x)$,
  false,
)

#assert-match($1loose.$, $1.$, false)
#assert-match($1 loose .$, $1.$, false)
#assert-match($1loose.$, $1 .$, (:))
#assert-match($1 loose .$, $1 .$, (:))

#assert-match($slot("a") loose slot("b")$, $n!$, false)
#assert-match(
  $slot("a") loose slot("b")$,
  $n !$,
  (a: $n$.body, b: $!$.body),
)



// greedy and lazy matching

#assert-match(
  $[slot("leading*"), slot("last*")]$,
  $[1, 2, 3]$,
  (leading: $1, 2$, last: $3$),
)

#assert-match(
  $[slot("head*?"), slot("tail*")]$,
  $[1, 2, 3]$,
  (head: $1$, tail: $2, 3$),
)


// matching content
#assert-match(
  math.frac,
  $a/b$.body,
  (num: $a$, denom: $b$),
)
#assert-match(
  rect,
  rect(stroke: 5pt, fill: blue),
  (stroke: stroke(5pt), fill: blue),
)

// union slots
#assert-match(
  $1 slot("op", any: #($<$, $=$, $>$)) 2$,
  $1 = 2$,
  (op: $=$)
)
#assert-match(
  $1 slot("op", any: #($<$, $=$, $>$)) 2$,
  $1 != 2$,
  false
)
#assert-match(
  $x slot("op", any: #($<$, $=_slot("eq-type")$, $>$)) y$,
  $x =_a y$, (op: $=_a$, eq-type: $a$),
  $x < y$, (op: $<$),
  $x + y$, false
)

// predicate slots
#assert-match(
  slot("num", guard: it => stringify(it).match(regex("^\d+$")) != none),
  [1234], (num: [1234]),
  $1234$, (num: $1234$),
  "1234", (num: "1234"),
  [abc], false,
  "abc", false,
)
#assert-match(
  slot("upper", guard: regex("^\p{Lu}+$")),
  [UPPERCASE], (upper: [UPPERCASE]),
  $X$, (upper: $X$),
  [NotUpper], false,
  $x$, false,
)

#assert-match(
  slot("hi*", guard: it => util.as-array(it).all(n => {
    util.is-space(n) or stringify(n) in "xyz"
  })),
  $x y z$, (hi: $x y z$),
  $x y 1$, false,
  $x$, (hi: $x$),
)
