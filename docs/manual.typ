#import "@preview/tidy:0.4.3"
#import "@preview/cetz:0.4.2"
#import "../src/exports.typ" as parsely: *

#let typst-toml = toml("../typst.toml")
#show "{{VERSION}}": typst-toml.package.version
#show "{{PACKAGE_NAME}}": typst-toml.package.name

#set heading(numbering: "1.", supplement: none)
#show heading: it => v(1em) + it + v(1em, weak: true)
#set text(font: "Fira Sans")
#show raw: set text(1.1em, font: "Fira Code", weight: 500)
#show link: it => underline(it)

#show ref: r => {
  if r.element != none and r.element.func() == heading {
    let label = r.supplement
    if label == auto { label = r.element.body }
    link(r.element.location(), strong(label))
  } else {
    r
  }
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
    )
    $ #render(it, grammar) $
  })

  let grammar = (
    eq: (infix: $=$, prec: 0),
    sum: (prefix: $sum_(slot("var") = slot("start"))^slot("stop")$, prec: 2),
    frac: (expr: $slot("num")/slot("denom")$),
    fact: (postfix: $!$, prec: 3),
    mul: (infix: $$, prec: 2),
    pow: (expr: $slot("base")^slot("exp")$),
    call: (expr: $slot("fn") tight (slot("args"))$),
  )

  let eq = $exp(x) = sum_(k = 0)^oo 1/k! x^k$
  let (tree, rest) = parse(eq, grammar)
  
  let sep = text(20pt, $ arrow.t.b $)
  stack(
    spacing: 10pt,
    box(text(15pt, regions(tree, grammar))),
    sep,
    util.walk(tree, post: it => {
      set text(12pt)
      let c = hash-color(it.head)
      text(c, strong[#it.head])
      text(c)[(]
      {
        it.at("slots", default: (:)).values()
        it.at("args", default: ())
      }.join(text(c)[, ])
      text(c)[)]
    }),
    sep,
    move(dx: 0.5em, text(12pt, cetz.canvas({
      let a = util.walk(tree, post: it => {
        let c = hash-color(it.head)
        (text(c, strong(it.head)), ..it.args, ..it.slots.values())
      })
      cetz.draw.set-style(content: (padding: .1))
      cetz.tree.tree(a, grow: 0.5, spread: 0)
    }))),
  )
}

#[
  #set text(15pt)
  #title[#typst-toml.package.name]
  Parse equations with Typst
]

version #typst-toml.package.version

#v(1fr)

#align(center, cover-graphic)

#v(1fr)

#context outline(target: selector(heading).after(here()))

#v(1fr)

#pagebreak()

#let code-fill = oklab(98.17%, -0.005, -0.007)
#show raw.where(block: true): box.with(width: 100%, inset: 1em, fill: code-fill, stroke: code-fill.darken(30%))

#let example(code, scope: (:)) = {
  code = code.text
  set box(width: 100%, inset: 1em, stroke: code-fill.darken(30%))
  let codebox = box(raw(code, lang: "typ"), fill: code-fill)
  let out = eval(code, mode: "markup", scope: (
    parsely: parsely,
    slot: slot,
    ..scope,
  ))
  if util.flatten-sequence(out).all(util.is-space) {
    codebox
  } else {
    stack(codebox, box(out))
  }
}



= At a glance

#set raw(lang: "typc")

+ Import the package with:

  ```typ
  #import "@preview/{{PACKAGE_NAME}}:{{VERSION}}"
  ```

