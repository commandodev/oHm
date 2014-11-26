{-# language ExtendedDefaultRules #-}
{-# language OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

module Main where

import Render
import Virtual
import Control.Monad
import Control.Concurrent.STM
import Pipes
import Pipes.Concurrent
import Messages

swap :: TVar a -> (a -> a) -> STM a
swap a f = modifyTVar a f >> readTVar a

handler :: TVar World -> (World -> HTML) -> TreeState -> Consumer Message IO ()
handler atom view tree = forever $ do
     msg <- await
     newVal <- lift $ atomically $ swap atom (process msg)
     lift $ rerender view newVal tree

main :: IO TreeState
main =
  do (atom,val) <- atomically $
                   do let val = (0,0)
                      atom <- newTVar val
                      return (atom,val)
     (output,input) <- spawn (Bounded 10)
     tree <- renderSetup (rootView output)
                         val
     _ <- runEffect $ fromInput input >-> handler atom (rootView output) tree
     return tree
