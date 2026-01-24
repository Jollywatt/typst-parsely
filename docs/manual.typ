#import "@preview/tidy:0.4.3"
#import "@preview/cetz:0.4.2"
#import "../src/exports.typ" as parsely: *

#let typst-toml = toml("../typst.toml")
#show "{{VERSION}}": typst-toml.package.version
#show "{{PACKAGE_NAME}}": typst-toml.package.name

#set page(margin: (x: 25mm, y: 20mm))
#set heading(numbering: "1.", supplement: none)
#show heading: it => v(1em) + text(1.2em, it) + v(1em, weak: true)
#set text(font: "Fira Sans")
#show raw: set text(1.1em, font: "Fira Code", weight: 500)
#show link: it => underline(it)

#show figure: set align(left)
#show figure.caption: set text(0.8em)

#show ref: r => {
  if r.element != none and r.element.func() == heading {
    let label = r.supplement
    if label == auto { label = r.element.body }
    link(r.element.location(), strong(label))
  } else {
    r
  }
}



#let code-fill = oklab(98.17%, -0.005, -0.007)
#show raw.where(block: true): box.with(width: 100%, inset: 1em, fill: code-fill, stroke: code-fill.darken(30%))

#let example(code, scope: (:)) = {
  code = code.text
  let frame = box.with(width: 100%, inset: 1em, stroke: code-fill.darken(30%))
  let codebox = frame(raw(code, lang: "typ"), fill: code-fill)
  let out = eval(code, mode: "markup", scope: (
    parsely: parsely,
    slot: slot,
    ..scope,
  ))
  if util.flatten-sequence(out).all(util.is-space) {
    codebox
  } else {
    stack(codebox, frame(out))
  }
}


#let hash-color(text) = {
  import "@preview/jumble:0.0.1"
  let h = array(jumble.md4(text)).sum()*7deg
  let s = calc.rem(array(jumble.md4(text.rev())).sum(), 100)*1%
  color.hsv(h, s, 80%)
}
#let waterfall(tree) = walk(tree, post: it => {
  let (head, args, slots) = it

  let c = hash-color(head)
  let ctext = text.with(0.8em, c)
  slots = slots.pairs().map(((k, v)) => [
    #ctext[#k] #v
  ])

  args = slots + args
  
  let gap = 3pt

  box(
    stroke: (rest: 0.5pt + c, top: 1.5pt + c, bottom: none),
    radius: (top: 5pt),
    grid(
    align: bottom,
    inset: (x: gap, top: gap),
    columns: 1 + args.len(),
    ctext(strong(head)), ..args,
    ..range(args.len()).map(x => grid.vline(x: x + 1, stroke: 0.5pt + c))
  ))
}, leaf: math.equation)


#let examples(grammar-block, ..args) = {
  let eqns = args.pos()
  let grammar = eval("("+grammar-block.text+")", scope: (slot: slot, tight: tight, loose: loose))
  stack(
    {
      let setrule(color, it) = {
        show color: set text(hash-color(color), weight: "bold")
        it
      }
      let it = grammar-block
      for key in grammar.keys() {
        it = setrule(key, it)
      }
      it
    },
    {
      show: box.with(stroke: code-fill.darken(30%))
      set text(1.2em)
      table(
        columns: (1fr, 2fr),
        align: (right + bottom, left),
        stroke: none,
        inset: 7pt,
        ..eqns.map(eqn => {
          let e = eqn
          if e.func() == raw { e = eval(e.text) }
          let (tree, rest) = parse(e, grammar)
          (eqn, waterfall(tree) + text(red, $space rest$))
        }).flatten()
      )
    },
  )
}


