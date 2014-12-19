{-# LANGUAGE ImpredicativeTypes #-}
module Main where

import Control.Lens
import Pipes
--import Prelude hiding ((.))
import Data.Foldable (traverse_)
import Data.Monoid ((<>))
import Messages
import Render
import Component
import XHRIO

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

logMessage :: (Show a) => Processor a a IO
logMessage = (Processor $ liftIO . print)

chatMessageProcessor :: Processor ChatMessage ChatMessage IO
chatMessageProcessor = Processor $ \msg -> do
  void $ liftIO $ post_ "/test/" msg 
  yield msg

adapt :: (Monad m) => Processor e e m -> Prism' msg e -> Processor msg msg m
adapt (Processor p) prsm = Processor $ \msg ->
   traverse_ (p ~> (yield . review prsm)) . preview prsm $ msg
  
modelComp :: Component Message AppModel Message
modelComp = Component process rootView combined
  where
    combined = (adapt chatMessageProcessor _Chat)
            <> (adapt (Processor yield) _Count)
            <> logMessage

chatComp :: Component ChatMessage ChatModel ChatMessage
chatComp = Component processChat messagesRender chatMessageProcessor

main :: IO ()
main = do
  void $ runComponent (initialModel) modelComp
