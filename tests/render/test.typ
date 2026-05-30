#import "/src/exports.typ": *
#set page(width: auto, height: auto, margin: 1cm)

#let tree = util.content-to-tree($sqrt(1 + x^2)$)
#page(render.tree(tree))

#let tree = util.content-to-tree(parse($sqrt(a^2 + b^2) = c$, common.arithmetic).tree)
#page(render.tree(tree))
#page(render.waterfall(tree))
#page(render.waterfall(tree, side: bottom, grow: .4em, inset: .4em, head-color: util.random-color.with(hue: (180deg, 320deg))))
