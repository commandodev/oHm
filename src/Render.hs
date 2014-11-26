{-# LANGUAGE CPP #-}

module Render (rootView) where

import Pipes.Concurrent
import Messages
import Virtual

div_ :: [HTML] -> HTML
div_ = vnode "div"

rootView :: (Output Message) -> (Int,Int) -> HTML
rootView output state =
  div_ [vbutton click1 "+(5, 0)"
       ,vbutton click2 "+(0, 3)"
       ,vtext "div" (show state)]
  where click1 _ = atomically $ send output (IncFst 5) >> return ()
        click2 _ = atomically $ send output (IncSnd 3) >> return ()
