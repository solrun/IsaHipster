(*  Author:     Moa Johansson, Chalmers University of Technology
    Author:     Irene Lobo Valbuena, Chalmers University of Technology

Hipster induction tactics and predifined routine-hard reasoning pairs
parameterising theory exploration.
*)

(* Various tactics for Hipster. Induction, simplification and metis. *)

(* TODO: checkout Type.could_unify
          --> and: purely structural matching (raw_match, etc)
         else Term.could_unify (for terms...) *)

signature IND_TACS =
sig
  type inductionStrategy
  val simp_all : Proof.context -> thm list -> tactic
  val sledgehammer_goals : Proof.context -> tactic
  val prove_by_simp : Proof.context -> thm list -> tactic
  val timed_metis_tac : Proof.context -> bool -> Thm.thm list -> int -> tactic
  val simp_or_metis : Proof.context -> (thm list * thm list) -> tactic
  val simp_or_sledgehammer_tac : Proof.context -> tactic
  val induct_and_simp : thm list -> inductionStrategy
  val induct_simp_or_metis : thm list * thm list -> inductionStrategy
  val induct_and_sledgehammer : inductionStrategy

  val try_inductable_vars : Proof.context -> inductionStrategy -> int -> tactic

  (* Utility function: figure out induction vars and arbitrary vars for induction tactic. *)
  val mk_induct_insts : (string * typ) list -> string list ->
                        (string * typ) list * (string * typ) option list

  (* Does induction on specified var.  *)
  val induct_on_var_tac : Proof.context -> (string * thm list) option -> string list option -> int -> tactic

  (* Get variable names to try structural induction on *)
  val inductable_things_in_sg : Proof.context -> int -> thm -> (string * typ) list * (string * typ) list

  (* Context -> tactic, to be pasted into proof script. *)
  val induct_simp_tac : Proof.context -> tactic

  (* Context -> list of simp rules (defs) -> tactic, to be pasted into proof script. *)
  val induct_simp_metis : Proof.context -> thm list -> tactic
  (* Context -> tactic, to be pasted into proof script. *)
  val induct_sledgehammer_tac :  Proof.context -> tactic

  (* Context -> list of induct rules (schemes) -> tactic *)
  val induct_with_schemes : Proof.context -> thm list -> tactic
  val try_induct_schemes : Proof.context -> inductionStrategy -> int -> tactic

end

structure Ind_Tacs  : IND_TACS  =
struct

type inductionStrategy = Proof.context -> (string * thm list) option -> string list option (*-> int*) -> tactic

fun SOLVE_TIMEOUT mseconds tac t =
  let val res = Timeout.apply (Time.fromMilliseconds mseconds)
                  (fn () => SINGLE ( tac) t) ()
                handle Timeout.TIMEOUT _ => NONE
                     | ERROR message => (warning ("Error: " ^ message ^ "\n"); NONE)
  in
    case res of
      NONE => Seq.empty  (* Hipster_Utils.maybe_output ctxt 50 ("Timeout :(") *)
    | SOME t' => Seq.single t'
  end;


(*-----------------------------------------------------------------------------------------*)
(* Simp tactics *)
(*-----------------------------------------------------------------------------------------*)
(*fun pretty_thm ctxt thm = Syntax.pretty_term ctxt (prop_of thm);*)
fun SOLVE_OR_FAIL tac st =
  let fun solved st = has_fewer_prems 1 st;
  in Seq.filter solved (tac st) end;

