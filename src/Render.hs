module Render (
  rootView) where

import Browser

rootView :: (Int,Int) -> HTML
rootView state = vtext "div" (show state)
