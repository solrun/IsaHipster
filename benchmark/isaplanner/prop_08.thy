theory A
imports Main
begin
  datatype Nat = Z | S "Nat"
  fun plus :: "Nat => Nat => Nat" where
  "plus (Z) y = y"
  | "plus (S z) y = S (plus z y)"
  fun minus :: "Nat => Nat => Nat" where
  "minus (Z) y = Z"
  | "minus (S z) (Z) = S z"
  | "minus (S z) (S x2) = minus z x2"
  theorem x0 :
    "!! (k :: Nat) (m :: Nat) (n :: Nat) .
       (minus (plus k m) (plus k n)) = (minus m n)"
    oops
end
