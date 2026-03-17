#import "@preview/tidy:0.4.3"
#import "@preview/cetz:0.4.2"
#import "../src/exports.typ" as parsely: *

#let PUBLIC_SOURCE_URL = sys.inputs.at("source-url", default: none)
#let typst-toml = toml("../typst.toml")
#show "{{VERSION}}": typst-toml.package.version
#show "{{PACKAGE_NAME}}": typst-toml.package.name

#set page(margin: (x: 25mm, y: 20mm))
#set heading(numbering: "1.", supplement: none)
#show heading: it => v(1em) + text(1.2em, it) + v(1em, weak: true)

#set text(font: "Fira Sans")
#show raw: set text(1.2em, font: "Fira Code", weight: 500)
#set raw(lang: "typc")

#show link: it => underline(it)
#show figure: set align(left)
#show figure.caption: set text(0.8em)
#set par(justify: true)

#show ref: r => {
  if r.element != none and r.element.func() == heading {
    let label = r.supplement
    if label == auto { label = r.element.body }
    link(r.element.location(), strong(label))
  } else { r }
}


#let code-fill = oklab(98.17%, -0.005, -0.007)
#let frame(..args) = {
  set par(justify: false)
  set text(0.93em)
  box(width: 100%, inset: 8pt, stroke: code-fill.darken(30%), ..args)
}
#show raw.where(block: true): it => {
  frame(it, fill: code-fill)
}

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
  slots = slots.pairs().map(((k, v)) => [#ctext[#k] #v])
  args = slots + args

  let gap = 3pt
  show: box.with(
    stroke: (rest: 0.5pt + c, top: 1.5pt + c, bottom: none),
    radius: (top: 5pt),
  )
  grid(
    align: bottom,
    inset: (x: gap, top: gap),
    columns: 1 + args.len(),
    ctext(strong(head)), ..args,
    ..range(args.len()).map(x => {
      grid.vline(x: x + 1, stroke: 0.5pt + c)
    }),
  )
}, leaf: math.equation)

