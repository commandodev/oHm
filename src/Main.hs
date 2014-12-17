{-# LANGUAGE ImpredicativeTypes #-}
module Main where

import Control.Lens
import Control.Lens.Prism
import Pipes
--import Prelude hiding ((.))
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


-- chatRoute :: ChatMessage -> Route a
-- chatRoute m@(Typing s) = Local m
-- chatRoute (EnterMessage (name, msg)) = Remote (NewChatMessage name msg)

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
  :: Matcher msg edom1 ein1
  -> Matcher msg edom2 ein2
  -> (msg -> Producer msg IO ())
combinedProcessor (prsm1, prod1) (prsm2, prod2) = \msg ->
   over prsm1._Just prod1-- prod1 ~> \m -> yield (m ^. pre prsm1)
  
modelComp :: Component Message AppModel Message
modelComp = Component process rootView combined
  where
    combined = combinedProcessor (_Chat, chatMessageProcessor)
                                 (_Count, yield)

chatComp :: Component ChatMessage ChatModel ChatMessage
chatComp = Component processChat messagesRender chatMessageProcessor


main :: IO ()
main = do
  void $ runComponent (_chat initialModel) chatComp -- modelComp
