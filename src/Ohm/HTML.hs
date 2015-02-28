{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE OverloadedStrings #-}

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
  , module VirtualDom
  , module Ohm.DOMEvent
  , lmap, dimap
  ) where
import Control.Lens hiding (aside, children, coerce, pre)
import GHCJS.Foreign
import VirtualDom
import VirtualDom.Prim
import Ohm.DOMEvent
import Control.Applicative
--import Data.Profunctor

type Renderer edom model = DOMEvent edom -> model -> HTML

bootstrapEl :: String -> [HTML] -> HTML
bootstrapEl cls = with div_ (classes .= [cls])

bsCol :: Int -> [HTML] -> HTML
bsCol n = bootstrapEl $ "col-sm-" ++ (show n)

container, row, col3, col6, col9 :: [HTML] -> HTML
container = bootstrapEl "container"
row = bootstrapEl "row"
col3 = bsCol 3
col6 = bsCol 6
col9 = bsCol 9

mkButton :: IO () -> HTML -> [String] -> HTML
mkButton msgAction btnTxt classList = 
  with button_
    (do
       classes .= ["button", "btn"] ++ classList
       on "click" msgAction)
    [btnTxt]
           
embedRenderer :: Renderer subE subM -> Prism' e subE -> Lens' m subM -> Renderer e m
embedRenderer subRenderer prsm l evt mdl = subRenderer converted focussed
  where
    converted = contramap (review prsm) evt 
    focussed = mdl ^. l

classes :: Traversal' HTMLElement [String]
classes = attributes . at "class" . anon "" (isEmptyStr . fromJSString) . iso (words . fromJSString) (toJSString . unwords)
  where isEmptyStr = (== ("" :: String))
