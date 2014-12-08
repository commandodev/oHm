module Francium.DOMEvent where

import Control.Concurrent.STM
import Control.Monad (void)
import Data.Functor.Contravariant
import Pipes.Concurrent

data DOMEvent a = DOMEvent { channel :: a -> IO () }

instance Contravariant DOMEvent where
  contramap f (DOMEvent chan) = DOMEvent (chan . f)

domChannel :: (Show a) => Output a -> DOMEvent a
domChannel chan = DOMEvent f
  where 
  f a = do
    print a
    void . atomically $ send chan a 

clickChannel :: Output a -> a -> DOMEvent ()
clickChannel chan msg = DOMEvent $ const $ void . atomically $ send chan msg
