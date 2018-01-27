
import Test.HUnit

import Math.Algebra.Group.PermutationGroup (Permutation,p)
import qualified Math.Algebra.Group.PermutationGroup as Permutation

import Data.IntMap (IntMap)
import qualified Data.IntMap as IntMap

import Data.List ((\\))
import qualified Data.List as List

import Automata 
import PPerm 
import GenSystem 
import Stack
import Bisim

mkTestCasesFrom = TestList . List.map TestCase

main :: IO ()
main =
  do
    cnts <- runTestTT (mkTestCasesFrom allTests)
    print (show cnts)

allTests = [
    permEqTest,
    permGenTestY,
    permGenTestN,
    toPPermsTest,
    genSysPartialGens,
    genSysMember1,
    genSysMember2,
    genSysMember3,
    genSysMember4,
    genSysMember5,
    succsTest1,
    succsTest2,
    succsTest3,
    succsTest4,
    chTest1,
    chTest2,
    extTest1,
    extTest2,
    extTest3,
    algTest1,
    algTest2,
    algTest3,
    sumTest1,
    sumTest2,
    fraBisimTest1,
    fraBisimTest2,
    fraBisimTest3,
    fraBisimTest4,
    fraBisimTest5,
    fraBisimTest6,
    fraBisimTest7,
    freshSuccsTest
  ]

---------------------------------------
-- Some shorthands to help readability
---------------------------------------
q1 = 1
q2 = 2
q3 = 3
a  = 1
b  = 2

--------------------------------------------------------------------------------------------
-- Checking that the supplied PermutationGroup and SchreierSims libraries work as expected
--

-- Permutations (0,1) and (2,3) generate the group (), (0,1), (2,3), (0,1)(2,3)
gs = [p [[0,1]], p [[2,3]]]

permEqTest =
  assertEqual "" (p [[0,1],[2,3]])  (p [[2,3],[0,1]])

permGenTestY =
  assertBool "" (isMem gs (p [[0,1],[2,3]]))

permGenTestN =
  assertBool "" (not $ isMem gs (p [[1,2]]))

toPPermsTest =
  assertEqual "Permutation to partial permutation conversion." (List.map (toPPerm [0,1,2,3]) (Permutation.elts gs)) pperms
  where
    pperms = [
        IntMap.fromList [(0,0),(1,1),(2,2),(3,3)],
        IntMap.fromList [(0,1),(1,0),(2,2),(3,3)],
        IntMap.fromList [(0,1),(1,0),(2,3),(3,2)],
        IntMap.fromList [(0,0),(1,1),(2,3),(3,2)]
      ]

-------------------------------------------------------------------------------------------

-- Checking generating systems work correctly

-- A generating system over states '[1,2,3]' and registers '[0,1,2,3,4]'.
--
-- States '1' and '2' are equivalent and represented by '1', state '3' is represented by itself.
--
-- The characteristic set of '1' is the registers '[0,1,2,3]', the characteristic set of
-- state 3 is registers '[2,3]'.
--
-- The group associated with state '1' is generated by the permutations (0,1) and (2,3),
-- the group associated with state '3' is generated by (2,3).
--
-- The ray connecting states '1' and '2' is the partial permutation mapping '1' to '3'
-- and '3' to '2'.
--
genSys = GenSys {
    rep = IntMap.fromList [(1, 1), (2, 1), (3, 3)],
    chr = IntMap.fromList [(1, [0,1,2,3]), (3, [2,3])],
    grp = IntMap.fromList [(1, [p [[0, 1]], p [[2, 3]]]), (3, [p [[2, 3]]])],
    ray = IntMap.fromList [(1, toPPerm [0,1,2,3] 1), (2, IntMap.fromList [(0,4),(1,1),(2,2),(3,3)]), (3, toPPerm [2,3] 1)]
  }

