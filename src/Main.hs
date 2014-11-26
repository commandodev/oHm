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

handler :: (World -> HTML) -> TVar World -> TreeState -> Consumer Message IO ()
handler view worldState tree =
  forever $
  do msg <- await
     newVal <- lift $
               atomically $
               swap worldState (process msg)
     lift $
       rerender view newVal tree

sendMessage :: Output Message -> Message -> IO ()
sendMessage output msg = atomically $ send output msg >> return ()

main :: IO ()
main =
  do (worldState,val) <- atomically $
                   do let val = (0,0)
                      worldState <- newTVar val
                      return (worldState,val)
     (output,input) <- spawn (Bounded 10)
     let renderer = rootView (sendMessage output)
     initialTree <- renderSetup renderer val
     runEffect $
       fromInput input >->
       handler renderer worldState initialTree