#let grammar-examples(grammar-block, eqns, ..args, styler: (t, g) => waterfall(t)) = {
  let grammar = eval("(\n"+grammar-block.text+"\n)", scope: (slot: slot, tight: tight, loose: loose, parsely: parsely))
  figure(grid(
    frame(fill: code-fill, {
      let lines = grammar-block.text.split("\n")
      let it = for l in lines {
        if l.match(regex("^\w+:")) == none { raw(l + "\n") }
        else {
          let i = l.position(":")
          let key = l.slice(0, i)
          text(hash-color(key), raw(key)) + raw(l.slice(i)) + "\n"
        }
      }
      emph[Operators in grammar] 
      par(it)
    }),
    frame({
      emph[Parsing examples] + v(-1em)
      set text(1.1em)
      set align(center)
      grid(
        columns: (auto, auto, auto),
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
    color.oklch(65%, 40%, h)
  }

  let regions(tree, grammar) = context util.walk(tree, post: it => {
    let c = hash-color(it.head)
    show: rect.with(
      stroke: 1.5pt + c,
      fill: c.transparentize(95%),
      inset: 4pt,
    )
    $ #render.node(it, grammar) $
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

  let array-tree = util.walk(tree, post: it => {
    let args = {
      if it.head == "sum" {
        (it.slots.var, it.slots.start, it.slots.stop) // custom order
      } else {
        it.slots.values()
      }
      it.args
    }
    (head: it.head, args: args, slots: (:))
  }, leaf: math.equation)
  
  
  let lisp-figure = util.walk(array-tree, post: it => {
      set text(14pt)
      let c = hash-color(it.head)
      text(c, strong[#it.head])
      text(c)[(]
      it.args.join(text(c)[, ])
      text(c)[)]
    })

  let tree-figure = {
    set text(12pt)
    cetz.canvas({
      let a = util.walk(tree, post: it => {
        let c = hash-color(it.head)
        (text(c, strong(it.head)), ..it.args, ..it.slots.values())
      })
      cetz.draw.set-style(content: (padding: .15))
      cetz.tree.tree(a, grow: 0.55, spread: 0.15)
    })
  }


  let sep = text(20pt, $ arrow.t.b $)
  stack(
    spacing: 1.5em,
    box(text(17pt, regions(tree, grammar))),
    sep,
    lisp-figure,
    sep,
    move(dx: .9em, tree-figure),
  )
}

#[
  #set text(15pt)
  #box(title[#typst-toml.package.name])
  #text(0.8em)[
    version #typst-toml.package.version
    #if PUBLIC_SOURCE_URL != none { link(PUBLIC_SOURCE_URL)[source] }
  ]

  Parse equations with Typst
]


#v(1fr)
#align(center, cover-graphic)
#v(1fr)

#context align(right, block(width: 50%, outline(depth: 1, title: none)))

#pagebreak()
#heading(numbering: none)[Contents]
#show outline.entry.where(level: 1): it => v(1em) + it
#context outline(target: selector(heading).after(here()), title: none)


#pagebreak()
#set page(numbering: "1")



= At a glance


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
  #parsely.render.tree(tree)
  ```, scope: (tree: tree, grammar: grammar))

  #example(```typ
  #parsely.walk(tree, post: n => parsely.render.node(n, grammar))
  ```, scope: (grammar: grammar, tree: tree))


#let example-file(path, tint) = {
  show: block.with(
    inset: 1em,
    width: 100%,
    fill: tint.lighten(95%),
    stroke: (thickness: 1pt, paint: tint.lighten(50%), dash: (1pt, 1pt)),
  )
  set heading(outlined: false)
  set heading(offset: 1)
  show heading.where(level: 2): set heading(outlined: true)
  let url = PUBLIC_SOURCE_URL + "/docs/" + path
  text(tint.darken(40%), emph[Source code: #link(url, raw(path, lang: none))])
  v(-2em)

  // don't include first line of example, which imports parsely
  let src = read(path).split("\n").slice(1).join("\n")
  eval(src, mode: "markup", scope: (parsely: parsely))
}

#pagebreak()


= Usage examples <examples>

This section contains some intresting self-contained applications of Parsely.
Each section is a separate example file which may be found at
#{let u = PUBLIC_SOURCE_URL + "/docs/examples"; link(u, u)}.

#example-file("examples/cetz-tree.typ", orange)
#example-file("examples/venn.typ", yellow)
#example-file("examples/calc.typ", blue)
#example-file("examples/pariman.typ", green)


#pagebreak()


= Guide

== Declaring grammars <grammars>

Grammars define how content is transformed into an abstract syntax tree.


A grammar is given as a dictionary where each value is an _operator_ and each key is the operator's name, which becomes the name of the corresponding node in the syntax tree.

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

The order that operators are listed in a grammar matters (and is not related to @prec[operator precedence]).
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
  stroke: none,
  columns: (auto, ..(1fr,)*4),

  [Operator type], [Prefix], [Infix], [Postfix], [Match],
  table.hline(),
  [Positional arguments], [one after], [to either side], [one before], text(gray)[none],
  [Slot arguments], ..([yes],)*4,
  [Precedence, `prec`], [required], [required], [required], text(gray)[not applicable],
  [Associativity, `assoc`], na, [left/right/both], na, na,
), caption: [
  Kinds of operators available when declaring grammars and their features.
]) <op-kinds-table>
]


Prefix, infix and postfix operators consume tokens around them as _positional arguments_, subject to @prec[precedence].
Match operators do not consume tokens to the left or right, but simply match a pattern.
All operators support @slots, possibly consuming tokens as _slot arguments_.




=== Other operator fields

In addition to its kind and pattern, an operator can have any of the keys in @op-table.

#[
#let na = text(gray)[not applicable]
#figure(table(
  columns: (auto, 1fr),
  stroke: none,
  [Operator key], [Description],
  table.hline(),

  [(@op-kinds[kind])],
  // [content or @slots[pattern]],
  [For example, the operator `(infix: $+$, ..)` has the @op-kinds[kind] "`infix`" and the @slots[pattern] `$+$`. This must be first entry in the operator dictionary.],

  `prec`,
  // `number`,
  [The @prec level. Has no effect for `match` operators.],

  `assoc`,
  // [`left`/`right`/`true`],
  [@assoc[Associativity] for infix operators, ignored for other kinds.],

  `guard`,
  [A @op-guard[predicate function] to allow matching nodes conditionally depending on the values of slots. Must be a boolean function accepting a dicionary.],

  `rewrite`,
  [A @rewrite[rewrite rule] or function which takes the node which would be produced and transforms it before parsing continues.],

  [(others)], [Any other fields are allowed and ignored.]
), caption: [
  Meanings of entries of an operator dictionary.
]) <op-table>
]


== Pattern matching and slots <slots>

Operator patterns are used to match sequences of tokens while parsing content.
Patterns can be:

- *Single tokens*, like `$+$` or `$in$`.

- *Sequences of tokens*, like `$::$`, `$=^"def"$` or `$dif/(dif x)$`.

- *Slot patterns*, like `$sum_slot("var")$` or `$[slot("left*"), slot("right*")]$`.

- *Element functions*, like `math.frac`, as a shorthand for the slot pattern matching that element and capturing its fields, i.e. `$frac(slot("num"), slot("denom"))$`.

Pattern matching is done by the function `parsely.match(pattern, expr)`, which returns a dictionary if the match is successful and `false` otherwise.
#example(```typ
#import parsely: slot
- #parsely.match($1 + slot("rhs")$, $1 + x^2$)
- #parsely.match($A B C$, $A B Omega$)
- #parsely.match(math.frac, $1/2$) // or $slot("num")/slot("denom")$
```)

Slots are wildcard tokens that match content in several ways:

- `slot(name)` matches any single token.

- `slot(name, many: true, greedy: bool)` @slot-many[matches any sequence].

- `slot(name, any: array)` @slot-any[matches any one of a set of patterns].

- `slot(name, guard: function)` @slot-guard[matches a token conditionally].

- The special patterns `parsely.tight` and `parsely.loose` allow @tight-loose[matching whitespace].

=== Matching sequences greedily or lazily <slot-many>

A slot such as `slot("rhs")` will match a single token, but *multiple tokens* can be matched with `slot("rhs", many: true)` or `slot("rhs*")` for short.

#example(```typ
#parsely.match($1; 2; slot("etc")$,  $1; 2; 3; 4$) // single token slot
#parsely.match($1; 2; slot("etc*")$, $1; 2; 3; 4$) // multi token slot
```)

By default, multi-token slots are *greedy*, preferring to match more tokens when there is choice.
Conversely, *lazy* slots such as `slot("name*", greedy: false)` or `slot("name*?")` for short match as few tokens as possible.

#example(```typ
- #parsely.match($slot("greedy*"), slot("rest*")$, $alpha, beta, gamma$)
- #parsely.match($slot("lazy*?"),  slot("rest*")$, $alpha, beta, gamma$)
```)

=== Matching any pattern in a union <slot-any>

Slots with an `any` argument containing an array of sub-patterns only match one of those patterns (in the order they are given).

This is sometimes useful for grouping many similar tokens together into one operator.

#grammar-examples(```typ
comp: (infix: slot("op", any: ($=$, $!=$, $<$, $>$, $<=$, $>=$)))
```, (
  $xi = 2 > epsilon != 0$,
), caption: [
  All comparison tokens are parsed as the `comp` operator tagged by an `"op"` slot.
])

=== Matching conditionally (slot guards) <slot-guard>

Slots may be made conditional by supplying a boolean predicate in the `guard` argument.
A predicate is a function accepting the matched content and returning a boolean.
A regular expression `re` can also be used as a shortcut for the predicate function `it => parsely.stringify(it).match(re) != none`.

#grammar-examples(```typ
sep: (infix: $,$, assoc: true),
number: (match: slot("it", guard: regex("^[\d\.]+$"))),
text: (match: slot("it", guard: it => it.func() == text)),
```, (
  $pi, "hi", circle^2, 1.414$,
))


=== Matching whitespace tightly or loosely <tight-loose>

The presence of whitespace in equations is not always visible (for example, `$f(x)$` and #box[`$f (x)$`] are rendered identically) and whitespace is usually ignored when pattern matching.
However, the presence or lack of whitespace between tokens can be explicitly matched with the special `parsely.tight` and `parsely.loose` patterns.
For example, you can write a pattern that matches `$k!$` but not `$k !$` by using `tight`:
#example(```typ
#import parsely: tight, loose
#parsely.match($slot("a") !$, $A!$)         // matches (insensitive)
#parsely.match($slot("a") !$, $A !$)        // matches (insensitive)
#parsely.match($slot("a") tight !$, $A!$)   // matches
#parsely.match($slot("a") loose !$, $A !$)  // matches
#parsely.match($slot("a") tight !$, $A !$)  // no match (too loose)
#parsely.match($slot("a") loose !$, $A!$)   // no match (too tight)
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





// #pagebreak()

== Operator precedence <prec>

Operators which consume positional arguments (`prefix`, `infix` or `postfix` operators) have an optional precedence specified by a `prec` key which controls how tightly they bind to operands (neighbouring non-whitespace tokens).
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
    let it = parsely.render.node(n, grammar)
    let c = hash-color(n.head).darken(10%)
    text(c, $lr((it), size: #115%)$)

  }),
  caption: [
    Precedence is higher for "stickier" operators, and can be an integer or float.
  ]
)

All operators support slot patterns, in particular prefix operators.
This allows summation notation "$sum_#`var` #`body`$" to be parsed as a prefix operator with slots, for example.
#grammar-examples(```typc
  add: (infix: $+$, prec: 1, assoc: true),
  dot: (infix: $dot$, prec: 2),
  sum: (prefix: $sum_slot("var")$, prec: 2),
  mul: (infix: $$, prec: 2, assoc: true),
  grp: (match: $(slot("body*"))$),
  ```,
  (
    $sum_i alpha x_i + y + z$,
    $sum_i alpha (x_i + y_i) + z$,
    $sum_i alpha (x_i dot y_i + z_i)$,
  ),
  caption: [
    Summation notation as a prefix operator with higher precedence than addition.
  ]
)


// #pagebreak()
== Associativity of infix operators <assoc>

Infix operators additionally have an associativity specified by an `assoc` key which applies when the same operator appears in a sequence.
Possible values are `left` (default), `right` and `true`, for left/right associativity and true associativity (meaning the operator merges with itself and collects multiple arguments) respectively.

#grammar-examples(```typc
  left:  (infix: $<==$,  assoc: left),   // always has exactly two args
  right: (infix: $==>$,  assoc: right),  // always has exactly two args
  both:  (infix: $<==>$, assoc: true),   // can have more than two args
  ```,
  (
    $a <== b <== c$,
    $a ==> b ==> c$,
    $a <==> b <==> c$,
  ),
  styler: (tree, grammar) => parsely.walk(tree, post: n => {
    let it = parsely.render.node(n, grammar)
    let c = hash-color(n.head).darken(10%)
    text(c, $(it)$)

  }),
)



== How trees are represented <trees>

Everywhere in this manual, a "tree" or "node" refers to a dictionary of the form
```
(head: str, args: array, slots: dictionary)
```
where "`head`" is name of the node, and the node's children are the elements of "`args`" or the values of "`slots`".
Both `args` and `slots` always be present, even if they are empty.

Nodes in a tree are often represented in the simpler array form `(head, ..children)`.
However, having both kinds of children makes it easier to represent
- operators with both positional arguments and named slots; and
- element functions associated with positional and named arguments.


=== Tree traversal

You can do many things with a syntax tree with @walk.
For example, @example-walk implements a post-walk which transforms leaf nodes (the symbols $a$, $b$ and $2$) into `"{a}"`, `"{b}"`, `"{2}"` and then converts operator into strings with custom rules.
#figure(example(```typ
#let tree = parsely.parse($sqrt(a + b^2)$, parsely.common.arithmetic).tree
#parsely.walk(tree, post: node => {
  let (head, args, slots) = node
  if head == "add" { args.join(" + ") }
  else if head == "pow" { args.join("^") }
  else if head == "sqrt" { "√(" + slots.radicand + ")" }
  else { repr(node) } // a fallback representation
}, leaf: it => "{" + it + "}")
```, scope: (grammar: grammar)),
caption: [Traversing the syntax tree to output a string.]) <example-walk>

Similar post-order tree walks can be used to rewrite nodes, reorder arguments, evaluate expressions numerically, or return content with certain styles or annotations added to specific nodes.

See the source code of the @examples for many different examples of syntax tree manipulations with tree walks.








== Operator rewriting and operator guards


=== Operator predicates <op-guard>

=== Rewrite rules <rewrite>


== Gotchas

=== Parsing juxtaposition as an operator <juxt>

It is common to want to parse sequences of consecutive non-operator tokens.
The default behaviour is to stop parsing when a token is encountered that is not the argument or slot of an operator.
To parse multiple tokens as one, you can use strings (if the formatting is acceptable) or wrap the tokens in an invisible box.

#grammar-examples(```typ
op: (infix: $plus.o$),
grp: (match: box),
```, (
  `$1 plus.o a b c$`,
  `$1 plus.o "abc"$`,
  `$1 plus.o #box($a b c$)$`,
), caption: [
  Different ways to parse multiple juxtaposed tokens. The trailing red symbols show the `rest` argument returned by `parsely.parse()`, containing content that failed to parse.
])

