module Main where

import Control.Concurrent.MVar
import Control.Concurrent.STM
import Control.Monad (void)
import Control.Monad.Trans.State.Strict
import Pipes
import Pipes.Concurrent
import MVC
import MVC.Prelude

import Virtual
import Messages
import Render

input :: Input Message -> Controller Message
input clicks = asInput clicks

model :: Model World Message HTML
model = asPipe $ do
  m <- await
  lift $ modify $ process m
  

vdomView :: View HTML
vdomView = undefined

initialWorld = (0, 0, NotRequested)

sendMessage :: Output Message -> Message -> IO ()
sendMessage output msg = do
  print msg
  atomically $ void $ send output msg

main = runMVC initialWorld model $ managed $ \k -> do


  (clicksOut, clicksIn) <- spawn (Bounded 10)
  treeState <- newMVar =<< renderSetup (rootView (sendMessage clicksOut)) initialWorld
  body <- documentBody
  k (asSink (reRenderDiff treeState), input clicksIn)
  where
    reRenderDiff treeStateVar newTree = do
      modifyMVar treeStateVar $ \(TreeState {_node = oldNode, _tree = oldTree}) -> do
        let patches = diff oldTree newTree
        newNode <- patch oldNode patches
        return $ (makeTreeState newNode newTree, ())
  
