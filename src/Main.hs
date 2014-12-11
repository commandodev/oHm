module Main where

import Control.Monad (forever, void)
import Control.Monad.Trans.State.Strict
import Pipes
import qualified Pipes.Prelude as P
import Prelude hiding ((.))
import MVC

import Messages
import Render
import Component

-- | Construct a @HTML@ tree from the world with a callback for clicks
appModel ::  Model AppModel Message AppModel
appModel = asPipe $ forever $ do
  m <- await
  w <- lift $ get
  let w' = process m w
  lift $ put w'
  yield w'
  
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

-- chatRoute :: ChatMessage -> Route a
-- chatRoute m@(Typing s) = Local m
-- chatRoute (EnterMessage (name, msg)) = Remote (NewChatMessage name msg)


comp :: Component Message AppModel Message
comp = Component appModel rootView

main :: IO ()
main = do
  void $ runComponent initialModel (P.map id)
