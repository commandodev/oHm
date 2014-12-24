{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric #-}

module Messages where

import GHC.Generics
import Data.Aeson hiding ((.=))
import Data.Set
import qualified Data.Set as S
import Data.Text (Text)
import Control.Lens

import ChatTypes

data View =
    LoginView
  | ChatView
  deriving (Show, Generic)
  
instance ToJSON View
instance FromJSON View

              
data ChatModel = ChatModel {
    _messages :: [Said]
  , _peopleChatting :: Set Text
  , _peopleTyping :: Set Text
  , _userName :: Maybe Text
  , _nConnected :: Int
  , _msgBox :: Text
  } deriving (Show)

data LoginModel = LoginModel {
   _loginBox :: Text
   } deriving (Show)

data AppModel = AppModel {
    _currentView :: View
  , _chat :: ChatModel
  , _login :: LoginModel
  } deriving Show
  
makeLenses ''ChatModel
makeLenses ''LoginModel
makeLenses ''AppModel


data ChatMessage = 
   EnteringText Text
 | SomeoneTyping UserName
 | StopTyping UserName
 | SetName UserName
 | NewUser UserJoined
 | UserLeft UserJoined
 | EnterMessage Said
 deriving (Show, Generic)

makePrisms ''ChatMessage

instance ToJSON ChatMessage
instance FromJSON ChatMessage

data LoginMessage = 
   EnteringName Text
 | UserLogin Text
 deriving (Show, Generic)

makePrisms ''LoginMessage

instance ToJSON LoginMessage
instance FromJSON LoginMessage


data Message = 
    SwitchView View
  | Login LoginMessage
  | Chat ChatMessage
  deriving (Show, Generic)

makePrisms ''Message
  
instance ToJSON Message
instance FromJSON Message


process :: Message -> AppModel -> AppModel
process (SwitchView v) model = model & currentView .~ v

process (Login (EnteringName uName)) model = model & login.loginBox .~ uName
process (Login (UserLogin uName)) model = model &~ do
    login.loginBox .= ""
    chat.userName .= Just uName
    
process (Chat msg) model = model & chat %~ processChat msg

processChat :: ChatMessage -> ChatModel -> ChatModel
processChat (EnteringText s) model = model & msgBox .~ s
processChat (SomeoneTyping (UserName n)) model = model & peopleTyping %~ (S.insert n)
processChat (StopTyping (UserName n)) model = model & peopleTyping %~ (S.delete n)
processChat (SetName (UserName n)) model = model & userName .~ Just n
processChat (NewUser (UserJoined n c)) model = model &~ do
  nConnected .= c
  peopleChatting %= (S.insert n)
processChat (UserLeft (UserJoined n c)) model = model &~ do
  nConnected .= c
  peopleChatting %= (S.delete n) 
processChat (EnterMessage message) model = model &~ do
   messages %= (message:)
   msgBox .= ""
