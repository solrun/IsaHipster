theory sort_NMSortTDSorts
imports Main
        "$HIPSTER_HOME/IsaHipster"
begin

datatype 'a list = Nil2 | Cons2 "'a" "'a list"

datatype Nat = Z | S "Nat"

fun take :: "Nat => 'a list => 'a list" where
"take (Z) y = Nil2"
| "take (S z) (Nil2) = Nil2"
| "take (S z) (Cons2 x2 x3) = Cons2 x2 (take z x3)"

fun lmerge :: "int list => int list => int list" where
"lmerge (Nil2) y = y"
| "lmerge (Cons2 z x2) (Nil2) = Cons2 z x2"
| "lmerge (Cons2 z x2) (Cons2 x3 x4) =
     (if z <= x3 then Cons2 z (lmerge x2 (Cons2 x3 x4)) else
        Cons2 x3 (lmerge (Cons2 z x2) x4))"

fun length :: "'t list => Nat" where
"length (Nil2) = Z"
| "length (Cons2 y xs) = S (length xs)"

fun half :: "Nat => Nat" where
"half (Z) = Z"
| "half (S (Z)) = Z"
| "half (S (S n)) = S (half n)"

fun drop :: "Nat => 'a list => 'a list" where
"drop (Z) y = y"
| "drop (S z) (Nil2) = Nil2"
| "drop (S z) (Cons2 x2 x3) = drop z x3"

fun nmsorttd :: "int list => int list" where
"nmsorttd (Nil2) = Nil2"
| "nmsorttd (Cons2 y (Nil2)) = Cons2 y (Nil2)"
| "nmsorttd (Cons2 y (Cons2 x2 x3)) =
     lmerge
       (nmsorttd
          (take
             (half (length (Cons2 y (Cons2 x2 x3)))) (Cons2 y (Cons2 x2 x3))))
       (nmsorttd
          (drop
             (half (length (Cons2 y (Cons2 x2 x3)))) (Cons2 y (Cons2 x2 x3))))"

fun and2 :: "bool => bool => bool" where
"and2 True y = y"
| "and2 False y = False"

fun ordered :: "int list => bool" where
"ordered (Nil2) = True"
| "ordered (Cons2 y (Nil2)) = True"
| "ordered (Cons2 y (Cons2 y2 xs)) =
     and2 (y <= y2) (ordered (Cons2 y2 xs))"

(*hipster take lmerge length half drop nmsorttd and2 ordered *)

theorem x0 :
  "!! (x :: int list) . ordered (nmsorttd x)"
  by (tactic {* Subgoal.FOCUS_PARAMS (K (Tactic_Data.hard_tac @{context})) @{context} 1 *})

end
