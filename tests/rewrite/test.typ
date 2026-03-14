#import "/src/exports.typ": *

#let grammar = (
  pow: (match: math.attach, rewrite: it => {
    let (base, ..rest) = it.slots
    if "t" in rest {
      (head: "pow", args: (), slots: (base: base, exp: rest.t))
    } else {
      base
    }
  }),
  group: (match: $(slot("body*"))$)
)

#parse($x_i^2$, grammar)
#parse($(x_i)^2$, grammar)