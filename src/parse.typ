#import "match.typ": *
#import "util.typ": *


// parse tokens as one of the operators defined in the grammar
// returning a tuple of the operator and the remaining tokens.
// if no operator was matched, the operator is `none`
#let parse-op(tokens, grammar, ctx: (:)) = {

  // test whether tokens possibly begin with given operator
  // or return false if no match
  let match-op(spec, tokens) = {
    let kind = spec.keys().first()
    let pattern = as-array(unwrap(spec.remove(kind)))

    // disallow leading with infix/postfix
    if ctx.at("left", default: none) == none {
      if kind in ("infix", "postfix") { return false }
    }

    let m = match-sequence(pattern, tokens, match: match)
    if m == false { return false }
    let (slots, tokens) = m
    let op = (kind: kind, slots: slots)
    
    if kind in ("prefix", "infix", "postfix") {
      op.insert("prec", spec.remove("prec", default: 0))
      if kind == "infix" {
        op.insert("assoc", spec.remove("assoc", default: alignment.left))
      }
    }

    if "rewrite" in spec {
      op.insert("rewrite", spec.remove("rewrite"))
    }

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
    break // if selecting first break early
    // may extend this in future
  }

  // choose one operator
  let old-tokens = tokens
  let (op, tokens) = matching-ops.at(0, default: (none, tokens))

  
  // if no operators match, interpret tokens as literal
  if op == none {
    // drop whitespace
    while true {
      if tokens.len() == 0 { return (none, none) }
      if util.is-space(tokens.first()) {
        tokens = tokens.slice(1)
      } else { break }
    }

    let it = tokens.first()
  }

  (op, tokens)
}


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
// summation variable and limits. The entire pattern is
// treated as one "token" in and subsequent tokens are
// consumed as arguments to a prefix operator.
#let parse(it, grammar, min-prec: -float.inf) = {

  let tokens = flatten-sequence(as-array(unwrap(it)))
  if tokens.len() == 0 { return (tree: none, rest: none) }

  let make-node(op, args: ()) = {
    let node = (head: op.name, args: args, slots: op.slots)
    let rewrite-rule = op.at("rewrite", default: it => it)
    node = rewrite-rule(node)
    // try to parse pattern slots

    for (key, slot) in node.slots {
      if type(slot) != content { continue }

      // // danger of infinite recursion
      // // do not parse a slot's content if it is the same as the content that
      // // gave rise to this slot in the first place
      // let m = match-sequence(slot, old-tokens, match: match)
      // // panic(old-tokens, slot, m)
      // if m != false { continue }

      let (tree, rest) = parse(slot, grammar, min-prec: -float.inf)
      // if the whole slot doesn't parse to the end, keep unparsed
      if rest != none { continue }
      node.slots.at(key) = tree
    }

    // sometimes slots are stored as positional arguments
    // e.g., for some content functions
    if "args" in node {
      for (i, arg) in node.args.enumerate() {
        if type(arg) != content { continue }
        let (tree, rest) = parse(arg, grammar, min-prec: -float.inf)
        // if the whole arg doesn't parse to the end, keep unparsed
        if rest != none { continue }
        node.args.at(i) = tree
      }
    }

    node

  }


  let left = none
  let (op, tokens) = parse-op(tokens, grammar, ctx: (left: left))


  if op == none {
    // leading token(s) did not match any operator
    // so we consume as a literal token
    while true {
      if tokens.len() == 0 { return (tree: none, rest: none) }
      (left, ..tokens) = tokens
      if not util.is-space(left) { break }
    }
    let _ = tokens

  } else if op.kind == "match" {
    left = make-node(op, args: ())
  
  // prefix
  } else if op.kind == "prefix" {
    let (tree: right, rest) = parse(tokens, grammar, min-prec: op.prec)
    left = make-node(op, args: (right,))
    tokens = as-array(rest) // consumed op + right
  }



  // infix and postfix
  let i = 0
  while tokens.len() > 0 {
    assert(type(tokens) == array)
    if i > 200 {
      panic("seems to be infinite", tokens)
    }
    i += 1

    let (op, subtokens) = parse-op(tokens, grammar, ctx: (left: left))
    if op == none { break }
    
    if op.kind == "postfix" {
      if op.prec < min-prec { break }
      left = make-node(op, args: (left,))

      tokens = subtokens // consumed op
      continue

    } else if op.kind == "infix" {

      // nothing left for right of infix
      // leave operator unparsed
      if subtokens.len() == 0 { break }

      if op.prec < min-prec { break }
      
      let assoc = op.at("assoc", default: alignment.left)
      if assoc == true {
        // n-ary
        left = make-node(op, args: (left,))
        let abort = false
        while true {
          let (tree: right, rest) = parse(subtokens, grammar, min-prec: op.prec + 1e-3)
          rest = as-array(rest)

          // don't allow rhs of operator to be none
          if right == none { break }

          left.args.push(right)
          tokens = rest // consumed op + right

          // if followed by same operator, absorb
          let (next-op, rest) = parse-op(rest, grammar, ctx: (left: right))
          if next-op == none { break }
          if next-op.name != op.name { break }
          if next-op.prec < min-prec { break }
          subtokens = rest
        }
        if abort { break }
        continue
      } else {
        // binary
        let right-prec = if assoc == alignment.left { op.prec + 1e-3 } else { op.prec }
        let (tree: right, rest) = parse(subtokens, grammar, min-prec: right-prec)
        
        // don't allow rhs of operator to be none
        if right == none { break }

        left = make-node(op, args: (left, right))

        tokens = as-array(rest)
        continue
      }

    } else if op.kind == "match" {
      // encountered two consecutive tokens
      // which are not joined by any operator
      // leave unparsed
      break
    }
    
    panic(op)

  }
  
  return (tree: left, rest: tokens.join())
}
