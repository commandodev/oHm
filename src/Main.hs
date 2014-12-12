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

feedModel :: Output Message -> Consumer Message IO ()
feedModel modelIn = forever $ do
  msg <- await
  liftIO $ do
    print msg
    void $ atomically $ send modelIn msg

comp :: Component Message AppModel Message
comp = Component process rootView feedModel

main :: IO ()
main = do
  void $ runComponent initialModel comp
