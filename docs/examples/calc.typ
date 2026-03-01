#import "../../src/exports.typ" as parsely
#import "@preview/lilaq:0.5.0" as lq

#show "Lilaq": link.with("https://lilaq.org")

= Plotting equations

This example#context if query(<venn>).len() > 0 [, similar to @venn,
] shows how equations may be converted into anonymous functions which can be evaluated by passing a dictionary of values of the equation's unknowns.
Plots are produced with the beautiful Lilaq package.

#let eqns = (
  $ 1/(1 + e^(-2x)) $,
  $ sin(5x)/(5x) $,
)

For example, #eqns.map(math.equation.with(block: false)).join(last: [ and ])[, ] are typed once yet displayed and plotted automatically.


#let constants = (
  "e": calc.exp(1),
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

#let eqn-to-func(eqn) = {
  let (tree, rest) = parsely.parse(eqn, parsely.common.arithmetic)

  parsely.walk(
    tree,
    leaf: it => {
      let x = parsely.stringify(it)
      if x in constants { return s => constants.at(x) }
      if x.match(regex("^[\d\.]+$")) != none {
        // looks like a number
        return s => eval(x)
      }
      s => s.at(x)
    },
    post: ((head, args, slots)) => {
      if head == "group" { slots.expr }
      else if head == "number" { s => eval(slots.it.text) }
      else if head == "add" { s => args.map(a => a(s)).sum() }
      else if head == "neg" { s => -args.first()(s) }
      else if head == "mul" { s => args.map(a => a(s)).product() }
      else if head == "pow" { s => calc.pow((slots.base)(s), (slots.exp)(s)) }
      else if head == "frac" { s => args.first()(s)/args.last()(s) }
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

#let x = lq.linspace(-5, 5, num: 200)
#let plot = lq.diagram(
  xlabel: $x$, 
  ylabel: $f(x)$,
  legend: (position: top + left),
  width: 100%,
  ..eqns.map(eqn => {
    let fn = eqn-to-func(eqn)
    lq.plot(
      x, x => fn((x: x)), 
      mark: none,
      label: eqn
    )
  })
)

#figure(plot)

To convert to an anonymous function from the syntax tree, leaf nodes like $4.5$, $pi$ or $cos$ are first mapped to anonymous functions returning a value like `s => eval("4.5")`, `s => calc.pi` or `s => calc.cos` (yes, in the last case a function is returned as the value).

Then, nodes are also converted into anonymous functions which accept a scope dictionary and return a value.
For example, $x + y$ becomes `s => args.first()(s) + args.last()(s)`
where `args.first()` is `s => s.at("x")`.
Function application $cos(x)$ becomes `s => (slots.op)(s)((slots.args)(s))`, where the value of `slots.op(s)` is the actual function `calc.cos`.
If this is hard to follow, don't worry; look at the code.
