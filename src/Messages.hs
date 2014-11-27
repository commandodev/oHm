{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module Messages where

import Ajax
import Control.Monad
import Pipes.Concurrent

data Pending a
  = NotRequested
  | Loading
  | Value a deriving (Show)
type World = (Int,Int,Pending String)

data Message
  = IncFst Int
  | IncSnd Int
  | IncBoth Int Int
  | FetchAjax
  | AjaxPending
  | AjaxResponse String

process :: Message -> World -> World
process (IncFst n) (a,b,c) = (a + n,b,c)
process (IncSnd n) (a,b,c) = (a,b + n,c)
process AjaxPending (a,b,_) = (a,b,Loading)
process (AjaxResponse s) (a,b,_) = (a,b, Value s)
process _ w = w

queue :: Message -> Output Message -> IO Bool
queue (IncBoth x y) output = atomically $ send output (IncFst x) >> send output (IncSnd y)
queue FetchAjax output =
  do _ <- atomically (send output AjaxPending)
     (output2,input2) <- spawn Single
     _ <- get "https://api.github.com/users/boothead" output2
     _ <- forkIO $
          void $
          atomically $
          do Just response <- recv input2
             send output (AjaxResponse response)
     return True
queue _ _ = return True