#let cover-graphic = {

  let hash-color(text) = {
    import "@preview/jumble:0.0.1"
    let h = array(jumble.md4(text)).sum()*5deg
    let s = calc.rem(array(jumble.md4(text.rev())).sum(), 100)*1%
    color.hsv(h, 80%, 70%)
  }

  let regions(tree, grammar) = context util.walk(tree, post: it => {
    let c = hash-color(it.head)
    show: rect.with(
      stroke: 2pt + c,
      fill: c.transparentize(95%),
      inset: 4pt,
    )
    $ #render(it, grammar) $
  })

  let grammar = (
    eq: (infix: $=$, prec: 0),
    sum: (prefix: $sum_(slot("var") = slot("start"))^slot("stop")$, prec: 2),
    frac: (match: $slot("num")/slot("denom")$),
    fact: (postfix: $!$, prec: 3),
    mul: (infix: $$, prec: 2),
    pow: (match: $slot("base")^slot("exp")$),
    call: (match: $slot("fn") tight (slot("args"))$),
  )

  let eq = $exp(x) = sum_(k = 0)^oo 1/k! x^k$
  let (tree, rest) = parse(eq, grammar)
  
  let sep = text(20pt, $ arrow.t.b $)
  stack(
    spacing: 10pt,
    box(text(15pt, regions(tree, grammar))),
    sep,
    util.walk(tree, post: it => {
      set text(14pt)
      let c = hash-color(it.head)
      text(c, strong[#it.head])
      text(c)[(]
      {
        if it.head == "sum" {
          (it.slots.var, it.slots.start, it.slots.stop) // custom order
        } else {
          it.at("slots", default: (:)).values()
        }
        it.at("args", default: ())
      }.join(text(c)[, ])
      text(c)[)]
    }, leaf: it => $it$),
    sep,
    move(dx: 0.5em, text(12pt, cetz.canvas({
      let a = util.walk(tree, post: it => {
        let c = hash-color(it.head)
        (text(c, strong(it.head)), ..it.args, ..it.slots.values())
      }, leaf: it => $it$)
      cetz.draw.set-style(content: (padding: .1))
      cetz.tree.tree(a, grow: 0.5, spread: 0)
    }))),
  )
}

#[
  #set text(15pt)
  #box(title[#typst-toml.package.name])
  #text(0.8em)[version #typst-toml.package.version]

  Parse equations with Typst
]



#v(1fr)

#align(center, cover-graphic)

#v(1fr)

#context outline(target: selector(heading).after(here()))


#pagebreak()


= At a glance

#set raw(lang: "typc")

+ Import the package with:

  ```typ
  #import "@preview/{{PACKAGE_NAME}}:{{VERSION}}"
  ```

