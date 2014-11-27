{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}

module Messages where

import Ajax
import Control.Applicative
import Control.Monad
import Data.Aeson
-- Aeson's "encode" to json generates lazy bytestrings
import qualified Data.ByteString.Lazy.Char8 as BSL
import Pipes.Concurrent

data Pending a
  = NotRequested
  | NotFound
  | Loading
  | Loaded a deriving (Show)

type World = (Int,Int,Pending User)

data User =
  User {login :: String
       ,id :: Integer} deriving (Eq, Show)

instance FromJSON User where
  parseJSON (Object v) = User <$> v .: "login" <*> v .: "id"
  parseJSON _          = mzero

data Message
  = IncFst Int
  | IncSnd Int
  | IncBoth Int Int
  | FetchAjax
  | AjaxPending
  | AjaxResponse (Maybe User)

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

queue :: Message -> Output Message -> IO Bool

-- We could process IncBoth directly easily enough. Instead, here's how to process it by applying two submessages.
queue (IncBoth x y) output = atomically $ send output (IncFst x) >> send output (IncSnd y)

queue FetchAjax output =
  do _ <- atomically (send output AjaxPending)
     (output2,input2) <- (spawn Single)::IO (Output String, Input String)
     _ <- get "https://api.github.com/users/boothead" output2
     _ <- forkIO $
          void $
          atomically $
          do response <- recv input2
             send output (AjaxResponse (jsonToUser response))
     return True
queue _ _ = return True
