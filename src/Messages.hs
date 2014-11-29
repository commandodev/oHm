{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}

module Messages where

import Ajax
import Control.Monad
import Data.Aeson
import MarketData
import qualified Data.ByteString.Lazy.Char8 as BSL
import Control.Monad.IO.Class
import Pipes
import Pipes.Concurrent

type World = (Int,Int,Market -> Bool,Pending [Market])

data Pending a
  = NotRequested
  | NotFound
  | Loading
  | Loaded a
  | LoadFailed String
  deriving (Eq,Show)

data Message
  = IncFst Int
  | IncSnd Int
  | IncBoth Int
            Int
  | FilterCurrency (Maybe String)
  | FetchMarket
  | MarketPending
  | MarketResponse (Either String [Market])
  deriving (Show)

process :: Message -> World -> World
process (IncFst n) (a,b,c,d) = (a + n,b,c,d)
process (IncSnd n) (a,b,c,d) = (a,b + n,c,d)
process MarketPending (a,b,c,_) = (a,b,c,Loading)
process (FilterCurrency Nothing) (a,b,_,d) = (a,b,const True,d)
process (FilterCurrency (Just x)) (a,b,_,d) =
  (a
  ,b
  ,\market ->
     x ==
      currency market
  ,d)
process (MarketResponse (Left e)) (a,b,c,_) = (a,b,c,LoadFailed e)
process (MarketResponse (Right u)) (a,b,c,_) = (a,b,c,Loaded u)
process _ w = w

jsonToMarket :: Maybe String -> Either String [Market]
jsonToMarket (Just x) = eitherDecode (BSL.pack x)
jsonToMarket Nothing = Left "Nothing supplied."

queue :: (MonadIO m) => Message -> Output Message -> Effect m ()

-- We could process IncBoth directly easily enough. Instead, here's how to process it by applying two submessages.
queue (IncBoth x y) output = liftIO $ do
  void $ atomically $ send output (IncFst x) >> send output (IncSnd y)

queue FetchMarket output = liftIO $ do
  _ <- atomically (send output MarketPending)
  (output2, input2) <- spawn Single
  _ <- get "/markets.json" output2
  void $ forkIO $
     void $
     atomically $
     do response <- recv input2
        send output (MarketResponse (jsonToMarket response))
queue m o = liftIO . void . atomically $ send o m
