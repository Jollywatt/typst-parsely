#import "/src/match.typ": *

#assert.eq(match("A", "A"), (:))
#assert.eq(match("A", "B"), false)
#assert.eq(match(slot("x"), "A"), (x: "A"))
#assert.eq(match($A$, $A$), (:))
#assert.eq(match($A B$, $A B$), (:))
#assert.eq(match($slot("x") B$, $A B$), (x: $A$.body))
#assert.eq(match($slot("x") slot("y")$, $A B$), (x: $A$.body, y: $B$.body))
#assert.eq(match($slot("x") slot("x")$, $A B$), false)
#assert.eq(match($slot("x") slot("x")$, $A A$), (x: $A$.body))

#assert.eq(match($a + slot("x")$, $a + (b + c)$), (x: $(b + c)$.body))
#assert.eq(match($a + (b slot("op") c)$, $a + (b + c)$), (op: $+$.body))
#assert.eq(match($(dif slot("x"))/2$, $frac(dif x, 2)$), (x: $x$.body))
#assert.eq(match($slot("x")^i_j$, $a_j^i$), (x: $a$.body))
#assert.eq(match($sum_(slot("var") = slot("start"))^slot("stop")$, $sum_(k = 1)^n$), (var: $k$.body, start: $1$.body, stop: $n$.body))

#assert.eq(match($[slots("seq")]$, $[1, 2, 3]$), (seq: $1, 2, 3$.body))
#assert.eq(match($[slots("left"), slots("right")]$, $[a b c, x y z]$), (left: $a b c$.body, right: $x y z$.body))

#assert.eq(match($a+b$, $a + b$), (:))
#assert.eq(match($a + b$, $a+b$), (:))

#assert.eq(match($a + b$, $a + b + c$), (:))


#assert.eq(match($f(slot("arg")).$, $f(x)$), false)
#assert.eq(match($f(slot("arg"))$, $f(x)$), (arg: $x$.body))


// whitespace sensitive matching

#assert.eq(match($a tight + tight b$, $a+b$), (:))
#assert.eq(match($a tight + b$, $a+ b$), (:))
#assert.eq(match($a tight + b$, $a +b$), false)

#assert.eq(match($slot("fn") tight (slots("args"))$, $f(x)$), (fn: $f$.body, args: $x$.body))
#assert.eq(match($slot("fn") tight (slots("args"))$, $f (x)$), false)

#assert.eq(match($1loose.$, $1.$), false)
#assert.eq(match($1 loose .$, $1.$), false)
#assert.eq(match($1loose.$, $1 .$), (:))
#assert.eq(match($1 loose .$, $1 .$), (:))

#assert.eq(match($slot("a") loose slot("b")$, $n!$), false)
#assert.eq(match($slot("a") loose slot("b")$, $n !$), (a: $n$.body, b: $!$.body))

