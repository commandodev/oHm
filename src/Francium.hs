{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
module Francium
  ( -- * Running Francium applications

    -- * Building HTML trees
    HTML
  , newTopLevelContainer
  , renderTo
  , DOMEvent
  , domChannel
  , clickChannel
  , liftIO
    -- * Re-exported modules
  , module Control.Applicative
  , lmap, dimap
  ) where

import Prelude hiding (div, mapM, sequence)

import Data.Profunctor
import Francium.HTML (HTML, newTopLevelContainer, renderTo)
import Francium.DOMEvent
import Control.Applicative
import Control.Monad.IO.Class
