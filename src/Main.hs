module Main where

import Control.Concurrent.STM
import Control.Category ((.))
import Control.Monad (forever, void)
import Control.Monad.Trans.State.Strict
import Pipes
import qualified Pipes.Prelude as P
import Pipes.Concurrent
import Prelude hiding ((.))
import MVC

import Francium
import Messages
import Render

-- | Construct a @HTML@ tree from the world with a callback for clicks
model ::  Model AppModel Message AppModel
model = asPipe $ forever $ do
  m <- await
  w <- lift $ get
  let w' = process m w
  lift $ put w'
  yield w'

toHtml :: (a -> HTML) -> Model s a HTML
toHtml = asPipe . P.map


-- | A callback the sends @Message@s to an @Output@
sendMessage :: Output Message -> Message -> IO ()
sendMessage output msg = do
  atomically $ void $ send output msg
  
initialModel :: AppModel
initialModel = AppModel {
    _chat = ChatModel {
        _messages = [ ("Ben", "test")
                    , ("Kris", "Hi")
                    ]
      , _userName = "Ben"
      , _msgBox    = ""
      }
  , _counter = 0
  }


main :: IO ()
main = do
  (clicksOut, clicksIn) <- spawn (Bounded 10)
  putStrLn "Starting up.."
  let viewFn = rootView (domChannel clicksOut)
  void $ runMVC initialModel (model) $ managed $ \k -> do
    pres <- newTopLevelContainer
    putStrLn "Rendering"
    renderTo pres $ viewFn initialModel
    putStrLn "Rendered"
    k (asSink (render viewFn pres), asInput clicksIn)
   
  where
  render viewFn pres appState = do
    print appState
    renderTo pres $ viewFn appState
    