+ @grammars[Declare a grammar] by listing the @op-kinds[operators] you want to parse in a dictionary:

  #let grammar = (
    eq:  (infix: $=$, prec: 0),
    add: (infix: $+$, prec: 1, assoc: true),
    mul: (infix: $$,  prec: 2, assoc: true),
    group: (match: $(slot("body*"))$),
    pow: (match: $slot("base")^slot("exp")$),
  )

  #example(```typ
  #import parsely: slot
  #let grammar = (
    eq:  (infix: $=$, prec: 0),
    add: (infix: $+$, prec: 1, assoc: true),
    mul: (infix: $$,  prec: 2, assoc: true),
    grp: (match: $(slot("body*"))$),
    pow: (match: $slot("base")^slot("exp")$),
  )
  ```)

  Operators can have @prec-assoc and use @slots.

+ Call `parsely.parse()` on the content with the grammar to use.

  #let eqn = $(a + b)^2 = a^2 + 2a b + b^2$
  #let (tree, rest) = parsely.parse(eqn, grammar)

  #example(```typ
  #let it = $(a + b)^2 = a^2 + 2a b + b^2$
  #let (tree, rest) = parsely.parse(it, grammar)
  ```, scope: (grammar: grammar))

  This returns the parsed syntax tree along with any trailing tokens that failed to parse.
  
+ Use `parsely.walk()` and `parsely.render()` to visit nodes and turn them into content.

  #example(```typ
  #parsely.walk(tree, post: node => parsely.render(node, grammar))
  ```, scope: (grammar: grammar, tree: tree))

  #example(```typ
  #import "@preview/cetz:0.4.2"
  #cetz.canvas({
    let cetz-tree = parsely.walk(tree, // convert tree into cetz format
      post: it => (strong(it.head), ..it.args, ..it.slots.values()),
      leaf: it => $(it)$
    )
    cetz.draw.set-style(content: (padding: 3pt))
    cetz.tree.tree(cetz-tree, grow: 0.2, spread: 0.5)
  })
  ```, scope: (tree: tree, grammar: grammar))







= Guide

== Declaring grammars <grammars>

Grammars define how content is transformed into an abstract syntax tree.


A grammar is given as a dictionary where each value is an *operator* and each key is the operator's name, which becomes the name for corresponding nodes in a syntax tree.

For example, the simple grammar below defines:
- the token "$+$" as an associative binary operator of lower precedence than "$times$" so that $a + b times c$ is parsed as $a + (b times c)$
- the token "$-$" as left associative so $a - b - c$ is parsed as $(a - b) - c$
- the @slots[slot pattern] "$#(`base`)^#(`exp`)$" matching expressions like $2^5$, $(a + b)^2$ or $e^(-i (k x + omega t))$

#figure(example(```typ
#let grammar = (
  add: (infix: $+$, prec: 1, assoc: true),
  sub: (infix: $-$, prec: 1, assoc: left),
  neg: (prefix: $-$, prec: 1),
  mul: (infix: $times$, prec: 2, assoc: true),
  pow: (match: $slot("base")^slot("exp")$),
)
```), caption: [Simple example grammar]) <example-grammar>

The order of operators in a grammar matters.
The first operator whose pattern matches content will be used to parse that content.
This means operators should generally be listed with the more specific patterns earlier, with "catch all" patterns later. An important case of this is when @juxt.
Operator precedence is not related to the order that operators are listed in the grammar.



== Prefix, infix, postfix and match operators <op-kinds>

An operator is specified as a dictionary whose first key is the *operator type* and first value is the *operator pattern*.
For example, `(infix: $+$, ..)` is an operator of type _infix_ with pattern `$+$`.
There are four kinds of operators: `prefix`, `infix`, `postfix` and `match`.

#[
#show table.cell.where(x: 0): smallcaps
#let na = text(gray)[not applicable]
#figure(table(
  inset: (left: 0pt, rest: 8pt),
  align: left,
  stroke: (none),
  columns: (auto, ..(1fr,)*4),

  [Operator type], [Prefix], [Infix], [Postfix], [Match],
  table.hline(),
  [Positional arguments], [one after], [to either side], [one before], text(gray)[none],
  [Slot arguments], ..([yes],)*4,
  [Precedence, `prec`], [required], [required], [required], text(gray)[not applicable],
  [Associativity, `assoc`], na, [left/right/both], na, na,
), caption: [
  Kinds of operators available when declaring grammars and their features.
]) <op-table>
]


Prefix, infix and postfix operators consume tokens around them as *positional arguments*, subject to @prec-assoc[precedence].
Match operators do not consume tokens to the left or right, but simply match a pattern.
All operators support @slots, consuming tokens as *slot arguments*.



== Parsing and syntax trees

Parsing content with respect to a grammar is the process of transforming the content into a *syntax tree*.
The parse function `parsely.parse(expr, grammar)` returns a dictionary containing `tree` and `rest`.
The tree is composed of nodes with two kinds of children: *positional* arguments and *slot* arguments.
Nodes are of the form
```
(head: str, args: array, slots: dictionary)
```
where "`head`" is the operator name that was matched at that point in the expression.
The positional arguments in "`args`" hold the left and right sides of unary or binary operators, while "`slot`" arguments hold the matched values of slots in patterns.
Associative operators may have more than two positional arguments.

For example, using the simple grammar defined in @example-grammar:

#figure(example(```typ
#parsely.parse($a + b^2 + c$, grammar).tree
```, scope: (grammar: grammar)), caption: [A parsed syntax tree with two operator nodes defined in @example-grammar and three leaf nodes.]) <example-tree>
*Not all content has to be parsed.*
When `parsely.parse()` is called on some content, it tries to match the content with operators defined in the grammar.
If successful, the parser recursively descends into arguments and tries to parse those.
If parsing slot arguments fails, the slot is simply left as content in the resulting syntax tree.
If parsing a positional argument fails, what was parsed so far is returned in `tree` and remaining content is returned in `rest`.

=== Tree traversal

You can do many things to the resulting syntax tree by performing a post-order tree walk:
#example(```typ
#parsely.walk(tree, post: node => {
  let (head, args, slots) = node
  if head == "add" { args.join(" + ") }
  else if head == "pow" { slots.base + "^" + slots.exp }
  else { repr(node) } // a fallback string representation
}, leaf: it => "{" + it + "}")
```, scope: (tree: parsely.parse($a + b^2$, grammar).tree))
In this example, leaf nodes (the symbols $a$, $b$ and $2$) are first transformed into `"{a}"`, `"{b}"`, `"{2}"` and then operator nodes (`add` and `pow`) are converted to strings using specific rules.

Similar post-order tree walks can be used to rewrite nodes, reorder arguments, evaluate expressions numerically, or return content with certain styles or annotations added to specific nodes.


== Pattern matching <slots>

Operator patterns are matched against sequences of tokens in order to parse content.
Patterns can be:

- *single tokens*, such as `$+$` or `$in$`

- *sequences of tokens*, such as `$::$`, `$=^"def"$` or `$dif/(dif x)$`

- *slot patterns*, such as `$sum_slot("var")$` or `$[slot("left*"), slot("right*")]$`

- *element functions* as a shorthand for slot patterns matching that element and capturing its fields, such as `math.frac` short for `$frac(slot("num"), slot("denom"))$`

Pattern matching is done by the function `parsely.match(pattern, expr)`, which returns a dictionary if the match is successful and `false` otherwise.
#example(```typ
#import parsely: slot
#parsely.match($1 + slot("rhs")$, $1 + x^2$) \
#parsely.match($A B C$, $A B Omega$)
```)

Slots are wildcard tokens that match any content.
A slot such as `slot("rhs")` will match a single token, but *multiple tokens* can be matched with `slot("rhs", many: true)` or `slot("rhs*")` for short.

#example(```typ
#parsely.match($1; 2; slot("etc")$,  $1; 2; 3; 4; 5$) \
#parsely.match($1; 2; slot("etc*")$, $1; 2; 3; 4; 5$)
```)

By default, many-token slots are *greedy*, prefering to match more tokens when there is choice.
Conversely, *lazy* slots such as `slot("name*", greedy: false)` or `slot("name*?")` match as few tokens as possible.

#example(```typ
#parsely.match($slot("greedy*"), slot("x")$, $alpha, beta, gamma$) \
#parsely.match($slot("lazy*?"),  slot("x")$, $alpha, beta, gamma$)
```)


== Precedence and associativity <prec-assoc>

#examples(```typc
  add: (infix: $+$, prec: 1, assoc: true),
  sum: (prefix: $sum_slot("var")$, prec: 2),
  mul: (infix: $$, prec: 2, assoc: true),
  grp: (match: $(slot("body*"))$),
  pow: (match: $slot("base")^slot("exp")$),
  com: (match: $[slot("left*"), slot("right*")]$)
  ```,
  $C_(i j) + sum_k A_(i k) B_(k j) + II$,
  $[h]_star (rho^n + R)$,
  $[A B, C + D]$,
)


#examples(```typc
  add:   (infix: $+$,   prec: 1, assoc: true),
  dot:   (infix: $dot$, prec: 2),
  fact:  (postfix: $!$, prec: 3),
  query: (postfix: $?$, prec: 0),
  mul:   (infix: $$,    prec: 2, assoc: true),
  ```,
  $x + bold(u) dot bold(v) + p q r$,
  $4pi r^2 + z!$,
  $X  k! Z?$,
)



== Matching whitespace tightly or loosely

#examples(```typc
  fact: (postfix: $tight !$, prec: 3),
  assert: (postfix: $loose !$, prec: 0),
  mul: (infix: $$, prec: 2, assoc: true),
  grp: (match: $(slot("body*"))$),
  call: (match: $slot("fn") tight (slot("body*"))$),
  pow: (match: $slot("base")^slot("exp")$),
  ```,
  `$lambda f(x^2)$`,
  `$lambda f (x^2)$`,
  `$n k!$`,
  `$P Q !$`,
)

== Parsing juxtaposition as an operator <juxt>



= Examples

== Common grammars

#let grammar = (
  eq: (infix: $=$, prec: 0),
  ne: (infix: $!=$, prec: 0),
  add: (infix: $+$, prec: 1, assoc: true),
  sub: (infix: $-$, prec: 1),
  dot: (infix: $dot$, prec: 2),
  fact: (postfix: $!$, prec: 4),
  pow: (match: $slot("base")^slot("exp")$),
  mul: (infix: $$, prec: 3),
  group: (match: $(slot("body*"))$, prec: 0),
)


== Drawing expression trees


  // #example(```typ
  // #parsely.walk(tree, post: node => $[parsely.render(node, grammar)]_node.head$)
  // ```, scope: (tree: tree, grammar: grammar))

  More examples

  // #example(```typ
  // #parsely.util.walk(tree, post: node => {
  //   if node.head == "eq" {
  //     node.args.first() + " == " + node.args.last()
  //   } else if node.head == "add" {
  //     node.args.join(" + ")
  //   } else if node.head == "mul" {
  //     node.args.join("*")
  //   } else if node.head == "pow" {
  //     node.slots.base + "**" + node.slots.exp
  //   } else if node.head == "group" {
  //     "(" + node.slots.body + ")"
  //   } else {
  //     panic(node)
  //   }
  // })
  // ```, scope: (tree: tree, grammar: grammar))



  #cetz.canvas({
    cetz.draw.set-style(content: (padding: 5pt))
    cetz.tree.tree(util.walk(tree, post: it => {
      (it.head, ..it.args, ..it.slots.values())
    }))
  })


