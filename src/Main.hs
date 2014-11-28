module Main where

import Control.Concurrent.MVar
import Control.Concurrent.STM
import Control.Monad (void, forever)
import Control.Monad.Trans.State.Strict
import Pipes
import qualified Pipes.Prelude as P
import Pipes.Concurrent
import MVC
import MVC.Prelude

import Virtual
import Messages
import Render

input :: Input Message -> Controller Message
input clicks = asInput clicks

model :: (Message -> IO ()) -> Model World Message HTML
model sendCB = asPipe $ forever $ do
  m <- await
  w <- lift $ get 
  let w' = process m w
  lift $ put w'
  yield $ rootView sendCB w'
  

vdomView :: View HTML
vdomView = undefined

initialWorld = (0, 0, NotRequested)

sendMessage :: Output Message -> Message -> IO ()
sendMessage output msg = do
  print msg
  atomically $ void $ send output msg
  
handler :: Output Message -> Input Message -> IO (Input Message)
handler output input = do
  (out, inner) <- spawn Single
  forkIO $ runEffect $ for (fromInput input) $ \msg -> do
    queue msg out
  return inner
  
  -- do msg <- await
  --    _ <- lift $ queue msg output
  --    newVal <- lift $
  --              atomically $
  --              swap worldState (process msg)
  --    lift $
  --      rerender view newVal tree

main = do
  (clicksOut, clicksIn) <- spawn (Bounded 10)
  processedClicks <- handler clicksOut clicksIn
  let sendCB = sendMessage clicksOut
  runMVC initialWorld (model sendCB) $ managed $ \k -> do
    treeState <- newMVar =<< renderSetup (rootView sendCB) initialWorld
    body <- documentBody
    k (asSink (reRenderDiff treeState), input processedClicks)
    where
      reRenderDiff treeStateVar newTree = do
        modifyMVar treeStateVar $ \(TreeState {_node = oldNode, _tree = oldTree}) -> do
          let patches = diff oldTree newTree
          newNode <- patch oldNode patches
          return $ (makeTreeState newNode newTree, ())
  
