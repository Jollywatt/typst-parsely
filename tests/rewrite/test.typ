#import "/src/exports.typ": *

#let grammar = (
  pow: (
    match: math.attach,
    guard: it => "t" in it.fields(),
    rewrite: it => {
      let (base, ..rest) = it.slots
      let exp = rest.remove("t", default: none)
      let base = if rest.len() > 0 { math.attach(base, ..rest) } else { base }
      if exp == none { return base }
      (head: "pow", args: (), slots: (base: base, exp: exp))
    },
  ),
  group: (match: $(slot("body*"))$)
)

#assert.eq(
  parse($x_i^2$, grammar).tree,
  {
    let inner = $x_0$.body
    parse($inner^2$, grammar).tree
  }
)

// #parse($(x_i)^2$, grammar)