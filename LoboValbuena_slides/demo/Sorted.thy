theory Sorted
imports "$HIPSTER_HOME/IsaHipster"

begin
datatype Nat = 
  Z
  | Succ "Nat"

fun leq :: "Nat => Nat => bool"
where
  "leq Z y = True"
| "leq x Z = False"
| "leq (Succ x) (Succ y) = leq x y"

hipster leq
lemma lemma_a [thy_expl]: "leq x2 x2 = True"
by (hipster_induct_schemes Sorted.leq.simps)

lemma lemma_aa [thy_expl]: "leq x2 (Succ x2) = True"
by (hipster_induct_schemes Sorted.leq.simps)

lemma lemma_ab [thy_expl]: "leq (Succ x2) x2 = False"
by (hipster_induct_schemes Sorted.leq.simps)

fun sorted :: "Nat list => bool"
where
  "sorted [] = True"
| "sorted [x] = True"
| "sorted (x # y # xs) = ((leq x y) \<and> (sorted (y#xs)))"

fun ins :: " Nat => Nat list => Nat list"
where
 "ins x [] = [x]"
|"ins x (y#ys) = (if (leq x y) then (x#y#ys) else (y#(ins x ys)))"

(*hipster sorted ins*)
lemma lemma_ac [thy_expl]: "Sorted.sorted (ins Z x3) = Sorted.sorted x3"
by (hipster_induct_schemes Sorted.sorted.simps Sorted.ins.simps)

lemma unknown []: "Sorted.sorted (ins x y) = Sorted.sorted y"
oops

lemma unknown' []: "ins Z (ins x y) = ins x (ins Z y)"
oops
lemma unknown []: "ins x (ins y z) = ins y (ins x z)"
oops

fun isort :: "Nat list => Nat list"
where
  "isort [] = []"
| "isort (x#xs) = ins x (isort xs)"

(*hipster_cond sorted ins isort leq*)
lemma lemma_ad [thy_expl]: "ins Z (isort x2) = isort (ins Z x2)"
by (hipster_induct_schemes Sorted.sorted.simps Sorted.ins.simps Sorted.isort.simps Sorted.leq.simps)

lemma lemma_ae [thy_expl]: "Sorted.sorted x3 \<Longrightarrow> isort x3 = x3"
by (hipster_induct_schemes Sorted.sorted.simps Sorted.ins.simps Sorted.isort.simps Sorted.leq.simps)

lemma unknown [thy_expl]: "isort (ins x y) = ins x (isort y)"
oops

lemma unknown [thy_expl]: "Sorted.sorted (isort x) = True"
oops

lemma unknown [thy_expl]: "isort (isort x) = isort x"
oops

lemma unknown [thy_expl]: "ins Z (ins x y) = ins x (ins Z y)"
oops

lemma unknown [thy_expl]: "Sorted.sorted y \<Longrightarrow> Sorted.sorted (ins x y) = True"
oops

lemma unknown [thy_expl]: "Sorted.sorted y \<Longrightarrow> isort (ins x y) = ins x y"
oops

fun sorted2 :: "nat list \<Rightarrow> bool" where
  "sorted2 []                   = True"
| "sorted2 ( _ # Nil)          = True"
| "sorted2 ( r # (Cons t ts))  = ( r \<le> t \<and> sorted2 ( t # ts))"

fun insert :: "nat \<Rightarrow> nat list \<Rightarrow> nat list" where
  "insert r Nil         = Cons r Nil"
| "insert r (Cons t ts) = (if r \<le> t then Cons r (Cons t ts) else (Cons t (insert r ts)))"


fun isort2 :: "nat list \<Rightarrow> nat list" where
  "isort2 [] = []"
| "isort2 (t# ts) = insert t (isort2 ts)"


lemma lemm_ac [thy_expl]: "Sorted.sorted2 (insert 0 x3) = Sorted.sorted2 x3"
by (metis insert.simps(1) insert.simps(2) isort2.cases le0 sorted2.elims(3) sorted2.simps(2) sorted2.simps(3))

lemma unknon []: "Sorted.sorted2 (insert x y) = Sorted.sorted2 y"
by (hipster_induct_schemes Sorted.sorted2.simps Sorted.insert.simps)


lemma unknon' []: "insert 0 (insert x y) = insert x (insert 0 y)"
by (hipster_induct_simp_metis Sorted.sorted2.simps Sorted.insert.simps)

lemma unknonb [thy_expl]: "insert x (insert y z) = insert y (insert x z)"
by (hipster_induct_simp_metis Sorted.sorted2.simps Sorted.insert.simps)

lemma unknonc [thy_expl]: "insert 0 (isort2 x2) = isort2 (insert 0 x2)"
by (hipster_induct_simp_metis  Sorted.insert.simps Sorted.isort2.simps)
(*
lemma unknond [thy_expl]: "Sorted.sorted2 x3 \<Longrightarrow> isort2 x3 = x3"
by (hipster_induct_schemes Sorted.sorted2.simps Sorted.insert.simps Sorted.isort2.simps)
*)
lemma unknone [thy_expl]: "isort2 (insert x y) = insert x (isort2 y)"
by (hipster_induct_simp_metis Sorted.sorted2.simps Sorted.insert.simps Sorted.isort2.simps)


lemma unknong [thy_expl]: "isort2 (isort2 x) = isort2 x"
by (hipster_induct_simp_metis Sorted.sorted2.simps Sorted.insert.simps Sorted.isort2.simps)


setup{* Hip_Tac_Ops.set_metis_to @{context} 1000 *}
setup{* Hip_Tac_Ops.toggle_full_types @{context}  *}

lemma unknoni []: "Sorted.sorted2 y \<Longrightarrow> Sorted.sorted2 (insert x y) = True"
by (hipster_induct_schemes Sorted.sorted2.simps Sorted.insert.simps Sorted.isort2.simps)

lemma unknonf [thy_expl]: "Sorted.sorted2 (isort2 x) = True"
by (hipster_induct_simp_metis unknon Sorted.sorted2.simps Sorted.insert.simps Sorted.isort2.simps)

lemma unknonj [thy_expl]: "Sorted.sorted2 y \<Longrightarrow> isort2 (insert x y) = insert x y"
by (hipster_induct_schemes Sorted.sorted2.simps Sorted.insert.simps Sorted.isort2.simps)




end
