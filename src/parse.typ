#import "match.typ": *
#import "util.typ": *

// This is a Pratt parser
// which handles prefix, infix and postfix operators
// of variable precedence using recursive descent.
// 
// Tokens may be symbols or entire subexpressions,
// to support the nested structures produced by math mode.
// 
// Multi-token operators are supported and may use
// pattern matching with capture groups.
// For example, $sum_(#var = #lo)^#hi$ may be parsed as a
// prefix operator with "slots" (capture groups) for the
// summation variable and limits.

#let parse(it, grammar, min-prec: -float.inf) = {

  let tokens = flatten-sequence(as-array(unwrap(it)))
  if tokens.len() == 0 { return (none, tokens) }

  // parse tokens as one of the operators defined in the grammar
  // or return false if no match
  let parse-op(tokens, ctx: (:)) = {

    // test whether tokens possibly begin with given operator
    let match-op(spec, tokens) = {
      let (kind, pattern) = spec.pairs().first()
      let pattern = as-array(unwrap(pattern))

      // disallow leading with infix/postfix
      if ctx.at("left", default: none) == none {
        if kind in ("infix", "postfix") { return false }
      }

      let m = match-sequence(pattern, tokens, match: match)
      if m == false { return false }
      let (slots, tokens) = m
      let op = (
        kind: spec.keys().first(),
        ..if "prec" in spec { (prec: spec.prec) },
        ..if kind == "infix" { (assoc: spec.at("assoc", default: alignment.left)) },
        slots: slots,
      )
      return (op, tokens)
    }

    // find all possible operators matching leading tokens
    let matching-ops = ()
    for (name, spec) in grammar {
      let m = match-op(spec, tokens)
      if m == false { continue }
      let (op, tokens) = m
      op.name = name        
      matching-ops.push((op, tokens))
    }

    // choose one operator
    let (op, tokens) = matching-ops.at(0, default: (none, tokens))

    
    // if no operators match, interpret tokens as literal
    if op == none {
      // drop whitespace
      while true {
        if tokens.len() == 0 { return (none, ()) }
        if util.is-space(tokens.first()) {
          tokens = tokens.slice(1)
        } else { break }
      }

      let it = tokens.first()

      // recurse into content
      if type(it) == content and false {
        let kind = repr(it.func())
        if kind not in ("symbol", "text") {
          tokens = tokens.slice(1)
          let named = it.fields()
          let pos = ()
          for n in util.content-positional-args.at(kind) {
            pos.push(named.remove(n))
          }
          op = (
            name: "content",
            kind: "expr",
            args: (it.func(), ..pos),
            slots: named,
          )
        }
      }
    }

    // try to parse pattern slots
    if op != none {
      for (key, slot) in op.slots {
        if type(slot) != content { continue }
        let (tree, rest) = parse(slot, grammar, min-prec: -float.inf)
        // if the whole slot doesn't parse to the end, keep unparsed
        if rest.len() != 0 { continue }
        op.slots.at(key) = tree
        
      }
    }


    (op, tokens)
  }


  let left = none
  let (op, tokens) = parse-op(tokens, ctx: (left: left))

  // consume literal token
  if op == none {
    while true {
      if tokens.len() == 0 { return (none, ()) }
      (left, ..tokens) = tokens
      if not util.is-space(left) { break }
    }
    let _ = tokens

  } else if op.name == "content" {
    // parsing doesn't recurse into content args??
    left = (head: "content", args: op.args, slots: op.slots)

  } else if op.kind == "expr" {
    left = (head: op.name, args: (), slots: op.slots)
  
  // prefix
  } else if op.kind == "prefix" {
    let (right, rest) = parse(tokens, grammar, min-prec: op.prec)
    left = (head: op.name, args: (right,), slots: op.slots)
    tokens = rest // consumed op + right
  }



  // infix and postfix
  while tokens.len() > 0 {
    let (op, subtokens) = parse-op(tokens, ctx: (left: left))
    if op == none { break }
    
    if op.kind == "postfix" {
      if op.prec < min-prec { break }
      left = (head: op.name, args: (left,), slots: (:))

      tokens = subtokens // consumed op
      continue

    } else if op.kind == "infix" {
      if op.prec < min-prec { break }
      
      let assoc = op.at("assoc", default: alignment.left)
      if assoc == true {
        // n-ary
        left = (head: op.name, args: (left,), slots: (:))
        while true {
          let (right, rest) = parse(subtokens, grammar, min-prec: op.prec + 1)
          tokens = rest // consumed op + right

          // is this better to include??
          // controls what happens with e.g., $1 + 2 + $
          // if right == none { break }

          left.args.push(right)

          // if followed by same operator, absorb
          let (next-op, rest) = parse-op(rest, ctx: (left: right))
          if next-op == none { break }
          if next-op.name != op.name { break }
          if next-op.prec < min-prec { break }
          subtokens = rest
        }
        continue
      } else {
        // binary
        let right-prec = if assoc == alignment.left { op.prec + 1 } else { op.prec }
        let (right, rest) = parse(subtokens, grammar, min-prec: right-prec)
        left = (head: op.name, args: (left, right), slots: (:))

        tokens = rest
        continue
      }

    } else if op.kind == "expr" {
      // encountered two consecutive tokens
      // which are not joined by any operator
      // leave unparsed
      break
    }
    
    panic(op)

  }
  
  return (left, tokens)
}


