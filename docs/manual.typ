#import "@preview/tidy:0.4.3"
#import "../src/exports.typ": *

#let typst-toml = toml("../typst.toml")

#set text(font: "Fira Sans")

#title[#typst-toml.package.name manual]
version #typst-toml.package.version

#context outline(target: selector(heading).after(here()))

#set list(marker: [--])

= Tutorial


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

#let expr = $a + b bold(u) dot bold(v) + c! = (1 - (2 - 3))$
#let (tree, rest) = parse(expr, grammar)
#expr

#util.walk(tree, post: it => {
  let body = render-node(it, grammar)
  $[body]_mono(it.head)$
})

#util.walk(tree, post: it => {
  let (head, args, slots) = it.values()
  box(stroke: (left: 1pt), inset: (left: 5pt))[
    #emph(head)
    #args.map(i => enum.item[#i]).join()
    #slots.pairs().map(((k, v)) => list.item[#k:\ #v]).join()
  ]
})


= Examples

== Drawing expression trees

== Evaluating arithmetic from equations

== Annotating matrix dimensions

== Rewriting cubing algorithms

= Guide

== Declaring grammars

== Prefix, infix and postfix operators

== Precedence and associativity

== Pattern matching operators

== Matching whitespace tightly or loosely

== Parsing juxtaposition as an operator