Alternatively, juxtaposition can be parsed as an infix operator by using an empty pattern #box[(`$$` or `none`)].
This is useful for parsing implicit multiplication, in which case the operator is also given a product-level precedence, as in @example-juxt.

Because the empty pattern always matches anything, #highlight[juxtaposition operators should appear later than other infix operators] in the grammar dictionary (otherwise $a times b$ is parsed as three tokens $(a, times, b)$ juxtaposed).
Additionally, they should occur #highlight[before match operators], otherwise trailing tokens will be encountered (and parsing halted) before the parser realises the tokens can be interpreted as the right-hand argument of the juxtaposition operator.

#grammar-examples(```typ
add: (infix: $+$, prec: 1),
mul: (infix: $times$, prec: 2),  // "juxt" must be after this
juxt: (infix: none, assoc: true, prec: 2), 
grp: (match: $(slot("body*"))$), // "juxt" must be before this
```, (
  $1 + a b times c$,
  $(1 + a) (b times c)$,
  $2^0 2^1 2^2 dots.c 2^k$
), caption: [
  Parsing implicit multiplication.
]) <example-juxt>





=== Parsing exponents and subscripts

Because Typst content is itself a tree-like structure, some content cannot be parsed in the same way that a string of tokens would be.
For instance, the body of the equation `$x_i^2$` is a single `math.attach` element containing both the superscript and subscript as fields:
#example(```typ
#let tree = parsely.util.content-to-tree($x_i^2$.body)
#parsely.render.tree(tree)
```)
In fact, `$x_i^2$` and `$x^2_i$` are indistinguishable.
This makes parsing `$x_i^2$` as $(x_i)^2$ as opposed to $(x^2)_i$ slightly tricky, for example.

To illustrate what why this is an issue, the grammar in @example-pow-bad naively matches `math.attach` elements, but silently drops other fields such as subscripts, so $x_i^2$ becomes $x^2$.
#grammar-examples(```
pow: (match: $slot("base")^slot("exp")$) // don't do this
```, (
  $x_i^2$,
), caption: [A limitation of slot-based pattern matching. #highlight[Notice the subscript gets dropped.]]) <example-pow-bad>

The trick is to use an operator `rewrite` rule, which lets us manipulate the node however we want as soon as the parser encounters content matching the operator's pattern.
A rewrite rule is a function which accepts the node (as it would be parsed) and outputs content or another node which the parser will continue to descend into.

The `pow` operator in @example-pow-good matches `math.attach` elements, and uses a `rewrite` rule to ensure that non-superscript attachments are added to the base before parsing continues.

#grammar-examples(```
group: (match: $(slot("body*"))$),
add: (infix: $+$),
pow: (
  match: math.attach,
  guard: slots => "t" in slots, // required to avoid infinite recursion
  rewrite: it => {
    let (base, t, ..rest) = it.slots
    if rest.len() > 0 { base = math.attach(base, ..rest) }
    (head: "pow", args: (base, t), slots: (:))
  }),
