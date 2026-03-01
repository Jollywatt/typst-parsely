#import "@preview/parsely:0.1.0"
#import "@preview/cetz:0.4.2"

#show "CeTZ": link.with("https://cetz-package.github.io/")

= Drawing expression trees with CeTZ 

The CeTZ package has utilities for drawing trees represented as nested arrays.
You can transform Parsely's syntax trees from their dictionary format into `(node, ..children)` format with a simple post-walk.

#let eqn-tree(eqn) = {
  let (tree, rest) = parsely.parse(eqn, parsely.common.arithmetic)

  let array-tree = parsely.walk(tree, post: it => (
    strong(raw(it.head)), 
    ..it.args, 
    ..it.slots.pairs().map(((slot, it)) => {
      // convert slots into unary nodes
      (text(gray, 0.8em, raw(slot)), it)
    }),
  ), leaf: math.equation)

  cetz.canvas({
    cetz.draw.set-style(
      content: (padding: .1),
      stroke: 1pt + gray,
    )
    cetz.tree.tree(
      array-tree,
      grow: 0.5, spread: 0.15,
      draw-edge: (src, tgt, parent, child) => {
        cetz.draw.bezier(
          (name: src, anchor: "south"),
          (name: tgt, anchor: "north"),
          (tgt, 60%, (tgt, "|-", src)),
          stroke: 2pt/(1 + parent.depth/3)
        )
      }
    )
  })
}

#let eqn = $((-1)^(n - 1) (2n)!)/(4^n (n!)^2 (2n - 1))$
For example, the $n$th coefficient in the series expansion of $sqrt(1 + x)$ is:
$ eqn quad equiv quad #eqn-tree(eqn) $
