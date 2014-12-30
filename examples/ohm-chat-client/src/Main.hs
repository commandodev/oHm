{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
module Main where

import Control.Lens
import Control.Monad.STM
import Control.Monad.Trans.Reader
import Data.Aeson (ToJSON)
import qualified Data.Set as S
import Pipes
import qualified Pipes.Concurrent as PC
--import Prelude hiding ((.))
import Control.Applicative
import Data.Foldable (traverse_)
import Data.Monoid ((<>))
import Messages
import Render
import Ohm.Component
import ChatTypes
import Ohm.SocketIO ( SocketIO, socketIONew, socketIOWaitForConnection, socketIOOpen
                , sioSend, sioSend_, sioSub
                )

initialModel :: AppModel
initialModel = AppModel {
    _currentView = LoginView
  , _chat = ChatModel {
        _messages = []
      , _peopleChatting = S.empty
      , _peopleTyping = S.empty
      , _userName = Nothing
      , _nConnected = 0
      , _msgBox    = ""
      }
  , _login = LoginModel {
        _loginBox = ""
      }
  }
  
data Env = Env {
    ws :: SocketIO
  }
  
type ProcessorMonad = ReaderT Env IO

logMessage :: (Show a, MonadIO m) => String -> a -> m () 
logMessage msg a = liftIO . putStrLn $ msg ++ ": " ++ (show a)

wsEmit :: (ToJSON a) => String -> a -> ProcessorMonad ()
wsEmit chan msg = do
  sio <- ws <$> ask
  liftIO $ sioSend sio chan msg

wsEmit_ :: String -> ProcessorMonad ()
wsEmit_ chan = do
  sio <- ws <$> ask
  liftIO $ sioSend_ sio chan


chatMessageProcessor :: Processor ChatMessage ChatMessage ProcessorMonad
chatMessageProcessor = Processor $ \msg -> do
  case msg of
    EnteringText _ -> do
      lift $ wsEmit_ "typing"
      yield msg
    EnterMessage (Said _ m) -> do
      logMessage "SAID" msg
      lift $ wsEmit "new message" $ NewMessage m 
      lift $ wsEmit_ "stop typing"
    SomeoneTyping _   -> lift $ wsEmit_ "typing"
    StopTyping _      -> lift $ wsEmit_ "stop typing"
    _ -> return ()
  yield msg

appMessageProcessor :: Processor Message Message ProcessorMonad
appMessageProcessor = Processor $ \msg -> do
  case msg of
    Login (UserLogin uName) -> do
      logMessage "LOGIN" msg
      lift $ wsEmit "add user" (AddUser uName)
      yield (SwitchView ChatView)
      yield msg
    m@(Login (EnteringName _)) -> do
      logMessage "ENTERINGNAME" m
      yield m
    _ -> return ()

adapt :: (Monad m) => Processor e e m -> Prism' msg e -> Processor msg msg m
adapt (Processor p) prsm = Processor $ \msg ->
   traverse_ (p ~> (yield . review prsm)) . preview prsm $ msg
  
modelComp :: Component Env Message AppModel Message
modelComp = Component process rootView combined
  where
    combined = (adapt chatMessageProcessor _Chat)
            <> appMessageProcessor

main :: IO ()
main = do
  s <- socketIONew "http://localhost:8000"
  putStrLn "socket"
  socketIOOpen s
  putStrLn "open"
  socketIOWaitForConnection s
  putStrLn "connected"
  modelEvents <- runComponent (initialModel) (Env s) modelComp
  sioSub s "new message" $ sendToModel modelEvents (Chat . EnterMessage)
  sioSub s "user joined" $ sendToModel modelEvents (Chat . NewUser)
  sioSub s "user left"   $ sendToModel modelEvents (Chat . UserLeft)
  --sioSub s "login"       $ sendToModel modelEvents (Chat . NewUser)
  sioSub s "typing"      $ sendToModel modelEvents (Chat . SomeoneTyping)
  sioSub s "stop typing" $ sendToModel modelEvents (Chat . StopTyping)
  
  where
    sendToModel evts f = void . atomically . PC.send evts . f
