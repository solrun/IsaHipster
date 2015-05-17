theory prop_68
imports Main
        "../../IsaHipster"
begin
  datatype 'a list = Nil2 | Cons2 "'a" "'a list"
  datatype Nat = Z | S "Nat"
  fun len :: "'a list => Nat" where
  "len (Nil2) = Z"
  | "len (Cons2 y xs) = S (len xs)"
  fun le :: "Nat => Nat => bool" where
  "le (Z) y = True"
  | "le (S z) (Z) = False"
  | "le (S z) (S x2) = le z x2"
  fun equal2 :: "Nat => Nat => bool" where
  "equal2 (Z) (Z) = True"
  | "equal2 (Z) (S z) = False"
  | "equal2 (S x2) (Z) = False"
  | "equal2 (S x2) (S y2) = equal2 x2 y2"
  fun delete :: "Nat => Nat list => Nat list" where
  "delete x (Nil2) = Nil2"
  | "delete x (Cons2 z xs) =
       (if equal2 x z then delete x xs else Cons2 z (delete x xs))"
  (*hipster len le equal2 delete *)

lemma lemma_a [thy_expl]: "equal2 x4 y4 = equal2 y4 x4"
by (hipster_induct_schemes prop_68.equal2.simps)

lemma lemma_aa [thy_expl]: "equal2 x2 x2 = True"
by (hipster_induct_schemes prop_68.equal2.simps)

lemma lemma_ab [thy_expl]: "equal2 x2 (S x2) = False"
by (hipster_induct_schemes prop_68.equal2.simps)

(*hipster le len*)
lemma lemma_ac [thy_expl]: "le x2 x2 = True"
by (hipster_induct_schemes prop_68.le.simps prop_68.len.simps)

lemma lemma_ad [thy_expl]: "le x2 (S x2) = True"
by (hipster_induct_schemes prop_68.le.simps prop_68.len.simps)

lemma lemma_ae [thy_expl]: "le (S x2) x2 = False"
by (hipster_induct_schemes prop_68.le.simps prop_68.len.simps)

hipster delete len

  theorem x0 :
    "le (len (delete n xs)) (len xs)"
    by (tactic {* Subgoal.FOCUS_PARAMS (K (Tactic_Data.hard_tac @{context})) @{context} 1 *})
end
