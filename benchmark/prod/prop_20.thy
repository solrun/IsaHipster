theory prop_20
imports Main
        "$HIPSTER_HOME/IsaHipster"
begin
  datatype 'a list = Nil2 | Cons2 "'a" "'a list"
  datatype Nat = Z | S "Nat"
  fun length :: "'a list => Nat" where
  "length (Nil2) = Z"
  | "length (Cons2 y xs) = S (length xs)"
  fun even :: "Nat => bool" where
  "even (Z) = True"
  | "even (S (Z)) = False"
  | "even (S (S z)) = even z"
  fun append :: "'a list => 'a list => 'a list" where
  "append (Nil2) y = y"
  | "append (Cons2 z xs) y = Cons2 z (append xs y)"
  (*hipster length even append *)

fun yum ::  "'a list => 'a list => 'a list" where
  "yum Nil2 Nil2 = Nil2"
| "yum (Cons2 x xs) Nil2 = yum xs Nil2"
| "yum Nil2 (Cons2 y ys) = yum Nil2 ys"
| "yum (Cons2 x xs) (Cons2 y ys) = yum xs ys"

thm yum.induct
lemma xx: "even x = even y"
apply(induction x)
apply(induction y)
(*hipster length even append*)
lemma lemma_a [thy_expl]: "append x2 Nil2 = x2"
by (hipster_induct_schemes length.simps even.simps append.simps)

lemma lemma_aa [thy_expl]: "append (append x1 y1) z1 = append x1 (append y1 z1)"
by (hipster_induct_schemes length.simps even.simps append.simps)

lemma unknown [thy_expl]: "length (append x y) = length (append y x)"
oops

lemma ax2[thy_expl]: "length (append y (Cons2 ya xs)) = S (length (append y xs))"
by(hipster_induct_schemes)

  theorem x0 :
    "even (length (append x x))"
    by (hipster_induct_schemes length.simps even.simps append.simps list.exhaust Nat.exhaust)

    by (tactic {* Subgoal.FOCUS_PARAMS (K (Tactic_Data.hard_tac @{context})) @{context} 1 *})
end
