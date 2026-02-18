#import "../../src/exports.typ" as parsely
#import "@preview/lilaq:0.5.0" as lq

= Plotting equations



#let eqn-to-func(eqn) = {
  let (tree, rest) = parsely.parse(eqn, parsely.common.arithmetic)

  parsely.walk(
    tree,
    leaf: it => {
      let x = parsely.stringify(it)
      let constants = (
        e: calc.exp(1),
        "π": calc.pi,
        "τ": calc.tau,
        "exp": calc.exp,
        "sin": calc.sin,
        "cos": calc.cos,
        "tan": calc.tan,
        "sinh": calc.sinh,
        "cosh": calc.cosh,
        "tanh": calc.tanh,
        "arcsin": calc.asin,
        "arccos": calc.acos,
        "arctan": calc.atan,
      )
      if x in constants { return s => constants.at(x) }
      if x.match(regex("^[\d\.]+$")) != none {
        // looks like a number
        return s => eval(x)
      }
      s => s.at(x)
    },
    post: ((head, args, slots)) => {
      if head == "group" { slots.expr }
      else if head == "number" {
        s => eval(slots.it.text)
      }
      else if head == "add" { s => args.map(a => a(s)).sum() }
      else if head == "neg" { s => -args.first()(s) }
      else if head == "mul" { s => args.map(a => a(s)).product() }
      else if head == "pow" {
        s => calc.pow((slots.base)(s), (slots.exp)(s))
      }
      else if head == "frac" {
        s => args.first()(s)/args.last()(s)
      }
      else if head == "op-call" {
        s => {
          let fn = (slots.op)(s)
          fn((slots.args)(s))
        }
      }
      else { panic(head) }
    }
  )

}

#let eqn = $ 1/(1 + e^(-x)) $
#let fn = eqn-to-func(eqn)
#let x = lq.linspace(-5, 5, num: 100)
#lq.diagram(
  xlabel: $x$, 
  ylabel: $f(x)$,
  legend: (position: top + left),
  lq.plot(
    x, x => fn((x: x)), 
    mark: none,
    label: eqn
  )
)