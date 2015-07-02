theory isaplannerBench
imports Main
        "$HIPSTER_HOME/IsaHipster"
begin

  datatype 'a list = nil | cons "'a" "'a list"
  datatype Nat = Z | S "Nat"

  datatype ('a, 'b) Pair2 = Pair "'a" "'b"

  fun plus :: "Nat => Nat => Nat" where
  "plus (Z) y = y"
  | "plus (S z) y = S (plus z y)"

  fun minus :: "Nat => Nat => Nat" where
  "minus (Z) y = Z"
  | "minus (S z) (Z) = S z"
  | "minus (S z) (S x2) = minus z x2"

  fun equal2 :: "Nat => Nat => bool" where
  "equal2 (Z) (Z) = True"
  | "equal2 (Z) (S z) = False"
  | "equal2 (S x2) (Z) = False"
  | "equal2 (S x2) (S y2) = equal2 x2 y2"

  fun le :: "Nat => Nat => bool" where
  "le (Z) y = True"
  | "le (S z) (Z) = False"
  | "le (S z) (S x2) = le z x2"

  fun lt :: "Nat => Nat => bool" where
  "lt x (Z) = False"
  | "lt (Z) (S z) = True"
  | "lt (S x2) (S z) = lt x2 z"

  fun max2 :: "Nat => Nat => Nat" where
  "max2 (Z) y = y"
  | "max2 (S z) (Z) = S z"
  | "max2 (S z) (S x2) = S (max2 z x2)"

  fun min2 :: "Nat => Nat => Nat" where
  "min2 (Z) y = Z"
  | "min2 (S z) (Z) = Z"
  | "min2 (S z) (S y1) = S (min2 z y1)"

  fun len :: "'a list => Nat" where
  "len (nil) = Z"
  | "len (cons y xs) = S (len xs)"

  fun drop :: "Nat => 'a list => 'a list" where
  "drop (Z) y = y"
  | "drop (S z) (nil) = nil"
  | "drop (S z) (cons x2 x3) = drop z x3"

  fun append :: "'a list => 'a list => 'a list" where
  "append (nil) y = y"
  | "append (cons z xs) y = cons z (append xs y)"

  fun count :: "Nat => Nat list => Nat" where
  "count x (nil) = Z"
  | "count x (cons z ys) =
       (if equal2 x z then S (count x ys) else count x ys)"

  fun map2 :: "('a => 'b) => 'a list => 'b list" where
  "map2 x (nil) = nil"
  | "map2 x (cons z xs) = cons (x z) (map2 x xs)"

  fun take :: "Nat => 'a list => 'a list" where
  "take (Z) y = nil"
  | "take (S z) (nil) = nil"
  | "take (S z) (cons x2 x3) = cons x2 (take z x3)"

  fun filter :: "('a => bool) => 'a list => 'a list" where
  "filter x (nil) = nil"
  | "filter x (cons z xs) =
       (if x z then cons z (filter x xs) else filter x xs)"

  fun elem :: "Nat => Nat list => bool" where
  "elem x (nil) = False"
  | "elem x (cons z xs) = (if equal2 x z then True else elem x xs)"

  fun ins :: "Nat => Nat list => Nat list" where
  "ins x (nil) = cons x (nil)"
  | "ins x (cons z xs) =
       (if lt x z then cons x (cons z xs) else cons z (ins x xs))"

  fun ins1 :: "Nat => Nat list => Nat list" where (* out of order insertion with no duplicates *)
  "ins1 x (nil) = cons x (nil)"
  | "ins1 x (cons z xs) =
       (if equal2 x z then cons z xs else cons z (ins1 x xs))"

  fun last :: "Nat list => Nat" where
  "last (nil) = Z"
  | "last (cons y (nil)) = y"
  | "last (cons y (cons x2 x3)) = last (cons x2 x3)"

  fun insort :: "Nat => Nat list => Nat list" where
  "insort x (nil) = cons x (nil)"
  | "insort x (cons z xs) =
       (if le x z then cons x (cons z xs) else cons z (insort x xs))"

  fun sort :: "Nat list => Nat list" where
  "sort (nil) = nil"
  | "sort (cons y xs) = insort y (sort xs)"

  fun dropWhile :: "('a => bool) => 'a list => 'a list" where
  "dropWhile x (nil) = nil"
  | "dropWhile x (cons z xs) =
       (if x z then dropWhile x xs else cons z xs)"

  fun takeWhile :: "('a => bool) => 'a list => 'a list" where
  "takeWhile x (nil) = nil"
  | "takeWhile x (cons z xs) =
       (if x z then cons z (takeWhile x xs) else nil)"

  fun delete :: "Nat => Nat list => Nat list" where
  "delete x (nil) = nil"
  | "delete x (cons z xs) =
       (if equal2 x z then delete x xs else cons z (delete x xs))"

  fun zip :: "'a list => 'b list => (('a, 'b) Pair2) list" where
  "zip (nil) y = nil"
  | "zip (cons z x2) (nil) = nil"
  | "zip (cons z x2) (cons x3 x4) = cons (Pair z x3) (zip x2 x4)"

  fun zipConcat :: "'a => 'a list => 'b list =>
                    (('a, 'b) Pair2) list" where
  "zipConcat x y (nil) = nil"
  | "zipConcat x y (cons y2 ys) = cons (Pair x y2) (zip y ys)"

  fun null :: "'a list => bool" where
  "null (nil) = True"
  | "null (cons y z) = False"

  fun butlast :: "'a list => 'a list" where
  "butlast (nil) = nil"
  | "butlast (cons y (nil)) = nil"
  | "butlast (cons y (cons x2 x3)) = cons y (butlast (cons x2 x3))"

  fun butlastConcat :: "'a list => 'a list => 'a list" where
  "butlastConcat x (nil) = butlast x"
  | "butlastConcat x (cons z x2) = append x (butlast (cons z x2))"

  fun rev :: "'a list => 'a list" where
  "rev (nil) = nil"
  | "rev (cons y xs) = append (rev xs) (cons y (nil))"

  fun lastOfTwo :: "Nat list => Nat list => Nat" where
  "lastOfTwo x (nil) = last x"
  | "lastOfTwo x (cons z x2) = last (cons z x2)"

  fun sorted :: "Nat list => bool" where
  "sorted (nil) = True"
  | "sorted (cons y (nil)) = True"
  | "sorted (cons y (cons y2 ys)) =
       (if le y y2 then sorted (cons y2 ys) else False)"
 

  datatype 'a Tree = Leaf | Node "'a Tree" "'a" "'a Tree"

  fun mirror :: "'a Tree => 'a Tree" where
  "mirror (Leaf) = Leaf"
  | "mirror (Node l y r) = Node (mirror r) y (mirror l)"

  fun height :: "'a Tree => Nat" where
  "height (Leaf) = Z"
  | "height (Node l y r) = S (max2 (height l) (height r))"


end

