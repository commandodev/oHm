{-# LANGUAGE ImpredicativeTypes #-}
module Main where

import Control.Lens
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
  -> (msg -> Producer msg IO ())
combinedProcessor (prsm1, prod1) (prsm2, prod2) msg = do
   liftIO $ print msg
   run prsm1 msg prod1
   run prsm2 msg prod2
   -- flip (prsm1) msg (prod1 ~> (yield . review prsm1))
   -- Expected type: (edom1 -> Proxy X () () msg IO edom1)
   --              -> msg -> Proxy X () () msg IO ()
   -- Actual type: (edom1 -> Proxy X () () msg IO edom1)
   --             -> msg -> Proxy X () () msg IO msg
   where
     run :: Prism' msg sub -> msg -> (sub -> Producer sub IO ()) -> Producer msg IO ()
     run prsm m p = case matching prsm m of
        Left  _ -> return ()
        Right x -> for (p x) $ (yield . review prsm)
--   flip prsm2 msg prod2
   
  
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