+ @grammars[Declare a grammar] by listing the operators you want to parse in a dictionary:

  #let grammar = (
    eq:  (infix: $=$, prec: 0),
    add: (infix: $+$, prec: 1, assoc: true),
    mul: (infix: $$,  prec: 2, assoc: true),
    group: (expr: $(slot("body", many: #true))$),
    pow: (expr: $slot("base")^slot("exp")$),
  )

  #example(```typ
  #import parsely: slot
  #let grammar = (
    eq:  (infix: $=$, prec: 0),
    add: (infix: $+$, prec: 1, assoc: true),
    mul: (infix: $$,  prec: 2, assoc: true),
    grp: (expr:  $(slot("body", many: #true))$),
    pow: (expr:  $slot("base")^slot("exp")$),
  )
  ```)

  Operators can have @prec-assoc and use @slots.

+ Call `parsely.parse()` with the content and the grammar dictionary to use.

  #let eqn = $(a + b)^2 = a^2 + 2a b + b^2$
  #let (tree, rest) = parsely.parse(eqn, grammar)

  #example(```typ
  #let it = $(a + b)^2 = a^2 + 2a b + b^2$
  #let (tree, rest) = parsely.parse(it, grammar)
  ```, scope: (grammar: grammar))

  This returns the syntax tree along with any trailing tokens that failed to parse.
  
+ Use `parsely.walk()` and `parsely.render()` to visit nodes and convert them to content.

  #example(```typ
  #parsely.walk(tree, post: node => parsely.render(node, grammar))
  ```, scope: (grammar: grammar, tree: tree))
  #example(```typ
  #import "@preview/cetz:0.4.2"
  #cetz.canvas({
    let t = parsely.walk(tree, post: ((head, args, slots)) => {
      (pad(strong(head), 3pt), ..args, ..slots.values())
    }, leaf: rect)
    cetz.tree.tree(t, grow: 0.2, spread: 0.5)
  })
  ```, scope: (tree: tree, grammar: grammar))






// #util.walk(tree, post: it => {
//   set list(marker: [--])
//   let (head, args, slots) = it.values()
//   box(stroke: (left: 1pt), inset: (left: 5pt))[
//     #emph(head)
//     #args.map(i => enum.item[#i]).join()
//     #slots.pairs().map(((k, v)) => list.item[#k:\ #v]).join()
//   ]
// })

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


= Guide

== Declaring grammars <grammars>

Grammars define how content is transformed into an abstract syntax tree and can be changed to work for different contexts or domain specific languages.

A grammar is a dictionary where each value is an _operator_ and each key is the operator's name.

For example, a the simple grammar below
#example(```typ
#let grammar = (
  add: (infix: $+$, prec: 1, assoc: true),
  sub: (infix: $-$, prec: 1, assoc: left),
  mul: (infix: $times$, prec: 2, assoc: true),
  pow: (expr: $slot("base")^slot("exp")$),
)
```)
defines $+$ as an associative operator of lower precedence than $times$

#let grammar = (
  add: (infix: $+$, prec: 1, assoc: true),
  sub: (infix: $-$, prec: 1, assoc: left),
  pos: (prefix: $+$, prec: 1),
  neg: (prefix: $-$, prec: 1, assoc: left),
  fact: (postfix: $!$, prec: 3),
  mul: (infix: $times$, prec: 2, assoc: true),
  grp: (expr: $(slot("body", many: #true))$),
  pow: (expr: $slot("base")^slot("exp")$),
  call: (expr: $slot("fn")(slot("args"))$),
  frac: math.frac,
)
#let (tree, rest) = parse($A times f - B^n times sqrt(d)$, grammar)
#waterfall(tree)
// #render.lisp(tree)

An output parse tree consists of nodes whose heads are the name of one of these operators.

// #render.regions(tree, grammar)


== Prefix, infix, postfix and expression operators <op-kinds>

An operator is specified as a dictionary whose first key is its _operator type_ and first value is a _pattern_, such as
`(infix: $+$, ..)`.
Possible operator types are _prefix_, _infix_, _postfix_ and _expr_.
The pattern can be:
- a single literal such as `$+$` or `$in$`
- a sequence of tokens such as `$::$`, `$=^"def"$` or `$dif/(dif x)$`
- a @slots[slot pattern] such as `$sum_slot("var")$` or `$[slot("l"), slot("r")]$`

Prefix, infix and postfix operators consume tokens around them, subject to their precedence, given by a `prec` entry in the operator dictionary.

#[
#show table.cell.where(x: 0): emph
#let na = text(gray)[not applicable]
#table(
  inset: (left: 0pt, rest: 8pt),
  stroke: (x: none),
  columns: (auto, ..(1fr,)*4),
  [Operator type], [Prefix], [Infix], [Postfix], [Expression],
  [Captures positional\ arguments], [one after], [to either side], [one before], text(gray)[neither side],
  [Has precedence], [required], [required], [required], text(gray)[not applicable],
  [Has associativity], na, [left/right/both], na, na,
  [Captures slot\ arguments], ..([yes],)*4,
)
]


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
          (eqn, waterfall(tree) + text(red, $space rest.join()$))
        }).flatten()
      )
    },
  )
}


- a *kind*, either 
- a *pattern*


== Precedence and associativity <prec-assoc>

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


== Pattern matching with slots <slots>

#examples(```typc
  add: (infix: $+$, prec: 1, assoc: true),
  sum: (prefix: $sum_slot("var")$, prec: 2),
  mul: (infix: $$, prec: 2, assoc: true),
  grp: (expr: $(slot("body*"))$),
  pow: (expr: $slot("base")^slot("exp")$),
  com: (expr: $[slot("left*"), slot("right*")]$)
  ```,
  $C_(i j) + sum_k A_(i k) B_(k j) + II$,
  $[h]_star (rho^n + R)$,
  $[A B, C + D]$,
)


== Matching whitespace tightly or loosely

#examples(```typc
  fact: (postfix: $tight !$, prec: 3),
  assert: (postfix: $loose !$, prec: 0),
  mul: (infix: $$, prec: 2, assoc: true),
  grp: (expr: $(slot("body*"))$),
  call: (expr: $slot("fn") tight (slot("body*"))$),
  pow: (expr: $slot("base")^slot("exp")$),
  ```,
  `$lambda f(x^2)$`,
  `$lambda f (x^2)$`,
  `$n k!$`,
  `$P Q !$`,
)

== Parsing juxtaposition as an operator



= Examples

== Common grammars

#let grammar = (
  eq: (infix: $=$, prec: 0),
  ne: (infix: $!=$, prec: 0),
  add: (infix: $+$, prec: 1, assoc: true),
  sub: (infix: $-$, prec: 1),
  dot: (infix: $dot$, prec: 2),
  fact: (postfix: $!$, prec: 4),
  pow: (expr: $slot("base")^slot("exp")$),
  mul: (infix: $$, prec: 3),
  group: (expr: $(slots("body"))$, prec: 0),
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
