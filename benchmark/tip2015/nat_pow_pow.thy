theory nat_pow_pow
imports Main
        "$HIPSTER_HOME/IsaHipster"
begin

datatype Nat = Z | S "Nat"

fun plus :: "Nat => Nat => Nat" where
"plus (Z) y = y"
| "plus (S n) y = S (plus n y)"

fun mult :: "Nat => Nat => Nat" where
"mult (Z) y = Z"
| "mult (S n) y = plus y (mult n y)"

fun pow :: "Nat => Nat => Nat" where
"pow x (Z) = S Z"
| "pow x (S m) = mult x (pow x m)"

(*hipster plus mult pow *)

theorem x0 :
  "!! (x :: Nat) (y :: Nat) (z :: Nat) .
     (pow x (mult y z)) = (pow (pow x y) z)"
  by (tactic {* Subgoal.FOCUS_PARAMS (K (Tactic_Data.hard_tac @{context})) @{context} 1 *})

end
