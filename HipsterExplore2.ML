(* Re-factoring of Hipster_Explore to use ctactics and tracing proofs *)

structure Hipster_Explore (* : HIPSTER_THY_EXPLORATION *) = 
struct


fun proof_str ctxt proof_script name thm = 
  let 
    (* Print variables without ? *)
    val ctxt' = Config.put show_question_marks false ctxt
    (* Disables silly Isabelle YXML markup for printing *)
    val str_of_term = Sledgehammer_Util.with_vanilla_print_mode (Syntax.string_of_term ctxt')
    val lemma_str = Library.quote (str_of_term (Thm.concl_of thm))
    (*val name = Long_Name.base_name (Thm.get_name_hint thm)
    val _ = @{print} name *)
  in
    (* FIXME: Make keeping track of used names used better. Put in theory data instead of having tag *)
    "lemma " ^ name ^" [thy_expl]: " ^ lemma_str ^ "\n" ^ proof_script
  end

(*-----------------------------------------------------------------------------------------*)
(* The proof-loop, trying to prove the conjectures found by HipSpec  *) 
(*-----------------------------------------------------------------------------------------*)
fun try_nxt_conj ctxt =
  case (ThyExpl_Data.open_conjs_of_ctxt ctxt) of
    [] => (*retry open_conjs if we have some new proved since last time.*)
      if (ThyExpl_Data.progress_of_ctxt ctxt) 
        then SOME (ctxt 
                    |> ThyExpl_Data.set_open_conjs_ctxt (ThyExpl_Data.failed_of_ctxt ctxt)
                    |> ThyExpl_Data.set_failed_ctxt []
                    |> ThyExpl_Data.set_progress_ctxt false)                
        else NONE

  | (c::cs) => (* try proving next open conj *)
      let 
        val lemma_str = Syntax.string_of_term ctxt (Thm.concl_of c)
      in
        case (SINGLE (Tactic_Data.routine_tac ctxt) c) of (* Discard this, it is trivial *)
          SOME _ => 
            let val _ = Output.tracing ("Trivial proof: "^lemma_str)
            in SOME (ThyExpl_Data.set_open_conjs_ctxt cs ctxt)
            end
        | NONE => 
            let val hard_ctac = Tactic_Data.hard_ctac ctxt in
            case (CTac.SINGLE hard_ctac (ctxt,c)) of
              SOME (ctxt1, proved_thm) =>
                let
                  val (new_nm, ctxt') = ThyExpl_Data.fresh_name ctxt1
                  val proof_script = 
                      proof_str ctxt'(Induction_Data.get_proof_script_ctxt ctxt') new_nm proved_thm
                  val final_thm = proved_thm
                                    |> Drule.generalize 
                                      (Hipster_Utils.frees_and_tfrees_of_thm proved_thm) 
                                    |> Goal.finish ctxt'
                                    |> Thm.put_name_hint new_nm
                 
                  val gen_thm = Drule.generalize 
                            (Hipster_Utils.frees_and_tfrees_of_thm final_thm) final_thm
                  val _ = Sledgehammer_Util.with_vanilla_print_mode writeln
                            ("Proved: " ^ lemma_str)
                in
                  SOME (ctxt'
                          |> ThyExpl_Data.set_open_conjs_ctxt cs
                          |> ThyExpl_Data.add_proved_ctxt (Thm.put_name_hint new_nm gen_thm)                            
                          |> ThyExpl_Data.set_progress_ctxt true
                          |> ThyExpl_Data.add_proof_script_ctxt (new_nm, proof_script))
                end
            (* NONE indicates that the tactic failed to prove c *)
            | NONE =>
                let val _ = Output.tracing ("Failed proving: "^lemma_str)
                in SOME (ctxt
                          |> ThyExpl_Data.set_open_conjs_ctxt cs
                          |> ThyExpl_Data.add_failed_ctxt c)
                end
            end
      end


fun proof_loop ctxt cand_lemmas_str = 
  let
    val ctxt1 = ThyExpl_Data.init_expl ctxt [] [] NONE
                  (Library.split_lines (Library.trim_line cand_lemmas_str))
    fun recf ctxt = 
      case (try_nxt_conj ctxt) of
        NONE => ctxt
      | SOME ctxt' => recf ctxt'
  in
    recf ctxt1
  end

(*-----------------------------------------------------------------------------------------*)

(* TODO: Implement properly. This is for mapping back to Isabelle constants those things that the
   code generator renamnes in Haskell. Otherwise, Isabelle will not understand the resulting lemmas. *)
fun map_to_haskell isa_nm = 
  let 
    val haskell_consts =
  [ ("List.rev","reverse"),("List.append","++"), ("HOL.conj", " '&&' "),
    ("Groups.plus_class.plus", "plus_nat"), ("Groups.zero_class.zero", "Zero_nat"),
    ("Groups.one_class.one", "one_nat"),("<="," less_eq_nat "), ("<", " less_nat ") ]
  in
  case (Library.find_first (fn (nm,_) => nm = isa_nm) haskell_consts) of 
    NONE => isa_nm
  | SOME (_,hask_nm) => hask_nm
  end;

fun hipspec_plain consts file =
  let val add_funs = List.foldl (fn (nm,s) => "--extra-trans="^
        (Long_Name.base_name nm)^ " "^s) " " consts
  in "hipster-hipspec "^ "--isabelle-mode " ^ add_funs  ^ file ^ " --tests=600"
  end

fun hipspec_cond cond_name consts file = 
  let val add_funs = List.foldl (fn (nm,s) => "--extra-trans="^
          (Long_Name.base_name nm)^ " "^s) " " consts
  in "hipster-hipspec "^ "--isabelle-mode " ^ add_funs  ^ file ^ " --cond-name=" ^ 
      (Long_Name.base_name cond_name) ^ " --cond-count=2 --tests=600"
  end

fun hipspec_explore ctxt cond_opt const_nms =
  let
    val thy = Proof_Context.theory_of ctxt
    val thynm = Context.theory_name thy
    val outfile = Hipster_Setup.filepath^ (Context.theory_name thy) ^"_hipspec.hs"
    val const_nms' = map map_to_haskell const_nms
      
    val hipspec_cmd = case cond_opt of NONE => hipspec_plain const_nms' outfile 
                                     | SOME c => hipspec_cond c const_nms' outfile
    val path_opt = SOME (Path.explode Hipster_Setup.filepath);    
    val _ = Code_Target.export_code ctxt false const_nms [((("Haskell",thynm), path_opt), [])]
    val args = "H " ^ Hipster_Setup.filepath^thynm^".hs " ^outfile
    val _ = Isabelle_System.bash ("HipSpecifyer " ^ args)
  in 
      fst (Isabelle_System.bash_output hipspec_cmd)
  end;

(*-----------------------------------------------------------------------------------------*)
(* The output string for each lemma discovered. *)
fun mk_lemma_str ctxt thm = 
  let 
   (* val lemma = (*Thm.prop_of thm  *) Thm.concl_of thm
 
    (* Print variables without ? *)
    val ctxt' = Config.put show_question_marks false ctxt
    (* Disables silly Isabelle YXML markup for printing *)
    val str_of_term = Sledgehammer_Util.with_vanilla_print_mode (Syntax.string_of_term ctxt')
    val lemma_str = Library.quote (str_of_term lemma)
    *)
    val name = Long_Name.base_name (Thm.get_name_hint thm)
    val proof_script = 
        case (ThyExpl_Data.proof_script_of_thm name ctxt) of
          NONE => proof_str ctxt "oops" name thm
       |  SOME proof => proof
  in
    proof_script
    (* FIXME: Make keeping track of names used better. Put in theory data instead of having tag *)
  (*  "lemma " ^ name ^" [thy_expl]: " ^ lemma_str ^ "\n" ^ proof_script *)
  end

(* Outputs snippets of proof script with the discovered lemmas that can be pasted into the theory file. *)
fun explore' cond_opt ctxt const_nms =
  let
    val conjs = hipspec_explore ctxt cond_opt const_nms
    val res_ctxt = proof_loop ctxt conjs  
    val output = Library.space_implode "\n\n"
                (map (mk_lemma_str res_ctxt) 
                    ((ThyExpl_Data.proved_of_ctxt res_ctxt) 
                    @ (ThyExpl_Data.failed_of_ctxt res_ctxt)))
  in
    (res_ctxt, Sledgehammer_Util.with_vanilla_print_mode writeln
                  (Active.sendback_markup [Markup.padding_command] output))
  end

val explore = explore' NONE;
fun explore_cond cond = explore' cond;

end;