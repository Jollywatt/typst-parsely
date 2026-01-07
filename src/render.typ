#import "util.typ"
#import "match.typ"

#let render-node(it, grammar) = {
  if it.head == "content" {
    return util.dict-to-content(it.func, it.fields)
  } 
  
  let op = grammar.at(it.head)

  let (kind, pattern) = op.pairs().first()
  let op = match.substitute-wilds(pattern, it)
  
  if kind == "infix" {
    $it.left op it.right$
  } else if kind == "postfix" {
    $it.left op$
  } else if kind == "prefix" {
    $op it.right$
  } else if kind == "expr" {
    op
  } else {
    panic(op)
  }
}
