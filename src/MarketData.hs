{-# LANGUAGE DeriveGeneric #-}

module MarketData where

import Control.Monad
import Data.Aeson
import Data.Time
import GHC.Generics (Generic)
import Data.Time.Clock.POSIX

newtype EpochTime =
  EpochTime {time :: UTCTime}
  deriving (Show,Eq)

instance FromJSON EpochTime where
  parseJSON (Number v) =
    return $
    EpochTime $
    (posixSecondsToUTCTime . fromIntegral) (floor v :: Integer)
  parseJSON _ = mzero

data Market =
  Market {volume :: Maybe Double
         ,latest_trade :: EpochTime
         ,bid :: Maybe Double
         ,ask :: Maybe Double
         ,high :: Maybe Double
         ,low :: Maybe Double
         ,close :: Maybe Double
         ,avg :: Maybe Double
         ,currency :: String
         ,currency_volume :: Maybe Double
         ,symbol :: String}
  deriving (Show,Eq,Generic)

instance FromJSON Market
