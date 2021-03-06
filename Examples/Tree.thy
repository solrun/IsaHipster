theory Tree
imports "$HIPSTER_HOME/IsaHipster"

begin

datatype 'a Tree = 
  Leaf 'a 
  | Node "'a Tree""'a Tree"

fun mirror :: "'a Tree => 'a Tree"
where
  "mirror (Leaf x) = Leaf x"
| "mirror (Node l r) = Node (mirror r) (mirror l)"

fun tmap :: "('a => 'b) => 'a Tree => 'b Tree"
where
  "tmap f (Leaf x) = Leaf (f x)"
| "tmap f (Node l r) = Node (tmap f l) (tmap f r)" 


ML{* Hipster_Explore.explore  @{context} ["Tree.tmap", "Tree.mirror"]; *}
lemma lemma_a [thy_expl]: "mirror (tmap x2 y2) = tmap x2 (mirror y2)"
by (tactic {* Hipster_Tacs.induct_simp_metis @{context} @{thms Tree.tmap.simps Tree.mirror.simps thy_expl} *})

lemma lemma_aa [thy_expl]: "mirror (mirror x2) = x2"
by (tactic {* Hipster_Tacs.induct_simp_metis @{context} @{thms Tree.tmap.simps Tree.mirror.simps thy_expl} *})


fun rigthmost :: "'a Tree \<Rightarrow> 'a"
where 
  "rigthmost (Leaf x) = x"
|  "rigthmost (Node l r) = rigthmost r"

fun leftmost :: "'a Tree \<Rightarrow> 'a"
where 
  "leftmost (Leaf x) = x"
|  "leftmost (Node l r) = leftmost l"

ML{* Hipster_Explore.explore  @{context} ["Tree.mirror","Tree.tmap", "Tree.rigthmost", "Tree.leftmost"]; *}
lemma lemma_ab [thy_expl]: "leftmost (mirror x2) = rigthmost x2"
by (tactic {* Hipster_Tacs.induct_simp_metis @{context} @{thms Tree.mirror.simps Tree.tmap.simps Tree.rigthmost.simps Tree.leftmost.simps thy_expl} *})


fun flat_tree :: "'a Tree => 'a list"
where
  "flat_tree (Leaf x) = Cons x []"
| "flat_tree (Node l r) = (flat_tree l) @ (flat_tree r)"


ML{*Hipster_Explore.explore  @{context} ["Tree.flat_tree", "Tree.mirror", "Tree.tmap", "Tree.leftmost", "Tree.rigthmost","List.rev", "List.map", "List.hd", "List.append"]; *}
lemma lemma_ac [thy_expl]: "flat_tree (tmap x2 y2) = map x2 (flat_tree y2)"
by hipster_induct_simp_metis
(*by (tactic {* Hipster_Tacs.induct_simp_metis @{context} @{thms Tree.flat_tree.simps Tree.mirror.simps Tree.tmap.simps Tree.leftmost.simps Tree.rigthmost.simps List.rev.simps List.map.simps List.hd.simps List.append.simps thy_expl} *})
*)

lemma lemma_ad [thy_expl]: "map x2 (rev xs2) = rev (map x2 xs2)"
by hipster_induct_simp_metis
(*by (tactic {* Hipster_Tacs.induct_simp_metis @{context} @{thms Tree.flat_tree.simps Tree.mirror.simps Tree.tmap.simps Tree.leftmost.simps Tree.rigthmost.simps List.rev.simps List.map.simps List.hd.simps List.append.simps thy_expl} *})
*)

lemma lemma_ae [thy_expl]: "flat_tree (mirror x2) = rev (flat_tree x2)"
by hipster_induct_simp_metis
(*by (tactic {* Hipster_Tacs.induct_simp_metis @{context} @{thms Tree.flat_tree.simps Tree.mirror.simps Tree.tmap.simps Tree.leftmost.simps Tree.rigthmost.simps List.rev.simps List.map.simps List.hd.simps List.append.simps thy_expl} *})
*)

lemma lemma_af [thy_expl]: "hd (xs2 @ xs2) = hd xs2"
by hipster_induct_simp_metis
(*by (tactic {* Hipster_Tacs.induct_simp_metis @{context} @{thms Tree.flat_tree.simps Tree.mirror.simps Tree.tmap.simps Tree.leftmost.simps Tree.rigthmost.simps List.rev.simps List.map.simps List.hd.simps List.append.simps thy_expl} *})
*)
lemma unknown [thy_expl]: "hd (flat_tree x) = leftmost x"
oops

lemma flat_tree_non_emp[simp] : "flat_tree t \<noteq> []"
by(induct t, simp_all)

(* This lemma is discoved by Hipster, but cannot be proved. It is returned with an oops. 
   This is because it needs the above three non-equational lemma, which isn't
   generated by QuickSpec in this case.
*)
lemma unproved_from_hipster : "hd (flat_tree x) = leftmost x"
by(induct x, simp_all)




end