== Evaluating arithmetic from equations

== Annotating matrix dimensions

== Rewriting cubing algorithms

#let grammar = (
  eq: (infix: $=$, prec: 0),
  conjugate: (infix: $*$, prec: 2, assoc: right),
  prod: (infix: $$, prec: 1, assoc: true),
  commutator: (match: $[slot("left*"), slot("right*")]$),
  inverse: (match: $slot("body")'$),
  group: (match: $(slot("body*"))$),
)
#let alg = $A * [R, U] F' (D U)'$

#let (tree, rest) = parse(alg, grammar)
#parsely.render-spans(tree, grammar)

#let parse-algo(it) = {
  let (tree, rest) = parse(alg, grammar)
  parsely.walk(tree, post: ((head, args, slots)) => (head, ..args, ..slots.values()))
}

#let expand(algo) = util.walk-array(algo, post: ((head, ..args)) => {
  if head == "conjugate" {
    let (x, y) = args
    ("prod", x, y, ("inverse", x))
  } else if head == "commutator" {
    let (x, y) = args
    ("prod", x, y, ("inverse", x), ("inverse", y))
  } else {
    (head, ..args)
  }
})
#let flatten(algo) = util.walk-array(algo, post: ((head, ..args)) => {
  if head == "prod" {
    let flattened = ()
    for arg in args {
      if type(arg) == array and arg.len() > 1 and arg.first() == "prod" {
        flattened += arg.slice(1)
      } else {
        flattened.push(arg)
      }
    }
    ("prod", ..flattened)
  } else {
    (head, ..args)
  }
})
#parse-algo(tree)

#let sim = flatten(expand(parse-algo(tree)))
#util.walk-array(sim, post: ((head, ..args)) => {
  let slots = (:)
  if head == "inverse" {
    slots.body = args.pop()
  }
  let node = (head: head, args: args, slots: slots)
  parsely.render(node, grammar)
})
