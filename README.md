# Parsely

_Parse equations with Typst_.

[![Manual](https://img.shields.io/badge/dev-manual.pdf-orange)](https://github.com/Jollywatt/typst-parsely/releases/download/main/manual.pdf)

Tools to parse Typst equations into structured syntax trees using user-specified grammars, supporting prefix/infix/postfix operators, precedence, associativity and recursive pattern matching allowing complex mathematical expressions to be parsed.

```typ
#import "@preview/parsely:{{VERSION}}"
```


Minimal example: from the equation `$A x + b$` obtain the abstract syntax tree
```typ
(head: "add", args: ((head: "mul", args: ($A$, $x$)), $b$))
```
using the main function `parsely.parse(eqn, grammar)` where the  grammar
```typ
#let grammar = (
  add: (infix: $+$, prec: 1, assoc: true),
  mul: (infix: $$, prec: 2, assoc: true),
)
```
defines the syntax of the operators that form the nodes in the tree.


See [the manual](https://github.com/Jollywatt/typst-parsely/releases/download/main/manual.pdf) for documentation and complete usage examples, including:
- drawing expression trees from equations (using [CeTZ](https://cetz-package.github.io/))
- performing engineering calculations with units (using [Pariman](https://github.com/pacaunt/pariman))
- turning equations into functions for plotting (using [Lilaq](https://lilaq.org))