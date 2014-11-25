module Render (rootView) where

import Virtual

rootView :: (Int,Int) -> HTML
rootView state = vtext "div" (show state)
