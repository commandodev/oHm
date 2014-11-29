module Main where

import Control.Concurrent.MVar
import Control.Concurrent.STM
import Control.Monad (forever)
import Control.Monad.Trans.State.Strict
import Pipes
import Pipes.Concurrent
import MVC

import Virtual
import Messages
import Render

-- | Source of events from the UI
input :: Input Message -> Controller Message
input clicks = asInput clicks

-- | Construct a @HTML@ tree from the world with a callback for clicks
model :: (Message -> IO ()) -> Model World Message HTML
model sendCB = asPipe $ forever $ do
  m <- await
  w <- lift $ get
  let w' = process m w
  lift $ put w'
  yield $ rootView sendCB w'

-- | Initial State
initialWorld :: World
initialWorld = (0, 0, const True, NotRequested)

-- | A callback the sends @Message@s to an @Output@
sendMessage :: Output Message -> Message -> IO ()
sendMessage output msg = do
  atomically $ void $ send output msg

-- | Processes click events, possible dispatching to second order producers
clickProcessor :: Input Message -> IO (Input Message)
clickProcessor uiClicks = do
  (out, inner) <- spawn Unbounded
  void $ forkIO $ runEffect $ for (fromInput uiClicks) $ flip queue out
  return inner

main :: IO ()
main = do
  (clicksOut, clicksIn) <- spawn (Bounded 10)
  processedClicks <- clickProcessor clicksIn
  let sendCB = sendMessage clicksOut
  void $ runMVC initialWorld (model sendCB) $ managed $ \k -> do
    treeState <- newMVar =<< renderSetup (rootView sendCB) initialWorld
    k (asSink (reRenderDiff treeState), input processedClicks)
    where
      reRenderDiff treeStateVar newTree = do
        modifyMVar treeStateVar $ \(TreeState {_node = oldNode, _tree = oldTree}) -> do
          let patches = diff oldTree newTree
          newNode <- patch oldNode patches
          return $ (makeTreeState newNode newTree, ())
