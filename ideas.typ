#set page(width: 10cm, height: auto)

#let display-node(it) = {
  if it.kind == "seq" { it.children.join() }
  else if it.kind == "unary" { $it.op it.arg $ }
  else if it.kind == "op" { $it.lhs it.op it.rhs $ }
  else if it.kind == "=" { $it.lhs = it.rhs$ }
  else if it.kind == "+" { $it.lhs + it.rhs $ }
  else if it.kind == "/" { $it.lhs slash it.rhs $ }
  else if it.kind == "frac" { math.frac(it.num, it.denom) }
  else if it.kind == "-" {
    if it.args.len() == 1 { $-it.args.first()$ }
    else { it.args.join($-$) }
  } else if it.kind == "pow" { $it.base^it.exp$ }
  else if it.kind == "symbol" { $italic(it.text)$ }
  else [#it]
}

#let is-expr(it) = type(it) == dictionary and "kind" in it

#let post-walk(it, fn) = {
  if not is-expr(it) { return it }
  let f(it) = post-walk(it, fn)
  fn(it.pairs().map(((k, v)) => {
    if is-expr(v) { (k, f(v)) }
    else if type(v) == array {
      (k, v.map(f))
    }
    else { (k, v) }
  }).to-dict())
}



I want to be able to parse this equation:
#let eq = $
  a = (b^2 + c)/3
$
...which is represented in Typst by the following data structure:
```typc
equation(
  block: true,
  body: sequence(
    [a],
    [ ],
    [=],
    [ ],
    frac(
      num: sequence(attach(base: [b], t: [2]), [ ], [+], [ ], [c]),
      denom: [3],
    ),
  ),
)
```
...into an expression tree of the form:
#let expr = (
  kind: "=",
  lhs: $a$,
  rhs: (
    kind: "frac",
    num: (
      kind: "+",
      args: ((kind: "pow", base: $b$, exp: 2), $c$)
    ),
    denom: [3]
  ),
)
Which can be rendered back into the original form with:
// #$ #post-walk(expr, display-node) $


#let parse-equation(eq) = {
  if eq.func() != math.equation { return eq }
  
  let body = eq.body
  
  // Get children from sequence
  let tokens = if repr(body.func()) == "sequence" {
    body.children
  } else {
    (body,)
  }
  
  // Helper to check if content is whitespace
  let is-space(it) = {
    repr(it.func()) == "space"
  }
  
  // Helper to check if content is an operator
  let is-operator(it) = {
    if type(it) != content { return false }
    if not it.has("text") { return false }
    it.text in ("=", "+", "−", "-", "×", "÷", "/", "·", "*")
  }
  
  // Get operator precedence (higher = binds tighter)
  let precedence(op) = {
    if op in ("=",) { 1 }
    else if op in ("+", "−", "-") { 2 }
    else if op in ("×", "÷", "/", "·", "*") { 3 }
    else { 0 }
  }

  
  // Parse a single node (handles frac, attach, etc.)
  let parse-node(ctx, it) = {
    if type(it) == content {
      let func-repr = repr(it.func())
      
      if func-repr == "frac" {
        // Parse numerator and denominator
        let num = if repr(it.num.func()) == "sequence" {
          (ctx.parse-sequence)(ctx, it.num.children)
        } else {
          (ctx.parse-node)(ctx, it.num)
        }
        
        let denom = if repr(it.denom.func()) == "sequence" {
          (ctx.parse-sequence)(ctx, it.denom.children)
        } else {
          (ctx.parse-node)(ctx, it.denom)
        }
        
        (kind: "frac", num: num, denom: denom)
      } else if func-repr == "attach" {
        // Handle superscripts (powers)
        let base = (ctx.parse-node)(ctx, it.base)
        if it.has("t") {
          (kind: "pow", base: base, exp: (ctx.parse-node)(ctx, it.t))
        } else if it.has("b") {
          (kind: "subscript", base: base, sub: (ctx.parse-node)(ctx, it.b))
        } else {
          base
        }
      } else if func-repr == "sequence" {
        (ctx.parse-sequence)(ctx, it.children)
      } else if func-repr == "symbol" {
        (kind: "symbol", text: it.text)
      } else {
        // Simple content (variable, number, etc.)
        it
      }
    } else {
      it
    }
  }
  
  // Parse a sequence into an expression tree
  let parse-sequence(ctx, tokens) = {
    // Filter out whitespace
    tokens = tokens.filter(x => not is-space(x))
    
    // Parse expression using precedence climbing
    let parse-expr(tokens, min-prec: 0) = {
      if tokens.len() == 0 { return (none, tokens) }
      
      // Get left operand
      let (lhs, rest) = {
        let first = tokens.first()
        if is-operator(first) {
          // Unary operator
          let (operand, r) = parse-expr(tokens.slice(1), min-prec: 3)
          ((kind: "unary", op: first.text, arg: operand), r)
        } else {
          // Process the operand (could be frac, attach, etc.)
          let parsed = (ctx.parse-node)(ctx, first)
          (parsed, tokens.slice(1))
        }
      }
      
      // Parse binary operators
      let result = lhs
      let remaining = rest
      
      while remaining.len() > 0 {
        let next = remaining.first()
        if not is-operator(next) { break }
        
        let prec = precedence(next.text)
        if prec < min-prec { break }
        
        // Consume operator
        let op = next.text
        remaining = remaining.slice(1)
        
        // Parse right operand with higher precedence
        let (rhs, r) = parse-expr(remaining, min-prec: prec + 1)
        remaining = r
        
        // Build binary node
        result = (kind: "op", op: op, lhs: result, rhs: rhs)
      }
      
      (result, remaining)
    }

    let tree = (kind: "seq", children: ())

    while true {
      let (subtree, remaining) = parse-expr(tokens)
      tree.children.push(subtree)
      if remaining.len() == 0 { break }
      tokens = remaining
    }
    
    if tree.children.len() == 1 { tree = tree.children.first() }

    tree
  }
  
  // Store functions in context
  let ctx = (
    "parse-node": parse-node,
    "parse-sequence": parse-sequence,
  )
  parse-sequence(ctx, tokens)
}


#let eq = $[A, V]$
#let expr = parse-equation(eq)

$ #rect(eq) equiv #rect(post-walk(expr, display-node)) $

#expr

#raw(repr(eq.body))