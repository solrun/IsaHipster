theory unequal
imports Main
        "../data/Natu"
        "../funcs/equal"
        "$HIPSTER_HOME/IsaHipster"

begin

fun unequal :: "Nat => Nat => bool" where
  "unequal x y = (\<not> (equal2 x y))"
 
end

