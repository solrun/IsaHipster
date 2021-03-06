{-# LANGUAGE DeriveFunctor, FlexibleInstances, TypeOperators, ScopedTypeVariables, FlexibleContexts, GADTs #-}
module HipSpecifyer.Prelude(genericArbitrary, genericCoarbitrary, Observe(..), genericObserve, obs0, obs1, obs2, obs3, obs4, obs5) where

import Prelude hiding (Either(..))
import qualified Test.QuickCheck as QC
import Test.QuickCheck.Gen.Unsafe
import GHC.Generics
import Data.Typeable
import Control.Monad
import Test.QuickSpec.Signature hiding (observe, ord)
import Test.QuickSpec.Term
import Test.QuickSpec
import Data.Monoid

-- Generate a value generically.
genericArbitrary :: forall a. (Typeable a, QC.Arbitrary a, Generic a, GArbitrary (Rep a)) => QC.Gen a
genericArbitrary =
  QC.sized $ \n ->
    -- If the size is 0, only consider non-recursive constructors.
    if n > 0
    then QC.oneof (map gen constructors)
    else QC.oneof (map gen (filter (not . recursive) constructors))
  where
    constructors = map (fmap to) (garbitrary (QC.arbitrary :: QC.Gen a))
    recursive b = recursion b > 0

-- Generating random values of a datatype
class GArbitrary f where
  -- Argument is a generator for the datatype itself, which will be used
  -- when the datatype is recursive
  garbitrary :: Typeable a => QC.Gen a -> [Constr (f b)]

-- Generating random constructors
class GConstr f where
  gconstructor :: Typeable a => QC.Gen a -> Constr (f b)

-- Represents a generator for one constructor of a datatype
data Constr a = Constr {
  -- The generator itself
  gen :: QC.Gen a,
  -- Is the constructor recursive and if so, how many times does the datatype appear
  recursion :: Int
  } deriving Functor

-- Interesting typeclass instances

instance GConstr f => GArbitrary (C1 c f) where
  -- This is the generator for a single constructor.
  -- We have to resize the "recursive generator" depending on how many
  -- times the datatype appears recursively in the constructor
  garbitrary gen = [b]
    where
      b = gconstructor (QC.sized $ \m -> QC.resize (newSize m) gen)
      newSize m
        | recursion b == 1 = m-1
        | otherwise = m `div` recursion b

instance (Typeable a, QC.Arbitrary a) => GConstr (K1 i a) where
  -- An argument to a constructor: see if the argument is recursive or not
  gconstructor gen =
    case gcast gen of
      Nothing ->
        -- Not recursive: use normal generator
        Constr (fmap K1 QC.arbitrary) 0
      Just gen' ->
        -- Recursive: use recursive generator
        Constr (fmap K1 gen') 1

instance (GConstr f, GConstr g) => GConstr (f :*: g) where
  -- A constructor with several arguments: add up the number of recursive occurrences
  gconstructor gen = Constr (liftM2 (:*:) g1 g2) (r1 + r2)
    where
      Constr g1 r1 = gconstructor gen
      Constr g2 r2 = gconstructor gen

-- Generic drivel that doesn't really do anything.
instance GConstr f => GConstr (M1 i c f) where
  gconstructor gen = fmap M1 (gconstructor gen)

instance GConstr U1 where
  gconstructor _ = Constr (return U1) 0

instance (GArbitrary f, GArbitrary g) => GArbitrary (f :+: g) where
  garbitrary gen = map (fmap L1) (garbitrary gen) ++ map (fmap R1) (garbitrary gen)

instance GArbitrary f => GArbitrary (D1 c f) where
  garbitrary gen = map (fmap M1) (garbitrary gen)

-- All the same but for coarbitrary. Sigh...
genericCoarbitrary :: (Generic a, GCoarbitrary (Rep a)) => a -> QC.Gen b -> QC.Gen b
genericCoarbitrary x = gcoarbitrary (from x)

class GCoarbitrary f where
  gcoarbitrary :: f a -> QC.Gen b -> QC.Gen b

instance (GCoarbitrary f, GCoarbitrary g) => GCoarbitrary (f :*: g) where
  gcoarbitrary (x :*: y) = gcoarbitrary x . gcoarbitrary y

instance (GCoarbitrary f, GCoarbitrary g) => GCoarbitrary (f :+: g) where
  gcoarbitrary (L1 x) = QC.variant 0 . gcoarbitrary x
  gcoarbitrary (R1 x) = QC.variant 1 . gcoarbitrary x

instance QC.CoArbitrary a => GCoarbitrary (K1 i a) where
  gcoarbitrary (K1 x) = QC.coarbitrary x

instance GCoarbitrary U1 where
  gcoarbitrary U1 = id

instance GCoarbitrary f => GCoarbitrary (M1 i c f) where
  gcoarbitrary (M1 x) = gcoarbitrary x

-- A type class of things that can be randomly tested for equality.
class Observe a where
  observe :: a -> QC.Gen Observation

data Observation where
  Base :: (Typeable a, Ord a) => a -> Observation
  Pair :: Observation -> Observation -> Observation
  Left :: Observation -> Observation
  Right :: Observation -> Observation

ord :: (Typeable a, Ord a) => a -> QC.Gen Observation
ord x = return (Base x)

instance Eq Observation where
  x == y = x `compare` y == EQ

instance Ord Observation where
  Base x `compare` Base y = x' `compare` y
    where
      Just x' = cast x
  Pair x y `compare` Pair x' y' =
    case x `compare` x' of
      LT -> LT
      GT -> GT
      EQ -> y `compare` y'
  Left x `compare` Left y = x `compare` y
  Right x `compare` Right y = x `compare` y
  Left _ `compare` Right _ = LT
  Right _ `compare` Left _ = GT

instance Observe Bool where
  observe = ord

instance Observe Int where
  observe = ord

instance Observe A where
  observe = ord

instance (QC.Arbitrary a, Observe b) => Observe (a -> b) where
  observe f = do
    x <- QC.arbitrary
    observe (f x)

instance Observe a => Observe (Maybe a) where
  observe = genericObserve

instance (Observe a, Observe b) => Observe (a, b) where
  observe = genericObserve

instance Observe a => Observe [a] where
  observe = genericObserve

-- Now for Observe...
genericObserve :: (Generic a, GObserve (Rep a)) => a -> QC.Gen Observation
genericObserve = gobserve . from

class GObserve f where
  gobserve :: f a -> QC.Gen Observation

instance (GObserve f, GObserve g) => GObserve (f :*: g) where
  gobserve (x :*: y) = liftM2 Pair (gobserve x) (gobserve y)

instance (GObserve f, GObserve g) => GObserve (f :+: g) where
  gobserve (L1 x) = fmap Left (gobserve x)
  gobserve (R1 x) = fmap Right (gobserve x)

instance Observe a => GObserve (K1 i a) where
  gobserve (K1 x) = observe x

instance GObserve U1 where
  gobserve U1 = ord ()

instance GObserve f => GObserve (M1 i c f) where
  gobserve (M1 x) = gobserve x

obs0 :: (Observe a, Typeable a) => String -> a -> Sig
obs0 x f = blind0 x f
           `mappend` observer f

-- | A unary function.
obs1 :: (Typeable a,
         Typeable b, Observe b) =>
        String -> (a -> b) -> Sig
obs1 x f = blind1 x f
           `mappend` observer (f undefined)

-- | A binary function.
obs2 :: (Typeable a, Typeable b, {-Observe a, Observe b,-}
         Typeable c, Observe c) =>
        String -> (a -> b -> c) -> Sig
obs2 x f = blind2 x f
           `mappend` observer (f undefined undefined)

-- | A ternary function.
obs3 :: (Typeable a, Typeable b, Typeable c,
         Typeable d, Observe d) =>
        String -> (a -> b -> c -> d) -> Sig
obs3 x f = blind3 x f
           `mappend` observer (f undefined undefined undefined)

-- | A function of four arguments.
obs4 :: (Typeable a, Typeable b, Typeable c, Typeable d,
         Typeable e, Observe e) =>
        String -> (a -> b -> c -> d -> e) -> Sig
obs4 x f = blind4 x f
           `mappend` observer (f undefined undefined undefined undefined)

-- | A function of five arguments.
obs5 :: (Typeable a, Typeable b, Typeable c, Typeable d,
         Typeable e, Typeable f, Observe f) =>
        String -> (a -> b -> c -> d -> e -> f) -> Sig
obs5 x f = blind5 x f
           `mappend` observer (f undefined undefined undefined undefined undefined)

observer :: (Observe a, Typeable a) => a -> Sig
observer x = observerSig (Observer (pgen (promote observe)) `observing` x)
