{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric #-}

module Messages where

import GHC.Generics
import Data.Aeson hiding ((.=))
import Control.Lens
import Control.Monad.Trans.State

type Name = String
type Said = String
              
data ChatModel = ChatModel {
    _messages :: [(Name, Said)]
  , _userName :: Name
  , _msgBox :: String
  } deriving (Show)

data AppModel = AppModel {
    _chat :: ChatModel
  , _counter :: Int
  } deriving Show
  
makeLenses ''ChatModel
makeLenses ''AppModel

data CountMessage = Incr | Decr deriving (Show, Generic)

makePrisms ''CountMessage

instance ToJSON CountMessage
instance FromJSON CountMessage


data ChatMessage = 
   Typing String
 | EnterMessage (Name, Said)
 deriving (Show, Generic)

makePrisms ''ChatMessage

instance ToJSON ChatMessage
instance FromJSON ChatMessage


data Message = 
    Count CountMessage
  | Chat ChatMessage deriving (Show, Generic)

makePrisms ''Message
  
instance ToJSON Message
instance FromJSON Message

  
-- data Message
--   = Inc Increment
--   | FilterCurrency (Maybe String)
--   | FetchMarket
--   | MarketPending
--   | MarketResponse (Either String [Market])
--   deriving (Show)


process :: Message -> AppModel -> AppModel
process (Count msg) model = model & counter %~ fn
  where fn = case msg of
               Incr -> succ
               Decr -> pred
process (Chat msg) model = model & chat %~ processChat msg

processChat :: ChatMessage -> ChatModel -> ChatModel
processChat (Typing s) model = model & msgBox .~ s
processChat (EnterMessage message) model = flip execState model $ do
  msgBox .= ""
  messages %= (message:)
