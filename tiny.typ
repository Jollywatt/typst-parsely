
#let parse(text, grammar) = {
  let ops = (:)
  for (name, def) in grammar {
    if "prefix" in def { ops.insert(def.prefix, (type: "prefix", name: name, prec: def.prec)) }
    if "infix" in def { ops.insert(def.infix, (type: "infix", name: name, prec: def.prec)) }
    if "postfix" in def { ops.insert(def.postfix, (type: "postfix", name: name, prec: def.prec)) }
  }
  

  let parse-expr(tokens, min-prec) = {
    let left = none
    
    if tokens.len() == 0 { return (left, tokens) }

    // Parse prefix operators or atom
    if tokens.first() in ops and ops.at(tokens.first()).type == "prefix" {
      let op = ops.at(tokens.first())
      let (right, tokens) = parse-expr(tokens.slice(1), op.prec + 1)
      left = (op: op.name, right: right)
    } else {
      left = tokens.first()
      tokens = tokens.slice(1)
    }
    
    // Parse infix and postfix operators
    while tokens.len() > 0 and tokens.first() in ops {
      let op = ops.at(tokens.first())
      
      if op.type == "postfix" {
        if op.prec < min-prec { break }
        tokens = tokens.slice(1)
        left = (op: op.name, left: left)
      } else if op.type == "infix" {
        if op.prec < min-prec { break }
        let (right, rest) = parse-expr(tokens.slice(1), op.prec + 1)
        left = (op: op.name, left: left, right: right)
        tokens = rest
      } else {
        break
      }
    }
    
    (left, tokens)
  }
  
  parse-expr(text.split(regex("\s+")).filter(t => t != ""), 0).first()
}

#set page(width: auto, height: auto)


#let grammar = (
  add: (infix: "+", prec: 1),
  mul: (infix: "*", prec: 2),
  integral: (prefix: "int", prec: 2),
  qed: (postfix: ".", prec: 0),
  assert: (prefix: "|-", prec: 0),
)

#let expr = "|- a + h"
#raw(expr)

#parse(expr, grammar)

#import "utils.typ"

#utils.post-walk(parse(expr, grammar), it => {
  let (op, ..rest) = it
  op + "(" + rest.values().join(", ") + ")"
})