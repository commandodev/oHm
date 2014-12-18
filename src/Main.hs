{-# LANGUAGE ImpredicativeTypes #-}
module Main where

import Control.Lens
import Pipes
--import Prelude hiding ((.))
import Data.Foldable (traverse_)
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

type Matcher msg edom ein = (Prism' msg edom, edom -> Producer ein IO ())

feedModel :: CountMessage -> Producer CountMessage IO ()
feedModel domEvent = do
  yield domEvent
  liftIO $ print domEvent

chatMessageProcessor :: ChatMessage -> Producer ChatMessage IO ()
chatMessageProcessor msg = do
  void $ liftIO $ post_ "/test/" msg 
  yield msg


combinedProcessor
  :: Show msg
  => Matcher msg edom1 edom1
  -> Matcher msg edom2 edom2
  -> Processor msg msg IO
combinedProcessor m1 m2 msg = do
   liftIO $ print msg
   run m1 msg
   run m2 msg
   where
     run :: Matcher msg e e -> Processor msg msg IO
     run (prsm, p) = traverse_ (p ~> (yield . review prsm)) . preview prsm
  
modelComp :: Component Message AppModel Message
modelComp = Component process rootView combined
  where
    combined = combinedProcessor (_Chat, chatMessageProcessor)
                                 (_Count, yield)

chatComp :: Component ChatMessage ChatModel ChatMessage
chatComp = Component processChat messagesRender chatMessageProcessor


main :: IO ()
main = do
  void $ runComponent (initialModel) modelComp
