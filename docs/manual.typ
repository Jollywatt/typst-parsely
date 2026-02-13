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
#set par(justify: true)

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
#let frame = box.with(width: 100%, inset: 8pt, stroke: code-fill.darken(30%))
#show raw.where(block: true): frame.with(fill: code-fill)

#let example(code, scope: (:)) = {
  code = code.text
  let codebox = frame(raw(code, lang: "typ"), fill: code-fill)
  let out = eval(code, mode: "markup", scope: (
    parsely: parsely,
    slot: slot,
    ..scope,
  ))
  if util.flatten-sequence(util.as-array(out)).all(util.is-space) {
    codebox
  } else {
    stack(codebox, frame(out))
  }
}


#let hash-color(text) = {
  import "@preview/jumble:0.0.1"
  let h = array(jumble.md4(text)).sum()*7.2deg
  let c = calc.rem(array(jumble.md4(text.rev())).sum(), 70)*1%
  color.oklch(70%, c, h)
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


#let grammar-examples(grammar-block, eqns, ..args, styler: (t, g) => waterfall(t)) = {
  let grammar = eval("(\n"+grammar-block.text+"\n)", scope: (slot: slot, tight: tight, loose: loose))
  figure(grid(
    frame(fill: code-fill, {
      let lines = grammar-block.text.split("\n")
      let it = for l in lines {
        let i = l.position(":")
        let key = l.slice(0, i)
        text(hash-color(key), raw(key)) + raw(l.slice(i)) + "\n"
      }
      emph[Operators in grammar] 
      par(it)
    }),
    frame({
      emph[Parsing examples] + v(-1em)
      // set text(1.1em)
      grid(
        columns: (2fr, auto, 3fr),
        align: (right + bottom, center + bottom, left),
        inset: 5pt,
        ..eqns.map(eqn => {
          let e = eqn
          if e.func() == raw { e = eval(e.text) }
          let (tree, rest) = parse(e, grammar)
          (eqn, $|->$, styler(tree, grammar) + text(red, $space rest$))
        }).flatten()
      )
    }),
  ), supplement: [Example], ..args)
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

+ @grammars[Declare a grammar] by listing the mathematical @op-kinds[operators] you want to parse:

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

  Operators can be given @prec[precedence], @assoc[associativity] and @slots[pattern matching slots].

