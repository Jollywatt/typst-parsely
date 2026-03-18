#import "/src/exports.typ": *
#set page(width: auto, height: auto, margin: 1cm)

#let tree = util.content-to-tree($sqrt(1 + x^2)$)

#page(render.tree(tree))

