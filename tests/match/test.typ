#import "/src/match.typ": *

#assert.eq(match("A", "A"), (:))
#assert.eq(match("A", "B"), false)
#assert.eq(match(wild("x"), "A"), (x: "A"))
#assert.eq(match($A$, $A$), (:))
#assert.eq(match($A B$, $A B$), (:))
#assert.eq(match($wild("x") B$, $A B$), (x: $A$.body))
#assert.eq(match($wild("x") wild("y")$, $A B$), (x: $A$.body, y: $B$.body))
#assert.eq(match($wild("x") wild("x")$, $A B$), false)
#assert.eq(match($wild("x") wild("x")$, $A A$), (x: $A$.body))

#assert.eq(match($a + wild("x")$, $a + (b + c)$), (x: $(b + c)$.body))
#assert.eq(match($a + (b wild("op") c)$, $a + (b + c)$), (op: $+$.body))
#assert.eq(match($(dif wild("x"))/2$, $frac(dif x, 2)$), (x: $x$.body))
#assert.eq(match($wild("x")^i_j$, $a_j^i$), (x: $a$.body))
#assert.eq(match($sum_(wild("var") = wild("start"))^wild("stop")$, $sum_(k = 1)^n$), (var: $k$.body, start: $1$.body, stop: $n$.body))

#assert.eq(match($[wilds("seq")]$, $[1, 2, 3]$), (seq: $1, 2, 3$.body))
#assert.eq(match($[wilds("left"), wilds("right")]$, $[a b c, x y z]$), (left: $a b c$.body, right: $x y z$.body))

#assert.eq(match($a+b$, $a + b$), (:))
#assert.eq(match($a + b$, $a+b$), (:))


// whitespace sensitive matching

#assert.eq(match($a tight + tight b$, $a+b$), (:))
#assert.eq(match($a tight + b$, $a+ b$), (:))
#assert.eq(match($a tight + b$, $a +b$), false)

#assert.eq(match($wild("fn") tight (wilds("args"))$, $f(x)$), (fn: $f$.body, args: $x$.body))
#assert.eq(match($wild("fn") tight (wilds("args"))$, $f (x)$), false)

#assert.eq(match($1loose.$, $1.$), false)
#assert.eq(match($1 loose .$, $1.$), false)
#assert.eq(match($1loose.$, $1 .$), (:))
#assert.eq(match($1 loose .$, $1 .$), (:))

#assert.eq(match($wild("a") loose wild("b")$, $n!$), false)
#assert.eq(match($wild("a") loose wild("b")$, $n !$), (a: $n$.body, b: $!$.body))

