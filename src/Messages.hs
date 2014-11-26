module Messages where

type World = (Int,Int)

data Message = IncFst Int
             | IncSnd Int deriving (Show, Eq)

process :: Message -> World -> World
process (IncFst n) (a, b) = (a + n, b)
process (IncSnd n) (a, b) = (a, b + n)