```, (
  `$x_i^2$`,
  `$x^2_i$`,
  `$x_0$`,
  `$(x^i + y_j)^(p + q)$`,
), caption: [
  A correct way of parsing superscripts while preserving other attachments such as subscripts.
]) <example-pow-good>

Rewrite rules can be dangerous in the same sense as a tree pre-walk: it can result in infinite recursion if the output of the rewrite rule is matched by the same operator.

To guard against this, we must use the @op-guard[operator guard]
`slots => "t" in slots`
which ensures that `pow` only applies to `math.attach` elements which have a superscript (and possibly other fields).





#pagebreak()

= Function reference <func-ref>

#set heading(numbering: none)


#let show-function(fn, module) = [

  === #raw({
    module
    fn.name
    "("
    fn.args.keys().join(", ")
    ")"
  })
  #label(fn.name)

  #let i = fn.description.position(regex("\n\s*\n"),)
  #if i == none { i = 0 }
  #let summary = fn.description.slice(0, i)
  #let details = fn.description.slice(i)

  #eval(summary, mode: "markup")

  #for (arg, (description,)) in fn.args [
    #if description == "" { continue }
    - #strong(raw(arg + ":")) #eval(description, mode: "markup")
  ]

  #show raw.where(lang: "example"): it => {
    raw(it.text, lang: "typc", block: true)
    let out = eval(it.text, scope: (parsely: parsely))
    set text(font: "Fira Sans")
    [#out]
  }

  #eval(details, mode: "markup")
]


#let show-module-docs(path, module: none) = {

  let sec = "{{PACKAGE_NAME}}"
  if module != none { sec += "." + module }
  [== Module #raw(sec)]

  if module != none { module += "." }
  let m = tidy.parse-module(read(path), name: module)

  for fn in m.functions [
    - #link(label(fn.name), raw(module + fn.name + "()"))
  ]

  for fn in m.functions {
    show-function(fn, module)
    line(length: 100%, stroke: (thickness: 0.75pt, dash: "dotted"))
    v(5em, weak: true)
  }
}

#show-module-docs("../src/parse.typ")
#show-module-docs("../src/render.typ", module: "render")
#show-module-docs("../src/util.typ", module: "util")