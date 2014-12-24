{-# LANGUAGE TypeFamilies #-}
module Internal.Immutable
  ( Map
  , empty
  , insert
  ) where

import Prelude hiding (lookup)

import Control.Applicative hiding (empty)
import Control.Lens
import GHCJS.Marshal
import GHCJS.Types

data Immutable

newtype Map = Map (JSRef Immutable)

type instance IxValue Map = JSString
type instance Index Map = JSString

instance Ixed Map where
  ix k f m =
    case lookup k m of
     Just v  -> f v <&> \v' -> insert k v' m
     Nothing -> pure m

instance At Map where
  at k f m = f mv <&> \r -> case r of
    Nothing -> maybe m (const (delete k m)) mv
    Just v' -> insert k v' m
    where mv = lookup k m

lookup :: JSString -> Map -> Maybe JSString
lookup k m = let v = jsLookup k m
             in if isNull v
                  then Nothing
                  else Just v

foreign import javascript safe
  "Immutable.Map()" empty :: Map

foreign import javascript safe
  "$3.set($1, $2)" insert :: JSString -> JSString -> Map -> Map

foreign import javascript safe
  "$2.get($1)" jsLookup :: JSString -> Map -> JSString

foreign import javascript safe
  "$2.remove($1)" delete :: JSString -> Map -> Map

instance ToJSRef Map where
  toJSRef = return . toJS

foreign import javascript safe
  "$1.toJS()" toJS :: Map -> JSRef a
