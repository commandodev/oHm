{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE OverloadedStrings #-}

module Render (rootView) where

import GHCJS.Types
import Virtual

foreign import javascript unsafe
  "console.log($1)" consoleLog :: JSString -> IO ()
rootView :: (Int,Int) -> HTML
rootView state = vnode "div" [vbutton (\_ -> consoleLog "Yay") "Click Me",
                              vtext "div" (show state)]
