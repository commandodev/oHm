{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}


module ChatTypes where

import GHC.Generics
import Data.Aeson as Aeson
import qualified Data.Text as Text

data AddUser = AddUser Text.Text deriving (Show, Generic)

instance Aeson.ToJSON AddUser
instance Aeson.FromJSON AddUser

data NumConnected = NumConnected !Int deriving (Show, Generic)

instance Aeson.ToJSON NumConnected
instance Aeson.FromJSON NumConnected

data NewMessage = NewMessage Text.Text deriving (Show, Generic)

instance Aeson.ToJSON NewMessage
instance Aeson.FromJSON NewMessage

data Said = Said Text.Text Text.Text deriving (Show, Generic)

instance Aeson.ToJSON Said
instance Aeson.FromJSON Said

data UserName = UserName Text.Text deriving (Show, Generic)

instance Aeson.ToJSON UserName
instance Aeson.FromJSON UserName

data UserJoined = UserJoined Text.Text Int deriving (Show, Generic)

instance Aeson.ToJSON UserJoined
instance Aeson.FromJSON UserJoined

