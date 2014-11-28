{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}

module Messages where

import Ajax
import Control.Monad
import Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as BSL
import Control.Monad.IO.Class
import Pipes
import Pipes.Concurrent
import GHC.Generics (Generic)

type World = (Int,Int,Pending User)

data User =
  User {login :: !String
       ,name :: !String
       ,email :: String
       ,id :: Integer}
  deriving (Show,Generic)

instance FromJSON User
instance ToJSON User

data Pending a
  = NotRequested
  | NotFound
  | Loading
  | Loaded a deriving (Eq,Show)

data Message
  = IncFst Int
  | IncSnd Int
  | IncBoth Int Int
  | FetchAjax
  | AjaxPending
  | AjaxResponse (Maybe User)
  deriving (Show)

process :: Message -> World -> World
process (IncFst n) (a,b,c) = (a + n,b,c)
process (IncSnd n) (a,b,c) = (a,b + n,c)
process AjaxPending (a,b,_) = (a,b,Loading)
process (AjaxResponse (Just u)) (a,b,_) = (a,b, Loaded u)
process (AjaxResponse Nothing) (a,b,_) = (a,b, NotFound)
process _ w = w

jsonToUser :: Maybe String -> Maybe User
jsonToUser (Just x) = decode (BSL.pack x)
jsonToUser Nothing = Nothing

queue :: (MonadIO m) => Message -> Output Message -> Effect m ()
queue (IncBoth x y) output = liftIO $ do
  void $ atomically $ send output (IncFst x) >> send output (IncSnd y)

queue FetchAjax output = liftIO $ do
  _ <- atomically (send output AjaxPending)
  (output2, input2) <- spawn Single
  _ <- get "https://api.github.com/users/boothead" output2
  void $ forkIO $
     void $
     atomically $
     do response <- recv input2
        send output (AjaxResponse (jsonToUser response))
queue m o = liftIO . void . atomically $ send o m
