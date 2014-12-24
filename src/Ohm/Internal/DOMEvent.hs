module Ohm.Internal.DOMEvent (
    DOMEvent(..)
  , domChannel
  , clickChannel
  ) where

import Control.Concurrent.STM
import Control.Monad (void)
import Data.Functor.Contravariant
import Pipes.Concurrent

data DOMEvent a = DOMEvent { channel :: a -> IO () }

instance Contravariant DOMEvent where
  contramap f (DOMEvent chan) = DOMEvent (chan . f)

domChannel :: Output a -> DOMEvent a
domChannel chan = DOMEvent (void . atomically . send chan)


clickChannel :: Output a -> a -> DOMEvent ()
clickChannel chan msg = DOMEvent $ const $ void . atomically $ send chan msg
