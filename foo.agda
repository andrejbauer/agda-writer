

module Foo where
  data bool : Set where
    false : bool
    true : bool

  f : bool → bool → bool
  f p q = p
  g : bool → bool
  g x = x

  id : bool → bool
  id x = ?

  baz : bool → bool
  baz x = ?