#import "match.typ": *
#import "util.typ": *


#let parse(it, grammar) = {

  let parse-expr(tokens, min-prec) = {

    let parse-op(tokens) = {
      for (name, spec) in grammar {
        let pattern = spec.values().first()
        assert(type(pattern) == content and pattern.func() == math.equation)
        pattern = pattern.body

        if repr(pattern.func()) == "sequence" {
          pattern = pattern.children
          pattern = squeeze-space(pattern)
        } else {
          pattern = (pattern,)
        }


        let n-ahead = pattern.len()
        if n-ahead > tokens.len() { continue }
        let slice = tokens.slice(0, n-ahead)

        let m = match(pattern, slice)
        if m == false { continue }

        let slots = m.pairs().map(((slot-name, expr)) => {
          let seq = sequence-children(expr)
          let (tree, rest) = parse-expr(seq, 0)
          if rest.len() > 0 {
            // panic("failed to parse")
            return (slot-name, expr)
          }
          (slot-name, tree)
        }).to-dict()

        let op = (
          kind: spec.keys().first(),
          name: name,
          ..if "prec" in spec { (prec: spec.prec) },
          slots: slots,
        )
        return (op, tokens.slice(n-ahead))
      }

      (none, tokens)
    }


    tokens = squeeze-space(tokens)
    tokens = flatten-sequence(tokens)

    let left = none
    
    if tokens.len() == 0 { return (left, tokens) }


    let (op, tokens) = parse-op(tokens)
    if op == none {
      left = tokens.first()
      tokens = tokens.slice(1)
    } else if op.kind == "expr" {
      left = (head: op.name, ..op.slots)
    
    // prefix
    } else if op.kind == "prefix" {
      let (right, rest) = parse-expr(tokens, op.prec)
      left = (head: op.name, ..op.slots, right: right)
      tokens = rest
    }

    // infix and postfix
    while tokens.len() > 0 {
      let (op, subtokens) = parse-op(tokens)
      if op == none { break }
      
      if op.kind == "postfix" {
        if op.prec < min-prec { break }
        left = (head: op.name, left: left)
        tokens = subtokens

      } else if op.kind == "infix" {
        if op.prec < min-prec { break }
        let (right, rest) = parse-expr(subtokens, op.prec)
        left = (head: op.name, left: left, right: right)
        tokens = rest

      } else {
        break
      }
    }
    
    (left, tokens)
  }
  
  parse-expr(it.body.children, 0)
}