genSysOpenSubSet = [
    (1, pperm1 (p [[0,1]]), 1),
    (1, pperm1 (p [[2,3]]), 1),
    (1, pperm1 (p [[0,1],[2,3]]), 1),
    (1, pperm1 (p []), 1),
    (3, pperm3 (p [[2,3]]), 3),
    (3, pperm3 (p []), 3),
    (1, IntMap.fromList [(0,4),(1,1),(2,2),(3,3)], 2),
    (1, pperm1 1, 1),
    (3, pperm3 1, 3)
  ]
  where pperm1 = toPPerm [0,1,2,3]
        pperm3 = toPPerm [2,3]

genSysPartialGens =
  assertEqual "" ord1 ord2
  where ord1 = List.sort (partialGens genSys)
        ord2 = List.sort genSysOpenSubSet

genSysMember1 =
  assertBool "" (isMember genSys (1, IntMap.fromList [(0,4),(1,1),(2,2),(3,3)], 2))
  
genSysMember2 =
  assertBool "" (isMember genSys (2, toPPerm [1,2,3,4] 1, 2))

genSysMember3 =
  assertBool "" (isMember genSys (2, toPPerm [1,2,3,4] (p [[4,1],[2,3]]), 2))

genSysMember4 =
  assertBool "" (isMember genSys (2, toPPerm [0,1,2,3,4] 1, 2))

genSysMember5 =
  assertBool "" (isMember genSys (2, inverse (IntMap.fromList [(0,4),(1,1),(2,2),(3,3),(4,0)]), 1))

-----------------------------------------------------------
-- Testing successor computation
-----------------------------------------

dra = Auto { regs = [0,1,2,3,4], stts = [1,2,3], actv = av, trns = ts }
  where
    ts = [
        (q1, a, Stored, 0, q1),
        (q1, a, Stored, 1, q1),
        (q2, a, Stored, 4, q2),
        (q2, a, Stored, 1, q2),
        (q1, b, LFresh, 0, q3),
        (q1, b, Stored, 4, q3),
        (q2, b, LFresh, 4, q3),
        (q2, b, Stored, 0, q3),
        (q3, a, Stored, 2, q3),
        (q3, a, Stored, 3, q3)
      ]
    av = IntMap.fromList [(q1,[0,1,2,3,4]),(q2,[0,1,2,3,4]),(q3,[0,1,2,3,4])]

succsTest1 =
  assertEqual "" expected actual
  where
    actual   = fmap List.nub (succs dra Large (q3, IntMap.fromList [(2,3),(3,2)], q3))
    expected = Just [(q3, IntMap.fromList [(2,3),(3,2)], q3, Large)]

succsTest2 =
  assertEqual "" Nothing actual
  where
    actual = succs dra Large (q3, IntMap.fromList [], q3)

succsTest3 =
  assertEqual "" Nothing actual
  where
    actual = succs dra Large (q3, IntMap.fromList [(1,2),(2,1),(3,3)], q3)

succsTest4 = 
  assertEqual "" expected actual
  where 
    actual = fmap (List.sort . List.nub) (succs dra Large (q1, IntMap.fromList [(0,4),(1,1),(2,2),(3,3)], q2))
    expected = 
      Just (List.sort [
             (q1, IntMap.fromList [(0,4),(1,1),(2,2),(3,3)], q2, Large),
             (q3, IntMap.fromList [(0,4),(1,1),(2,2),(3,3)], q3, Large),
             (q3, IntMap.fromList [(0,0),(1,1),(2,2),(3,3)], q3, Large),
             (q3, IntMap.fromList [(1,1),(2,2),(3,3),(4,4)], q3, Large)
           ])

chTest1 =
  assertEqual "" [2,3] (ch [0,1,2,3,4] fs)
  where
    fs = List.map (\(_,f,_) -> f) genSysOpenSubSet

chTest2 =
  assertEqual "" [3,4] (ch [0,1,2,3,4] fs)
  where
    fs = [
        IntMap.fromList [(0,0),(1,1),(3,3),(4,4)],
        IntMap.fromList [(0,1),(1,2),(2,0),(3,4),(4,3)]
      ]