+ Call `parsely.parse()` on content along with the grammar to use.

  #let eqn = $(a + b)^2 = a^2 + 2a b + b^2$
  #let (tree, rest) = parsely.parse(eqn, grammar)

  #example(```typ
  #let eqn = $(a + b)^2 = a^2 + 2a b + b^2$
  #let (tree, rest) = parsely.parse(eqn, grammar)
  ```, scope: (grammar: grammar))

  This returns a syntax tree along with any trailing tokens that failed to parse (if any).
  
+ Use `parsely.walk()` or `parsely.render()` to visit nodes and turn them into content.

  #example(```typ
  #parsely.walk(tree, post: node => parsely.render(node, grammar))
  ```, scope: (grammar: grammar, tree: tree))

  #example(```typ
  #import "@preview/cetz:0.4.2"
  #cetz.canvas({
    let cetz-tree = parsely.walk(tree, // convert nodes to nested arrays
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


A grammar is given as a dictionary where each value is an _operator_ and each key is the operator's name, which becomes the name for corresponding nodes in the syntax tree.

For example, the simple grammar in @example-grammar defines:
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

The order that operators are listed in a grammar matters (and is not related to @prec[operator precidence]).
The first operator whose pattern matches content will be used to parse that content.
This means operators should generally be listed with the more specific patterns earlier and "catch all" patterns later.
An important special case is when @juxt.


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


Prefix, infix and postfix operators consume tokens around them as _positional arguments_, subject to @prec[precedence].
Match operators do not consume tokens to the left or right, but simply match a pattern.
All operators support @slots, consuming tokens as _slot arguments_.



== Pattern matching and slots <slots>

Operator patterns are snippets of content which can be matched against sequences of tokens in order to parse content.
Patterns can be:
- *Single tokens*, such as `$+$` or `$in$`.
- *Sequences of tokens*, such as `$::$`, `$=^"def"$` or `$dif/(dif x)$`.
- *Slot patterns*, such as `$sum_slot("var")$` or `$[slot("left*"), slot("right*")]$`.
- *Element functions*, such as `math.frac`, as a shorthand for the slot pattern matching that element and capturing its fields, such as `$frac(slot("num"), slot("denom"))$`.

Pattern matching is done by the function `parsely.match(pattern, expr)`, which returns a dictionary if the match is successful and `false` otherwise.
#example(```typ
#import parsely: slot
#parsely.match($1 + slot("rhs")$, $1 + x^2$) \
#parsely.match($A B C$, $A B Omega$)
```)

Slots are wildcard tokens that match any content.
A slot such as `slot("rhs")` will match a single token, but *multiple tokens* can be matched with `slot("rhs", many: true)` or `slot("rhs*")` for short.

#example(```typ
#parsely.match($1; 2; slot("etc")$,  $1; 2; 3; 4$) \ // single token slot
#parsely.match($1; 2; slot("etc*")$, $1; 2; 3; 4$)   // multi token slot
```)

=== Matching sequences greedily or lazily

By default, multi-token slots are *greedy*, prefering to match more tokens when there is choice.
Conversely, *lazy* slots such as `slot("name*", greedy: false)` or `slot("name*?")` match as few tokens as possible.

#example(```typ
#parsely.match($slot("greedy*"), slot("rest*")$, $alpha, beta, gamma$) \
#parsely.match($slot("lazy*?"),  slot("rest*")$, $alpha, beta, gamma$)
```)

#pagebreak()
=== Matching whitespace tightly or loosely

The presence of whitespace in equations is not always visible (for example, `$f(x)$` and #box[`$f (x)$`] are rendered identically) and whitespace is usually ignored when pattern matching.
However, the presense or lack of whitespace between tokens can be explicitly matched with the special `parsely.tight` and `parsely.loose` patterns.
For example, you can write a pattern that matches `$k!$` but not `$k !$` by using `tight`:
#example(```typ
#import parsely: tight, loose
#parsely.match($slot("a") !$, $A!$) \         // matches (insensitive)
#parsely.match($slot("a") !$, $A !$) \        // matches (insensitive)
#parsely.match($slot("a") tight !$, $A!$) \   // matches
#parsely.match($slot("a") loose !$, $A !$) \  // matches
#parsely.match($slot("a") tight !$, $A !$) \  // no match (too loose)
#parsely.match($slot("a") loose !$, $A!$) \   // no match (too tight)
```)
This can be useful to disambiguate function application `$f(x, y)$` from implicit multiplication, `$x^2 (1 - x)$`, for example.

#grammar-examples(```typc
  fact:   (postfix: $tight !$, prec: 3),
  assert: (postfix: $loose !$, prec: 0),
  mul:    (infix: $$, prec: 2, assoc: true),
  grp:    (match: $(slot("body*"))$),
  call:   (match: $slot("fn") tight (slot("body*"))$),
  pow:    (match: $slot("base")^slot("exp")$),
  ```,
  (
    `$lambda f(x^2)$`,
    `$lambda f (x^2)$`,
    `$n k!$`,
    `$P Q !$`,
  ),
  caption: [
    Tightness and looseness are used to distinguish `call` operators from `mul`s.
    Similarly, `fact` and `assert` are distinguished by whitespace patterns.
])

#pagebreak()

== Operator precidence <prec>

Operators which consume positional arguments (of kind `prefix`, `infix` or `postfix`) have an optional precedence specified by a `prec` key which controls how tightly they bind to operands (neighbouring non-whitespace tokens).
The default precedence is zero.

#grammar-examples(```typc
  add:   (infix: $+$,   prec: 1, assoc: true),
  neg:   (prefix: $-$,  prec: 2),
  dot:   (infix: $dot$, prec: 1.5),
  fact:  (postfix: $!$, prec: 3),
  query: (postfix: $?$, prec: 0),
  mul:   (infix: $$,    prec: 2, assoc: true),
  ```,
  (
    $-x + bold(u) dot lambda bold(v) + p q r$,
    $4pi r^2 + z!$,
    $-X k! Z?$,
  ),
  styler: (tree, grammar) => parsely.walk(tree, post: n => {
    let it = parsely.render(n, grammar)
    let c = hash-color(n.head).darken(10%)
    text(c, $lr((it), size: #115%)$)

  }),
  caption: [
    Precedence should higher for "stickier" operators, and can be fractional.
  ]
)

All operators support slot patterns, including prefix operators.
For example,, this allows you to parse summation notation "$sum_#`var` #`body`$" as a prefix operator with slots containing limits.
#grammar-examples(```typc
  add: (infix: $+$, prec: 1, assoc: true),
  dot: (infix: $dot$, prec: 2),
  sum: (prefix: $sum_slot("var")$, prec: 2),
  mul: (infix: $$, prec: 2, assoc: true),
  grp: (match: $(slot("body*"))$),
  ```,
  (
    $sum_i x_i + y + z$,
    $sum_i (x_i + y_i) + z$,
    $sum_i (x_i dot y_i + z_i)$,
  ),
  caption: [
    Summation notation as a prefix operator with higher precedence than addition.
  ]
)


#pagebreak()
== Associativity of infix operators <assoc>

Infix operators additionally have an optional associativity specified by an `assoc` key which applies when the same operator appears in a sequence.
Possible values are `left`, `right` and `true`, for left/right associativity (meaning the operators group leftward or rightward) and true associativity (meaning the operator merges with itself and collects multiple arguments).

#grammar-examples(```typc
  left:  (infix: $<==$,  assoc: left),   // always has exactly two args
  right: (infix: $==>$,  assoc: right),  // always has exactly two args
  both:  (infix: $<==>$, assoc: true),   // can have more than two args
  seq:  (infix: $,$, assoc: true),
  ```,
  (
    $a <== b <== c$,
    $a ==> b ==> c$,
    $a <==> b <==> c$,
  ),
  styler: (tree, grammar) => parsely.walk(tree, post: n => {
    let it = parsely.render(n, grammar)
    let c = hash-color(n.head).darken(10%)
    text(c, $(it)$)

  }),
)








== Parsing juxtaposition as an operator <juxt>

It is common to want to parse sequences of juxtaposed tokens.
The default behaviour is to stop parsing when a token is encountered that is not the argument or slot of an operator.
To parse multiple tokens as one, you can use strings if applicable or wrap tokens in a box.

#grammar-examples(```typ
op: (infix: $plus.o$),
grp: (match: box),
```, (
  `$1 plus.o a b c$`,
  `$1 plus.o "abc"$`,
  `$1 plus.o #box($a b c$)$`,
), caption: [
  Different ways to parse multiple juxtiposed tokens. The trailing red symbols show the `rest` argument returned by `parsely.parse()`, containing content that failed to parse.
])

