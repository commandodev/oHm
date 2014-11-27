{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}

module Messages where

import Ajax
import Control.Monad
import Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as BSL
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
  | FetchGithubUser String
  | GithubUserPending
  | GithubUserResponse (Maybe User)

process :: Message -> World -> World
process (IncFst n) (a,b,c) = (a + n,b,c)
process (IncSnd n) (a,b,c) = (a,b + n,c)
process GithubUserPending (a,b,_) = (a,b,Loading)
process (GithubUserResponse (Just u)) (a,b,_) = (a,b, Loaded u)
process (GithubUserResponse Nothing) (a,b,_) = (a,b, NotFound)
process _ w = w

jsonToUser :: Maybe String -> Maybe User
jsonToUser (Just x) = decode (BSL.pack x)
jsonToUser Nothing = Nothing

queue :: Message -> Output Message -> IO Bool

-- We could process IncBoth directly easily enough. Instead, here's how to process it by applying two submessages.
queue (IncBoth x y) output =
  atomically $
  send output (IncFst x) >>
  send output (IncSnd y)

-- This is more interesting, and show that we can display a loading
-- message while we wait for the data to return.
queue (FetchGithubUser username) output =
  do _ <- atomically (send output GithubUserPending)
     (output2,input2) <- spawn Single
     _ <- request output2
     _ <- forkIO $
          void $
          atomically $
          do response <- recv input2
             send output ((GithubUserResponse . jsonToUser) response)
     return True
  where request = get ("https://api.github.com/users/" ++ username)
queue _ _ = return True