initGenSys = GenSys {
    rep = IntMap.fromList [(1, 1), (2, 2), (3, 3)],
    chr = IntMap.fromList [(1, [0,1,2,3,4]), (2, [0,1,2,3,4]), (3, [0,1,2,3,4])],
    grp = IntMap.fromList [(1, []), (2, []), (3, [])],
    ray = IntMap.fromList [(1, toPPerm [0,1,2,3,4] 1), (2, toPPerm [0,1,2,3,4] 1), (3, toPPerm [0,1,2,3,4] 1)]
  }

step1GenSys = GenSys {
  rep = IntMap.fromList [(1, 1), (2, 2), (3, 3)],
  chr = IntMap.fromList [(1, [0,1,2,3,4]), (2, [1,2,3,4]), (3, [0,1,2,3,4])],
  grp = IntMap.fromList [(1, []), (2, [p [[1,4]]]), (3, [])],
  ray = IntMap.fromList [(1, toPPerm [0,1,2,3,4] 1), (2, toPPerm [1,2,3,4] 1), (3, toPPerm [0,1,2,3,4] 1)]
}

step2GenSys = GenSys {
  rep = IntMap.fromList [(1, 1), (2, 2), (3, 3)],
  chr = IntMap.fromList [(1, [0,1,2,3,4]), (2, [1,2,3,4]), (3, [0,1,2,3,4])],
  grp = IntMap.fromList [(1, [p [[2,3]]]), (2, [p [[1,4]]]), (3, [])],
  ray = IntMap.fromList [(1, toPPerm [0,1,2,3,4] 1), (2, toPPerm [1,2,3,4] 1), (3, toPPerm [0,1,2,3,4] 1)]
}

step3GenSys = GenSys {
  rep = IntMap.fromList [(1, 1), (2, 1), (3, 3)],
  chr = IntMap.fromList [(1, [0,1,2,3]), (3, [0,1,2,3,4])],
  grp = IntMap.fromList [(1, [p [[0,1]], p [[2,3]]]), (3, [])],
  ray = IntMap.fromList [(1, toPPerm [0,1,2,3] 1), (2, IntMap.fromList [(0,4),(1,1),(2,2),(3,3)]), (3, toPPerm [0,1,2,3,4] 1)]
}

extTest1 =
  assertEqual "" step1GenSys actual
  where
    actual = extend (q2, (IntMap.fromList [(1,4),(2,2),(3,3),(4,1)]), q2) initGenSys 

extTest2 =
  assertEqual "" step2GenSys actual
  where
    actual = extend (q1, (IntMap.fromList [(0,0),(1,1),(2,3),(3,2),(4,4)]), q1) step1GenSys 

extTest3 =
  assertEqual "" step3GenSys actual
  where
    actual = extend (q1, (IntMap.fromList [(0,4),(1,1),(2,2),(3,3)]), q2) step2GenSys 

algTest1 =
  assertBool "" $ raBisim dra (q1, IntMap.fromList [(0,4),(1,1),(2,2),(3,3)], q2)

algTest2 =
  assertBool "" . not $ raBisim dra (q1, IntMap.fromList [(0,0),(1,1),(2,2),(3,3)], q2)

algTest3 =
  assertBool "" $ raBisim dra (q2, IntMap.fromList [(1,4),(2,3),(3,2),(4,1)], q2)

sumTest1 =
  assertEqual "" expected (fst $ Automata.sum (Stack.lrStack 1) (Stack.lrStack 1))
  where
    r = [0]
    s = [0,1,2,3]
    a = IntMap.fromList [(0, []), (1, [0]), (2,[]), (3,[0])]
    t = [(0, 0, LFresh, 0, 1), (1, 1, Stored, 0, 0), (2, 0, LFresh, 0, 3), (3, 1, Stored, 0, 2)]
    expected =
      Auto {
        regs = r, 
        stts = s, 
        actv = a,
        trns = t
      }