Alternatively, juxtiposition can be parsed as an infix operator with an empty pattern (`$$` or `none`).
This is useful for parsing implicit multiplication, in which case the operator is also given a product-level precedence, as in @example-juxt.

Because the empty pattern always matches, #highlight[juxtaposition operators should appear later than other infix operators] in the grammar dictionary, otherwise $a times b$ is parsed as three tokens $(a, times, b)$ juxtaposed); #highlight[and before match operators], otherwise trailing tokens will be encountered (and parsing halted) before the parser realises the tokens can be interpreted as the right-hand argument of the juxtaposition operator.

#grammar-examples(```typ
add: (infix: $+$, prec: 1),
mul: (infix: $times$, prec: 2),  // juxt must be after this
juxt: (infix: none, assoc: true, prec: 2), 
grp: (match: $(slot("body*"))$), // juxt must be before this
```, (
  $1 + a b times c$,
  $(1 + a) (b times c)$,
  $2^0 2^1 2^2 dots.c 2^k$
), caption: [
  Parsing implicit multiplication.
]) <example-juxt>

== Parsing and syntax trees

Parsing content with respect to a grammar is the process of transforming the content into a _syntax tree_.
The main function `parsely.parse(expr, grammar)` returns a dictionary containing `tree` and `rest`.
The tree is composed of nodes with two kinds of children: _positional_ arguments and _slot_ arguments.
Each node is a dictionary of the form
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
#highlight[Not all content has to be parsed.]
When `parsely.parse()` is called on some content, it tries to match the content with operators defined in the grammar.
If successful, the parser recursively descends into arguments and tries to parse those.
If parsing slot arguments fails, the slot is simply left as content in the resulting syntax tree.
If parsing a positional argument fails, what was parsed so far is returned in `tree` and remaining content is returned in `rest`.


=== Tree traversal

You can do many things to the resulting syntax tree by performing a _post-order tree walk_.

For example, @example-walk implements a post-walk which transforms leaf nodes (the symbols $a$, $b$ and $2$) into `"{a}"`, `"{b}"`, `"{2}"` and then converts operators nodes (`add` and `pow`) into strings custom rules.
#figure(example(```typ
#parsely.walk(tree, post: node => {
  let (head, args, slots) = node
  if head == "add" { args.join(" + ") }
  else if head == "pow" { slots.base + "^" + slots.exp }
  else { repr(node) } // a fallback string representation
}, leaf: it => "{" + it + "}")
```, scope: (tree: parsely.parse($a + b^2$, grammar).tree)),
caption: [Traversing the syntax tree from @example-tree to output a string.]) <example-walk>

Similar post-order tree walks can be used to rewrite nodes, reorder arguments, evaluate expressions numerically, or return content with certain styles or annotations added to specific nodes.


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
