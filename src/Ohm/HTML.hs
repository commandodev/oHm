{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts #-}

module Ohm.HTML
  ( -- * bootstrap operators
    bootstrapEl
  , container, row, col3, col6, col9
    
    -- * Utilities
  , mkButton
  , embedRenderer
  
    -- * Callbacks
  , onClick
  , onChange
  , onKeyPress
  , onInput
    
    -- * Types
  , Renderer
    
    -- * Re-exported modules
  , module Control.Applicative
  , module VirtualDom
  , module Ohm.DOMEvent
  , module GHCJS.Types
  , lmap, dimap
  ) where
import Control.Lens hiding (aside, children, coerce, pre)
import Control.Monad.State
import Data.Foldable
import GHCJS.Foreign
import GHCJS.Marshal
import GHCJS.Types
import GHCJS.DOM.Event
import GHCJS.DOM.HTMLInputElement
import GHCJS.DOM.Types (GObject, toGObject, unsafeCastGObject)
import GHCJS.DOM.UIEvent
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

mkButton :: (JSRef Event -> IO ()) -> HTML -> [String] -> HTML
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


preventDefault :: JSRef Event -> IO ()
preventDefault evt = traverse_ eventPreventDefault =<< fromJSRef evt

onInput :: MonadState HTMLElement m => DOMEvent String -> m ()
onInput chan = on "input" f
  where
  f evt = do
    t <- fromJSRef evt
    for_ t (\t' -> do
      t'' <- eventGetTarget t'
      for_ t''
        (htmlInputElementGetValue .
         castToHTMLInputElement >=> (channel chan)))

onClick :: MonadState HTMLElement m => DOMEvent () -> m ()
onClick chan = on "click" $ (void . preventDefault >=> channel chan)

onChange :: MonadState HTMLElement m => DOMEvent () -> m ()
onChange chan = on "change" $ (void . preventDefault >=> channel chan)

onKeyPress :: MonadState HTMLElement m => DOMEvent Int -> m ()
onKeyPress (DOMEvent chan) = on "keypress" f
  where
  f evt = do
    t <- fromJSRef evt
    for_ t
         (uiEventGetKeyCode .
          -- A little messy, but we're working with a dom-delegator 'KeyEvent' here.
          (unsafeCastGObject :: GObject -> UIEvent) .
           toGObject >=> chan)
