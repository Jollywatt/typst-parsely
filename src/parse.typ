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

#let parse(it, grammar) = {

  let parse-expr(it, min-prec) = {
    assert(type(it) in (array, content))

    let tokens = as-array(it)
    tokens = flatten-sequence(tokens)
    // tokens = squeeze-space(tokens)


    let parse-op(tokens, ctx: (:)) = {

      // test whether tokens possibly begin with given operator
      let match-op(spec, tokens) = {
        let kind = spec.keys().first()
        let pattern = as-array(unwrap(spec.values().first()))

        // disallow leading with infix/postfix
        if ctx.at("left", default: none) == none {
          if kind in ("infix", "postfix") { return false }
        }

        let n-ahead = pattern.len()
        if n-ahead > tokens.len() { return false }
        let slice = tokens.slice(0, n-ahead)

        let m = match-sequence(pattern, tokens, match: match)
        if m == false { return false }
        let (slots, tokens) = m
        return (slots, tokens)
      }

      // find all possible operators matching leading tokens
      let matching-ops = ()
      for (name, spec) in grammar {
        let m = match-op(spec, tokens)
        if m == false { continue }
        let (m, tokens) = m
        let op = (
          kind: spec.keys().first(),
          name: name,
          ..if "prec" in spec { (prec: spec.prec) },
          slots: m,
        )
        matching-ops.push((op, tokens))
      }

      // chose one operator
      let (op, tokens) = matching-ops.at(0, default: (none, tokens))

      // for (name, spec) in grammar {
      //   break
      // }

      
      // if no matches, interpret tokens as simple expressions
      if op == none {
        while util.is-space(tokens.first()) {
          tokens = tokens.slice(1)
          if tokens.len() == 0 { return (none, ()) }
        }
        let it = tokens.first()

        // recurse into content
        if type(it) == content {
          let kind = repr(it.func())
          if kind not in ("symbol", "text") {
            tokens = tokens.slice(1)
            op = (
              name: "content",
              kind: "expr",
              slots: (func: it.func(), fields: it.fields()),
            )
          }
        }
      }

      if op != none {
        for (key, slot) in op.slots {
          // panic(slot.func())
          if type(slot) != content { continue }
          let (tree, rest) = parse-expr(slot, 0)
          if rest.len() != 0 { return (none, tokens) }
          op.slots.at(key) = tree
          
        }
      }


      (op, tokens)
    }


    let left = none
    
    if tokens.len() == 0 { return (left, tokens) }


    let (op, tokens) = parse-op(tokens, ctx: (left: left))

    if op == none {
      if tokens.len() == 0 { return (none, ()) }
      while util.is-space(tokens.first()) {
        tokens = tokens.slice(1)
      }
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
      let (op, subtokens) = parse-op(tokens, ctx: (left: left))
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
  
  parse-expr(it.body, 0)
}


