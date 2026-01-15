#import "util.typ"
#import "match.typ"

#let render(it, grammar) = {
  if it.head == "content" {
    let (fn, ..pos) = it.args
    return fn(..pos, ..it.slots)
  }
  
  let op = grammar.at(it.head)

  if type(op) == function {
    return op(..it.args, ..it.slots)
  }

  let (kind, pattern) = op.pairs().first()
  let op = match.substitute-slots(pattern, it.slots)

  let args = it.args
  
  if kind == "infix" {
    $args.join(op)$
  } else if kind == "postfix" {
    $args.first() op$
  } else if kind == "prefix" {
    $op args.first()$
  } else if kind == "expr" {
    op
  } else {
    panic(op)
  }
}
