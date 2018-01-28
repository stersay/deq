{-# LANGUAGE DeriveGeneric, DeriveAnyClass, DeriveDataTypeable #-}

module Main where

import GHC.Generics (Generic)
import NLambda
import Prelude hiding (map,sum)

import Data.Data (Data)
import Data.Typeable (Typeable)
import System.Console.CmdArgs.Implicit ((&=),summary,help,cmdArgs)

-- Adapted from https://github.com/Jaxan/nominal-lstar/blob/master/src/Examples/Stack.hs

data DataInput = Put Atom | Get Atom
  deriving (Eq, Ord, Show, Read, Generic, NominalType, Contextual)

-- The automaton: States consist of stacks and a sink state.
-- The parameter n is the bound.
lrStack :: Int -> Automaton (Maybe [Atom]) DataInput
lrStack n = automaton
    -- states
    (singleton Nothing
        `union` map Just allStates)
    -- alphabet
    (map Put atoms `union` map Get atoms)
    -- transitions
    (map (\a -> (Nothing, Put a, Nothing)) atoms
        `union` map (\a -> (Nothing, Get a, Nothing)) atoms
        `union` triplesWith (\s1 a s2 -> (Just s1, Put a, nextState s1 a s2)) allStates atoms allStates
        `union` triplesWith (\s1 a s2 -> (Just s1, Get a, prevState s1 a s2)) allStates atoms allStates)
    -- initial states
    (singleton (Just []))
    -- final states
    (map Just allStates)
    where
        allStates = sum . fromList $ [states i | i <- [0..n]]
        states i = replicateDifferentAtoms i
        nextState stack1 a stack2 = 
            if (a:stack1) == stack2 then Just stack2 else Nothing
        prevState stack1 a stack2 =
            if stack1 == (a:stack2) then Just stack2 else Nothing

rlStack :: Int -> Automaton (Maybe [Atom]) DataInput
rlStack n = automaton
    -- states
    (singleton Nothing
        `union` map Just allStates)
    -- alphabet
    (map Put atoms `union` map Get atoms)
    -- transitions
    (map (\a -> (Nothing, Put a, Nothing)) atoms
        `union` map (\a -> (Nothing, Get a, Nothing)) atoms
        `union` triplesWith (\s1 a s2 -> (Just s1, Put a, nextState s1 a s2)) allStates atoms allStates
        `union` triplesWith (\s1 a s2 -> (Just s1, Get a, prevState s1 a s2)) allStates atoms allStates)
    -- initial states
    (singleton (Just []))
    -- final states
    (map Just allStates)
    where
        allStates = sum . fromList $ [states i | i <- [0..n]]
        states i = replicateDifferentAtoms i
        nextState stack1 a stack2 = 
            if stack1 ++ [a] == stack2 then Just stack2 else Nothing
        prevState stack1 a stack2 =
            if stack1 == stack2 ++ [a] then Just stack2 else Nothing

data Args =
  Args {
    lrsz :: Int, 
    rlsz :: Int
  }
  deriving (Show,Data,Typeable)

argSpec = 
  Args { 
    lrsz = 1 &= help "LR stack of size VALUE (default 1)",
    rlsz = 1 &= help "RL stack of size VALUE (default 1)"
  } &= summary "LR vs RL stack equivalence using NLambda."

main :: IO ()
main =
  do args <- cmdArgs argSpec
     let a1 = lrStack (lrsz args)
     let a2 = rlStack (rlsz args)
     putStrLn "Constructed... "
     let f = equivalentDA a1 a2
     putStrLn ("Equivalent? " ++ show f)