sumTest2 =
  assertEqual "" expected (fst $ Automata.sum (Stack.lrStack 1) (Stack.rlStack 3))
  where
    r = [0,1,2]
    s = [0,1,2,3,4,5]
    a = IntMap.fromList [
          (0, []), 
          (1, [0]), 
          (2,[]), 
          (3,[2]),
          (4,[1,2]),
          (5,[0,1,2])
        ]
    t = [
          (0, 0, LFresh, 0, 1), 
          (1, 1, Stored, 0, 0),  
          (2, 0, LFresh, 2, 3),
          (3, 0, LFresh, 1, 4),
          (4, 0, LFresh, 0, 5), 
          (3, 1, Stored, 2, 2),
          (4, 1, Stored, 1, 3), 
          (5, 1, Stored, 0, 4)
        ]
    expected =
      Auto {
        regs = r, 
        stts = s, 
        actv = a,
        trns = t
      }

fra1 = 
  Auto { regs = [1,2], stts = [1,2,3,4], actv = av, trns = ts }
  where
    ts = [
        (1, a, GFresh, 1, 2),
        (2, a, GFresh, 1, 3),
        (3, a, GFresh, 1, 4)
      ]
    av = IntMap.fromList [(1,[]),(2,[1]),(3,[1]),(4,[1])]

fra2 = 
  Auto { regs = [1,2], stts = [1,2,3,4], actv = av, trns = ts }
  where
    ts = [
        (1, a, GFresh, 2, 2),
        (2, a, GFresh, 2, 3),
        (3, a, LFresh, 2, 4)
      ]
    av = IntMap.fromList [(1,[]),(2,[2]),(3,[2]),(4,[2])]

fra3 = 
  Auto { regs = [1,2], stts = [1,2], actv = av, trns = ts }
  where
    ts = [
        (1, a, GFresh, 1, 1),
        (2, a, LFresh, 2, 2)
      ]
    av = IntMap.fromList [(1,[1]),(2,[2])]

fra4 = 
  Auto { regs = [1,2], stts = [1,2,3,4], actv = av, trns = ts }
  where
    ts = [
        (1, a, GFresh, 1, 2),
        (2, a, GFresh, 2, 3),
        (3, a, LFresh, 2, 4)
      ]
    av = IntMap.fromList [(1,[]),(2,[1]),(3,[1,2]),(4,[1,2])]

fraBisimTest1 = 
  let (a, qf) = Automata.sum fra1 fra2
  in assertBool "" (not $ fraBisim a (1, IntMap.empty, qf 1))

fraBisimTest2 = 
  let (a, qf) = Automata.sum fra1 fra2
  in assertBool "" (fraBisim a (3, IntMap.fromList [(1,2)], qf 3))

fraBisimTest3 =
  assertBool "" (not $ fraBisim fra3 (1, IntMap.fromList [(1,2)], 2))

fraBisimTest4 = 
  let (a, qf) = Automata.sum fra1 fra4
  in assertBool "" (fraBisim a (1, IntMap.empty, qf 1))

fraBisimTest5 = 
  let (a, qf) = Automata.sum fra1 fra4
  in assertBool "" (fraBisim a (2, IntMap.fromList [(1,1)], qf 2))

fraBisimTest6 = 
  let (a, qf) = Automata.sum fra1 fra4
  in assertBool "" (fraBisim a (3, IntMap.fromList [(1,2)], qf 3))

fraBisimTest7 =
  let (a, qf) = Automata.sum fra1 fra4
  in assertBool "" (not $ fraBisim a (3, IntMap.empty, qf 3))

freshSuccsTest = 
  assertEqual "" expected actual
  where
    (a, qf) = Automata.sum fra1 fra4
    actual = fmap List.nub (succs a (Small 1) (2, IntMap.fromList [(1,1)], qf 2))
    expected = Just [(3, IntMap.fromList [(1,2),(2,1)], 8, Small 2)]