(* Apply simp to all subgoals *)
fun simp_all ctxt lemmas thm =
    let
       (*val _ = Pretty.writeln (Pretty.block [Pretty.str "simp_all: ", pretty_thm ctxt thm])*)
       (*val ss = map @{print} lemmas*)
       val ctxt' = Library.foldl (fn (ctxt,thm) => Simplifier.add_simp thm ctxt)
                                 (ctxt, lemmas)
    in
      (PARALLEL_GOALS o ALLGOALS) (fn i => SOLVE_TIMEOUT 500 (Simplifier.asm_full_simp_tac ctxt' i)) thm
    end;

(* Fails if all there are some subgoals left after application of simp *)
 fun prove_by_simp ctxt lemmas = SOLVE_OR_FAIL (SOLVE_TIMEOUT 500 (simp_all ctxt lemmas));


(*-----------------------------------------------------------------------------------------*)
(* Metis tactics *)
(*-----------------------------------------------------------------------------------------*)


(* Apply simp, if that doesn't work try metis.  *)
  (*  val _ = Pretty.writeln (Pretty.block [Pretty.str ("timed_metis: "^ @{make_string} i),pretty_thm ctxt thm]) in*)
fun timed_metis_tac ctxt full facts i thm =
  let val timeout = Hip_Tac_Ops.metis_to ctxt
      val args_metis = (if full then [ATP_Proof_Reconstruct.full_type_enc] else [])
  in (SOLVE_TIMEOUT timeout
       (Metis_Tactic.metis_tac args_metis
        ATP_Proof_Reconstruct.default_metis_lam_trans ctxt facts i)) thm
 end;

val has_tvar = exists_type (exists_subtype (fn TVar _ => true | _ => false)) o Thm.prop_of

fun metis_method ((override_type_encs, lam_trans), ths) ctxt facts =
  let val (schem_facts, nonschem_facts) = List.partition has_tvar facts
      val timeout = Hip_Tac_Ops.metis_to ctxt
  in
     (Method.insert_tac ctxt nonschem_facts THEN'
      CHANGED_PROP o (SOLVE_TIMEOUT timeout) o Metis_Tactic.metis_tac (these override_type_encs)
        (the_default ATP_Proof_Reconstruct.default_metis_lam_trans lam_trans) ctxt (schem_facts @ ths)) end


(* First simp, and if nessecary, let Metis deal with the rest *)
fun simp_or_metis ctxt (facts, lemmas) thm = (*let val _ = Pretty.writeln (pretty_thm ctxt thm) in*)
  let
    val type_enc = if Hip_Tac_Ops.use_full_types ctxt then (SOME [ATP_Proof_Reconstruct.full_type_enc]) else NONE
    val simp_adds = filter (fn lem => hd (Hip_Tac_Ops.simp_cond ctxt) (thm,lem)) lemmas
    val metis_adds = filter (fn lem => hd (Hip_Tac_Ops.metis_cond ctxt) (thm,lem)) (lemmas)
  in
    ((simp_all ctxt simp_adds) (* FIXME: both facts and lemmas? *)     (*SOLVE_TIMEOUT 2000*)
     THEN
     IF_UNSOLVED
     ((PARALLEL_GOALS o ALLGOALS) (metis_method ((type_enc,NONE), metis_adds) ctxt facts))) thm
  end;
(*REPEAT o FIRSTGOAL*) (*REPEAT_FIRST*)
(*((REPEAT_ALL_NEW (metis_method ((NONE,NONE), lemmas) ctxt facts))))*)


(* TODO: Maybe hack around with sledgehammer_with_metis to print string with actual facts as proof,
 also maybe see if we can pass in stuff proved during theory exploration but not yet in proof script.*)
(* Sledgehammer tactic *)
fun sledgehammer_goals ctxt =
  let
    val proved = ThyExpl_Data.proved_of_ctxt ctxt
    val _ = @{print} proved
  in
    ALLGOALS (Sledgehammer_Tactics.sledgehammer_with_metis_tac ctxt []
              Sledgehammer_Fact.no_fact_override proved)
  end;



(* Must fail if there are any open subgoals left *)
fun simp_or_sledgehammer_tac ctxt = let val _ = @{print} "simp or" in
   SOLVE_OR_FAIL ((simp_all ctxt []) THEN IF_UNSOLVED (sledgehammer_goals ctxt))
      handle Fail msg => (warning ("Failure in: *" ^ msg ^"\n"); fn _ =>  Seq.empty)
end

(*
fun sledgehammer_goals_explore ctxt =
  let
    val proved = ThyExpl_Data.proved_of_ctxt ctxt
  in
    (Hipster_Sledgehammer_Tactics.sledgehammer_with_metis_tac ctxt []
             Sledgehammer_Fact.no_fact_override proved)
  end
*)
(*-----------------------------------------------------------------------------------------*)
(* Figure out what we can do induction on, and tries each variable until success.*)
(* Stolen from IsaPlanner...                                                               *)
(*-----------------------------------------------------------------------------------------*)

(* find an element, but keep the rest also *)
fun pull_elem f l =
  let fun recf [] _ = NONE
        | recf (h :: t) L =
            if f h
              then SOME (h, (rev L) @ t)
              else recf t (h :: L)
  in recf l [] end;

(* re-arranges things to induct on (indnames) into the correct format
for Isabelles induction tactic, also removed them from ithings, so
that we know what other frees to turn into sinks (univ quantifies in
the IH) *)
(* assumes: indnames <= ithings *)
fun mk_induct_insts ithings indnames =
  let fun faux ithings [] L = (ithings, rev L)
        | faux ithings (h :: t) L =
            if h = "_"
              then faux ithings t (NONE :: L)
              else (case pull_elem (fn (n,_) => n = h) ithings of
                      NONE => raise ERROR ("No such variable to do induction on: " ^ h)
                    | SOME (v, ithings') => (faux ithings' t ((SOME v) :: L)));
    in faux ithings indnames [] end;

(* the free variables of a term that are of a datatype
   (can have induction applied) *)
fun inductable_things_in_term ctxt t =
  let fun lookup s =
        case (BNF_FP_Def_Sugar.fp_sugar_of ctxt s) of
          NONE => NONE
        | SOME di => (* SOME (di |> #fp_co_induct_sugar |> #co_inducts |> hd); *)
                      case (#fp_co_induct_sugar di) of
                        SOME c => SOME (#co_inducts c)
                        | NONE => NONE

      fun datatype_chk (Type(tn,_)) = Basics.is_some (lookup tn)
        | datatype_chk _ = false;
      (*val _ = @{print} (Term.fastype_of t,  (Term.strip_all_body t))
      val tfs = Hipster_Utils.typ_tfrees_of (Term.fastype_of t)
      val _ = @{print} (length tfs)*)
      (*val _ = @{print} (Hipster_Utils.frees_of t)*)
  in
    (* Return frees and forall quantified vars (if any) *)
    (* Split into those we can do structural induction over, and the rest *)
    List.partition (datatype_chk o snd)
                   ((Hipster_Utils.frees_of t) @ (Term.strip_all_vars t))
  end;

fun inductable_things_in_sg ctxt i thm =
  inductable_things_in_term ctxt (Library.nth (Thm.prems_of thm) (i - 1))  (* XXX: check how this might affect us *)


(* Term: has_abs, dest_abs??
         typ_subst_atomic? *)
(*fun isHO *)


(* Rule can be NONE if we just want plain structural induction. *)
(* var is the variable we want to do induction on *)
fun induct_on_var_tac ctxt rule var i goalthm =
  let val (ithings, _) = inductable_things_in_sg ctxt i goalthm;
      val (otherfrees, inductfrees) = (case var of
                                        NONE => mk_induct_insts ithings []
                                      | SOME v => mk_induct_insts ithings v (*[v]*))
      (*val (tss, ctxt') = (fold_map o fold_map) infer_term [case var of NONE => [] | SOME v=> [v]] ctxt
      val instss = map (map (fn inst => SOME (NONE, (inst, false)))) tss;*)
      val insts = map (fn NONE => NONE
                        | SOME v => SOME (NONE : Binding.binding option,(Free v,false)))
                          (* Each variable paired with false: matters not in our case since we are wrapping them with 'Free' *)
                  inductfrees

        (* Throw away Isar related stuff and only take the Thm.thm seq *)
      (* For now remove informative tracing info until we improve it
      val _ = Output.tracing ("induct_on: "^ (Library.space_implode " * "
                (map (fn NONE => "; "
                       | SOME (_, (Free (v,_),false)) => v) insts))^
                "; otherfrees: "^ (Library.space_implode ", " (map fst otherfrees))) *)
      val rule' = case rule of NONE => NONE | SOME (_,thms) => SOME thms
      val nw_thms = Induction.induction_tac ctxt false
                      [insts] [otherfrees] [] rule' [] i goalthm
                    handle ERROR message => (warning ("Error in: " ^ message ^ "\n"); Seq.empty)
                    handle Fail  errrrrr => (warning ("Failure in: *" ^ errrrrr ^"\n"); Seq.empty)
      (*val _ = @{print} (goalthm, rule', var)*)
  in
    (*Seq.cons (snd (Seq.hd nw_thms')) Seq.empty*) (*Seq.map snd*) nw_thms
  end;


(*-----------------------------------------------------------------------------------------*)
(* Induction tactics.                                                                      *)
(*-----------------------------------------------------------------------------------------*)

(* Apply induction on var and try to prove all cases by simp *)
fun induct_and_simp lemmas ctxt rule var (*i*) =
  DEPTH_SOLVE (
    (Seq.DETERM (HEADGOAL ((induct_on_var_tac ctxt rule var )))) THEN (prove_by_simp ctxt lemmas) )

(* Induction on var, then try to prove resulting subgoals by simp or metis *)
fun induct_simp_or_metis (facts, lemmas) ctxt rule var(* i*) =
  DEPTH_SOLVE (
    (Seq.DETERM (HEADGOAL ((induct_on_var_tac ctxt rule var (*i*) )))) THEN (simp_or_metis ctxt (facts,lemmas)) )

(* Induction on a var, then try to prove by sledgehammer *)
fun induct_and_sledgehammer ctxt rule var = (*let val _ = @{print} "induct_and_sl" in*)
  DEPTH_SOLVE (
    (Seq.DETERM (HEADGOAL ((induct_on_var_tac ctxt rule var)))) THEN (simp_or_sledgehammer_tac ctxt))


(* Try induction on each variable in vars until we find one that allows a proof. *)
fun try_induct_on ctxt rule strat vars i =
  case vars of
    []        => no_tac
  | (v :: vs) =>  (*let val _ = Pretty.writeln (Pretty.str (" - vars: "^ @{make_string} v)) in*)
      strat ctxt rule (SOME v) (*i*) (*THEN simp_all ctxt []*)
      ORELSE
      (try_induct_on ctxt rule strat vs i)

(* Find the variables we can induct on *)
fun try_inductable_vars ctxt strat i thm =
  let val vars = map (fn (v,_) => [v]) (*fst*) (fst (inductable_things_in_sg ctxt i thm))
  in (try_induct_on ctxt NONE strat vars i) thm
  end


  fun reP uu = case uu of
        Var (_,t) => t
      | (t$_) => reP t
      | (Abs (_, t, _)) => t
      | (Free (_, t)) => t; (* TODO: Bound, Const *)


(* Proof.context -> thm list list -> inductionStrategy -> vars -> int -> tactic *)
fun try_induction_with ctxt (scheme_rules : (string * Thm.thm list) list) strat vars i =
  (* let val vars = map fst (fst (inductable_things_in_sg i thm)) *)
  let val struct_tac = try_induct_on ctxt NONE strat (map (fn (v,_) => [v]) (*fst*) vars) i
          (* Output.tracing "Rule: none" *)
      fun rec_ind_tac rules =
        case rules of
          []            => no_tac
        | ((n,r) :: rs) =>
            let (*val _ = Output.tracing ("Rule: "^n)*)
                val argTyps =  binder_types (reP (HOLogic.dest_Trueprop (Thm.concl_of (hd r))))
                            (* binder_types (reP (HOLogic.dest_Trueprop (Thm.concl_of ((hd o the) r)))) *)

                val all_instances = (Scheme_Instances.instances_for_with argTyps vars)
              (*val instances = Scheme_Instances.flatten_instances true all_instances(* (Scheme_Instances.instances_for_with argTyps vars)*)*)
                val instt = hd all_instances
              (*val _ = @{print} instances   val _ = @{print} instt*)
              (* FIXME: vars types filter *)
            in
              try_induct_on ctxt (SOME (n,r)) strat (map (map fst) instt) i
              ORELSE
              rec_ind_tac rs (*ctxt rs strat vars i*)
            end
  in
    struct_tac ORELSE rec_ind_tac scheme_rules (* let val _ = @{print} "no struct!" in rec_ind_tac scheme_rules end *)
  end;


fun try_induct_schemes ctxt strat i thm =
  let val vars = fst (inductable_things_in_sg ctxt i thm) (* map fst ... *)
      val thynm = Context.theory_name (Proof_Context.theory_of ctxt)
      val consts = Hipster_Utils.thy_consts_of thynm thm
      val thinds = map_filter (fn n => SOME (n, (Sledgehammer_Util.thms_of_name ctxt n))
                        handle ERROR m  => (warning ("Error try: " ^ m ^ "\n"); NONE))
                    (distinct (op =) (map (fn c => (c^".induct")) consts))

                    (* map (fn n => (n, SOME (Sledgehammer_Util.thms_of_name ctxt n))
                        handle ERROR m  => (warning ("Error: " ^ m ^ "\n"); (n, NONE)))
                    (distinct (op =) (map (fn c => (c^".induct")) consts))
                    *)
      val schemes = rev thinds (* (filter (Basics.is_some (*o snd*)) thinds) *)
      val _ = warning ("For thm: " ^ (@{make_string} thm))
      (* FIXME: distinct ... *)
  in
    (try_induction_with ctxt schemes strat (distinct (op =) vars) i) thm
  end;


(* QUESTION: Should these tactics really add the lemma-list to the simplifier?
The tactics used by Hipster don't, they only pass them to Metis, looking them up from the ctxt.
However, if these tactics are used outside of theory exploration, they might not have all the
stuff in the ctxt, i.e. simprules and discovered theorems?

Maybe need all separate tactics for outside Theory Exploration? Or data for induction?
Or add to TacticData?
*)

(* An induction tactic to paste into the proof-script afterwards *)
fun induct_simp_metis ctxt facts thm =
  let val lemmas = (ThyExpl_Data.proved_of_ctxt ctxt) @ (Hipster_Rules.get ctxt)
  in
    (* XXX: removed as simplifier rules - in this case, so far, no changes *)
    ALLGOALS(try_inductable_vars ctxt (induct_simp_or_metis (facts,lemmas))) thm
  end;

fun induct_with_schemes ctxt facts thm =
  let val lemmas = (ThyExpl_Data.proved_of_ctxt ctxt) @ (Hipster_Rules.get ctxt)
      (*val thinds' = map (fn n => (n,  (Attrib.thms n))
                         handle _ => (n, NONE) ) (map (fn c => (c^".induct")) consts)*)
  in
    ALLGOALS(try_induct_schemes ctxt (induct_simp_or_metis (facts,lemmas))) thm
  end;

(* An induction tactic to paste into the proof-script afterwards *)
fun induct_simp_tac ctxt thm =
  let val lemmas = (ThyExpl_Data.proved_of_ctxt ctxt) @ (Hipster_Rules.get ctxt)
      val ctxt' = Library.foldl (fn (ctxt,thm) => Simplifier.add_simp thm ctxt)
                                (ctxt, lemmas)
  in ALLGOALS(try_inductable_vars ctxt' (induct_and_simp lemmas)) thm
  end;

fun induct_sledgehammer_tac ctxt = (*let val _ = @{print} "ind-sl-tac" in*)
  ALLGOALS(try_inductable_vars ctxt (induct_and_sledgehammer))

end


(*-----------------------------------------------------------------------------------------*)
(* Structures for pre-defined combinations of routine/hard reasoning in Hipster            *)
(*-----------------------------------------------------------------------------------------*)

signature EXPL_TACS =
sig
  val routine_tac : Proof.context -> tactic
  val routine_tac_str : string
  val hard_tac : Proof.context ->  tactic
  val final_tactic_str : Proof.context -> string
end


(* This structure considers simplification or FO reasoning by Metis as routine. *)
(* Proofs requiring structural induction is considered as "hard"                *)
structure Simp_Metis_T : EXPL_TACS =
struct

fun routine_tac ctxt = DEPTH_SOLVE (
  Ind_Tacs.simp_or_metis ctxt (ThyExpl_Data.facts_of_ctxt ctxt,
                               ThyExpl_Data.proved_of_ctxt ctxt @ Hipster_Rules.get ctxt) )

val routine_tac_str = "by (tactic {* Simp_Metis_Tacs.routine_tac @{context} *})";

fun hard_tac ctxt =
  let val lemmas = (ThyExpl_Data.proved_of_ctxt ctxt) @ (Hipster_Rules.get ctxt)
      val facts = ThyExpl_Data.facts_of_ctxt ctxt
  in
    ALLGOALS (Ind_Tacs.try_inductable_vars ctxt (Ind_Tacs.induct_simp_or_metis (facts,lemmas)))
  end;

(* The fact_nms are names of extra theorems that we want to refer to in the output *)
fun final_tactic_str ctxt =
  let (* Only need to pass the facts, the thy_expl theorems are looked up by the tactic *)
      val facts_str = Library.space_implode " " (ThyExpl_Data.fact_names_of_ctxt ctxt)
  in
    "by (hipster_induct_simp_metis " ^ facts_str ^")"
  end;
end

(* Induction and the just Sledgehammer everything *)
structure Sledgehammer_T : EXPL_TACS =
struct

fun sledgehammer_goals_tac ctxt thm =
  let
    val proved = ThyExpl_Data.proved_of_ctxt ctxt
  in
    ALLGOALS (Hipster_Sledgehammer_Tactics.just_sledgehammer ctxt []
              Sledgehammer_Fact.no_fact_override proved) thm
  end;
(* Just trust Sledgehammer *)
fun routine_tac ctxt = sledgehammer_goals_tac ctxt
val routine_tac_str = "sledgehammer"

(* We should call here a tactic that runs sledgehammer, but return one that calls metis
   with exactly the right arguments. Ideally, it should also know what it did induction on,
   so it doesn't have to repeat it. *)
fun hard_tac ctxt = Ind_Tacs.induct_sledgehammer_tac ctxt
fun final_tactic_str _ = "hipster_induct_sledgehammer"
(*"by (tactic {* Ind_Tacs.induct_sledgehammer_tac @{context}*})"*)
end;



(* Induction with schemes! *)
structure Ind_Schemes_T : EXPL_TACS =
struct

fun routine_tac ctxt = DEPTH_SOLVE (
  Ind_Tacs.simp_or_metis ctxt (ThyExpl_Data.facts_of_ctxt ctxt,
                               ThyExpl_Data.proved_of_ctxt ctxt @ Hipster_Rules.get ctxt) )

val routine_tac_str = "by (tactic {* Ind_Schemes_Tacs.routine_tac @{context} *})";

fun hard_tac ctxt =
  let val lemmas = (ThyExpl_Data.proved_of_ctxt ctxt) @ (Hipster_Rules.get ctxt)
      val facts = ThyExpl_Data.facts_of_ctxt ctxt
  in
    ALLGOALS (Ind_Tacs.try_induct_schemes ctxt (Ind_Tacs.induct_simp_or_metis (facts,lemmas)))
  end;

fun final_tactic_str ctxt =
  let val facts_str = Library.space_implode " " (ThyExpl_Data.fact_names_of_ctxt ctxt)
      (* TODO: change so as to have the top level extract the appropriate induction scheme rules? *)
  in
    "by (hipster_induct_schemes " ^ facts_str ^")"
  end;
end


structure Simp_T : EXPL_TACS =
struct

fun routine_tac ctxt =
  let val lemmas = (ThyExpl_Data.proved_of_ctxt ctxt) @ (Hipster_Rules.get ctxt)
  in
    SOLVE (Ind_Tacs.prove_by_simp ctxt lemmas)
  end;

val routine_tac_str = "by (tactic {*Simp_Tacs.routine_tac @{context}*})";

fun hard_tac ctxt =
  let val lemmas = ThyExpl_Data.proved_of_ctxt ctxt @ Hipster_Rules.get ctxt
  in
    ALLGOALS (Ind_Tacs.try_inductable_vars ctxt (Ind_Tacs.induct_and_simp lemmas))
  end;

(* The fact_nms are names of extra theorems that we want to refer to in the output *)
fun final_tactic_str _ = "by hipster_induct_simp"

end
