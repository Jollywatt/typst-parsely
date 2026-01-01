
#let parse(text, grammar) = {
  let parse-op(tokens) = {
    for (name, spec) in grammar {
      let pattern = spec.values().first()

      if type(pattern) == str {
        pattern = pattern.split()
        let n = pattern.len()
        if tokens.len() < n { continue }
        if tokens.slice(0, n) == pattern {
          let op = (
            name: name,
            kind: spec.keys().first(),
            ..spec,
            slots: (:),
          )
          return (op, tokens.slice(n))
        }

      } else if type(pattern) == regex {
        let m = tokens.join(" ")
        m = m.match(pattern)
        if m == none or m.start != 0 { continue }
        let op = (
          name: name,
          kind: spec.keys().first(),
          ..spec,
          slots: spec.slots.zip(m.captures).to-dict(),
        )
        return (op, tokens.slice(m.text.split().len()))
      }
    }
    return (none, tokens)
  }


  let parse-expr(tokens, min-prec) = {
    let left = none
    
    if tokens.len() == 0 { return (left, tokens) }

    // Parse prefix operators or atom

    let (op, tokens) = parse-op(tokens)
    if op == none {
      left = tokens.first()
      tokens = tokens.slice(1)

    } else if op.kind == "prefix" {
      let (right, rest) = parse-expr(tokens, op.prec)
      left = (op: op.name, ..op.slots, right: right)
      tokens = rest
    } else if op.kind == "expr" {
      left = (op: op.name, ..op.slots)
    }
    
    // Parse infix and postfix operators
    while tokens.len() > 0 {
      let (op, subtokens) = parse-op(tokens)
      if op == none { break }
      
      if op.kind == "postfix" {
        if op.prec < min-prec { break }
        left = (op: op.name, left: left)
        tokens = subtokens

      } else if op.kind == "infix" {
        if op.prec < min-prec { break }
        let (right, rest) = parse-expr(subtokens, op.prec)
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
  summation: (prefix: regex("sum (\\S+)"), slots: ("range",), prec: 2),
  commutator: (expr: regex("\\[ (\\S+) , (\\S+) \\]"), slots: ("left", "right"), prec: 10)
)

#let expr = "|- [ a , b ] * a + h + sum 10 k!"
// #let expr = "k * z + 1 ."
#raw(expr)

#parse(expr, grammar)

#import "utils.typ"

#utils.post-walk(parse(expr, grammar), it => {
  let (op, ..rest) = it
  op + "(" + rest.values().join(", ") + ")"
})