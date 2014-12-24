{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
module Ohm.HTML
  ( -- * bootstrap operators
    bootstrapEl
  , container, row, col3, col6, col9
    
    -- * Utilities
  , mkButton
  , embedRenderer
    
    -- * Types
  , Renderer
    
    -- * Re-exported modules
  , module Control.Applicative
  , module Ohm.Internal.HTML
  , module Ohm.Internal.DOMEvent
  , lmap, dimap
  ) where
import Prelude hiding (div, head, map, mapM, sequence, span)
import Ohm.Internal.HTML
import Ohm.Internal.DOMEvent
import Control.Applicative
import Control.Lens
--import Data.Profunctor

type Renderer edom model = DOMEvent edom -> model -> HTML

bootstrapEl :: String -> [HTML] -> HTML
bootstrapEl cls = with div (classes .= [cls])

bsCol :: Int -> [HTML] -> HTML
bsCol n = bootstrapEl $ "col-sm-" ++ (show n)

container, row, col3, col6, col9 :: [HTML] -> HTML
container = bootstrapEl "container"
row = bootstrapEl "row"
col3 = bsCol 3
col6 = bsCol 6
col9 = bsCol 9

mkButton :: (() -> IO ()) -> HTML -> [String] -> HTML
mkButton msgAction btnTxt classList = 
  with button
    (do
       classes .= ["button", "btn"] ++ classList
       onClick $ DOMEvent msgAction)
    [btnTxt]
           
embedRenderer :: Renderer subE subM -> Prism' e subE -> Lens' m subM -> Renderer e m
embedRenderer subRenderer prsm l evt mdl = subRenderer converted focussed
  where
    converted = contramap (review prsm) evt 
    focussed = mdl ^. l
