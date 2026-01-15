#import "/src/match.typ": *

#assert.eq(substitute-slots($1 + slot("a")$, (a: $2$.body)), $1 + 2$)
