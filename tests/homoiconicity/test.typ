#import "/src/exports.typ": *

#let is-homoiconic(it, ..args) = util.tree-to-content(util.content-to-tree(it, ..args)) == it

#assert(is-homoiconic($a + x^2$))
#assert(is-homoiconic($12.52 = "xyz"$))
#assert(is-homoiconic($sqrt(x)$))
#assert(is-homoiconic($x$, exclude: ("symbol",)))
#assert(is-homoiconic(rect(fill: blue, circle[hi *there*])))
#assert(is-homoiconic($pi + sqrt(#circle[not parsed $x^2$])$, exclude: "circle"))
#assert(is-homoiconic(text(red)[styled text]))