#import "/src/exports.typ": *
#set page(width: 10cm, height: auto, margin: 5mm)

#let debug-mode = "x-preview" in sys.inputs // true if tinymist preview, false if tytanic test

#let to-sexpr(tree) = walk(tree, post: it => {
  (it.head, ..it.args, ..it.slots.values())
})

#let stringify(it) = {
  if util.is-sequence(it) {
    it.children.map(stringify).join()
  } else if type(it) == content {
    if "text" in it.fields() { it.text }
    else { repr(it) }
  } else {
    repr(it)
  }
}

#let compact-sexpr(tree) = walk(tree, post: ((head, args, slots)) => {
  "(" + (head, ..args, ..slots.values()).map(str).join(" ") + ")"
}, leaf: it => stringify(it))

#let test-sexpr(grammar, ..eqn-target-pairs) = {
  for (i, (eqn, target)) in eqn-target-pairs.pos().chunks(2).enumerate(start: 1) {
    let tree = parse(eqn, grammar).tree
    let result = compact-sexpr(tree)
    target = target.text.replace(regex("\s+"), " ")

    if debug-mode {
      let report = if result == target [
        #text(green)[== Test #i passed]
        #table(
          columns: 1,
          stroke: green,
          eqn, raw(target)
        )
      ] else [
        #text(red)[== Test #i failed]
        #table(
          columns: 2,
          align: (right, left),
          stroke: red,
          text(red)[Content], eqn,
          text(red)[Expected], raw(target),
          text(red)[Result], raw(result),
        )
      ]

      page(report)
    } else {
      assert.eq(result, target)
    }

  }
}

#test-sexpr(
  common.arithmetic,

  // Implicit multiplication and precedence
  $a b c + d e + c$,
  `(add (mul (mul a b) c) (mul d e) c)`,

  $2 x y - 3 z$,
  `(sub (mul (mul 2 x) y) (mul 3 z))`,

  // Prefix operators and chaining
  $- -a + + -b$,
  `(add (neg (neg a)) (plus (neg b)))`,

  $a + -b - + c$,
  `(sub (add a (neg b)) (plus c))`,


  // Postfix factorial with combinations
  $n!! + m!$,
  `(add (factorial (factorial n)) (factorial m))`,

  $ (n + 1)! / n! $,
  `(frac (factorial (group (add n 1))) (factorial n))`,

  $-n! + m!$,
  `(add (neg (factorial n)) (factorial m))`,

  $a b! c!$,
  `(mul (mul a (factorial b)) (factorial c))`,

  // Powers and right-associativity
  $a^b^c + d^e$,
  `(add (pow a (pow b c)) (pow d e))`,

  $a^(b + c) times d^(e - f)$,
  `(times (pow a (add b c)) (pow d (sub e f)))`,

  $(a b)^(c d)$,
  `(pow (group (mul a b)) (mul c d))`,

  $a^n! + b^m!$,
  `(add (pow a (factorial n)) (pow b (factorial m)))`,

  // Fractions
  $ a / b + c / d = e / f $,
  `(= (add (frac a b) (frac c d)) (frac e f))`,

  $ (a + b) / (c - d) $,
  `(frac (add a b) (sub c d))`,

  $ a / b / c + d $,
  `(add (frac (frac a b) c) d)`,

  // Explicit multiplication operators (times, dot) vs implicit
  $a times b c + d dot e f$,
  `(add (times a (mul b c)) (dot d (mul e f)))`,

  $a dot b + c times d = e f$,
  `(= (add (dot a b) (times c d)) (mul e f))`,

  // Equality at lowest precedence
  $a + b times c = d e - f$,
  `(= (add a (times b c)) (sub (mul d e) f))`,

  $a^2 = b^2 + c^2$,
  `(= (pow a 2) (add (pow b 2) (pow c 2)))`,

  // Grouping and nested parentheses
  $((a + b)) times ((c - d))$,
  `(times (group (group (add a b))) (group (group (sub c d))))`,

  $(a (b + c)) d$,
  `(mul (group (mul a (group (add b c)))) d)`,

  // Classic formulas
  $a^2 + 2 a b + b^2$,
  `(add (pow a 2) (mul (mul 2 a) b) (pow b 2))`,

  $(a + b)(a - b) = a^2 - b^2$,
  `(= (mul (group (add a b)) (group (sub a b))) (sub (pow a 2) (pow b 2)))`,

  $-b + (b^2 - 4 a c)^(1/2)$,
  `(add (neg b) (pow (group (sub (pow b 2) (mul (mul 4 a) c))) (frac 1 2)))`,

  $ n! / (k! (n - k)!) $,
  `(frac (factorial n) (mul (factorial k) (factorial (group (sub n k)))))`,

  $(a - -b)(a + +b)$,
  `(mul (group (sub a (neg b))) (group (add a (plus b))))`,

  $a + b c - (-2 k)^(1/2)$,
  `(sub (add a (mul b c)) (pow (group (neg (mul 2 k))) (frac 1 2)))`,

  $sin(- omega t) log(z)$,
  `(mul (op-call sin (neg (mul ω t))) (op-call log z))`,

  $sqrt(a + b) + root(n, A)$,
  `(add (root (add a b)) (root n A))`,
)