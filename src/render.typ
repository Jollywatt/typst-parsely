#import "util.typ"
#import "match.typ"

#let node(it, grammar) = {
  let op = grammar.at(it.head)

  if type(op) == function {
    return op(..it.args, ..it.slots)
  }

  let (kind, pattern) = op.pairs().first()
  let op = if "slots" in it {
    match.substitute-slots(pattern, it.slots)
  } else { pattern }

  let args = it.args
  
  if kind == "infix" {
    $args.join(op)$
  } else if kind == "postfix" {
    $args.first() op$
  } else if kind == "prefix" {
    $op args.first()$
  } else if kind == "match" {
    op
  } else {
    panic(op)
  }
}


#let spans(tree, grammar) = {
  tree = util.node-depths(tree)
  let max-depth = if type(tree) == dictionary {
    tree.at("depth", default: 0)
  } else { 0 }
  let gap = 3pt
  let out = util.walk(tree, post: it => {
    let color = color.hsl(150deg + 35deg*it.depth, 90%, 45%)
    box(
      node(it, grammar),
      inset: (x: 2pt),
      outset: (x: -1pt, top: gap*it.depth),
      radius: (top: 3pt),
      stroke: (rest: 0.5pt + color, top: 1.5pt + color, bottom: none),
    )
  },
  leaf: it => {
    box(
      $it$,
      inset: (x: 1pt),
      outset: (x: -1pt),
      stroke: (bottom: 1pt + yellow.transparentize(35%)),
    )
  })
  pad(out, top: gap*max-depth)
}

#let tree(tree, grow: 2.5em, spread: 1.5em, stroke: black) = context {
  set curve(stroke: stroke)
  set curve(stroke: (cap: "round"))
  util.walk(tree,
    leaf: it => {
      if it == none { return raw("none", lang: "typc") }
      [#it]
    },
    post: ((head, args, slots)) => {
      let children = args + slots.values()
      let widths = children.map(it => measure(it).width)
      let head = align(center, text(0.9em, strong(raw(head))))
      if children.len() == 0 { return head }

      let head-height = measure(head).height
      let total-width = (widths.sum(default: 0pt) + (children.len() - 1)*spread).to-absolute()
      let gap = grow*0.15

      box(width: calc.max(total-width, measure(head).width), align(center, box(width: total-width, {
        grid(
          columns: children.len(), align: top,
          row-gutter: grow,
          column-gutter: spread,
          grid.cell(colspan: children.len(), head),
          ..args,
          ..slots.values().map(s => pad(top: 0*gap, s)),
        )
        let x = 0pt
        let names = (none,)*args.len() + slots.keys()
        for (width, name) in widths.zip(names) {
          x += width/2
          let shift = 0pt
          if name != none {
            let name = text(0.7em, std.stroke(stroke).paint, raw(name))
            let (width, height) = measure(name)
            shift = height + gap
            place(top, dx: x - width/2, dy: head-height + grow - gap - height, name)
          }
          place(top, curve(
            curve.move((total-width/2, head-height + gap)),
            curve.quad((x, head-height + gap + 0.2*grow), (x, head-height + grow - gap - shift)),
          ))
          x += width/2 + spread
        }
      })))
    }
  )
}

