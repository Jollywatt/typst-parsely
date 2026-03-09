#import "/src/exports.typ": *

#let grammar = (
  pow: (
    match: math.attach,
    guard: slots => "t" in slots,
    rewrite: it => {
      let (base, t: exp, ..rest) = it.slots
      let base = if rest.len() > 0 { math.attach(base, ..rest) } else { base }
      if exp == none { return base }
      (head: "pow", args: (base, exp), slots: (:))
    },
  ),
  group: (match: $(slot("body*"))$, rewrite: it => it.slots.body)
)

#assert.eq(
  parse($x_i^2$, grammar).tree,
  {
    let inner = $x_i$.body
    parse($inner^2$, grammar).tree
  }
)

#assert.eq(
  parse($(x_i)^2$, grammar).tree,
  (head: "pow", args: ($x_i$.body, [2]), slots: (:))
)